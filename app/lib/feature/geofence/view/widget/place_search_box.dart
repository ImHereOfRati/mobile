import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/geofence/model/dto/place_search_result_dto.dart';
import 'package:iamhere/feature/geofence/model/service/map_search_service.dart';

/// 장소 이름이나 주소로 검색해 후보를 고른다.
class PlaceSearchBox extends StatefulWidget {
  final MapSearchService service;
  final ValueChanged<PlaceSearchResultDto> onSelected;

  const PlaceSearchBox({
    super.key,
    required this.service,
    required this.onSelected,
  });

  @override
  State<PlaceSearchBox> createState() => _PlaceSearchBoxState();
}

class _PlaceSearchBoxState extends State<PlaceSearchBox> {
  final _query = TextEditingController();
  List<PlaceSearchResultDto> _results = const [];
  bool _searching = false;
  bool _searched = false;
  bool _failed = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final results = await widget.service.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _failed = true;
        _searching = false;
      });
    }
  }

  void _select(PlaceSearchResultDto place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _results = const [];
      _searched = false;
    });
    widget.onSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ImHereTextField(
                label: '장소 검색',
                controller: _query,
                hint: '장소 이름이나 주소',
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
            ),
            SizedBox(width: metrics.resolve(ImHereSpace.xs)),
            ImHereButton(
              label: '검색',
              tone: ImHereButtonTone.weak,
              loading: _searching,
              onPressed: _searching ? null : _search,
            ),
          ],
        ),
        if (_failed)
          Padding(
            padding: EdgeInsets.only(top: metrics.resolve(ImHereSpace.xs)),
            child: Text(
              '장소를 검색하지 못했어요',
              style: textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
        if (_searched && _results.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: metrics.resolve(ImHereSpace.xs)),
            child: Text(
              '검색 결과가 없어요',
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
        for (final place in _results) ...[
          ImHereListRow(
            title: place.title,
            description: place.address,
            onTap: () => _select(place),
          ),
          const ImHereBorder(tone: ImHereDividerTone.subtle),
        ],
      ],
    );
  }
}
