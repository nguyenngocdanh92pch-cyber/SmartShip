import React, { useState, useEffect } from 'react';
import { FaBullhorn, FaPaperPlane, FaMobileAlt, FaClock } from 'react-icons/fa';
import axios from 'axios';

export default function PromotionManagement() {
  const [title, setTitle] = useState('🎁 Siêu Sale Cuối Tuần!');
  const [body, setBody] = useState('Nhập mã CUOITUAN giảm ngay 20k cho mọi chuyến giao hàng. Đặt xe ngay!');
  const [target, setTarget] = useState('ALL_SENDERS');

  // State quản lý lịch sử chiến dịch lấy THẬT từ Database
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  // 🚀 1. TỰ ĐỘNG KÉO LỊCH SỬ THẬT TỪ JAVA KHI MỞ TRANG
  useEffect(() => {
    fetchCampaignHistory();
  }, []);

  const fetchCampaignHistory = async () => {
    try {
      // Gọi đúng đến API lấy lịch sử ở Notification Service (Cổng 8085)
      const response = await axios.get('http://localhost:8080/promotions/history');
      setHistory(response.data);
      setLoading(false);
    } catch (error) {
      console.error("Lỗi khi kéo lịch sử thật từ DB:", error);
      setLoading(false);
    }
  };

  // 🚀 2. HÀM GỬI THÔNG BÁO ĐÃ SỬA KHỚP 100% VỚI BACKEND
  const handleSend = async () => {
    if (!title || !body) {
      alert("Xuân ơi, vui lòng điền đầy đủ Tiêu đề và Nội dung nhé!");
      return;
    }

    // Đóng gói dữ liệu - Sửa từ 'topic' thành 'target' để khớp với payload.get("target") ở Java
    const payload = {
      target: target,
      title: title,
      body: body
    };

    try {
      // Lưu ý: Đường dẫn API của bạn ở Java Controller đang để là @RequestMapping("/promotions") và @PostMapping("/send")
      // Nên URL chuẩn phải là: http://localhost:8085/promotions/send
      const response = await axios.post('http://localhost:8085/promotions/send', payload);

      if (response.status === 200) {
        alert("🎉 BÙM! Đã phát thông báo thành công và lưu vào Database!");

        // Xóa trắng ô nhập liệu để sẵn sàng soạn tin mới
        setTitle('');
        setBody('');

        // Tải lại bảng lịch sử ngay lập tức để dòng dữ liệu thật vừa gửi hiện lên màn hình
        fetchCampaignHistory();
      }
    } catch (error) {
      redis
      console.error("Lỗi kết nối API:", error);
      alert("❌ Lỗi kết nối! Xuân hãy kiểm tra xem Notification Service (Java port 8085) đã bấm nút RUN chưa nha!");
    }
  };

  return (
    <div style={{ paddingBottom: '50px' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaBullhorn style={{ color: '#DD6B20' }} /> Chiến dịch Khuyến mãi & Thông báo (FCM)
      </h1>

      <div style={{ display: 'flex', gap: '30px' }}>

        {/* KHU VỰC SOẠN THẢO (BÊN TRÁI) */}
        <div style={{ flex: 1 }}>
          <div style={styles.card}>
            <h3 style={styles.cardTitle}>Soạn nội dung Push Notification</h3>

            <div style={styles.formGroup}>
              <label style={styles.label}>Nhóm đối tượng nhận thông báo</label>
              <select style={styles.input} value={target} onChange={(e) => setTarget(e.target.value)}>
                <option value="ALL_SENDERS">Tất cả Khách hàng</option>
                <option value="DIAMOND_SENDERS">Chỉ Khách hàng VIP (Kim Cương)</option>
                <option value="ALL_DRIVERS">Tất cả Tài xế (Cảnh báo vận hành)</option>
              </select>
            </div>

            <div style={styles.formGroup}>
              <label style={styles.label}>Tiêu đề (Title)</label>
              <input type="text" style={styles.input} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Ví dụ: Siêu bão giảm giá..." maxLength={50} />
            </div>

            <div style={styles.formGroup}>
              <label style={styles.label}>Nội dung (Body)</label>
              <textarea style={{ ...styles.input, height: '100px', resize: 'none' }} value={body} onChange={(e) => setBody(e.target.value)} placeholder="Nhập nội dung thông báo chi tiết..."></textarea>
            </div>

            <button onClick={handleSend} style={styles.sendBtn}>
              <FaPaperPlane /> PHÁT THÔNG BÁO NGAY
            </button>
          </div>

          {/* LỊCH SỬ GỬI DỮ LIỆU THẬT */}
          <div style={{ ...styles.card, marginTop: '25px' }}>
            <h3 style={styles.cardTitle}>Lịch sử chiến dịch</h3>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
              <thead>
                <tr style={{ backgroundColor: '#F7FAFC' }}>
                  <th style={styles.th}>Thời gian</th>
                  <th style={styles.th}>Tiêu đề & Nội dung</th>
                  <th style={styles.th}>Đối tượng</th>
                  <th style={styles.th}>Trạng thái</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="4" style={{ textAlign: 'center', padding: '20px', color: '#718096' }}>Đang kết nối trung tâm điều khiển chiến dịch...</td></tr>
                ) : history.length > 0 ? (
                  history.map(item => (
                    <tr key={item.id} style={{ borderBottom: '1px solid #E2E8F0', transition: '0.2s' }}>
                      <td style={styles.td}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '5px', whiteSpace: 'nowrap' }}>
                          <FaClock style={{ color: '#A0AEC0' }} />
                          {item.createdAt ? new Date(item.createdAt).toLocaleString('vi-VN') : 'Vừa xong'}
                        </div>
                      </td>
                      <td style={styles.td}>
                        <div><strong>{item.title}</strong></div>
                        <div style={{ fontSize: '12px', color: '#718096', marginTop: '3px' }}>{item.body}</div>
                      </td>
                      <td style={styles.td}>
                        <span style={{ padding: '4px 8px', borderRadius: '6px', fontSize: '12px', backgroundColor: '#EBF8FF', color: '#2B6CB0', border: '1px solid #BEE3F8', fontWeight: '500' }}>
                          {item.targetAudience || item.target}
                        </span>
                      </td>
                      <td style={styles.td}>
                        <span style={{ padding: '4px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 'bold', backgroundColor: '#C6F6D5', color: '#22543D' }}>
                          {item.status || 'Đã gửi'}
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan="4" style={{ textAlign: 'center', padding: '20px', color: '#718096' }}>Chưa có chiến dịch khuyến mãi nào dưới Database! Hoan nghênh Xuân tạo chiến dịch đầu tiên.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* KHU VỰC XEM TRƯỚC - ĐIỆN THOẠI GIẢ LẬP (BÊN PHẢI) */}
        <div style={{ width: '350px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <h3 style={{ color: '#4A5568', display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '15px' }}>
            <FaMobileAlt /> Xem trước (Preview)
          </h3>

          <div style={{ width: '300px', height: '600px', backgroundColor: '#1A202C', borderRadius: '40px', border: '8px solid #CBD5E0', position: 'relative', boxShadow: '0 10px 25px rgba(0,0,0,0.2)', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)', width: '120px', height: '25px', backgroundColor: '#CBD5E0', borderBottomLeftRadius: '15px', borderBottomRightRadius: '15px', zIndex: 10 }}></div>

            <div style={{ width: '100%', height: '100%', backgroundImage: 'linear-gradient(to bottom, #2B6CB0, #2D3748)', paddingTop: '80px', paddingLeft: '15px', paddingRight: '15px', boxSizing: 'border-box' }}>
              <div style={{ textAlign: 'center', color: 'white', marginBottom: '30px' }}>
                <h2 style={{ margin: 0, fontSize: '48px', fontWeight: '300' }}>10:30</h2>
                <p style={{ margin: 0, fontSize: '14px', color: '#E2E8F0' }}>Thứ Hai, 20 tháng 4</p>
              </div>

              <div style={{ backgroundColor: 'rgba(255,255,255,0.9)', borderRadius: '15px', padding: '15px', backdropFilter: 'blur(10px)', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                  <div style={{ width: '20px', height: '20px', backgroundColor: '#1E88E5', borderRadius: '5px', display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'white', fontSize: '10px', fontWeight: 'bold' }}>S</div>
                  <span style={{ fontSize: '12px', color: '#4A5568', fontWeight: 'bold' }}>SMARTSHIP</span>
                  <span style={{ fontSize: '12px', color: '#A0AEC0', marginLeft: 'auto' }}>Bây giờ</span>
                </div>
                <h4 style={{ margin: '0 0 5px 0', fontSize: '14px', color: '#2D3748' }}>{title || 'Tiêu đề thông báo...'}</h4>
                <p style={{ margin: 0, fontSize: '13px', color: '#4A5568', lineHeight: '1.4' }}>{body || 'Nội dung thông báo sẽ hiển thị ở đây...'}</p>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}

const styles = {
  card: { backgroundColor: 'white', padding: '25px', borderRadius: '12px', boxShadow: '0 2px 10px rgba(0,0,0,0.05)', border: '1px solid #E2E8F0' },
  cardTitle: { margin: '0 0 20px 0', fontSize: '16px', color: '#2D3748', borderBottom: '2px solid #EBF8FF', paddingBottom: '10px' },
  formGroup: { marginBottom: '20px' },
  label: { display: 'block', fontSize: '13px', fontWeight: 'bold', color: '#4A5568', marginBottom: '8px' },
  input: { width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid #CBD5E0', outline: 'none', boxSizing: 'border-box', fontFamily: 'inherit' },
  sendBtn: { display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', backgroundColor: '#DD6B20', color: 'white', padding: '15px', border: 'none', borderRadius: '8px', fontSize: '16px', fontWeight: 'bold', cursor: 'pointer', width: '100%', transition: '0.3s' },
  th: { textAlign: 'left', padding: '12px', color: '#718096', borderBottom: '2px solid #E2E8F0', fontWeight: 'bold' },
  td: { padding: '15px 12px', color: '#2D3748' },
};