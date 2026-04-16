import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import '../../../user_permission/service/concrete/locate_permission_service.dart';
import '../../model/location_search_result.dart';
import '../../service/geocoding_service.dart';

class MapSelectResult {
  final NLatLng location;
  final String address;

  MapSelectResult({required this.location, required this.address});
}

class MapSelectView extends StatefulWidget {
  final NLatLng? initialLocation;

  const MapSelectView({super.key, this.initialLocation});

  @override
  State<MapSelectView> createState() => _MapSelectViewState();
}

class _MapSelectViewState extends State<MapSelectView> {
  late NaverMapController _mapController;
  late Future<NaverMapViewOptions> _mapOptionsFuture;
  NMarker? _currentMarker;
  NLatLng? _selectedLocation;
  String _selectedAddress = '';
  NLatLng? _initialTarget;

  // 검색 관련
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _geocodingService = GeocodingService();
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _mapOptionsFuture = _getInitialMapOptions();
  }

  Future<NaverMapViewOptions> _getInitialMapOptions() async {
    Position currentUserLocation = await LocatePermissionService()
        .getCurrentUserLocation();

    _initialTarget =
        widget.initialLocation ??
        NLatLng(currentUserLocation.latitude, currentUserLocation.longitude);

    return NaverMapViewOptions(
      initialCameraPosition: NCameraPosition(target: _initialTarget!, zoom: 16),
      scrollGesturesEnable: true,
      zoomGesturesEnable: true,
      tiltGesturesEnable: true,
      consumeSymbolTapEvents: false,
    );
  }

  void _updateMarker(NLatLng location) {
    if (_currentMarker != null) {
      _mapController.deleteOverlay(_currentMarker!.info);
    }

    _currentMarker = NMarker(id: "location_marker", position: location);

    _mapController.addOverlay(_currentMarker!);
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(
        MapSelectResult(
          location: _selectedLocation!,
          address: _selectedAddress,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위치를 선택해주세요')));
    }
  }

  // ── 검색 ────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final results = await _geocodingService.search(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _showResults = results.isNotEmpty;
        _isSearching = false;
      });
    }
  }

  void _onResultTapped(LocationSearchResult result) {
    final latlng = NLatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLocation = latlng;
      _selectedAddress = result.address;
      _showResults = false;
    });
    _searchFocusNode.unfocus();
    _updateMarker(latlng);
    _mapController.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: latlng, zoom: 16),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<NaverMapViewOptions>(
        future: _mapOptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return _buildMainMapWidget(snapshot, context);
          }
          return const Center(child: Text('지도 로딩 준비 중...'));
        },
      ),
    );
  }

  Widget _buildMainMapWidget(
    AsyncSnapshot<NaverMapViewOptions> snapshot,
    BuildContext context,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        _naverMap(snapshot),
        _buildSearchBar(cs),
        if (_showResults) _buildSearchResults(cs),
        _finishedButton(context),
      ],
    );
  }

  // ── 검색바 ──────────────────────────────────────────────────────────
  Widget _buildSearchBar(ColorScheme cs) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _debounceTimer?.cancel();
              _performSearch(query);
            }
          },
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 14.sp,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '주소 또는 장소명을 검색하세요',
            hintStyle: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 22.r,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: _isSearching
                ? Padding(
                    padding: EdgeInsets.all(12.r),
                    child: SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20.r,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _showResults = false;
                          });
                        },
                      )
                    : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ),
    );
  }

  // ── 검색 결과 리스트 ────────────────────────────────────────────────
  Widget _buildSearchResults(ColorScheme cs) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12.h + 56.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        constraints: BoxConstraints(maxHeight: 280.h),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              final isPlace = result.type == LocationSearchType.place;
              return InkWell(
                onTap: () => _onResultTapped(result),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPlace
                            ? Icons.place_outlined
                            : Icons.location_on_outlined,
                        size: 20.r,
                        color: isPlace ? cs.tertiary : cs.primary,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.title,
                              style: TextStyle(
                                fontFamily: 'BMHANNAAir',
                                fontSize: 13.sp,
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (result.address.isNotEmpty)
                              Text(
                                result.address,
                                style: TextStyle(
                                  fontFamily: 'BMHANNAAir',
                                  fontSize: 12.sp,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Positioned _finishedButton(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 80,
      child: ElevatedButton(
        onPressed: () {
          _confirmSelection();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 4,
        ),
        child: Text(
          '이 위치로 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  NaverMap _naverMap(AsyncSnapshot<NaverMapViewOptions> snapshot) {
    return NaverMap(
      options: snapshot.data!,
      onMapReady: (controller) {
        _mapController = controller;
        debugPrint("Naver map is ready!");

        if (widget.initialLocation != null) {
          _updateMarker(widget.initialLocation!);
        }
      },
      onMapTapped: (NPoint point, NLatLng latlng) async {
        setState(() {
          _selectedLocation = latlng;
          _selectedAddress = '';
          _showResults = false;
        });
        _searchFocusNode.unfocus();
        _updateMarker(latlng);

        final address = await _geocodingService.reverseGeocode(
          latlng.latitude,
          latlng.longitude,
        );
        if (mounted) {
          setState(() => _selectedAddress = address);
        }
      },
      onCameraChange: (NCameraUpdateReason reason, bool animated) {
        if (reason == NCameraUpdateReason.gesture) {
          debugPrint("지도가 제스처로 이동됨");
        }
      },
    );
  }

  Center _buildErrorWidget(AsyncSnapshot<NaverMapViewOptions> snapshot) {
    return Center(
      child: Text(
        '위치 정보를 가져오는 데 실패했습니다.\n${snapshot.error}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
