import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';

class TicketPosterPickerScreen extends ConsumerStatefulWidget {
  final JournalState journal;

  const TicketPosterPickerScreen({super.key, required this.journal});

  @override
  ConsumerState<TicketPosterPickerScreen> createState() =>
      _TicketPosterPickerScreenState();
}

class _TicketPosterPickerScreenState
    extends ConsumerState<TicketPosterPickerScreen> {
  static const _languageTabs = [
    ('Original Language', null),
    ('English', 'en'),
    ('繁體中文', 'zh'),
    ('日本語', 'ja'),
  ];

  final List<GlobalKey> _tabKeys = List.generate(
    _languageTabs.length,
    (_) => GlobalKey(),
  );

  int _selectedTabIndex = 0;
  String? _selectedPosterPath;
  bool _loading = true;

  /// Cache of fetched posters per language code.
  final Map<String, List<MovieImage>> _posterCache = {};

  String? _resolvedOriginalLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndFetch();
    });
  }

  Future<void> _initAndFetch() async {
    final notifier = ref.read(movieDetailControllerProvider.notifier);
    await notifier.fetchMovieDetails(widget.journal.tmdbId);

    final asyncMovie = ref.read(movieDetailControllerProvider);
    final movie = asyncMovie.hasValue ? asyncMovie.value : null;
    if (movie != null) {
      _resolvedOriginalLanguage = movie.originalLanguage;
    }

    await _fetchPostersForTab(0);
  }

  String _languageCodeForTab(int index) {
    if (index == 0) {
      return _resolvedOriginalLanguage ?? 'en';
    }
    return _languageTabs[index].$2!;
  }

  Future<void> _fetchPostersForTab(int index) async {
    final langCode = _languageCodeForTab(index);

    if (_posterCache.containsKey(langCode)) {
      _autoSelectFirst(langCode);
      return;
    }

    setState(() => _loading = true);

    try {
      final repo = ref.read(movieRepoProvider);
      final images = await repo.getMovieImages(
        id: widget.journal.tmdbId,
        language: langCode,
      );
      _posterCache[langCode] = images.posters;
      _autoSelectFirst(langCode);
    } catch (e) {
      debugPrint('Failed to fetch posters: $e');
      _posterCache[langCode] = [];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _autoSelectFirst(String langCode) {
    final posters = _posterCache[langCode] ?? [];
    if (posters.isNotEmpty && _selectedPosterPath == null) {
      setState(() {
        _selectedPosterPath = posters.first.filePath;
      });
    }
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) return;
    setState(() {
      _selectedTabIndex = index;
    });
    _fetchPostersForTab(index);

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
    setState(() => _selectedPosterPath = path);
  }

  void _onNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareTicketScreen(
          journal: widget.journal,
          posterPath: _selectedPosterPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = _languageCodeForTab(_selectedTabIndex);
    final posters = _posterCache[langCode] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircledIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
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
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _selectedPosterPath != null ? _onNext : null,
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                overlayColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary,
                ),
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                side: WidgetStateProperty.all(
                  BorderSide(
                    color: _selectedPosterPath != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white24,
                    width: 1,
                  ),
                ),
                foregroundColor: WidgetStateProperty.all(
                  _selectedPosterPath != null ? Colors.white : Colors.white38,
                ),
              ),
              child: const Text('Next'),
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
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withAlpha(77),
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

          // Poster grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : posters.isEmpty
                    ? Center(
                        child: Text(
                          'No posters available',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 14,
                            fontFamily: 'AvenirNext',
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: posters.length,
                        itemBuilder: (context, index) {
                          final poster = posters[index];
                          final isSelected =
                              poster.filePath == _selectedPosterPath;
                          return GestureDetector(
                            onTap: () => _onPosterSelected(poster.filePath),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      'https://image.tmdb.org/t/p/w500${poster.filePath}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                                ),
                                if (isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
