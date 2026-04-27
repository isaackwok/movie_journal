import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/analytics_manager.dart';

class TicketPosterPickerScreen extends ConsumerStatefulWidget {
  final JournalState journal;
  final ShareTicketEntry entry;

  const TicketPosterPickerScreen({
    super.key,
    required this.journal,
    required this.entry,
  });

  @override
  ConsumerState<TicketPosterPickerScreen> createState() =>
      _TicketPosterPickerScreenState();
}

class _TicketPosterPickerScreenState
    extends ConsumerState<TicketPosterPickerScreen> {
  static const _allLanguageTabs = [
    ('Original Language', null),
    ('English', 'en'),
    ('繁體中文', 'zh-TW'),
    ('日本語', 'ja'),
  ];

  List<(String, String?)> _languageTabs = _allLanguageTabs;

  List<GlobalKey> _tabKeys = List.generate(
    _allLanguageTabs.length,
    (_) => GlobalKey(),
  );

  late final PageController _pageController;

  int _selectedTabIndex = 0;
  bool _loading = true;

  /// Cache of fetched posters per language code.
  final Map<String, List<MovieImage>> _posterCache = {};

  String? _resolvedOriginalLanguage;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.logScreenView('TicketPosterPicker');
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndFetch();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _selectedTabIndex) {
      _onTabSelected(page);
    }
  }

  Future<void> _initAndFetch() async {
    final notifier = ref.read(movieDetailControllerProvider.notifier);
    await notifier.fetchMovieDetails(widget.journal.tmdbId);

    final asyncMovie = ref.read(movieDetailControllerProvider);
    final movie = asyncMovie.hasValue ? asyncMovie.value : null;
    if (movie != null) {
      _resolvedOriginalLanguage = movie.originalLanguage;
      _applyLanguageTabFilter();
    }

    await _fetchPostersForTab(0);
  }

  /// Hides any language tab whose code matches the movie's original language
  /// (e.g. if `original_language` is `zh`, drop the `zh-TW` tab) so the user
  /// doesn't see the same posters twice across tabs.
  void _applyLanguageTabFilter() {
    final original = _resolvedOriginalLanguage;
    if (original == null) return;
    final originalBase = original.split('-').first.toLowerCase();
    final filtered = _allLanguageTabs.where((tab) {
      final code = tab.$2;
      if (code == null) return true;
      return code.split('-').first.toLowerCase() != originalBase;
    }).toList();
    if (filtered.length == _languageTabs.length) return;
    if (!mounted) return;
    setState(() {
      _languageTabs = filtered;
      _tabKeys = List.generate(filtered.length, (_) => GlobalKey());
    });
  }

  String _languageCodeForTab(int index) {
    if (index == 0) {
      return _resolvedOriginalLanguage ?? 'en';
    }
    return _languageTabs[index].$2!;
  }

  Future<void> _fetchPostersForTab(int index) async {
    final langCode = _languageCodeForTab(index);

    if (_posterCache.containsKey(langCode)) return;

    setState(() => _loading = true);

    try {
      final repo = ref.read(movieRepoProvider);
      final images = await repo.getMovieImages(
        id: widget.journal.tmdbId,
        language: langCode,
      );
      _posterCache[langCode] = images.posters;
    } catch (e) {
      debugPrint('Failed to fetch posters: $e');
      _posterCache[langCode] = [];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) return;
    setState(() {
      _selectedTabIndex = index;
    });
    _fetchPostersForTab(index);

    // Sync PageView with tab selection
    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Animate the selected tab into the viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _tabKeys[index].currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _onPosterSelected(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: kShareFlowRouteName),
        builder: (context) => ShareTicketScreen(
          journal: widget.journal,
          posterPath: path,
          entry: widget.entry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Choose a Ticket Poster',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'AvenirNext',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => closeShareFlow(context, widget.entry),
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Language tabs
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languageTabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedTabIndex;
                return GestureDetector(
                  key: _tabKeys[index],
                  onTap: () => _onTabSelected(index),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withAlpha(179) // 70%
                            : Colors.white.withAlpha(38), // 15%
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withAlpha(230) // 90%
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        _languageTabs[index].$1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'AvenirNext',
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Poster grid pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _languageTabs.length,
              itemBuilder: (context, pageIndex) {
                final langCode = _languageCodeForTab(pageIndex);
                final pagePosters = _posterCache[langCode] ?? [];
                final isCurrentPage = pageIndex == _selectedTabIndex;
                final isPageLoading = isCurrentPage && _loading;

                if (isPageLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (pagePosters.isEmpty) {
                  return Center(
                    child: Text(
                      'No posters available',
                      style: TextStyle(
                        color: Colors.white.withAlpha(128),
                        fontSize: 14,
                        fontFamily: 'AvenirNext',
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: pagePosters.length,
                  itemBuilder: (context, index) {
                    final poster = pagePosters[index];
                    return GestureDetector(
                      onTap: () => _onPosterSelected(poster.filePath),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w500${poster.filePath}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: const Color(0xFF2C2C2E),
                            child: const Center(
                              child: Icon(
                                Icons.movie,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
