import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Сетевая картинка с обходом блокировки CDN и стильной заглушкой.
///
/// Для доменов Deadlock сначала пробует публичный image-прокси
/// (images.weserv.nl), затем его зеркало wsrv.nl, CORS-прокси и прямое
/// подключение. Если всё упало — показывает [fallback] в стиле приложения,
/// а не системный «битый» значок.
class RemoteImage extends StatefulWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.useProxy = false,
    this.proxyWidth = 600,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final bool useProxy;

  /// Желаемая ширина при проксировании (экономит трафик для аватарок).
  final int proxyWidth;
  final Widget? fallback;

  @override
  State<RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  late List<String> _sources;
  int _index = 0;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _sources = _buildSources(widget.url, widget.useProxy, widget.proxyWidth);
  }

  @override
  void didUpdateWidget(covariant RemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.useProxy != widget.useProxy ||
        oldWidget.proxyWidth != widget.proxyWidth) {
      _sources = _buildSources(widget.url, widget.useProxy, widget.proxyWidth);
      _index = 0;
      _advancing = false;
    }
  }

  /// Цепочка источников: прокси → зеркало → CORS-прокси → оригинал.
  static List<String> _buildSources(String raw, bool useProxy, int width) {
    final url = raw.trim();
    if (url.isEmpty) {
      return const [];
    }

    final uri = Uri.tryParse(url);
    if (!useProxy || uri == null || !uri.hasScheme) {
      return [url];
    }

    final host = uri.host.toLowerCase();
    if (!host.endsWith('deadlock-api.com')) {
      return [url];
    }

    final path =
        '${uri.host}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    final encodedPath = Uri.encodeComponent(path);
    final encodedFull = Uri.encodeComponent(url);

    return [
      'https://images.weserv.nl/?url=$encodedPath&w=$width',
      'https://wsrv.nl/?url=$encodedPath&w=$width',
      'https://corsproxy.io/?url=$encodedFull',
      url,
    ];
  }

  void _tryNextSource() {
    if (_advancing || _index + 1 >= _sources.length) {
      return;
    }
    _advancing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _index++;
        _advancing = false;
      });
    });
  }

  Widget get _fallback => widget.fallback ?? const DeadlockImageFallback();

  @override
  Widget build(BuildContext context) {
    if (_sources.isEmpty || _index >= _sources.length) {
      return _fallback;
    }

    return Image.network(
      _sources[_index],
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        _tryNextSource();
        return _fallback;
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const ColoredBox(color: AppColors.surfaceLight);
      },
    );
  }
}

/// Красивая заглушка вместо битой картинки: тёмный градиент и логотип DL.
class DeadlockImageFallback extends StatelessWidget {
  const DeadlockImageFallback({super.key, this.label});

  /// Подпись поверх заглушки (например, имя героя).
  final String? label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : width;
        final side = math.min(width, height);
        final compact = side < 72;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B0F16),
                Color(0xFF171214),
                Color(0xFF1D1613),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (compact)
                Center(
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: (side * 0.55).clamp(12.0, 30.0).toDouble(),
                    color: AppColors.copper,
                  ),
                )
              else ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(side * 0.14),
                    child: Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (label != null && label!.trim().isNotEmpty)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Text(
                      label!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.75),
                        fontSize: (side * 0.055).clamp(8.0, 13.0).toDouble(),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
