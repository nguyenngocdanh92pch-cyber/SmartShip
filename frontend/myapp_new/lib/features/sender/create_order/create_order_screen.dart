import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';
import 'address_search_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? pickupAddress;
  double? pickupLat;
  double? pickupLng;

  String? deliveryAddress;
  double? deliveryLat;
  double? deliveryLng;

  final TextEditingController _packageDescController = TextEditingController();
  final TextEditingController _packageValueController = TextEditingController();

  // 🌟 BIẾN LƯU LOẠI XE (Mặc định là xe máy)
  String _selectedVehicle = "xe_may";

  File? _selectedImage;
  bool _isLoading = false;

  final String apiGatewayUrl = ApiConfig.baseUrl;

  // Danh sách các loại xe để hiển thị UI
  final List<Map<String, dynamic>> _vehicles = [
    {"id": "xe_may", "name": "Xe máy", "icon": Icons.motorcycle},
    {"id": "xe_ban_tai", "name": "Bán tải", "icon": Icons.local_shipping},
    {"id": "xe_tai", "name": "Xe tải", "icon": Icons.fire_truck},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _selectAddress(bool isPickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSearchScreen(
          title: isPickup ? "Chọn điểm lấy hàng" : "Chọn điểm giao hàng",
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          pickupAddress = result['address'];
          pickupLat = result['lat'];
          pickupLng = result['lng'];
        } else {
          deliveryAddress = result['address'];
          deliveryLat = result['lat'];
          deliveryLng = result['lng'];
        }
      });
    }
  }

  Future<void> _handleCreateOrder() async {
    if (pickupAddress == null ||
        deliveryAddress == null ||
        _packageDescController.text.isEmpty ||
        _packageValueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin!")),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng tải lên hình ảnh hàng hóa!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? token = await SessionManager.getToken();
      int? userId = await SessionManager.getUserId();

      var uri = Uri.parse("$apiGatewayUrl/shipments/");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      if (userId != null) request.headers['X-User-Id'] = userId.toString();

      request.fields['pickupAddress'] = pickupAddress!;
      request.fields['deliveryAddress'] = deliveryAddress!;
      request.fields['pickupLatitude'] = pickupLat.toString();
      request.fields['pickupLongitude'] = pickupLng.toString();
      request.fields['deliveryLatitude'] = deliveryLat.toString();
      request.fields['deliveryLongitude'] = deliveryLng.toString();
      request.fields['packageDescription'] = _packageDescController.text;
      request.fields['packageValue'] = _packageValueController.text;

      // 🌟 TRUYỀN LOẠI XE XUỐNG BACKEND
      request.fields['vehicleType'] = _selectedVehicle;

      var imageFile = await http.MultipartFile.fromPath(
        'images',
        _selectedImage!.path,
      );
      request.files.add(imageFile);

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tạo đơn hàng thành công!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Tạo đơn hàng mới",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle("Thông tin địa chỉ"),
            _buildInputCard([
              _buildAddressSelector(
                title: pickupAddress ?? "Điểm lấy hàng",
                icon: Icons.circle_outlined,
                iconColor: Colors.blue,
                isPlaceholder: pickupAddress == null,
                onTap: () => _selectAddress(true),
              ),
              const Divider(height: 20),
              _buildAddressSelector(
                title: deliveryAddress ?? "Điểm giao hàng",
                icon: Icons.location_on,
                iconColor: Colors.red,
                isPlaceholder: deliveryAddress == null,
                onTap: () => _selectAddress(false),
              ),
            ]),

            const SizedBox(height: 20),

            // 🌟 GIAO DIỆN CHỌN LOẠI XE MỚI
            _buildSectionTitle("Phương tiện vận chuyển"),
            Row(
              children: _vehicles
                  .map(
                    (v) => Expanded(
                      child: _buildVehicleCard(v['id'], v['name'], v['icon']),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 20),

            _buildSectionTitle("Thông tin hàng hóa"),
            _buildInputCard([
              _buildTextField(
                "Mô tả hàng hóa",
                Icons.inventory_2,
                Colors.orange,
                _packageDescController,
              ),
              const Divider(height: 20),
              _buildTextField(
                "Giá trị hàng hóa (VNĐ)",
                Icons.attach_money,
                Colors.green,
                _packageValueController,
                keyboardType: TextInputType.number,
              ),
              const Divider(height: 20),
              _buildImagePickerButton(),
            ]),

            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleCreateOrder,
                    child: const Text(
                      "XÁC NHẬN TẠO ĐƠN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // 🌟 WIDGET CHỌN LOẠI XE
  Widget _buildVehicleCard(String id, String name, IconData icon) {
    bool isSelected = _selectedVehicle == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerButton() {
    return InkWell(
      onTap: _pickImage,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedImage == null
                    ? "Tải lên hình ảnh hàng hóa"
                    : "Đã chọn ảnh",
                style: TextStyle(
                  color: _selectedImage == null ? Colors.grey : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  _selectedImage!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAddressSelector({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isPlaceholder ? Colors.grey : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    Color iconColor,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, color: iconColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
