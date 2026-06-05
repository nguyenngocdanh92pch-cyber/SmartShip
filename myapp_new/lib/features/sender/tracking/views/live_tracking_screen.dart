import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/api_config.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int driverId;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;

  const LiveTrackingScreen({
    super.key,
    required this.driverId,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  late StompClient _stompClient;
  LatLng? _driverLocation; // T?a d? tài x? thay d?i liên t?c

  // THAY IP THÀNH IP MÁY B?N - Chú ý port 8084 c?a LocationService
  // Dùng giao th?c ws:// cho WebSocket
  final String _wsUrl = "ws://${ApiConfig.baseUrl}/ws-location";

  // Token Mapbox c?a b?n
  final String _mapboxToken =
      "pk.eyJ1IjoibmdvY2RhbmgwMjAzMjAwNSIsImEiOiJjbW85ZmluejMwOGs4MndvaXU1MDc4aG1xIn0.R9tJL97Mm909Xwt1GE4I3w";

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => debugPrint(error.toString()),
      ),
    );
    _stompClient.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint("? Ðã k?t n?i WebSocket thành công!");
    // L?ng nghe dúng kênh c?a ông tài x? dang giao don này
    _stompClient.subscribe(
      destination: '/topic/driver/${widget.driverId}',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          Map<String, dynamic> data = jsonDecode(frame.body!);
          if (mounted) {
            setState(() {
              // C?p nh?t t?a d? m?i
              _driverLocation = LatLng(data['lat'], data['lng']);

              // T? d?ng di chuy?n camera b?n d? theo tài x?
              _mapController.move(_driverLocation!, 15.0);
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ði?m d?n (Giao hàng)
    final deliveryPoint = LatLng(widget.deliveryLat, widget.deliveryLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài x? dang trên du?ng"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _driverLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Ðang k?t n?i d?nh v? tài x?..."),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverLocation!,
                initialZoom: 15.0,
              ),
              children: [
                // B?n d? Mapbox
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken',
                  userAgentPackageName: 'com.smartship.customer',
                ),

                // V? 1 du?ng th?ng tu?ng trung t? xe máy t?i nhà khách
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_driverLocation!, deliveryPoint],
                      color: Colors.blueAccent.withOpacity(0.5),
                      strokeWidth: 4.0,
                      pattern: StrokePattern.dashed(segments: [10.0, 10.0]),
                    ),
                  ],
                ),

                // Marker: Xe máy & Ði?m giao
                MarkerLayer(
                  markers: [
                    // Ði?m giao hàng (Nhà khách)
                    Marker(
                      point: deliveryPoint,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    // Tài x? (Di chuy?n liên t?c)
                    Marker(
                      point: _driverLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 5),
                          ],
                        ),
                        child: const Icon(
                          Icons.motorcycle,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
