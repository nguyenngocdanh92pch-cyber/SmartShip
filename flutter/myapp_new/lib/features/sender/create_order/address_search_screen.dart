import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';

// 🌟 KHÔNG CẦN DÙNG Geolocator NỮA VÌ OPENSTREETMAP TÌM TEXT RẤT XỊN

class AddressSearchScreen extends StatefulWidget {
  final String title;
  const AddressSearchScreen({super.key, required this.title});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placesList = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm gọi API của OpenStreetMap (Thay thế Mapbox)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Để 600ms vì API miễn phí yêu cầu không spam quá nhanh
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (query.trim().isEmpty) {
        setState(() => _placesList = []);
        return;
      }

      setState(() => _isLoading = true);

      String encodedQuery = Uri.encodeComponent(query.trim());

      // 🌟 LÕI TÌM KIẾM MỚI: OPENSTREETMAP (Miễn phí, Data VN cực chuẩn)
      String url =
          "https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&countrycodes=vn&addressdetails=1&limit=10";

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            // API mở yêu cầu có Header User-Agent để hệ thống nhận diện
            'User-Agent': 'SmartShip_Student_Project',
          },
        );

        if (response.statusCode == 200) {
          // Xử lý lỗi font tiếng Việt bằng utf8.decode
          final data =
              jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          setState(() {
            _placesList = data;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint("Lỗi tìm địa chỉ OSM: $e");
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 18)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Nhập số nhà, tên đường, chợ...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _placesList = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Danh sách kết quả
          Expanded(
            child: ListView.separated(
              itemCount: _placesList.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 50),
              itemBuilder: (context, index) {
                final place = _placesList[index];

                // 🌟 TRÍCH XUẤT DỮ LIỆU TỪ OPENSTREETMAP
                // OSM trả về 'display_name' rất chuẩn xác (VD: Chợ Bến Thành, Đường Lê Lợi, Phường Bến Thành...)
                final fullAddress = place['display_name'] ?? "";

                // Cắt tên ngắn gọn ra làm Tiêu đề chính
                final placeName = fullAddress.split(',').first.trim();

                // Phần còn lại làm Tiêu đề phụ (Bỏ tên ngắn gọn bị lặp ở đầu đi)
                String addressDetail = fullAddress;
                if (addressDetail.startsWith("$placeName,")) {
                  addressDetail = addressDetail
                      .replaceFirst("$placeName,", "")
                      .trim();
                }

                // OSM lưu tọa độ dưới dạng String, cần convert sang double
                final double lat =
                    double.tryParse(place['lat'].toString()) ?? 0.0;
                final double lng =
                    double.tryParse(place['lon'].toString()) ?? 0.0;

                return Container(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      placeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        addressDetail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context, {
                        'address': fullAddress,
                        'lat': lat,
                        'lng': lng,
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
