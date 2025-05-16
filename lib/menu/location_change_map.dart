import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapLocationPicker extends StatefulWidget {
  final Function(double lat, double lon) onLocationSelected;
  final Function(String name)? onNameSelected;

  const MapLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.onNameSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  gmaps.LatLng? selectedPosition;
  late gmaps.GoogleMapController _mapController;
  late FlutterGooglePlacesSdk _places;
  String? _selectedPlaceName;

  @override
  void initState() {
    super.initState();
    _places = FlutterGooglePlacesSdk(dotenv.env['GOOGLE_MAPS_API_KEY']!);
  }

  void _searchPlaces() async {
    final input = await showDialog<String>(
      context: context,
      builder: (context) {
        String temp = '';
        return AlertDialog(
          title: const Text('검색할 장소 입력'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => temp = value,
            decoration: const InputDecoration(hintText: '예: 남산타워, 홍대입구역...'),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('검색'),
              onPressed: () => Navigator.pop(context, temp),
            ),
          ],
        );
      },
    );

    if (input == null || input.trim().isEmpty) return;

    final result = await _places.findAutocompletePredictions(
      input.trim(),
      countries: ['KR'],
    );

    if (result.predictions.isEmpty) return;

    final selected = await showDialog<AutocompletePrediction>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text("장소 선택"),
            children:
                result.predictions.map((p) {
                  return SimpleDialogOption(
                    child: Text(p.primaryText ?? p.fullText ?? '알 수 없음'),
                    onPressed: () => Navigator.pop(context, p),
                  );
                }).toList(),
          ),
    );

    if (selected == null) return;

    final details = await _places.fetchPlace(
      selected.placeId,
      fields: [PlaceField.Location, PlaceField.Name],
    );
    print("📦 장소 디테일 도착: ${details.place}");

    final latLngRaw = details.place?.latLng;
    final name = details.place?.name;
    print("📍 이름: $name");

    if (latLngRaw != null) {
      final latLng = gmaps.LatLng(latLngRaw.lat, latLngRaw.lng);
      print("📍 이동할 좌표: $latLng");

      _mapController.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(latLng, 16),
      );
      setState(() {
        selectedPosition = latLng;
        _selectedPlaceName = name;
      });
      if (widget.onNameSelected != null && name != null) {
        widget.onNameSelected!(name);
      }
    } else {
      print("❗ latLng 정보 없음");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도에서 위치 선택"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _searchPlaces),
        ],
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: const gmaps.CameraPosition(
              target: gmaps.LatLng(37.5665, 126.9780),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (gmaps.LatLng position) async {
              setState(() {
                selectedPosition = position;
                _selectedPlaceName = null;
              });
              // 🔄 좌표 → 주소 이름으로 변환
              try {
                final placemarks = await placemarkFromCoordinates(
                  position.latitude,
                  position.longitude,
                  // localeIdentifier: 'ko_KR', // 한국어 주소
                );
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  final name = [
                    place.locality,
                    place.subLocality,
                    place.thoroughfare,
                    place.name,
                  ].where((e) => e != null && e.isNotEmpty).join(' ');

                  setState(() {
                    _selectedPlaceName = name;

                    // ⬇️ 콜백으로 상위에 전달!
                    if (widget.onNameSelected != null) {
                      widget.onNameSelected!(name);
                    }
                  });
                }
              } catch (e) {
                print("❗ 주소 변환 실패: $e");
              }
            },
            markers:
                selectedPosition != null
                    ? {
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId("selected"),
                        position: selectedPosition!,
                        infoWindow: gmaps.InfoWindow(title: _selectedPlaceName),
                      ),
                    }
                    : {},
          ),
          if (selectedPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onLocationSelected(
                    selectedPosition!.latitude,
                    selectedPosition!.longitude,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text("이 위치 선택"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on Place? {
  get location => null;
}
