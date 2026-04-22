import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/geofence/view_model/map/map_select_view_model.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
import 'component/map_select_overlay.dart';
import 'component/map_select_widgets.dart';

class MapSelectView extends ConsumerStatefulWidget {
  final NLatLng? initialLocation;
  const MapSelectView({super.key, this.initialLocation});

  @override
  ConsumerState<MapSelectView> createState() => _MapSelectViewState();
}

class _MapSelectViewState extends ConsumerState<MapSelectView> {
  NaverMapController? _map;
  late Future<NaverMapViewOptions> _opts;
  NMarker? _marker;
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _opts = _initOpts();
  }

  Future<NaverMapViewOptions> _initOpts() async {
    final pos = await LocatePermissionService().getCurrentUserLocation();
    final target = widget.initialLocation ?? NLatLng(pos.latitude, pos.longitude);
    return NaverMapViewOptions(initialCameraPosition: NCameraPosition(target: target, zoom: 16), consumeSymbolTapEvents: false);
  }

  void _updateMarker(NLatLng latlng) {
    if (_map == null) return;
    if (_marker != null) _map!.deleteOverlay(_marker!.info);
    _marker = NMarker(id: "loc", position: latlng);
    _map!.addOverlay(_marker!);
    _map!.updateCamera(NCameraUpdate.scrollAndZoomTo(target: latlng, zoom: 16));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapSelectViewModelProvider(widget.initialLocation));
    final notifier = ref.read(mapSelectViewModelProvider(widget.initialLocation).notifier);

    ref.listen(mapSelectViewModelProvider(widget.initialLocation), (prev, next) {
      if (next.selectedLocation != null && next.selectedLocation != prev?.selectedLocation) {
        _updateMarker(next.selectedLocation!);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<NaverMapViewOptions>(
        future: _opts,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return Stack(children: [
            NaverMap(
              options: snap.data!,
              onMapReady: (c) {
                _map = c;
                if (state.selectedLocation != null) _updateMarker(state.selectedLocation!);
              },
              onMapTapped: (_, l) {
                _focus.unfocus();
                notifier.updateLocationByTapped(l);
              },
            ),
            MapSelectOverlay(state: state, notifier: notifier, searchController: _search, focusNode: _focus),
            Positioned(
              bottom: 24,
              left: 16,
              right: 80,
              child: MapConfirmButton(onTap: () {
                if (state.selectedLocation != null) {
                  Navigator.pop(
                    context,
                    MapSelectResult(
                      location: state.selectedLocation!,
                      address: state.selectedAddress,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('위치를 선택해주세요')),
                  );
                }
              }),
            ),
          ]);
        },
      ),
    );
  }

  @override
  void dispose() { _search.dispose(); _focus.dispose(); super.dispose(); }
}
