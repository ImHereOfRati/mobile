import 'package:iamhere/feature/geofence/model/location_search_result.dart';

class MapSearchInfo {
  final List<LocationSearchResult> results;
  final bool isSearching;
  final bool showResults;

  const MapSearchInfo({
    this.results = const [],
    this.isSearching = false,
    this.showResults = false,
  });

  MapSearchInfo copyWith({
    List<LocationSearchResult>? results,
    bool? isSearching,
    bool? showResults,
  }) {
    return MapSearchInfo(
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      showResults: showResults ?? this.showResults,
    );
  }
}
