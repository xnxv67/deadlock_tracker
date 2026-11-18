#!/usr/bin/env python3
"""
Network Watchdog
================

A small "watchdog timer" for unstable network environments.

It runs a target process, tails its combined stdout/stderr, and when a network-
related error pattern is detected (for example HTTP 429 or a timeout), it:

1. Stops the target process.
2. Executes a recovery command (by default: `warp-cli disconnect && warp-cli connect`)
   to refresh network routes/connectivity.
3. Restarts the target process.

Designed as a universal DevOps helper to keep long-running/background jobs alive
during transient connectivity issues.

Examples:
    python tools/network_watchdog.py -- opencode
    python tools/network_watchdog.py --pattern 429 --pattern Timeout -- python worker.py
    python tools/network_watchdog.py --recovery-cmd "ipconfig /renew" -- cmd /c myjob.bat
    python tools/network_watchdog.py --shell-cmd "npm run dev"
"""

from __future__ import annotations

import argparse
import os
import re
import shlex
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime
from typing import Iterable, List, Optional, Sequence


DEFAULT_PATTERNS = [
    r"\b429\b",
    r"timeout",
    r"timed out",
    r"ETIMEDOUT",
    r"ECONNRESET",
    r"ECONNREFUSED",
    r"EAI_AGAIN",
    r"temporarily unavailable",
    r"rate limit",
]
DEFAULT_RECOVERY_CMD = "warp-cli disconnect && warp-cli connect"


def log(message: str, *, stream=None) -> None:
    stream = stream or sys.stdout
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] [watchdog] {message}", file=stream, flush=True)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="network_watchdog",
        description="Run a command and restart it after network-related failures.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="Target command to run. Prefix with '--' to separate from watchdog options.",
    )
    p.add_argument(
        "--shell-cmd",
        help="Run the target as a single shell command string instead of argv.",
    )
    p.add_argument(
        "-p",
        "--pattern",
        action="append",
        dest="patterns",
        help="Regex pattern that indicates a network failure (repeatable).",
    )
    p.add_argument(
        "--ignore-case",
        action="store_true",
        default=True,
        help="Match patterns case-insensitively.",
    )
    p.add_argument(
        "--case-sensitive",
        action="store_false",
        dest="ignore_case",
        help="Match patterns case-sensitively.",
    )
    p.add_argument(
        "--recovery-cmd",
        default=DEFAULT_RECOVERY_CMD,
        help="Shell command to run after a detected failure (e.g. refresh network).",
    )
    p.add_argument(
        "--no-recovery",
        action="store_true",
        help="Skip the recovery command and only restart the target process.",
    )
    p.add_argument(
        "--restart-delay",
        type=float,
        default=3.0,
        help="Seconds to wait before restarting the target after recovery.",
    )
    p.add_argument(
        "--recovery-timeout",
        type=float,
        default=60.0,
        help="Timeout in seconds for the recovery command.",
    )
    p.add_argument(
        "--cooldown",
        type=float,
        default=15.0,
        help="Minimum seconds between recovery/restart cycles (loop protection).",
    )
    p.add_argument(
        "--max-restarts",
        type=int,
        default=0,
        help="Maximum number of recovery restarts (0 = unlimited).",
    )
    p.add_argument(
        "--stop-on-exit",
        action="store_true",
        help="Exit watchdog when the target exits cleanly instead of restarting it.",
    )
    p.add_argument(
        "--cwd",
        help="Working directory for the target and recovery commands.",
    )
    return p


def normalize_command(args: argparse.Namespace) -> Optional[Sequence[str] | str]:
    if args.shell_cmd:
        return args.shell_cmd
    cmd = list(args.command or [])
    if cmd and cmd[0] == "--":
        cmd = cmd[1:]
    if not cmd:
        return None
    if len(cmd) == 1:
        # Accept a single quoted command string for convenience.
        return cmd[0]
    return cmd


def compile_patterns(patterns: Iterable[str], ignore_case: bool) -> List[re.Pattern[str]]:
    flags = re.IGNORECASE if ignore_case else 0
    compiled = []
    for p in patterns:
        try:
            compiled.append(re.compile(p, flags))
        except re.error as e:
            raise SystemExit(f"Invalid pattern {p!r}: {e}")
    return compiled


def popen_target(cmd: Sequence[str] | str, cwd: Optional[str]) -> subprocess.Popen:
    use_shell = isinstance(cmd, str)
    if use_shell:
        log(f"Starting target (shell): {cmd}")
    else:
        log(f"Starting target: {shlex.join([str(c) for c in cmd])}")

    kwargs = {}
    if os.name == "nt":
        # New process group so we can manage/terminate more predictably.
        kwargs["creationflags"] = getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
    else:
        kwargs["start_new_session"] = True

    return subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        stdin=subprocess.DEVNULL,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
        shell=use_shell,
        **kwargs,
    )


