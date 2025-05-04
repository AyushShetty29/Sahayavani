import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class Hospital {
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;

  Hospital({
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  double distanceFrom(Position position) {
    const earthRadius = 6371; // km
    double dLat = _deg2rad(latitude - position.latitude);
    double dLon = _deg2rad(longitude - position.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(position.latitude)) * cos(_deg2rad(latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;
}

class NearbyHospitalsPage extends StatefulWidget {
  @override
  _NearbyHospitalsPageState createState() => _NearbyHospitalsPageState();
}

class _NearbyHospitalsPageState extends State<NearbyHospitalsPage> {
  List<Hospital> hospitals = [
    Hospital(name: 'Rural Clinic', address: 'Hill Road', phone: '111222333', latitude: 12.9716, longitude: 77.5946),
    Hospital(name: 'Health Center', address: 'Village Square', phone: '444555666', latitude: 12.9352, longitude: 77.6142),
    Hospital(name: 'City Hospital', address: 'Highway', phone: '777888999', latitude: 12.9611, longitude: 77.6387),
  ];

  Position? _currentPosition;
  List<Hospital> _nearbyHospitals = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _nearbyHospitals = hospitals.where((h) => h.distanceFrom(position) <= 10).toList(); // within 10 km
    });
  }

  void _callHospital(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Hospitals')),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _nearbyHospitals.length,
              itemBuilder: (context, index) {
                final h = _nearbyHospitals[index];
                return Card(
                  child: ListTile(
                    title: Text(h.name),
                    subtitle: Text('${h.address}\n${h.distanceFrom(_currentPosition!).toStringAsFixed(2)} km away'),
                    trailing: IconButton(
                      icon: Icon(Icons.call, color: Colors.green),
                      onPressed: () => _callHospital(h.phone),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
