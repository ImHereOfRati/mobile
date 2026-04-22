import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/feature/geofence/model/location_search_result.dart';
import 'map_search_info.dart';
import 'map_selection_info.dart';
export 'map_search_info.dart';
export 'map_selection_info.dart';

class MapSelectState {
  final MapSearchInfo search;
  final MapSelectionInfo selection;

  MapSelectState({
    this.search = const MapSearchInfo(),
    this.selection = const MapSelectionInfo(),
  });

  MapSelectState copyWith({
    MapSearchInfo? search,
    MapSelectionInfo? selection,
  }) {
    return MapSelectState(
      search: search ?? this.search,
      selection: selection ?? this.selection,
    );
  }

  // Helper getters to minimize UI changes if possible
  List<LocationSearchResult> get searchResults => search.results;
  bool get isSearching => search.isSearching;
  bool get showResults => search.showResults;
  NLatLng? get selectedLocation => selection.location;
  String get selectedAddress => selection.address;
}
