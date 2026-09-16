# 🚀 SmartShip - Hệ thống Giao nhận Thông minh[cite: 1]

## 📖 Giới thiệu
SmartShip là một nền tảng di động kết nối "Người Gửi hàng" (cá nhân, cửa hàng) với "Người Giao hàng" (tài xế tự do), giúp quy trình gửi và nhận hàng trở nên nhanh chóng, minh bạch và hiệu quả[cite: 1]. Hệ thống được thiết kế theo mô hình Client-Server kết hợp với kiến trúc Microservices để đảm bảo hiệu năng cao, dễ dàng bảo trì và mở rộng khi lượng người dùng tăng cao[cite: 2].

## 🏗️ Cấu trúc dự án (Repository Structure)
Dự án được tổ chức thành các phân hệ riêng biệt, phân tách rõ ràng vai trò:
- 📁 **`SmartShip_backend/`**: Mã nguồn hệ thống API Backend được xây dựng theo kiến trúc Microservices[cite: 2].
- 📁 **`flutter/myapp_new/`**: Mã nguồn ứng dụng di động đa nền tảng (Cross-platform) dành cho cả Người Gửi và Người Giao hàng[cite: 2].
- 📁 **`smartship-admin/`**: Mã nguồn trang quản trị (Admin Portal) giúp theo dõi và vận hành toàn bộ hoạt động của nền tảng[cite: 1].

## 🛠️ Công nghệ & Kiến trúc (Tech Stack & Architecture)
Dự án áp dụng các công nghệ hiện đại nhằm đảm bảo tính toàn vẹn dữ liệu và trải nghiệm người dùng tối ưu:

- **Mobile Client:** Flutter (Dart) cho phép chạy mượt mà trên cả iOS và Android[cite: 2].
- **Web Admin:** ReactJS kết hợp với Tailwind CSS mang lại giao diện Dashboard hiện đại, chuẩn UI/UX.
- **Backend Architecture:** Java (Spring Boot) triển khai theo kiến trúc Microservices (Bao gồm các service độc lập: API Gateway, Auth, User, Shipment, Location, Notification, Routing Service)[cite: 2].
- **Cơ sở dữ liệu (Database Strategy):**
  - **PostgreSQL:** Lưu trữ dữ liệu có cấu trúc quan hệ (thông tin người dùng, đơn hàng)[cite: 2].
  - **MongoDB / DynamoDB:** Lưu trữ dữ liệu vị trí GPS theo chuỗi thời gian để dễ dàng truy vấn[cite: 2].
  - **Redis:** Xử lý Caching và cơ chế Pub-Sub truyền tin real-time cho việc cập nhật vị trí lên bản đồ[cite: 2].
- **Tích hợp bên thứ ba (Third-party Integrations):** 
  - Mapbox API / Google Maps (Bản đồ & Routing)[cite: 2].
  - Firebase Cloud Messaging (FCM cho Push Notifications)[cite: 2].
  - AWS S3 / Google Cloud Storage (Lưu trữ hình ảnh kiện hàng, avatar)[cite: 2].
  - Cổng thanh toán VNPay.

## ✨ Tính năng nổi bật (Key Features)

### 📦 Dành cho Người Gửi (Sender)[cite: 1]
- **Tạo đơn hàng thông minh:** Chụp ảnh kiện hàng, hệ thống tự động đề xuất chi phí vận chuyển dựa trên khoảng cách và kích thước[cite: 1].
- **Theo dõi Real-time:** Xem trạng thái đơn hàng và vị trí của Người Giao hàng đang đến lấy hàng trực tiếp trên bản đồ trực quan[cite: 1].
- **Tích điểm & Đánh giá:** Tích điểm thưởng cho tài xế dựa trên mức độ hài lòng sau mỗi chuyến đi thành công[cite: 1].

### 🛵 Dành cho Người Giao hàng (Driver)[cite: 1]
- **Tối ưu lộ trình (Routing Optimization):** Tự động tính toán và đề xuất lộ trình lấy hàng tối ưu nhất khi nhận nhiều đơn cùng lúc, tiết kiệm chi phí và thời gian[cite: 1].
- **Cập nhật trạng thái linh hoạt:** Cập nhật các mốc trạng thái (Đã lấy hàng, Đã về kho), gửi thông báo "Tôi đã đến" qua app[cite: 1].
- **Quản lý thu nhập:** Bảng thống kê chi tiết tổng thu nhập theo ngày/tuần/tháng và quản lý điểm thưởng tích lũy[cite: 1].

### 💻 Dành cho Quản trị viên (Admin)[cite: 1]
- **Dashboard Tổng quan:** Theo dõi các chỉ số quan trọng (tổng đơn hàng, người dùng mới, doanh thu)[cite: 1].
- **Quản trị người dùng & Giao dịch:** Duyệt hồ sơ tài xế, quản lý toàn bộ luồng đơn hàng và giải quyết các vấn đề phát sinh[cite: 1].

## 👥 Đội ngũ phát triển (Contributors)
- **Danh (nguyenngocdanh92pch-cyber)** - *Software Engineer*
- **minhxuan07082005-lang**
- **CuongDepTrai12390**

---
*Dự án được xây dựng với mục tiêu ứng dụng thực tiễn các kiến thức về phát triển phần mềm, thiết kế hệ thống phân tán và quản lý quy trình vận hành chuỗi cung ứng.*
