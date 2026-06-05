import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';
import '../../../../shared_widgets/picked_up_slider.dart';
import '../../../../core/utils/session_manager.dart';
import '../../home/models/shipment_model.dart';
import '../../../../shared_widgets/chat_detail_screen.dart';
import '../../../../core/utils/api_config.dart';

class OrdersView extends StatefulWidget {
  final bool isActive;
  const OrdersView({super.key, this.isActive = false});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final MapController _mapController = MapController();
  final String apiGatewayUrl = ApiConfig.baseUrl;

  // State quản lý lộ trình và định vị
  LatLng? driverLocation;
  StreamSubscription<Position>? _positionStream;

  // State quản lý đơn hàng & vẽ đường
  bool isDriverOffline = true; // 🌟 Trạng thái Online/Offline
  bool isLoading = true;
  List<ShipmentModel> optimizedOrders = [];
  List<LatLng> actualRoutePoints = [];
  int _currentStopIndex = 0;
  bool _allPickedUp = false;

  // BIẾN THEO DÕI CHIỀU CAO BOTTOM SHEET
  double _sheetExtent = 0.45;

  @override
  void initState() {
    super.initState();
    _initTrackingAndRouting();
  }

  @override
  void didUpdateWidget(covariant OrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == true && oldWidget.isActive == false) {
      _fetchAndOptimizeRoute();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initTrackingAndRouting() async {
    await _startLocationTracking();
    await _fetchAndOptimizeRoute();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }

      Position initPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        driverLocation = LatLng(initPos.latitude, initPos.longitude);
      });

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                driverLocation = LatLng(position.latitude, position.longitude);
              });
            }
          });
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        driverLocation = const LatLng(10.8230983, 106.6296633);
      });
    }
  }

  Future<void> _fetchAndOptimizeRoute() async {
    // 🌟 1. KIỂM TRA TRẠNG THÁI ONLINE
    bool onlineStatus = await SessionManager.getDriverOnlineStatus();
    if (mounted) {
      setState(() {
        isDriverOffline = !onlineStatus;
      });
    }

    if (isDriverOffline || driverLocation == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      int? driverId = await SessionManager.getUserId();

      final response = await http
          .get(
            Uri.parse('$apiGatewayUrl/shipments/driver/$driverId/accepted'),
            headers: {'X-User-Id': driverId.toString()},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        List<ShipmentModel> acceptedShipments = data
            .map((json) => ShipmentModel.fromJson(json))
            .toList();

        if (acceptedShipments.isEmpty) {
          if (mounted) setState(() => isLoading = false);
          return;
        }

        String driverCoord =
            "${driverLocation!.longitude},${driverLocation!.latitude}";
        List<String> pickupAddresses = acceptedShipments
            .map((s) => "${s.pickupLongitude},${s.pickupLatitude}")
            .toList();

        String urlParams = "driverLocation=$driverCoord";
        for (String addr in pickupAddresses) {
          urlParams += "&pickupAddresses=$addr";
        }

        final optimizeRes = await http
            .get(Uri.parse('$apiGatewayUrl/routing/optimize?$urlParams'))
            .timeout(const Duration(seconds: 10));

        if (optimizeRes.statusCode == 200) {
          final optimizeData = jsonDecode(utf8.decode(optimizeRes.bodyBytes));
          String? waypointsStr = optimizeData['waypointsData'];

          if (waypointsStr != null && waypointsStr.isNotEmpty) {
            List<dynamic> waypoints = jsonDecode(waypointsStr);
            final originalList = List<ShipmentModel>.from(acceptedShipments);

            acceptedShipments.sort((a, b) {
              int indexA = originalList.indexOf(a) + 1;
              int indexB = originalList.indexOf(b) + 1;
              int waypointA = waypoints[indexA]['waypoint_index'];
              int waypointB = waypoints[indexB]['waypoint_index'];
              return waypointA.compareTo(waypointB);
            });
          }
        }

        if (mounted) {
          setState(() {
            optimizedOrders = acceptedShipments;
            isLoading = false;
          });
        }
        _fetchRouteGeometry();
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRouteGeometry() async {
    if (driverLocation == null || optimizedOrders.isEmpty) return;

    String coords = "${driverLocation!.longitude},${driverLocation!.latitude}";
    for (var order in optimizedOrders) {
      coords += ";${order.pickupLongitude},${order.pickupLatitude}";
    }

    String token =
        "pk.eyJ1IjoibmdvY2RhbmgwMjAzMjAwNSIsImEiOiJjbW85ZmluejMwOGs4MndvaXU1MDc4aG1xIn0.R9tJL97Mm909Xwt1GE4I3w";
    String url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/$coords?geometries=geojson&overview=full&access_token=$token";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];
          if (mounted) {
            setState(() {
              actualRoutePoints = coordinates
                  .map((c) => LatLng(c[1], c[0]))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Lỗi vẽ đường Mapbox: $e");
    }
  }

  Future<bool> _updateShipmentStatus(int shipmentId, String status) async {
    try {
      int? driverId = await SessionManager.getUserId();
      final response = await http.put(
        Uri.parse('$apiGatewayUrl/shipments/$shipmentId/status?status=$status'),
        headers: {'X-User-Id': driverId.toString()},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _confirmPickUp(int orderIndex) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    ShipmentModel order = optimizedOrders[orderIndex];
    bool success = await _updateShipmentStatus(order.id, "PICKED_UP");

    if (mounted) Navigator.pop(context);

    if (success) {
      setState(() {
        _currentStopIndex++;
        if (_currentStopIndex >= optimizedOrders.length) {
          _allPickedUp = true;
        } else {
          var nextOrder = optimizedOrders[_currentStopIndex];
          _mapController.move(
            LatLng(nextOrder.pickupLatitude, nextOrder.pickupLongitude),
            15.0,
          );
        }
      });
    }
  }

  Future<void> _confirmAtWarehouse() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    for (int i = 0; i < _currentStopIndex; i++) {
      var order = optimizedOrders[i];
      bool success = await _updateShipmentStatus(order.id, "AT_WAREHOUSE");
      if (success) successCount++;
    }

    if (mounted) Navigator.pop(context);

    if (successCount > 0) {
      setState(() {
        _currentStopIndex = 0;
        _allPickedUp = false;
        optimizedOrders.clear();
        actualRoutePoints.clear();
        isLoading = true;
      });
      _fetchAndOptimizeRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Lộ trình giao hàng",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,

      // 🌟 CẤU TRÚC ĐIỀU KIỆN CHUẨN XÁC
      body: isDriverOffline
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_off, size: 80, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text(
                    "Bạn đang OFFLINE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Vui lòng bật ONLINE ở Trang chủ để làm việc",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            )
          : isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : optimizedOrders.isEmpty
          ? const Center(
              child: Text(
                "Bạn chưa có đơn hàng nào",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(child: _buildRealTimeMap()),
                NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _sheetExtent = notification.extent;
                    });
                    return true;
                  },
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.45,
                    minChildSize: 0.15,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 16,
                                ),
                                height: 5,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _fetchAndOptimizeRoute,
                                color: AppColors.primary,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: optimizedOrders.length,
                                  itemBuilder: (context, index) =>
                                      _buildOrderCard(index),
                                ),
                              ),
                            ),
                            if (_currentStopIndex > 0)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: PickedUpSlider(
                                  text: _allPickedUp
                                      ? 'Vuốt để báo Đã về Kho'
                                      : 'Chốt ca & Về kho sớm',
                                  onConfirm: _confirmAtWarehouse,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (driverLocation != null) _buildMyLocationButton(),
              ],
            ),
    );
  }

  // =========================================================================
  // CÁC HÀM XÂY DỰNG GIAO DIỆN CON
  // =========================================================================

  Widget _buildRealTimeMap() {
    List<LatLng> displayPoints = actualRoutePoints.isNotEmpty
        ? actualRoutePoints
        : optimizedOrders
              .map((o) => LatLng(o.pickupLatitude, o.pickupLongitude))
              .toList();
    if (driverLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: driverLocation!, initialZoom: 14.0),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoibmdvY2RhbmgwMjAzMjAwNSIsImEiOiJjbW85ZmluejMwOGs4MndvaXU1MDc4aG1xIn0.R9tJL97Mm909Xwt1GE4I3w',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: displayPoints,
              color: const Color(0xFF1565C0), // Xanh đậm
              strokeWidth: 8.0,
            ),
            Polyline(
              points: displayPoints,
              color: const Color(0xFF42A5F5), // Xanh sáng
              strokeWidth: 4.0,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // MŨI TÊN TÀI XẾ 32x32 CHUẨN GOOGLE MAPS
            Marker(
              point: driverLocation!,
              width: 32,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.navigation,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
            ...optimizedOrders.asMap().entries.map((entry) {
              int index = entry.key;
              var order = entry.value;
              bool isDone = index < _currentStopIndex;
              return Marker(
                point: LatLng(order.pickupLatitude, order.pickupLongitude),
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDone ? Colors.grey.shade400 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? Colors.white : Colors.black87,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isDone ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMyLocationButton() {
    double bottomPosition =
        (MediaQuery.of(context).size.height * _sheetExtent) + 16.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      bottom: bottomPosition,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'myLocationBtn_orders',
        backgroundColor: const Color(0xFF1E2238),
        mini: true,
        elevation: 4,
        onPressed: () {
          if (driverLocation != null) {
            _mapController.move(driverLocation!, 15.0);
          }
        },
        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildOrderCard(int index) {
    final order = optimizedOrders[index];
    final isActive = index == _currentStopIndex && !_allPickedUp;
    final isDone = index < _currentStopIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.blueAccent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Điểm dừng ${index + 1}: Lấy Hàng",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.blueAccent,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  int? driverId = await SessionManager.getUserId();
                  if (driverId != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          currentUserId: driverId.toString(),
                          currentUserName: order.driverName,
                          peerId: order.senderId.toString(),
                          peerName: order.senderName,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.packageDescription,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.pickupAddress,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tiền thu: \$${order.shippingCost}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "#${order.id}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            PickedUpSlider(
              text: 'Vuốt khi lấy xong hàng',
              onConfirm: () => _confirmPickUp(index),
            ),
          ],
          if (isDone) ...[
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Đã lấy hàng ✅",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