def terminate_process(proc: subprocess.Popen, grace: float = 5.0) -> None:
    if proc.poll() is not None:
        return
    log(f"Stopping target process (pid={proc.pid})...")
    try:
        if os.name == "nt":
            # Try graceful terminate first, then force-kill the tree.
            proc.terminate()
            try:
                proc.wait(timeout=grace)
                return
            except subprocess.TimeoutExpired:
                pass
            subprocess.run(
                ["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
        else:
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            except Exception:
                proc.terminate()
            try:
                proc.wait(timeout=grace)
                return
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
                except Exception:
                    proc.kill()
        proc.wait(timeout=grace)
    except Exception as e:
        log(f"Error while stopping process: {e}", stream=sys.stderr)
        try:
            proc.kill()
        except Exception:
            pass


def run_recovery(cmd: str, cwd: Optional[str], timeout: float) -> int:
    log(f"Running recovery command: {cmd}")
    try:
        completed = subprocess.run(
            cmd,
            cwd=cwd,
            shell=True,
            timeout=timeout if timeout > 0 else None,
            check=False,
        )
        rc = completed.returncode
        if rc == 0:
            log("Recovery command completed successfully.")
        else:
            log(f"Recovery command exited with code {rc}.", stream=sys.stderr)
        return rc
    except subprocess.TimeoutExpired:
        log(f"Recovery command timed out after {timeout}s.", stream=sys.stderr)
        return 124
    except Exception as e:
        log(f"Failed to run recovery command: {e}", stream=sys.stderr)
        return 1


def matches_any(line: str, patterns: List[re.Pattern[str]]) -> Optional[re.Pattern[str]]:
    for pat in patterns:
        if pat.search(line):
            return pat
    return None


def stream_output(proc: subprocess.Popen, patterns: List[re.Pattern[str]], trigger: threading.Event, matched: dict) -> None:
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            # Preserve process output for observability.
            print(line, end="", flush=True)
            if trigger.is_set():
                continue
            m = matches_any(line, patterns)
            if m:
                matched["pattern"] = m.pattern
                matched["line"] = line.rstrip("\n")
                trigger.set()
    except Exception as e:
        if not trigger.is_set():
            log(f"Output reader error: {e}", stream=sys.stderr)
    finally:
        try:
            if proc.stdout:
                proc.stdout.close()
        except Exception:
            pass


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    cmd = normalize_command(args)
    if not cmd:
        parser.print_usage(sys.stderr)
        log("Error: no target command provided. Use -- <command> or --shell-cmd.", stream=sys.stderr)
        return 2

    patterns = compile_patterns(args.patterns or DEFAULT_PATTERNS, args.ignore_case)
    log(f"Watching for {len(patterns)} pattern(s): {[p.pattern for p in patterns]}")
    if args.no_recovery:
        log("Recovery command is disabled (--no-recovery).")
    else:
        log(f"Recovery command: {args.recovery_cmd}")
    log(f"Cooldown={args.cooldown}s, restart_delay={args.restart_delay}s, max_restarts={args.max_restarts or 'unlimited'}")

    restarts = 0
    last_trigger = 0.0
    stopping = False
    current: Optional[subprocess.Popen] = None

    def handle_signal(signum, frame):
        nonlocal stopping
        stopping = True
        log(f"Received signal {signum}, shutting down...")
        if current and current.poll() is None:
            terminate_process(current)

    for sig in (getattr(signal, "SIGINT", None), getattr(signal, "SIGTERM", None)):
        if sig is not None:
            try:
                signal.signal(sig, handle_signal)
            except Exception:
                pass

    while not stopping:
        current = popen_target(cmd, args.cwd)
        trigger = threading.Event()
        matched: dict = {}
        reader = threading.Thread(target=stream_output, args=(current, patterns, trigger, matched), daemon=True)
        reader.start()

        while not stopping:
            if trigger.is_set():
                now = time.monotonic()
                since = now - last_trigger
                if since < args.cooldown:
                    log(
                        f"Failure detected (pattern={matched.get('pattern')!r}) but still in cooldown "
                        f"({args.cooldown - since:.1f}s remaining); ignoring duplicate trigger."
                    )
                    trigger.clear()
                    matched.clear()
                    continue

                restarts += 1
                last_trigger = now
                log(f"Failure detected (pattern={matched.get('pattern')!r}).")
                if matched.get("line"):
                    log(f"Matched line: {matched['line']}")
                log(f"Initiating recovery/restart cycle #{restarts}.")

                terminate_process(current)

                if not args.no_recovery:
                    run_recovery(args.recovery_cmd, args.cwd, args.recovery_timeout)
                else:
                    log("Skipping recovery command.")

                if args.max_restarts and restarts >= args.max_restarts:
                    log(f"Reached max restarts ({args.max_restarts}). Exiting.", stream=sys.stderr)
                    stopping = True
                    break

                if args.restart_delay > 0:
                    log(f"Waiting {args.restart_delay}s before restart...")
                    time.sleep(args.restart_delay)
                break  # restart loop -> spawn new process

            rc = current.poll()
            if rc is not None:
                reader.join(timeout=1.0)
                if stopping:
                    break
                if rc == 0 and args.stop_on_exit:
                    log(f"Target exited with code 0. --stop-on-exit set, exiting watchdog.")
                    return 0
                if rc == 0:
                    log("Target exited with code 0. Restarting (use --stop-on-exit to disable).")
                else:
                    log(f"Target exited with code {rc}. Restarting.")
                if args.restart_delay > 0:
                    time.sleep(args.restart_delay)
                break  # restart

            time.sleep(0.2)

        if stopping:
            terminate_process(current)
            reader.join(timeout=1.0)
            break

    log("Watchdog stopped.")
    return 0


if __name__ == "__main__":
    sys.exit(main())