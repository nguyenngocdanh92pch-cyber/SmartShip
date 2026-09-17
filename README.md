# 🚀 SmartShip - Hệ thống Giao nhận Thông minh

## 📖 Giới thiệu
SmartShip là nền tảng di động đa nền tảng kết nối "Người Gửi hàng" với "Người Giao hàng", giúp quy trình vận chuyển trở nên minh bạch và hiệu quả. Hệ thống được xây dựng trên kiến trúc Microservices có khả năng mở rộng cao, tích hợp công nghệ theo dõi thời gian thực, tối ưu lộ trình và trợ lý ảo AI để nâng cao trải nghiệm người dùng.

## 📸 Giao diện Hệ thống (Screenshots)

### 📦 Luồng Người Gửi (Sender Flow)
*Trải nghiệm đặt đơn nhanh chóng, trực quan và theo dõi trạng thái giao hàng theo thời gian thực.*

| Đăng nhập hệ thống | Chọn địa chỉ vận chuyển | Chi tiết gói hàng | Theo dõi đơn hàng |
|:---:|:---:|:---:|:---:|
| <img src="screenshot/1789635790525_186156117467684517_3027660837223229236_cb30af9d1f5a48e13c6ea0276f45bfdf.jpg" width="200" alt="Đăng nhập"> | <img src="screenshot/1789635790269_186156117467684517_3027660837223229236_c0fd7a876e3a720c045863b435a81c4a.jpg" width="200" alt="Tạo đơn"> | <img src="screenshot/1789635790236_186156117467684517_3027660837223229236_2b0056b10387f0c4314de9169dcfc164.jpg" width="200" alt="Thông tin hàng"> | <img src="screenshot/1789635790427_186156117467684517_3027660837223229236_25857b579da3874c96e3cee1a1ff17bb.jpg" width="200" alt="Theo dõi"> |
| *Giao diện xác thực* | *Ghim vị trí chính xác* | *Mô tả & Hình ảnh* | *Quản lý chuyến đi* |

### 🛵 Luồng Người Giao Hàng (Driver Flow)
*Tối ưu hóa hành trình, hỗ trợ định vị chính xác và tương tác linh hoạt với khách hàng.*

| Trực tuyến nhận đơn | Định vị & Lộ trình | Tương tác khách hàng | Cập nhật trạng thái |
|:---:|:---:|:---:|:---:|
| <img src="screenshot/1789635790491_186156117467684517_3027660837223229236_c51ca906a4aea9ab2468e15db7b94feb.jpg" width="200" alt="Trực tuyến"> | <img src="screenshot/1789635790388_186156117467684517_3027660837223229236_945a972985fd43990616cc7e29074a2b.jpg" width="200" alt="Lộ trình"> | <img src="screenshot/1789635790351_186156117467684517_3027660837223229236_bfb1c81941631df40d76e492bad0834c.jpg" width="200" alt="Thông báo"> | <img src="screenshot/1789635790310_186156117467684517_3027660837223229236_5897c26a4535898a73c7bac7ffb08554.jpg" width="200" alt="Lấy hàng"> |
| *Quét đơn hàng lân cận* | *Bản đồ lộ trình tối ưu* | *Báo cáo vị trí điểm đến* | *Xác nhận lấy hàng* |

### 🤖 Trợ lý Ảo Thông Minh (SmartShip AI)
<img src="screenshot/1789635790194_186156117467684517_3027660837223229236_d53cdb750d6fd010a306026b1e0133a7.jpg" width="250" alt="SmartShip AI">

*Trợ lý AI hỗ trợ giải đáp tự động về giá cước, lộ trình và các vấn đề vận chuyển.*

## 🛠️ Công nghệ & Kiến trúc (Tech Stack)
- **Backend Architecture:** Phát triển bằng Spring Boot theo kiến trúc Microservices có tính mở rộng cao, định tuyến tập trung qua API Gateway.
- **Cơ sở dữ liệu (Database Strategy):**
  - **PostgreSQL:** Lưu trữ dữ liệu giao dịch có cấu trúc (thông tin người dùng, đơn hàng).
  - **MongoDB:** Lưu trữ và truy vấn chuỗi thời gian cho dữ liệu vị trí GPS.
  - **Redis:** Xử lý truyền tải dữ liệu thời gian thực cho tính năng theo dõi tài xế.
- **Frontend / Client:**
  - **Mobile App:** Flutter (Cross-platform) dành cho cả Người Gửi và Người Giao hàng.
  - **Admin Web:** ReactJS.
- **Tích hợp bên thứ ba (Integrations):**
  - Mapbox / Google Maps API (Tối ưu lộ trình).
  - VNPay API (Cổng thanh toán trực tuyến).
  - RESTful API & Groq API.

## ✨ Tính năng nổi bật (Key Features)
- **Quy trình vận hành liền mạch:** Xử lý toàn bộ vòng đời đơn hàng từ lúc đặt, tính toán chi phí, cho đến khi hoàn thành.
- **Tracking Real-time:** Ứng dụng Redis để phát tín hiệu vị trí, giúp Người Gửi xem tài xế di chuyển trực tiếp trên bản đồ.
- **Tối ưu lộ trình & Điều phối:** Gợi ý chuyến đi ngắn nhất cho tài xế dựa trên Mapbox/Google Maps.
- **SmartShip AI (RAG):** Chatbot hỗ trợ khách hàng được trợ lực bởi AI, ứng dụng kiến trúc Retrieval-Augmented Generation (RAG) qua Groq API, cung cấp câu trả lời chính xác, nhận thức ngữ cảnh.
- **Thanh toán bảo mật:** Tích hợp cổng VNPay cho các giao dịch không tiền mặt.

## ⚙️ Hướng dẫn Cài đặt (Installation & Setup)

Để triển khai hệ thống cục bộ, bạn cần cài đặt: **Java (JDK 17+)**, **Node.js**, **Flutter SDK**, cùng các hệ quản trị cơ sở dữ liệu (PostgreSQL, MongoDB, Redis).

### 1. Cài đặt Backend (Spring Boot Microservices)
```bash
# Di chuyển vào thư mục backend
cd SmartShip_backend

# Cấu hình môi trường: 
# Cập nhật thông tin kết nối DB (Postgres, Mongo, Redis), VNPay Keys và Groq API Key trong file application.yml / application.properties.

# Build và chạy ứng dụng
./mvnw clean install
./mvnw spring-boot:run
