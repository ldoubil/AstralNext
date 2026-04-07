
import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class BannerTag {
  final String text;
  final Color color;

  const BannerTag({required this.text, required this.color});

  factory BannerTag.fromJson(Map<String, dynamic> json) {
    return BannerTag(
      text: json['text'] as String,
      color: Color(int.parse(json['color'] as String)),
    );
  }
}

class BannerItem {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final List<BannerTag>? tags;
  final String? actionUrl;

  const BannerItem({
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.tags,
    this.actionUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      tags:
          json['tags'] != null
              ? (json['tags'] as List)
                  .map((tag) => BannerTag.fromJson(tag as Map<String, dynamic>))
                  .toList()
              : null,
      actionUrl: json['actionUrl'] as String?,
    );
  }
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  static const int _initialPage = 10000;
  List<BannerItem> _banners = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final response = await http
          .get(Uri.parse('https://astral.fan/banner.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String jsonString = utf8.decode(response.bodyBytes);
        jsonString = jsonString.replaceAll(RegExp(r',\s*]'), ']');
        jsonString = jsonString.replaceAll(RegExp(r',\s*}'), '}');

        final List<dynamic> jsonList = json.decode(jsonString);

        final banners =
            jsonList
                .map(
                  (item) => BannerItem.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        if (mounted) {
          setState(() {
            _banners = banners;
            _isLoading = false;
            if (_banners.isNotEmpty) {
              _pageController = PageController(initialPage: _initialPage);
              _currentPage = _initialPage;
              _startAutoPlay();
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_banners.isNotEmpty) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && mounted) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                  Theme.of(context).colorScheme.surfaceContainer,
                ],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    if (_banners.isEmpty || _hasError) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 150,
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _timer?.cancel();
              if (event.scrollDelta.dx > 0) {
                _pageController.animateToPage(
                  _currentPage + 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else if (event.scrollDelta.dx < 0) {
                _pageController.animateToPage(
                  _currentPage - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              Future.delayed(const Duration(milliseconds: 500), () {
                _resetTimer();
              });
            }
          },
          child: GestureDetector(
            onPanDown: (_) {
              _timer?.cancel();
            },
            onPanEnd: (_) {
              _resetTimer();
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollBehavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final bannerIndex = index % _banners.length;
                    return _buildBannerItem(_banners[bannerIndex]);
                  },
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _banners.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width:
                              _currentPage % _banners.length == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage % _banners.length == index
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem(BannerItem banner) {
    return GestureDetector(
      onTap:
          banner.actionUrl != null
              ? () => _showLaunchConfirmDialog(banner.actionUrl!)
              : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          if (banner.title != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          if (banner.title != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Text(
                        banner.title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          foreground:
                              Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        banner.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Text(
                          banner.subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            foreground:
                                Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2.5
                                  ..color = Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          banner.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showLaunchConfirmDialog(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认跳转'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('将要打开外部链接:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  url,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('打开'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _launchUrl(url);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

