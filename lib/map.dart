import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'hospital_marker.dart'; // Custom widget for marker

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  double centerLng = 0.0;
  double centerLat = 0.0;
  bool loading = true;
  double currentZoom = 15.0;
  late MapController mapController;
  List<Marker> hospitalMarkers = [];

  final String _apiKeyId = 'YOUR_NAVER_API_KEY_ID';
  final String _apiKeySecret = 'YOUR_NAVER_API_KEY_SECRET';

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    getPosition();
  }

  Future<void> getPosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    setState(() {
      centerLng = position.longitude;
      centerLat = position.latitude;
      loading = false;
    });
    _getNearbyHospitals();
  }

  Future<void> _getNearbyHospitals() async {
    final lat = centerLat;
    final lon = centerLng;

    final url = 'https://naveropenapi.apigw.ntruss.com/map-place/v1/search?query=피부과&coordinate=$lon,$lat&radius=1000';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'X-NCP-APIGW-API-KEY-ID': _apiKeyId,
        'X-NCP-APIGW-API-KEY': _apiKeySecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> places = data['places'];
      setState(() {
        hospitalMarkers = places.map((place) {
          return Marker(
            width: 30.0,
            height: 30.0,
            point: LatLng(double.parse(place['y']), double.parse(place['x'])),
            child: HospitalMarker(name: place['name']),
          );
        }).toList();
      });
    } else {
      throw Exception('Failed to load nearby hospitals');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: currentZoom,
              maxZoom: 18.0,
              minZoom: 2.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 30.0,
                    height: 30.0,
                    point: LatLng(centerLat, centerLng),
                    child: Container(
                      child: Image.asset('images/map/blue.blank.png'),
                    ),
                  ),
                  ...hospitalMarkers,
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: <Widget>[
                Zoom(
                  onClickIn: () {
                    if (currentZoom < 18.0) {
                      setState(() {
                        currentZoom += 1;
                      });
                      mapController.move(LatLng(centerLat, centerLng), currentZoom);
                    }
                  },
                  onClickOut: () {
                    if (currentZoom > 2.0) {
                      setState(() {
                        currentZoom -= 1;
                      });
                      mapController.move(LatLng(centerLat, centerLng), currentZoom);
                    }
                  },
                ),
                SizedBox(height: 10),
                Location(
                  onClickLocation: () {
                    mapController.move(LatLng(centerLat, centerLng), currentZoom);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Zoom extends StatelessWidget {
  final VoidCallback onClickIn;
  final VoidCallback onClickOut;

  Zoom({required this.onClickIn, required this.onClickOut});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.zoom_in),
          onPressed: onClickIn,
        ),
        IconButton(
          icon: Icon(Icons.zoom_out),
          onPressed: onClickOut,
        ),
      ],
    );
  }
}

class Location extends StatelessWidget {
  final VoidCallback onClickLocation;

  Location({required this.onClickLocation});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.my_location),
      onPressed: onClickLocation,
    );
  }
}
