import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/view_model/map/map_select_state.dart';
import 'package:iamhere/feature/geofence/view_model/map/map_select_view_model.dart';
import 'map_select_widgets.dart';

class MapSelectOverlay extends StatelessWidget {
  final MapSelectState state;
  final MapSelectViewModel notifier;
  final TextEditingController searchController;
  final FocusNode focusNode;

  const MapSelectOverlay({
    super.key,
    required this.state,
    required this.notifier,
    required this.searchController,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 12.h,
          left: 16.w,
          right: 16.w,
          child: MapSearchBar(
            controller: searchController,
            focusNode: focusNode,
            isSearching: state.isSearching,
            onChanged: notifier.onSearchChanged,
            onSubmitted: notifier.onSearchChanged,
            onClear: () {
              searchController.clear();
              notifier.clearSearch();
            },
          ),
        ),
        if (state.showResults)
          Positioned(
            top: MediaQuery.of(context).padding.top + 68.h,
            left: 16.w,
            right: 16.w,
            child: MapSearchResults(
              results: state.searchResults,
              onTap: (r) {
                focusNode.unfocus();
                notifier.selectResult(r);
              },
            ),
          ),
      ],
    );
  }
}
