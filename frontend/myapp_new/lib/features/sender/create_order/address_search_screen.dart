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
      if (query.trim().isEmpty) {
        setState(() => _placesList = []);
        return;
      }

      setState(() => _isLoading = true);

      // Giới hạn tìm kiếm ở Việt Nam (country=vn)
      String url =
          "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$mapboxToken&country=vn&autocomplete=true&limit=5";

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _placesList = data['features'] ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Lỗi tìm địa chỉ: $e");
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.all(16.0),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Danh sách kết quả
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: ListView.separated(
              itemCount: _placesList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _placesList[index];
                final addressName = place['place_name'] ?? "";

                // Mapbox trả về [Kinh độ, Vĩ độ] (Lng, Lat)
                final coordinates = place['center'];
                final double lng = coordinates[0];
                final double lat = coordinates[1];

                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(
                    place['text'] ?? "", // Tên ngắn gọn (Ví dụ: Chợ Bến Thành)
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    addressName, // Địa chỉ đầy đủ
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
