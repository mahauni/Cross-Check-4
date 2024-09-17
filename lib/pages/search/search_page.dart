import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:movie_app/models/movie_model.dart';
import 'package:movie_app/pages/search/widgets/movie_search.dart';
import 'package:movie_app/services/api_services.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiServices _apiServices = ApiServices();
  final TextEditingController _searchController = TextEditingController();
  late Future<Result> _result;
  late Future<List<dynamic>> _genresFuture;
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    _result = _apiServices.getPopularMovies();
    _genresFuture = _apiServices.getMovieGenres();
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _result = _selectedGenreId == null
            ? _apiServices.getPopularMovies()
            : _apiServices.getMoviesByGenre(_selectedGenreId!);
      } else if (query.length > 3) {
        _result = _apiServices.getSearchedMovie(query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchTitle = _searchController.text.isEmpty
        ? 'Top Searches'
        : 'Search Results for ${_searchController.text}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              CupertinoSearchTextField(
                controller: _searchController,
                padding: const EdgeInsets.all(10.0),
                prefixIcon:
                    const Icon(CupertinoIcons.search, color: Colors.grey),
                suffixIcon: const Icon(Icons.cancel, color: Colors.grey),
                style: const TextStyle(color: Colors.white),
                backgroundColor: Colors.grey.withOpacity(0.3),
                onChanged: (value) => _search(value),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<dynamic>>(
                future: _genresFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final genres = snapshot.data!;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButton<int>(
                        hint: const Text(
                          'Select Genre',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _selectedGenreId,
                        dropdownColor: Colors.grey[850],
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedGenreId = newValue;
                            _search(_searchController.text);
                          });
                        },
                        items: genres.map<DropdownMenuItem<int>>((genre) {
                          return DropdownMenuItem<int>(
                            value: genre['id'],
                            child: Text(
                              genre['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        iconSize: 24,
                      ),
                    );
                  } else {
                    return const Text('No genres available',
                        style: TextStyle(color: Colors.white));
                  }
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<Result>(
                future: _result,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final data = snapshot.data?.movies ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          searchTitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w300,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final movie = data[index];
                            if (movie.backdropPath.isEmpty) {
                              return const SizedBox();
                            }
                            return MovieSearch(movie: movie);
                          },
                        ),
                      ],
                    );
                  } else {
                    return const Center(
                        child: Text('No results found.',
                            style: TextStyle(color: Colors.white)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
