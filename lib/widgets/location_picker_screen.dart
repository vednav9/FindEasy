import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

class LocationPickerScreen extends StatefulWidget {
  final Function(String address, double lat, double lng) onLocationPicked;

  const LocationPickerScreen({required this.onLocationPicked, super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String _pickedAddress = 'Tap on the map to select a location';
  bool _isLoadingLocation = false;

  Future<void> _locateUser() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = loc.Location();
      
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _isLoadingLocation = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location service is disabled')),
            );
          }
          return;
        }
      }

      // Check if permission is granted
      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() => _isLoadingLocation = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      final locData = await location.getLocation();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locData.latitude!, locData.longitude!),
          16,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _pickedAddress =
              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() {
        _pickedAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get address: $e')),
        );
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
    _reverseGeocode(position);
  }

  @override
  void initState() {
    super.initState();
    _locateUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Location')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.5937, 78.9629),
                    zoom: 5,
                  ),
                  onTap: _onMapTap,
                  markers:
                      _pickedLocation != null
                          ? {
                            Marker(
                              markerId: const MarkerId('picked'),
                              position: _pickedLocation!,
                            ),
                          }
                          : {},
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.deepOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedAddress,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _pickedLocation != null
                              ? () {
                                widget.onLocationPicked(
                                  _pickedAddress,
                                  _pickedLocation!.latitude,
                                  _pickedLocation!.longitude,
                                );
                                Navigator.of(context).pop();
                              }
                              : null,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Confirm Location', 
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        disabledBackgroundColor: Colors.blueGrey[200],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // "Locate Me" Floating Button
          Positioned(
            top: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
              onPressed: _isLoadingLocation ? null : _locateUser,
              tooltip: 'My Location',
              child:
                  _isLoadingLocation
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
