import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../models/user_profile.dart';

class IdentityVerificationScreen extends StatefulWidget {
  final UserProfile userProfile;
  const IdentityVerificationScreen({super.key, required this.userProfile});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  File? _localIdCardFile;
  File? _localLicenseFile;
  bool _isSubmitting = false;

  // Controllers cho thông tin xe
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bóc tách chuỗi JSON xe cũ để đổ dữ liệu vào ô nhập
    try {
      if (widget.userProfile.vehicleInfo != null &&
          widget.userProfile.vehicleInfo!.isNotEmpty) {
        final Map<String, dynamic> vData = jsonDecode(
          widget.userProfile.vehicleInfo!,
        );
        _makeController.text = vData['make'] ?? '';
        _plateController.text = vData['plate'] ?? '';
      }
    } catch (e) {
      debugPrint("Lỗi parse vehicleInfo: $e");
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isIdCard) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isIdCard) {
          _localIdCardFile = File(pickedFile.path);
        } else {
          _localLicenseFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    try {
      String? newIdUrl = widget.userProfile.idCardImageUrl;
      String? newLicenseUrl = widget.userProfile.driverLicenseUrl;

      // 1. Upload ảnh lên GCS nếu có chọn mới
      if (_localIdCardFile != null) {
        newIdUrl = await ApiService.uploadImage(_localIdCardFile!);
      }
      if (_localLicenseFile != null) {
        newLicenseUrl = await ApiService.uploadImage(_localLicenseFile!);
      }

      // 2. Gói thông tin xe người dùng nhập thành chuỗi JSON
      Map<String, String> vehicleMap = {
        "make": _makeController.text.trim(),
        "plate": _plateController.text.trim(),
      };

      // 3. Cập nhật lại đối tượng profile
      widget.userProfile.idCardImageUrl = newIdUrl;
      widget.userProfile.driverLicenseUrl = newLicenseUrl;
      widget.userProfile.vehicleInfo = jsonEncode(vehicleMap);

      // 4. Gọi API lưu toàn bộ vào Database
      bool success = await ApiService.updateProfile(widget.userProfile);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã lưu thông tin xe và giấy tờ!")),
          );
          Navigator.pop(context); // Trở về màn hình Profile
        }
      } else {
        throw Exception("API trả về lỗi");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi khi cập nhật dữ liệu")),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Xác minh thông tin",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thông tin phương tiện",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // --- NHẬP LOẠI XE ---
            _buildEditableField(
              "Dòng xe (Vd: Honda Wave)",
              _makeController,
              Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 12),

            // --- NHẬP BIỂN SỐ ---
            _buildEditableField(
              "Biển số xe",
              _plateController,
              Icons.two_wheeler_outlined,
            ),
            const SizedBox(height: 24),

            // --- UPLOAD HÌNH ẢNH ---
            Row(
              children: [
                Expanded(
                  child: _buildUploadCard(
                    title: "CCCD/CMND (Mặt trước)",
                    btnText: "Tải CCCD lên",
                    networkUrl: widget.userProfile.idCardImageUrl,
                    localFile: _localIdCardFile,
                    onTap: () => _pickImage(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUploadCard(
                    title: "Bằng lái xe",
                    btnText: "Tải Bằng lái lên",
                    networkUrl: widget.userProfile.driverLicenseUrl,
                    localFile: _localLicenseFile,
                    onTap: () => _pickImage(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- NÚT SUBMIT ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047AB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitVerification,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Gửi yêu cầu xác minh",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tạo ô nhập liệu
  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                    hintText: "Chưa rõ",
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String btnText,
    String? networkUrl,
    File? localFile,
    required VoidCallback onTap,
  }) {
    bool hasImage =
        localFile != null || (networkUrl != null && networkUrl.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasImage ? Colors.green : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.black12,
            ),
            clipBehavior: Clip.hardEdge,
            child: localFile != null
                ? Image.file(localFile, fit: BoxFit.cover)
                : (networkUrl != null
                      ? Image.network(networkUrl, fit: BoxFit.cover)
                      : const Center(
                          child: Text(
                            "Khung ảnh",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        )),
          ),
          const SizedBox(height: 12),
          Text(
            hasImage ? "Đã tải lên" : "Chưa có ảnh",
            style: TextStyle(
              color: hasImage ? Colors.greenAccent : Colors.redAccent,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0047AB),
              minimumSize: const Size(double.infinity, 36),
            ),
            onPressed: onTap,
            child: Text(
              btnText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
