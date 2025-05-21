import 'package:flutter/material.dart';

class MovieResultList extends StatefulWidget {
  const MovieResultList({
    super.key,
    required this.results,
    required this.onLoadMore,
  });

  final List<SearchMoviesResultItem> results;
  final Function() onLoadMore;
  @override
  State<MovieResultList> createState() => _MovieResultListState();
}

class _MovieResultListState extends State<MovieResultList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      itemBuilder: (context, index) {
        return MovieResultItem(result: widget.results[index]);
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemCount: widget.results.length,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class MovieResultItem extends StatelessWidget {
  const MovieResultItem({super.key, required this.result});

  final SearchMovieResultItem result;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Handle movie selection
      },
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 95,
        child: Row(
          spacing: 16,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  result.posterPath != null
                      ? Image.network(
                        'https://image.tmdb.org/t/p/w500/${result.posterPath}',
                        width: 72,
                        height: 95,
                        fit: BoxFit.cover,
                      )
                      : Image.asset(
                        'assets/images/avatar.png',
                        width: 72,
                        height: 95,
                        fit: BoxFit.contain,
                      ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      result.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      result.releaseDate.substring(0, 4),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA7A7A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      result.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFE9E9E9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
