import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/config/naver_map_config.dart';

/// 지도를 눌러 장소를 고르고, 고른 곳 둘레에 감지 반경을 그려 보여 준다.
class GeofenceMapPicker extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final void Function(double latitude, double longitude) onPicked;

  const GeofenceMapPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.onPicked,
  });

  static const height = 280.0;

  @override
  State<GeofenceMapPicker> createState() => _GeofenceMapPickerState();
}

class _GeofenceMapPickerState extends State<GeofenceMapPicker> {
  static const _markerId = 'selected_pin';
  static const _circleId = 'selected_radius';

  NaverMapController? _controller;
  NMarker? _marker;
  NCircleOverlay? _circle;

  NLatLng get _position => NLatLng(widget.latitude, widget.longitude);

  @override
  void didUpdateWidget(GeofenceMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved =
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude;
    if (moved) {
      _marker?.setPosition(_position);
      _circle?.setCenter(_position);
      // 검색 결과를 골라 위치가 멀리 바뀐 경우에도 보이도록 카메라를 따라 보낸다.
      _controller?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: _position, zoom: 15),
      );
    }
    if (oldWidget.radiusMeters != widget.radiusMeters) {
      _circle?.setRadius(widget.radiusMeters.toDouble());
    }
  }

  @override
  void dispose() {
    _controller?.clearOverlays();
    _controller = null;
    super.dispose();
  }

  void _onMapReady(NaverMapController controller) {
    _controller = controller;
    final colors = ImHereColors.of(context);
    _circle = NCircleOverlay(
      id: _circleId,
      center: _position,
      radius: widget.radiusMeters.toDouble(),
      color: colors.action.withValues(alpha: 0.18),
      outlineColor: colors.action,
      outlineWidth: 2,
    );
    _marker = NMarker(id: _markerId, position: _position);
    controller.addOverlayAll({_circle!, _marker!});
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final radius = BorderRadius.circular(metrics.resolve(ImHereRadius.lg));

    return SizedBox(
      height: metrics.resolve(GeofenceMapPicker.height),
      child: ClipRRect(
        borderRadius: radius,
        child: NaverMapConfig.isAvailable
            ? NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: _position,
                    zoom: 15,
                  ),
                  tiltGesturesEnable: false,
                  consumeSymbolTapEvents: false,
                ),
                onMapReady: _onMapReady,
                onMapTapped: (_, latLng) =>
                    widget.onPicked(latLng.latitude, latLng.longitude),
              )
            : ColoredBox(
                color: colors.surfaceSubtle,
                child: const ImHereStatePanel(
                  glyph: ImHereGlyph.place,
                  title: '지도를 쓸 수 없어요',
                  description: '검색으로 장소를 골라 주세요',
                ),
              ),
      ),
    );
  }
}
