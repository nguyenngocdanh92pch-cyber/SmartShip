import React, { useState, useEffect } from 'react';
import { FaBullhorn, FaPaperPlane, FaMobileAlt, FaClock, FaTicketAlt, FaHistory, FaCheckCircle, FaExclamationTriangle, FaBell } from 'react-icons/fa';
import axios from 'axios';

// =========================================================================
// ⚙️ TRUNG TÂM ĐIỀU PHỐI ĐƯỜNG DẪN API GIỮA CÁC MICROSERVICES
// =========================================================================
const API_CONFIG = {
  GET_VOUCHERS: 'http://localhost:8080/shipments/vouchers',
  CREATE_VOUCHER: 'http://localhost:8080/shipments/vouchers/create',
  GET_NOTI_HISTORY: 'http://localhost:8085/promotions/history',
  SEND_NOTI: 'http://localhost:8085/promotions/send'
};

export default function PromotionManagement() {
  // 0. STATE QUẢN LÝ TAB HOẠT ĐỘNG
  const [activeTab, setActiveTab] = useState('PUSH'); // 'PUSH' hoặc 'VOUCHER'

  // 1. STATE QUẢN LÝ THÔNG BÁO PUSH
  const [title, setTitle] = useState('🎁 Siêu Sale Cuối Tuần!');
  const [body, setBody] = useState('Nhập mã CUOITUAN20K giảm ngay 20k cho mọi chuyến giao hàng. Đặt xe ngay!');
  const [target, setTarget] = useState('ALL_SENDERS');

  // 2. STATE QUẢN LÝ VOUCHER
  const [voucherCode, setVoucherCode] = useState('CUOITUAN20K');
  const [discountAmount, setDiscountAmount] = useState(20000);
  const [usageLimit, setUsageLimit] = useState(100);
  const [validUntil, setValidUntil] = useState('');
  
  // Tùy chọn: Bắn luôn thông báo khi tạo Voucher
  const [sendPushWithVoucher, setSendPushWithVoucher] = useState(false);

  // 3. STATE QUẢN LÝ DỮ LIỆU BẢNG
  const [notiHistory, setNotiHistory] = useState([]);
  const [vouchers, setVouchers] = useState([]);
  const [loadingNoti, setLoadingNoti] = useState(true);
  const [loadingVouchers, setLoadingVouchers] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    fetchCampaignHistory();
    fetchVouchers();
    
    // Gán ngày giờ hết hạn mặc định
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const year = tomorrow.getFullYear();
    const month = String(tomorrow.getMonth() + 1).padStart(2, '0');
    const day = String(tomorrow.getDate()).padStart(2, '0');
    setValidUntil(`${year}-${month}-${day}T23:59`);
  }, []);

  const fetchCampaignHistory = async () => {
    try {
      setLoadingNoti(true);
      const response = await axios.get(API_CONFIG.GET_NOTI_HISTORY);
      setNotiHistory(response.data);
      setLoadingNoti(false);
    } catch (error) {
      console.error("Lỗi kéo lịch sử thông báo:", error);
      setLoadingNoti(false);
    }
  };

  const fetchVouchers = async () => {
    try {
      setLoadingVouchers(true);
      const response = await axios.get(API_CONFIG.GET_VOUCHERS, {
        params: { page: 0, size: 50, sort: 'id,desc' }
      });
      if (response.data && Array.isArray(response.data)) {
        setVouchers(response.data);
      } else if (response.data && Array.isArray(response.data.content)) {
        setVouchers(response.data.content);
      } else {
        setVouchers([]);
      }
      setLoadingVouchers(false);
    } catch (error) {
      console.error("Lỗi tải danh sách Voucher:", error);
      setLoadingVouchers(false);
    }
  };

  // 🚀 LUỒNG 1: CHỈ GỬI THÔNG BÁO PUSH
  const handleSendPushOnly = async (e) => {
    e.preventDefault();
    setErrorMessage('');
    if (!title || !body) return alert("Vui lòng điền đủ Tiêu đề và Nội dung!");

    try {
      await axios.post(API_CONFIG.SEND_NOTI, {
        target: target,
        title: title.trim(),
        body: body.trim(),
        attachedVoucherCode: null // Gửi thông báo thuần, không đính kèm mã
      });
      alert(`🎉 Gửi thông báo Push thành công!`);
      setTitle(''); setBody('');
      fetchCampaignHistory();
    } catch (error) {
      setErrorMessage("Gửi thông báo thất bại. Kiểm tra lại cổng 8085.");
    }
  };

  // 🚀 LUỒNG 2: TẠO VOUCHER (VÀ TÙY CHỌN GỬI PUSH KÈM THEO)
  const handleCreateVoucher = async (e) => {
    e.preventDefault();
    setErrorMessage('');
    if (!voucherCode || !discountAmount) return alert("Điền đủ thông tin Voucher nhé!");

    const formattedDate = validUntil.replace('T', ' ') + ':00';
    const voucherPayload = {
      code: voucherCode.trim().toUpperCase(),
      discountAmount: parseFloat(discountAmount),
      usageLimit: parseInt(usageLimit),
      usedCount: 0,
      validUntil: formattedDate,
      isActive: true
    };

    try {
      // BƯỚC 1: Lưu Voucher
      await axios.post(API_CONFIG.CREATE_VOUCHER, voucherPayload);
      
      // BƯỚC 2: Nếu có tick chọn gửi Push, gọi thêm API gửi Noti
      if (sendPushWithVoucher) {
        await axios.post(API_CONFIG.SEND_NOTI, {
          target: target,
          title: title.trim() || `Tặng mã ${voucherPayload.code}`,
          body: body.trim() || `Nhập mã giảm ngay ${voucherPayload.discountAmount}đ`,
          attachedVoucherCode: voucherPayload.code
        });
      }

      alert(`🎉 Đã tạo thành công Voucher [ ${voucherCode.toUpperCase()} ] !`);
      setVoucherCode('');
      if (sendPushWithVoucher) { setTitle(''); setBody(''); }
      fetchVouchers();
      fetchCampaignHistory();
    } catch (error) {
      setErrorMessage("Tạo Voucher thất bại. Kiểm tra lại kết nối hệ thống.");
    }
  };

  return (
    <div style={styles.container}>
      <h1 style={styles.header}>
        <FaBullhorn style={{ color: '#DD6B20' }}/> Trung tâm Điều hành Chiến dịch & Khuyến mãi
      </h1>

      {errorMessage && (
        <div style={styles.errorAlert}>
          <FaExclamationTriangle /> <strong>Lỗi:</strong> {errorMessage}
        </div>
      )}

      {/* ĐIỀU HƯỚNG TABS */}
      <div style={styles.tabsContainer}>
        <button 
          style={activeTab === 'PUSH' ? styles.tabActive : styles.tabInactive}
          onClick={() => setActiveTab('PUSH')}
        >
          <FaPaperPlane /> 1. Gửi Thông Báo Push (FCM)
        </button>
        <button 
          style={activeTab === 'VOUCHER' ? styles.tabActive : styles.tabInactive}
          onClick={() => setActiveTab('VOUCHER')}
        >
          <FaTicketAlt /> 2. Quản Lý Voucher
        </button>
      </div>

      <div style={styles.gridContainer}>
        
        {/* ================= KHU VỰC BÊN TRÁI: THEO TAB ĐANG CHỌN ================= */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '25px' }}>
          
          {/* TAB 1: GỬI THÔNG BÁO PUSH */}
          {activeTab === 'PUSH' && (
            <>
              <div style={styles.card}>
                <form onSubmit={handleSendPushOnly}>
                  <div style={styles.section}>
                    <h3 style={styles.sectionTitle}><FaBell style={{ color: '#DD6B20' }} /> Nội dung Push Notification</h3>
                    <div style={styles.formGroup}>
                      <label style={styles.label}>Nhóm đối tượng nhận tin</label>
                      <select style={styles.input} value={target} onChange={(e) => setTarget(e.target.value)}>
                        <option value="ALL_SENDERS">Tất cả Khách hàng gửi hàng (Senders)</option>
                        <option value="ALL_DRIVERS">Tất cả Đối tác tài xế (Drivers)</option>
                      </select>
                    </div>
                    <div style={styles.formGroup}>
                      <label style={styles.label}>Tiêu đề (Title)</label>
                      <input type="text" style={styles.input} value={title} onChange={(e) => setTitle(e.target.value)} required />
                    </div>
                    <div style={styles.formGroup}>
                      <label style={styles.label}>Nội dung (Body)</label>
                      <textarea style={{...styles.input, height: '80px'}} value={body} onChange={(e) => setBody(e.target.value)} required />
                    </div>
                  </div>
                  <button type="submit" style={styles.sendBtn}><FaPaperPlane /> GỬI THÔNG BÁO NGAY</button>
                </form>
              </div>

              {/* Lịch sử Push */}
              <div style={styles.card}>
                <h3 style={styles.cardTitle}><FaHistory /> Lịch sử gửi thông báo</h3>
                <div style={styles.tableContainer}>
                  <table style={styles.table}>
                    <thead>
                      <tr style={{ backgroundColor: '#F7FAFC' }}>
                        <th style={styles.th}>Thời gian</th>
                        <th style={styles.th}>Nội dung</th>
                      </tr>
                    </thead>
                    <tbody>
                      {loadingNoti ? <tr><td colSpan="2" style={styles.tableEmpty}>Đang tải...</td></tr> 
                      : notiHistory.map(item => (
                        <tr key={item.id} style={styles.tableRow}>
                          <td style={styles.td}>{item.createdAt ? new Date(item.createdAt).toLocaleString('vi-VN') : 'Vừa xong'}</td>
                          <td style={styles.td}><strong>{item.title}</strong><br/><span style={{fontSize:'12px',color:'#718096'}}>{item.body}</span></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}

          {/* TAB 2: TẠO VOUCHER */}
          {activeTab === 'VOUCHER' && (
            <>
              <div style={styles.card}>
                <form onSubmit={handleCreateVoucher}>
                  <div style={styles.section}>
                    <h3 style={styles.sectionTitle}><FaTicketAlt style={{ color: '#3182CE' }} /> Thông số Mã Giảm Giá</h3>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                      <div style={styles.formGroup}>
                        <label style={styles.label}>Mã Code (In hoa)</label>
                        <input type="text" style={styles.input} value={voucherCode} onChange={(e) => setVoucherCode(e.target.value.toUpperCase())} required />
                      </div>
                      <div style={styles.formGroup}>
                        <label style={styles.label}>Mức giảm giá (VND)</label>
                        <input type="number" style={styles.input} value={discountAmount} onChange={(e) => setDiscountAmount(e.target.value)} required />
                      </div>
                      <div style={styles.formGroup}>
                        <label style={styles.label}>Giới hạn lượt dùng</label>
                        <input type="number" style={styles.input} value={usageLimit} onChange={(e) => setUsageLimit(e.target.value)} required />
                      </div>
                      <div style={styles.formGroup}>
                        <label style={styles.label}>Có hiệu lực đến</label>
                        <input type="datetime-local" style={styles.input} value={validUntil} onChange={(e) => setValidUntil(e.target.value)} required />
                      </div>
                    </div>
                  </div>

                  {/* KHỐI CHECKBOX: TÙY CHỌN BẮN PUSH KHI TẠO VOUCHER */}
                  <div style={{...styles.section, backgroundColor: '#EBF8FF', border: '1px solid #90CDF4'}}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontWeight: 'bold', color: '#2B6CB0' }}>
                      <input type="checkbox" checked={sendPushWithVoucher} onChange={(e) => setSendPushWithVoucher(e.target.checked)} style={{ transform: 'scale(1.2)' }}/>
                      Bắn thông báo (Push Notification) cho khách hàng về Voucher này
                    </label>

                    {/* Form phụ hiện ra khi tick chọn */}
                    {sendPushWithVoucher && (
                      <div style={{ marginTop: '15px', borderTop: '1px dashed #90CDF4', paddingTop: '15px' }}>
                        <div style={styles.formGroup}>
                          <label style={styles.label}>Tiêu đề Push</label>
                          <input type="text" style={styles.input} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Tặng mã Freeship!" required={sendPushWithVoucher} />
                        </div>
                        <div style={styles.formGroup}>
                          <label style={styles.label}>Nội dung Push</label>
                          <textarea style={{...styles.input, height: '60px'}} value={body} onChange={(e) => setBody(e.target.value)} required={sendPushWithVoucher} />
                        </div>
                      </div>
                    )}
                  </div>

                  <button type="submit" style={{...styles.sendBtn, backgroundColor: '#3182CE'}}>
                    <FaTicketAlt /> PHÁT HÀNH VOUCHER NÀY
                  </button>
                </form>
              </div>

              {/* Lịch sử Voucher */}
              <div style={styles.card}>
                <h3 style={styles.cardTitle}><FaHistory /> Kho Voucher Hệ thống</h3>
                <div style={styles.tableContainer}>
                  <table style={styles.table}>
                    <thead>
                      <tr style={{ backgroundColor: '#F7FAFC' }}>
                        <th style={styles.th}>Mã Code</th>
                        <th style={styles.th}>Mức giảm</th>
                        <th style={styles.th}>Lượt dùng</th>
                        <th style={styles.th}>Trạng thái</th>
                      </tr>
                    </thead>
                    <tbody>
                      {loadingVouchers ? <tr><td colSpan="4" style={styles.tableEmpty}>Đang tải...</td></tr>
                      : vouchers.map((v, i) => (
                        <tr key={i} style={styles.tableRow}>
                          <td style={styles.td}><strong>{v.code}</strong></td>
                          <td style={styles.td}>{parseInt(v.discountAmount).toLocaleString()}đ</td>
                          <td style={styles.td}>{v.usedCount} / {v.usageLimit}</td>
                          <td style={styles.td}>
                            {v.isActive ? <span style={styles.badgeActive}><FaCheckCircle/> Chạy</span> : <span style={styles.badgeInactive}>Dừng</span>}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </div>

        {/* ================= KHU VỰC BÊN PHẢI: PREVIEW ĐIỆN THOẠI ================= */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '25px', alignItems: 'center' }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '100%' }}>
            <h3 style={{ color: '#4A5568', display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '15px', alignSelf: 'flex-start' }}>
              <FaMobileAlt /> Xem trước thông báo
            </h3>
            
            <div style={styles.phoneSmartphone}>
              <div style={styles.phoneNotch}></div>
              <div style={styles.phoneScreenInside}>
                <div style={styles.phoneClockWidget}>
                  <h2 style={{ margin: 0, fontSize: '46px', fontWeight: '300' }}>10:30</h2>
                  <p style={{ margin: 0, fontSize: '13px', color: '#E2E8F0' }}>Thứ Hai, ngày 20</p>
                </div>

                <div style={styles.phoneNotiBubble}>
                  <div style={styles.phoneNotiBubbleHeader}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <div style={styles.phoneMiniLogo}>S</div>
                      <span style={{ fontWeight: 'bold', color: '#2D3748' }}>SMARTSHIP</span>
                    </div>
                    <span style={{ color: '#A0AEC0' }}>Bây giờ</span>
                  </div>
                  <h4 style={styles.phoneNotiBubbleTitle}>{title || 'Tiêu đề thông báo...'}</h4>
                  <p style={styles.phoneNotiBubbleBody}>{body || 'Nội dung thông báo sẽ hiển thị ở đây...'}</p>
                  
                  {/* Badge Voucher chỉ hiện khi ở Tab Voucher (và có check) hoặc ở Tab Push có nhập mã */}
                  {(activeTab === 'VOUCHER' && sendPushWithVoucher && voucherCode) && (
                    <div style={styles.phoneVoucherBadgeInside}>
                      🎫 MÃ ĐÍNH KÈM: {voucherCode}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}

// ================= HỆ THỐNG CSS =================
const styles = {
  container: { padding: '30px', fontFamily: 'Arial, sans-serif', backgroundColor: '#F7FAFC', minHeight: '100vh' },
  header: { color: '#2D3748', marginBottom: '15px', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '24px' },
  
  // Thiết kế Tabs UI
  tabsContainer: { display: 'flex', gap: '10px', marginBottom: '25px', borderBottom: '2px solid #E2E8F0', paddingBottom: '0px' },
  tabActive: { backgroundColor: '#FFFFFF', border: '1px solid #E2E8F0', borderBottom: 'none', padding: '12px 20px', borderRadius: '8px 8px 0 0', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '15px', fontWeight: 'bold', color: '#2B6CB0', boxShadow: '0 -4px 6px -1px rgba(0,0,0,0.05)', position: 'relative', top: '2px' },
  tabInactive: { backgroundColor: '#EDF2F7', border: '1px solid transparent', padding: '12px 20px', borderRadius: '8px 8px 0 0', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '15px', fontWeight: '500', color: '#718096', transition: '0.2s' },

  errorAlert: { backgroundColor: '#FFF5F5', border: '1px solid #FEB2B2', color: '#C53030', padding: '12px 15px', borderRadius: '8px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px' },
  gridContainer: { display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '30px', alignItems: 'start' },
  card: { backgroundColor: 'white', padding: '25px', borderRadius: '12px', boxShadow: '0 4px 12px rgba(0,0,0,0.05)', border: '1px solid #E2E8F0' },
  cardTitle: { margin: '0 0 15px 0', fontSize: '16px', color: '#2D3748', display: 'flex', alignItems: 'center', gap: '8px', borderBottom: '2px solid #EBF8FF', paddingBottom: '10px', fontWeight: 'bold' },
  section: { padding: '18px', backgroundColor: '#F8FAFC', borderRadius: '8px', marginBottom: '20px', border: '1px solid #E2E8F0' },
  sectionTitle: { marginTop: 0, marginBottom: '15px', fontSize: '15px', display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 'bold' },
  formGroup: { marginBottom: '15px' },
  label: { display: 'block', fontSize: '13px', fontWeight: 'bold', color: '#4A5568', marginBottom: '8px' },
  input: { width: '100%', padding: '11px', borderRadius: '6px', border: '1px solid #CBD5E0', outline: 'none', boxSizing: 'border-box', fontFamily: 'inherit', fontSize: '13px' },
  sendBtn: { display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', backgroundColor: '#DD6B20', color: 'white', padding: '15px', border: 'none', borderRadius: '8px', fontSize: '16px', fontWeight: 'bold', cursor: 'pointer', width: '100%', transition: '0.3s' },
  
  phoneSmartphone: { width: '300px', height: '540px', backgroundColor: '#1A202C', borderRadius: '35px', border: '8px solid #CBD5E0', position: 'relative', boxShadow: '0 10px 25px rgba(0,0,0,0.2)', overflow: 'hidden' },
  phoneNotch: { position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)', width: '120px', height: '22px', backgroundColor: '#CBD5E0', borderBottomLeftRadius: '12px', borderBottomRightRadius: '12px', zIndex: 10 },
  phoneScreenInside: { width: '100%', height: '100%', backgroundImage: 'linear-gradient(to bottom, #2B6CB0, #2D3748)', paddingTop: '60px', paddingLeft: '15px', paddingRight: '15px', boxSizing: 'border-box' },
  phoneClockWidget: { textAlign: 'center', color: 'white', marginBottom: '25px' },
  phoneNotiBubble: { backgroundColor: 'rgba(255,255,255,0.95)', borderRadius: '14px', padding: '12px', backdropFilter: 'blur(10px)', boxShadow: '0 4px 6px rgba(0,0,0,0.15)' },
  phoneNotiBubbleHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '11px', marginBottom: '6px' },
  phoneMiniLogo: { width: '18px', height: '18px', backgroundColor: '#1E88E5', borderRadius: '4px', display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'white', fontSize: '10px', fontWeight: 'bold' },
  phoneNotiBubbleTitle: { margin: '0 0 4px 0', fontSize: '13px', color: '#2D3748', fontWeight: 'bold' },
  phoneNotiBubbleBody: { margin: 0, fontSize: '12px', color: '#4A5568', lineHeight: '1.4' },
  phoneVoucherBadgeInside: { backgroundColor: '#EBF8FF', color: '#2B6CB0', border: '1px solid #BEE3F8', padding: '5px', borderRadius: '5px', fontSize: '11px', fontWeight: 'bold', textAlign: 'center', marginTop: '8px' },
  
  tableContainer: { overflowX: 'auto', maxHeight: '250px' },
  table: { width: '100%', borderCollapse: 'collapse', fontSize: '13px', textAlign: 'left' },
  th: { padding: '10px', color: '#718096', borderBottom: '2px solid #E2E8F0', fontWeight: 'bold' },
  td: { padding: '12px 10px', color: '#2D3748', verticalAlign: 'middle' },
  tableRow: { borderBottom: '1px solid #E2E8F0' },
  tableEmpty: { textAlign: 'center', padding: '20px', color: '#718096', fontStyle: 'italic' },
  badgeActive: { backgroundColor: '#C6F6D5', color: '#276749', padding: '3px 8px', borderRadius: '12px', fontSize: '11px', fontWeight: 'bold', display: 'inline-flex', alignItems: 'center', gap: '4px' },
  badgeInactive: { backgroundColor: '#E2E8F0', color: '#4A5568', padding: '3px 8px', borderRadius: '12px', fontSize: '11px', fontWeight: 'bold' }
};