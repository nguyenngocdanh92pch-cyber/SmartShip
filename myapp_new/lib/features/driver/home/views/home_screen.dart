import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../models/shipment_model.dart';
import '../../../../core/utils/api_config.dart';

// 🎯 TUI ĐÃ THÊM DÒNG NÀY ĐỂ NÓ NHẬN DIỆN ĐƯỢC MÀN HÌNH THÔNG BÁO NÈ 
import 'package:myapp_new/features/sender/notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOnline = false;

  final MapController _mapController = MapController();
  LatLng? driverLocation;

  // --- QUẢN LÝ TRẠNG THÁI ĐƠN HÀNG ---
  List<ShipmentModel> availableShipments = [];
  ShipmentModel? selectedShipment;
  bool isEstimatingRoute = false;
  String currentDistance = "";
  String currentDuration = "";

  // 🌟 BIẾN THEO DÕI CHIỀU CAO DANH SÁCH (Mặc định 35% màn hình)
  double _sheetExtent = 0.35;

  // 🌟 BIẾN LƯU SỐ LƯỢNG TIN NHẮN CHƯA ĐỌC NÈ
  int unreadNotificationCount = 0;

  final String apiGatewayUrl = ApiConfig.baseUrl;
  StreamSubscription<Position>? _positionStream;
  Timer? _fetchOrdersTimer; // Timer để quét đơn hàng mới mỗi 15s khi Online

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchUnreadCount(); // 🎯 GỌI HÀM LẤY SỐ LƯỢNG THÔNG BÁO NGAY KHI MỞ APP
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && driverLocation == null) {
        _setFallbackLocation();
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _fetchOrdersTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // API: ĐẾM SỐ LƯỢNG THÔNG BÁO CHƯA ĐỌC CỦA TÀI XẾ
  // =========================================================================
  Future<void> _fetchUnreadCount() async {
    try {
      int? userId = await SessionManager.getUserId();
      if (userId == null) return;

      // ⚠️ LƯU Ý: Chỉnh lại đường dẫn này cho khớp với API Spring Boot của Xuân (Nếu Xuân đặt tên khác)
      final url = Uri.parse('$apiGatewayUrl/api/notifications/unread-count/$userId');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            unreadNotificationCount = int.parse(response.body); 
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Lỗi đếm số thông báo chưa đọc: $e");
    }
  }

  // =========================================================================
  // API 1: TẢI DANH SÁCH ĐƠN HÀNG PENDING (GET /shipments/available)
  // =========================================================================
  Future<void> _fetchAvailableShipments() async {
    if (!isOnline) return;

    try {
      String url = '$apiGatewayUrl/shipments/available';
      if (driverLocation != null) {
        url += '?lat=${driverLocation!.latitude}&lng=${driverLocation!.longitude}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            availableShipments = data.map((json) => ShipmentModel.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Lỗi lấy đơn hàng: $e");
    }
  }

  // =========================================================================
  // API 2: TÍNH KHOẢNG CÁCH TỪ TÀI XẾ ĐẾN ĐƠN HÀNG (GET /routing/estimate)
  // =========================================================================
  Future<void> _estimateRouteToShipment(ShipmentModel shipment) async {
    if (driverLocation == null) return;

    setState(() {
      isEstimatingRoute = true;
      currentDistance = "Đang tính...";
      currentDuration = "";
    });

    try {
      final url = Uri.parse(
        '$apiGatewayUrl/routing/estimate?originLng=${driverLocation!.longitude}&originLat=${driverLocation!.latitude}&destLng=${shipment.pickupLongitude}&destLat=${shipment.pickupLatitude}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted && selectedShipment?.id == shipment.id) {
          setState(() {
            currentDistance = data['distance'] ?? "0 km";
            currentDuration = data['duration'] ?? "0 phút";
            isEstimatingRoute = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentDistance = "Lỗi tính toán";
          isEstimatingRoute = false;
        });
      }
    }
  }

  // =========================================================================
  // API 3: TÀI XẾ BẤM NHẬN ĐƠN (POST /shipments/{id}/accept)
  // =========================================================================
  Future<void> _acceptShipment(ShipmentModel shipment) async {
    try {
      int? driverId = await SessionManager.getUserId();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        Uri.parse('$apiGatewayUrl/shipments/${shipment.id}/accept'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': driverId.toString(),
        },
      );

      Navigator.pop(context); // Tắt loading

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Nhận đơn hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          selectedShipment = null; 
        });
        _fetchAvailableShipments(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn hàng đã bị người khác nhận hoặc có lỗi xảy ra!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint("❌ Lỗi Accept đơn hàng: $e");
    }
  }

  // =========================================================================
  // GỬI VỊ TRÍ TÀI XẾ LÊN REDIS 
  // =========================================================================
  Future<void> _sendLocationToBackend(double lat, double lng) async {
    try {
      int? userId = await SessionManager.getUserId();
      String driverId = userId != null ? "SSDRIVER_$userId" : "UNKNOWN_DRIVER";
      await http.post(
        Uri.parse('$apiGatewayUrl/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': driverId,
          'latitude': lat,
          'longitude': lng,
        }),
      );
    } catch (e) {
      debugPrint("❌ Lỗi gửi vị trí: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          driverLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(driverLocation!, 15.0);
      }
      _sendLocationToBackend(position.latitude, position.longitude);
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        driverLocation = const LatLng(10.762622, 106.660172);
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _mapController.move(driverLocation!, 15.0);
      });
    }
  }

  // --- XỬ LÝ BẬT/TẮT ONLINE ĐỂ TRACKING VỊ TRÍ ---
  void _toggleOnlineStatus() async {
    bool newStatus = !isOnline;
    await SessionManager.saveDriverOnlineStatus(newStatus); 

    setState(() {
      isOnline = newStatus;
      if (!isOnline) {
        _positionStream?.cancel();
        _fetchOrdersTimer?.cancel();
        debugPrint("🔴 Tắt luồng cập nhật vị trí");
      } else {
        debugPrint("🟢 Bật luồng lắng nghe vị trí");
        _getCurrentLocation();
        _fetchAvailableShipments();
        _fetchOrdersTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
          _fetchAvailableShipments();
        });

        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );

        _positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position? position) {
          if (position != null && mounted) {
            setState(() {
              driverLocation = LatLng(position.latitude, position.longitude);
            });
            _mapController.move(driverLocation!, 15.0);
            _sendLocationToBackend(position.latitude, position.longitude);
          }
        }, onError: (e) => debugPrint("❌ Lỗi Stream GPS: $e"));
      }
    });
  }

  // Xem hình ảnh
  void _showImagesDialog(List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            "Hình ảnh gói hàng",
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: imageUrls.isEmpty
                ? const Center(
                    child: Text(
                      "Không có hình ảnh",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 150,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[800],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Ảnh bị lỗi hoặc không có quyền truy cập (403)",
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ĐÓNG"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Bản đồ
          driverLocation == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _buildRealMap(),

          // Header & Nút Online
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildOnlineToggle(),
                const SizedBox(height: 16),
                if (isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "You are currently Online & receiving requests",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Nút My Location
          if (driverLocation != null) _buildMyLocationButton(),

          // Hiển thị List đơn hàng khi Đang Online
          if (isOnline && selectedShipment == null) _buildAvailableShipmentsList(),

          // Thẻ chi tiết Đơn hàng 
          if (selectedShipment != null && isOnline)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildShipmentCard(selectedShipment!),
            ),
        ],
      ),
    );
  }

  Widget _buildRealMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: driverLocation!,
        initialZoom: 15.0,
        onTap: (tapPosition, point) {
          setState(() {
            selectedShipment = null; 
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoibmdvY2RhbmgwMjAzMjAwNSIsImEiOiJjbW85ZmluejMwOGs4MndvaXU1MDc4aG1xIn0.R9tJL97Mm909Xwt1GE4I3w',
          userAgentPackageName: 'com.smartship.driver',
        ),
        if (isOnline)
          MarkerLayer(
            markers: [
              Marker(
                point: driverLocation!,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.navigation,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
              ...availableShipments.map((shipment) {
                return Marker(
                  point: LatLng(
                    shipment.pickupLatitude,
                    shipment.pickupLongitude,
                  ),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedShipment = shipment;
                      });
                      _estimateRouteToShipment(shipment);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedShipment?.id == shipment.id
                            ? Colors.orange
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 20,
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

  Widget _buildAvailableShipmentsList() {
    if (availableShipments.isEmpty) return const SizedBox.shrink();

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _sheetExtent = notification.extent;
        });
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.15,
        maxChildSize: 0.6,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Đơn hàng quanh đây (${availableShipments.length})",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: availableShipments.length,
                    itemBuilder: (context, index) {
                      final shipment = availableShipments[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2, color: AppColors.primary),
                        ),
                        title: Text(
                          shipment.packageDescription,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          shipment.pickupAddress,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          "\$${shipment.shippingCost.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () {
                          setState(() {
                            selectedShipment = shipment;
                          });
                          _mapController.move(
                            LatLng(shipment.pickupLatitude, shipment.pickupLongitude),
                            16.0,
                          );
                          _estimateRouteToShipment(shipment);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShipmentCard(ShipmentModel shipment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  shipment.packageDescription,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text("#${shipment.id}", style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedShipment = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shipment.pickupAddress,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 8),
              isEstimatingRoute
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      "$currentDistance • $currentDuration",
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                    ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Giá trị hàng: \$${shipment.packageValue.toStringAsFixed(2)}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tiền Ship: \$${shipment.shippingCost.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showImagesDialog(shipment.imageUrls),
                icon: const Icon(Icons.photo_camera, color: Colors.blueAccent),
                label: const Text("Ảnh", style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _acceptShipment(shipment),
              child: const Text(
                "ACCEPT REQUEST",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    double bottomPosition = 32.0;

    if (isOnline) {
      if (selectedShipment != null) {
        bottomPosition = 310.0;
      } else if (availableShipments.isNotEmpty) {
        bottomPosition = (MediaQuery.of(context).size.height * _sheetExtent) + 16.0;
      }
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      bottom: bottomPosition,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'myLocationBtn',
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Home",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              // 🎯 CHUÔNG XỊN XÒ CÓ SỐ ĐỎ BÁO TIN NHẮN (BADGE)
              IconButton(
                icon: Badge(
                  isLabelVisible: unreadNotificationCount > 0, // ẨN ĐI NẾU SỐ ĐẾM = 0
                  backgroundColor: Colors.redAccent,
                  label: Text(
                    unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(
                    Icons.notifications_none, 
                    color: Colors.white, 
                    size: 28,
                  ),
                ),
                onPressed: () {
                  // Chuyển trang và làm mới số đỏ khi quay lại
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ).then((_) {
                    // Khi tắt màn hình Thông báo quay về, tự động gọi API đếm lại để xóa số đỏ
                    _fetchUnreadCount(); 
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2238),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isOnline) _toggleOnlineStatus();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "OFFLINE",
                        style: TextStyle(color: isOnline ? Colors.white54 : Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isOnline) _toggleOnlineStatus();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "ONLINE",
                        style: TextStyle(color: isOnline ? AppColors.primary : Colors.white54, fontWeight: FontWeight.bold),
                      ),
                    ),
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