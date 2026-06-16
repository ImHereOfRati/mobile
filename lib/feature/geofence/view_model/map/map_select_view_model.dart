import 'dart:async';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/location_search_result.dart';
import 'package:iamhere/feature/geofence/service/geocoding_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'map_select_state.dart';

part 'map_select_view_model.g.dart';

@riverpod
class MapSelectViewModel extends _$MapSelectViewModel {
  Timer? _debounceTimer;

  @override
  MapSelectState build(NLatLng? initialLocation) {
    ref.onDispose(() => _debounceTimer?.cancel());
    return MapSelectState(
      selection: MapSelectionInfo(location: initialLocation),
    );
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(
        search: state.search.copyWith(results: [], showResults: false),
      );
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(search: state.search.copyWith(isSearching: true));
      try {
        final results = await ref.read(geocodingServiceProvider).search(query);
        state = state.copyWith(
          search: state.search.copyWith(
            results: results,
            showResults: results.isNotEmpty,
            isSearching: false,
          ),
        );
      } catch (e) {
        state = state.copyWith(
          search: state.search.copyWith(isSearching: false),
        );
      }
    });
  }

  void selectResult(LocationSearchResult result) {
    final location = NLatLng(result.latitude, result.longitude);
    final name = composePlaceName(
      title: result.title,
      reverseGeocode: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
    );
    state = state.copyWith(
      selection: MapSelectionInfo(
        location: location,
        name: name,
        address: result.address,
      ),
      search: state.search.copyWith(showResults: false),
    );
  }

  Future<void> updateLocationByTapped(NLatLng location) async {
    state = state.copyWith(
      selection: MapSelectionInfo(location: location, address: ''),
      search: state.search.copyWith(showResults: false),
    );
    final address = await ref
        .read(geocodingServiceProvider)
        .reverseGeocode(location.latitude, location.longitude);
    final name = composePlaceName(
      reverseGeocode: address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    state = state.copyWith(
      selection: state.selection.copyWith(name: name, address: address),
    );
  }

  void clearSearch() => state = state.copyWith(
    search: state.search.copyWith(results: [], showResults: false),
  );
}
