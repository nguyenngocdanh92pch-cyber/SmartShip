import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';

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

  // Dùng lại Token Mapbox của bạn
  final String mapboxToken =
      "pk.eyJ1IjoibmdvY2RhbmgwMjAzMjAwNSIsImEiOiJjbW85ZmluejMwOGs4MndvaXU1MDc4aG1xIn0.R9tJL97Mm909Xwt1GE4I3w";

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm gọi Mapbox API
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Đợi 500ms sau khi người dùng dừng gõ mới gọi API để chống Spam
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final trimmedQuery = query.trim();

      if (trimmedQuery.isEmpty) {
        setState(() {
          _placesList = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);

      // 🌟 BẢO MẬT & CHỐNG CRASH: Phải mã hóa chuỗi để hỗ trợ tiếng Việt có dấu và khoảng trắng
      final encodedQuery = Uri.encodeComponent(trimmedQuery);

      // Giới hạn tìm kiếm ở Việt Nam (country=vn)
      final String url =
          "https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$mapboxToken&country=vn&autocomplete=true&limit=5";

      try {
        final response = await http.get(Uri.parse(url));

        // 🌟 CHỐNG CRASH: Kiểm tra xem người dùng đã thoát màn hình chưa trước khi setState
        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _placesList = data['features'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint("Lỗi tìm địa chỉ: $e");
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true, // Tự động bật bàn phím khi mở trang
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Nhập tên đường, tòa nhà...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _placesList = []);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Danh sách kết quả
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child:
                _placesList.isEmpty &&
                    !_isLoading &&
                    _searchController.text.isNotEmpty
                ? const Center(
                    child: Text(
                      "Không tìm thấy kết quả nào",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: _placesList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final place = _placesList[index];
                      final addressName = place['place_name'] ?? "";

                      // 🌟 ÉP KIỂU AN TOÀN: Đảm bảo không bị crash nếu Mapbox trả về số nguyên (int)
                      final coordinates = place['center'] as List<dynamic>?;
                      final double lng =
                          (coordinates != null && coordinates.isNotEmpty)
                          ? (coordinates[0] as num).toDouble()
                          : 0.0;
                      final double lat =
                          (coordinates != null && coordinates.length > 1)
                          ? (coordinates[1] as num).toDouble()
                          : 0.0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          place['text'] ??
                              "", // Tên ngắn gọn (Ví dụ: Chợ Bến Thành)
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          addressName, // Địa chỉ đầy đủ
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          // Trả dữ liệu về cho màn hình trước
                          Navigator.pop(context, {
                            'address': addressName,
                            'lat': lat,
                            'lng': lng,
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}