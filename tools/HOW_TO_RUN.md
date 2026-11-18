# Network Watchdog (OpenCode + WARP) — как запустить

## 1) Одноразовая настройка Cloudflare WARP

После установки WARP один раз привяжите устройство/аккаунт:

```powershell
warp-cli registration new
# если аккаунт/команда уже настроены иначе, возможны варианты:
# warp-cli register
```

Проверьте статус и подключение:

```powershell
warp-cli status
warp-cli connect
```

> Примечание: точная команда первичной регистрации может отличаться в зависимости от версии WARP/типа аккаунта (personal/team). Если `registration new` недоступна, выполните `warp-cli --help` и используйте предложенную команду регистрации.

## 2) Запуск в один клик

В корне проекта запустите двойным кликом файл:

- `run_watchdog.bat`

Он стартует сторожевой таймер `tools\network_watchdog.py`, который запускает:

```bat
python tools\network_watchdog.py --shell-cmd "opencode"
```

## 3) Что делает watchdog

- Следит за выводом процесса `opencode`.
- При сетевых ошибках (например, `429`, `Timeout`, обрывы соединения) автоматически выполняет:
  - `warp-cli disconnect && warp-cli connect`
  - перезапуск `opencode`
- Пишет все свои действия в консоль с временными метками.

## 4) Если что-то не работает

- Убедитесь, что `python` (или `py`) и `warp-cli` доступны в `PATH` (после установки WARP может потребоваться перезапуск терминала/сессии).
- Запустите `run_watchdog.bat` из терминала, чтобы увидеть ошибки запуска.
- Для справки по опциям: `python tools\network_watchdog.py -h`
