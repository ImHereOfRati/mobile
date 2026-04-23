import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';

import 'enroll_map_hint_overlay.dart';
import 'enroll_map_overlays.dart';

class EnrollInlineMap extends StatefulWidget {
  final NLatLng? initialSelectedLocation;
  final void Function(NLatLng) onLocationPicked;
  final VoidCallback onOpenMapSelect;

  const EnrollInlineMap({
    super.key,
    required this.initialSelectedLocation,
    required this.onLocationPicked,
    required this.onOpenMapSelect,
  });

  @override
  State<EnrollInlineMap> createState() => EnrollInlineMapState();
}

class EnrollInlineMapState extends State<EnrollInlineMap> {
  NaverMapController? _ctrl;
  NMarker? _marker;
  late final Future<NLatLng> _futureInit;
  NLatLng? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelectedLocation;
    _futureInit = _fetchInit();
  }

  @override
  void dispose() {
    _marker = null;
    _ctrl?.clearOverlays();
    _ctrl = null;
    super.dispose();
  }

  Future<NLatLng> _fetchInit() => LocatePermissionService()
      .getCurrentUserLocation()
      .then((p) => NLatLng(p.latitude, p.longitude))
      .onError((_, __) => const NLatLng(37.5665, 126.9780));

  void moveTo(NLatLng latlng) {
    _placeMarker(latlng);
    _ctrl?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: latlng, zoom: 15),
    );
  }

  void _placeMarker(NLatLng latlng) {
    if (_marker != null) _ctrl?.deleteOverlay(_marker!.info);
    _marker = NMarker(id: 'selected_pin', position: latlng);
    _ctrl?.addOverlay(_marker!);
    setState(() => _selected = latlng);
    widget.onLocationPicked(latlng);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 300,
      child: FutureBuilder<NLatLng>(
        future: _futureInit,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Container(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(color: cs.primary),
              ),
            );
          }
          return Stack(
            children: [
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: snap.data!,
                    zoom: 15,
                  ),
                  scrollGesturesEnable: true,
                  zoomGesturesEnable: true,
                  tiltGesturesEnable: false,
                  consumeSymbolTapEvents: false,
                ),
                onMapReady: (c) {
                  _ctrl = c;
                  if (_selected != null) _placeMarker(_selected!);
                },
                onMapTapped: (_, latlng) => _placeMarker(latlng),
              ),
              if (_selected == null)
                const EnrollMapHintOverlay()
              else
                const EnrollMapSelectedBadge(),
              EnrollMapFullscreenButton(onTap: widget.onOpenMapSelect),
            ],
          );
        },
      ),
    );
  }
}
