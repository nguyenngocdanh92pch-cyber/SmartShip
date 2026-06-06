import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaSearch, FaMotorcycle, FaWallet, FaIdCard, FaLock, FaUnlock, FaMoneyBillWave, FaTimes, FaCheck, FaBan } from 'react-icons/fa';

export default function DriverManagement() {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('ALL');

  const [selectedDriver, setSelectedDriver] = useState(null); 
  const [topupAmount, setTopupAmount] = useState('');
  
  const [reviewProfile, setReviewProfile] = useState(null); 
  const [zoomedImage, setZoomedImage] = useState(null); 

  const [drivers, setDrivers] = useState([]);

  // 🛡️ BỘ NÃO BẢO MẬT (Lấy Token)
  const getAuthHeader = () => {
    const token = localStorage.getItem("accessToken");
    if (!token || token === "null" || token === "undefined") {
      return {}; 
    }
    return { Authorization: `Bearer ${token}` };
  };

  // 🚀 LẤY DỮ LIỆU TỪ BACKEND
  const fetchDrivers = async () => {
    try {
      // 1. Kéo danh sách từ user-service (Có tiền, xe, điểm...)
      const driverRes = await axios.get('http://localhost:8080/users/drivers', { headers: getAuthHeader() });
      
      // 2. Kéo danh sách Tên & SĐT từ auth-service 
      const userRes = await axios.get('http://localhost:8080/auth/all-users-info', { headers: getAuthHeader() });

      // 3. Đưa danh sách Tên vào "Từ điển" để truy xuất siêu tốc
      const usersMap = {};
      if (Array.isArray(userRes.data)) {
          userRes.data.forEach(u => {
              usersMap[u.userId] = { name: u.fullName, phone: u.phone };
          });
      }

      const realData = driverRes.data;
      if (!Array.isArray(realData)) return;

      const mappedDrivers = realData.map(d => {
        const rawId = d.userId || d.id;
        const userInfo = usersMap[rawId] || {}; // Lấy Tên và SĐT từ Từ điển ra ghép vào

        return {
          id: `TX-${rawId}`,
          rawId: rawId,
          name: userInfo.name || d.fullName || 'Tài xế mới',
          phone: userInfo.phone || d.phone || 'Chưa cập nhật',
          address: d.defaultAddress || 'Chưa cập nhật',
          balance: d.balance || 0,
          acceptanceRate: 100, 
          cancelRate: 0,      
          status: d.status || 'OFFLINE',
          profile: {
            id_card_image_url: d.idCardImageUrl || 'https://placehold.co/400x250/E2E8F0/A0AEC0?text=Chua+Co+Anh',
            id_card_back_url: d.idCardBackUrl || 'https://placehold.co/400x250/E2E8F0/A0AEC0?text=Chua+Co+Anh', 
            driver_license_url: d.driverLicenseUrl || 'https://placehold.co/400x250/E2E8F0/A0AEC0?text=Chua+Co+Anh',
            vehicle_reg_url: d.vehicleRegUrl || 'https://placehold.co/400x250/E2E8F0/A0AEC0?text=Chua+Co+Anh', 
            vehicle_info: { 
              brand: d.vehicleBrand || 'Đang cập nhật', 
              model: d.vehicleModel || '...', 
              plate: d.plateNumber || '...', 
              color: d.vehicleColor || '...' 
            } 
          }
        };
      });
      
      setDrivers(mappedDrivers);
    } catch (error) {
      console.error("Lỗi khi kéo danh sách tài xế:", error);
    }
  };

  useEffect(() => {
    fetchDrivers();
  }, []);

  const filteredDrivers = drivers.filter(driver => {
    const matchStatus = filterStatus === 'ALL' || 
                        driver.status === filterStatus || 
                        (filterStatus === 'PENDING_APPROVAL' && driver.status === 'PENDING');
    const keyword = searchTerm.toLowerCase();
    const matchSearch = driver.name.toLowerCase().includes(keyword) || driver.phone.includes(keyword) || driver.id.toLowerCase().includes(keyword);
    return matchStatus && matchSearch;
  });

  // 🛡️ TÁC VỤ DUYỆT ĐƠN
  const handleApproveAction = async (id, rawId, actionType) => {
    if (actionType === 'REJECT') {
      const reason = prompt("Nhập lý do từ chối (VD: Ảnh mờ, sai thông tin...):");
      if(reason) {
        setDrivers(drivers.filter(d => d.id !== id)); 
        alert(`Đã từ chối hồ sơ với lý do: ${reason}`);
      }
    } else {
        if (window.confirm("Bạn có chắc chắn muốn phê duyệt đối tác tài xế này không?")) {
            try {
                await axios.put(
                  `http://localhost:8080/users/admin/drivers/${rawId}/approve`, 
                  {}, 
                  { headers: getAuthHeader() }
                );
                alert("Phê duyệt và kích hoạt tài xế thành công!"); 
                
                setDrivers(drivers.map(d => d.id === id ? { ...d, status: 'ACTIVE' } : d));
                fetchDrivers(); // Tải lại danh sách
            } catch (error) {
                console.error("Lỗi khi duyệt hồ sơ:", error);
                alert("Có lỗi xảy ra khi phê duyệt!");
            }
        }
    }
    setReviewProfile(null);
  };

  const handleToggleLock = async (id, rawId, currentStatus, name) => {
    const isLocked = currentStatus === 'LOCKED' || currentStatus === 'BLOCKED';
    const action = isLocked ? 'MỞ KHÓA' : 'KHÓA';
    const newStatus = isLocked ? 'OFFLINE' : 'BLOCKED'; 

    if(window.confirm(`Bạn có chắc muốn ${action} tài khoản của ${name}?`)) {
        try {
            await axios.put('http://localhost:8080/auth/users/me', {
                userId: rawId,
                status: newStatus
            }, { headers: getAuthHeader() });
            
            setDrivers(drivers.map(d => d.id === id ? { ...d, status: newStatus } : d));
            alert(`Đã ${action.toLowerCase()} thành công tài khoản của ${name}`);
        } catch (error) {
            console.error("Lỗi khi khóa/mở khóa:", error);
            alert("Có lỗi xảy ra hoặc bạn không có quyền cập nhật trạng thái!");
        }
    }
  };

  const handleTopupSubmit = async (e) => {
    e.preventDefault();
    const amount = parseInt(topupAmount);
    if (!amount || amount <= 0) return alert("Vui lòng nhập số tiền hợp lệ!");
    
    try {
         await axios.put('http://localhost:8080/auth/users/me', {
             userId: selectedDriver.rawId,
             balance: selectedDriver.balance + amount
         }, { headers: getAuthHeader() });
         
         setDrivers(drivers.map(d => d.id === selectedDriver.id ? { ...d, balance: d.balance + amount } : d));
         alert(`Đã nạp ${amount.toLocaleString()}đ vào ví của tài xế ${selectedDriver.name}`);
    } catch (error) {
         console.error("Lỗi khi nạp tiền:", error);
         alert("Có lỗi xảy ra khi nạp tiền!");
    }
    
    setSelectedDriver(null); setTopupAmount('');
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'ACTIVE': 
      case 'ONLINE': return <span style={{...styles.badge, backgroundColor: '#C6F6D5', color: '#22543D'}}>Đang Online</span>;
      case 'OFFLINE': return <span style={{...styles.badge, backgroundColor: '#EDF2F7', color: '#4A5568'}}>Đang Offline</span>;
      case 'PENDING':
      case 'PENDING_APPROVAL': return <span style={{...styles.badge, backgroundColor: '#FEFCBF', color: '#B7791F'}}>Chờ duyệt</span>;
      case 'LOCKED': 
      case 'BLOCKED': 
          return <span style={{...styles.badge, backgroundColor: '#FED7D7', color: '#C53030'}}>Đã khóa</span>;
      default: return <span style={{...styles.badge, backgroundColor: '#EDF2F7', color: '#4A5568'}}>{status}</span>;
    }
  };

  return (
    <div style={{ paddingBottom: '50px' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaMotorcycle style={{ color: '#1E88E5' }} /> Quản lý Đối tác Tài xế
      </h1>

      <div style={{ display: 'flex', gap: '15px', marginBottom: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'white', padding: '10px 15px', borderRadius: '8px', border: '1px solid #E2E8F0', flex: 1 }}>
          <FaSearch style={{ color: '#A0AEC0', marginRight: '10px' }} />
          <input type="text" placeholder="Tìm kiếm mã TX, tên, SĐT..." style={{ border: 'none', outline: 'none', width: '100%' }} value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
        </div>
        <select style={styles.selectInput} value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
          <option value="ALL">Tất cả trạng thái</option>
          <option value="ACTIVE">Đang Online</option>        
          <option value="OFFLINE">Đang Offline</option>
          <option value="PENDING_APPROVAL">Chờ duyệt hồ sơ</option>
          <option value="BLOCKED">Bị khóa</option>            
        </select>
      </div>

      <div style={{ backgroundColor: 'white', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr><th style={styles.th}>Mã TX</th><th style={styles.th}>Tài xế</th><th style={styles.th}>Số dư Ví</th><th style={styles.th}>Hiệu suất</th><th style={styles.th}>Trạng thái</th><th style={styles.th}>Thao tác</th></tr>
          </thead>
          <tbody>
            {filteredDrivers.length > 0 ? filteredDrivers.map(d => (
              <tr key={d.id} style={styles.tr}>
                <td style={styles.td}><strong>{d.id}</strong></td>
                <td style={styles.td}><div><strong>{d.name}</strong></div><div style={{ fontSize: '12px', color: '#718096' }}>{d.phone}</div></td>
                <td style={styles.td}><span style={{ color: d.balance < 50000 ? '#E53E3E' : '#38A169', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' }}><FaWallet />{d.balance.toLocaleString()}đ</span></td>
                <td style={styles.td}>
                  <div style={{ fontSize: '13px' }}>Nhận: <span style={{ color: d.acceptanceRate > 80 ? '#38A169' : '#E53E3E', fontWeight: 'bold' }}>{d.acceptanceRate}%</span></div>
                  <div style={{ fontSize: '13px' }}>Hủy: <span style={{ color: '#E53E3E' }}>{d.cancelRate}%</span></div>
                </td>
                <td style={styles.td}>{getStatusBadge(d.status)}</td>
                
                <td style={styles.td}>
                  <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <button onClick={() => setReviewProfile(d)} style={styles.approveBtn}>
                      <FaIdCard /> {d.status === 'PENDING' || d.status === 'PENDING_APPROVAL' ? 'Duyệt hồ sơ' : 'Xem hồ sơ'}
                    </button>

                    {(d.status !== 'PENDING' && d.status !== 'PENDING_APPROVAL') && (
                      <>
                        <button onClick={() => setSelectedDriver(d)} style={styles.actionBtn}>
                          <FaMoneyBillWave color="#38A169" /> Nạp ví
                        </button>
                        {d.status === 'LOCKED' || d.status === 'BLOCKED' ? (
                          <button onClick={() => handleToggleLock(d.id, d.rawId, d.status, d.name)} style={styles.unlockBtn}>
                            <FaUnlock /> Mở khóa
                          </button>
                        ) : (
                          <button onClick={() => handleToggleLock(d.id, d.rawId, d.status, d.name)} style={styles.dangerBtn}>
                            <FaLock /> Khóa
                          </button>
                        )}
                      </>
                    )}
                  </div>
                </td>
              </tr>
            )) : (
               <tr><td colSpan="6" style={{textAlign: 'center', padding: '30px', color: '#718096'}}>Không tìm thấy đối tác tài xế nào.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* 🎯 GIAO DIỆN MODAL HỒ SƠ CHỈ CÒN 2 ẢNH */}
      {reviewProfile && (
        <div style={styles.modalOverlay}>
          <div style={{...styles.modalContent, width: '900px'}}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #E2E8F0', paddingBottom: '15px', marginBottom: '20px' }}>
              <h2 style={{ margin: 0, color: '#2D3748', display: 'flex', alignItems: 'center', gap: '10px' }}><FaIdCard color="#1E88E5"/> Chi tiết hồ sơ Đối tác</h2>
              <button onClick={() => setReviewProfile(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#A0AEC0' }}><FaTimes size={24} /></button>
            </div>

            <div style={{ display: 'flex', gap: '25px', marginBottom: '20px' }}>
              
              {/* 🚀 ĐÃ CẬP NHẬT: CỘT TRÁI CHỈ CÒN 2 ẢNH GIẤY TỜ */}
              <div style={{ flex: 1.5 }}>
                <h4 style={{ margin: '0 0 15px 0', color: '#4A5568' }}>Giấy tờ Đối tác cung cấp</h4>
                <div style={styles.docsGrid}>
                  
                  {/* Ảnh 1: CCCD Mặt Trước */}
                  <div style={styles.imageBox}>
                    <p style={styles.imageLabel}>CCCD/CMND (Mặt trước)</p>
                    <img 
                      src={reviewProfile.profile?.id_card_image_url} 
                      style={styles.docImage} 
                      onClick={() => setZoomedImage(reviewProfile.profile?.id_card_image_url)} 
                      alt="CCCD Trước" 
                    />
                  </div>

                  {/* Ảnh 2: Bằng lái xe */}
                  <div style={styles.imageBox}>
                    <p style={styles.imageLabel}>Bằng lái xe</p>
                    <img 
                      src={reviewProfile.profile?.driver_license_url} 
                      style={styles.docImage} 
                      onClick={() => setZoomedImage(reviewProfile.profile?.driver_license_url)} 
                      alt="Bằng lái" 
                    />
                  </div>

                </div>
              </div>

              {/* CỘT PHẢI: THÔNG TIN TEXT */}
              <div style={{ flex: 1 }}>
                <h4 style={{ margin: '0 0 10px 0', color: '#4A5568' }}>Thông tin cá nhân</h4>
                <div style={{ backgroundColor: '#F7FAFC', padding: '15px', borderRadius: '8px', marginBottom: '15px', border: '1px solid #E2E8F0' }}>
                  <p style={{ margin: '0 0 8px 0', fontSize: '14px' }}>Họ tên: <strong>{reviewProfile.name}</strong></p>
                  <p style={{ margin: '0 0 8px 0', fontSize: '14px' }}>SĐT: <strong>{reviewProfile.phone}</strong></p>
                  <p style={{ margin: '0', fontSize: '14px' }}>Địa chỉ tạm trú: <strong>{reviewProfile.address}</strong></p>
                </div>

                <h4 style={{ margin: '0 0 10px 0', color: '#4A5568' }}>Thông tin xe</h4>
                <div style={{ backgroundColor: '#F7FAFC', padding: '15px', borderRadius: '8px', border: '1px solid #E2E8F0' }}>
                  <p style={{ margin: '0 0 8px 0', fontSize: '14px' }}>Hãng xe: <strong>{reviewProfile.profile?.vehicle_info?.brand}</strong></p>
                  <p style={{ margin: '0 0 8px 0', fontSize: '14px' }}>Dòng xe: <strong>{reviewProfile.profile?.vehicle_info?.model}</strong></p>
                  <p style={{ margin: '0 0 8px 0', fontSize: '14px' }}>Màu sắc: <strong>{reviewProfile.profile?.vehicle_info?.color}</strong></p>
                  <p style={{ margin: '0', fontSize: '14px' }}>Biển số: <strong style={{ color: '#1E88E5' }}>{reviewProfile.profile?.vehicle_info?.plate}</strong></p>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '15px', borderTop: '1px solid #E2E8F0', paddingTop: '15px' }}>
              {reviewProfile.status === 'PENDING' || reviewProfile.status === 'PENDING_APPROVAL' ? (
                <>
                  <button onClick={() => handleApproveAction(reviewProfile.id, reviewProfile.rawId, 'REJECT')} style={{ padding: '12px 20px', borderRadius: '8px', border: '1px solid #E53E3E', backgroundColor: 'white', color: '#E53E3E', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' }}><FaBan /> Từ chối hồ sơ</button>
                  <button onClick={() => handleApproveAction(reviewProfile.id, reviewProfile.rawId, 'APPROVE')} style={{ padding: '12px 20px', borderRadius: '8px', border: 'none', backgroundColor: '#38A169', color: 'white', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' }}><FaCheck /> Phê duyệt & Kích hoạt</button>
                </>
              ) : (
                <button onClick={() => setReviewProfile(null)} style={{ padding: '10px 20px', borderRadius: '8px', border: '1px solid #CBD5E0', backgroundColor: 'white', color: '#4A5568', cursor: 'pointer' }}>Đóng</button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL NẠP TIỀN VÍ */}
      {selectedDriver && (
        <div style={styles.modalOverlay}>
          <div style={styles.modalContent}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #E2E8F0', paddingBottom: '15px', marginBottom: '20px' }}>
              <h2 style={{ margin: 0, color: '#2D3748', display: 'flex', alignItems: 'center', gap: '10px' }}><FaWallet color="#1E88E5"/> Nạp tiền vào Ví</h2>
              <button onClick={() => setSelectedDriver(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#A0AEC0' }}><FaTimes size={24} /></button>
            </div>
            <div style={{ backgroundColor: '#F7FAFC', padding: '15px', borderRadius: '8px', marginBottom: '20px', border: '1px solid #E2E8F0' }}>
              <p style={{ margin: '0 0 5px 0' }}>Tài xế: <strong>{selectedDriver.name} ({selectedDriver.id})</strong></p>
              <p style={{ margin: 0 }}>Số dư hiện tại: <strong style={{ color: selectedDriver.balance < 50000 ? '#E53E3E' : '#38A169' }}>{selectedDriver.balance.toLocaleString()}đ</strong></p>
            </div>
            <form onSubmit={handleTopupSubmit}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', color: '#4A5568', fontSize: '14px' }}>Nhập số tiền cần nạp (VNĐ)</label>
              <input type="number" placeholder="VD: 500000" style={{ width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid #CBD5E0', outline: 'none', fontSize: '16px', marginBottom: '25px', boxSizing: 'border-box' }} value={topupAmount} onChange={(e) => setTopupAmount(e.target.value)} autoFocus />
              <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
                <button type="button" onClick={() => setSelectedDriver(null)} style={{ padding: '12px 20px', borderRadius: '8px', border: '1px solid #CBD5E0', backgroundColor: 'white', cursor: 'pointer', fontWeight: 'bold' }}>Hủy</button>
                <button type="submit" style={{ padding: '12px 20px', borderRadius: '8px', border: 'none', backgroundColor: '#1E88E5', color: 'white', cursor: 'pointer', fontWeight: 'bold' }}>Xác nhận nạp</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* LỚP PHỦ ZOOM ẢNH TÀI LIỆU */}
      {zoomedImage && (
        <div style={styles.zoomOverlay} onClick={() => setZoomedImage(null)}>
          <span style={styles.closeZoom}>&times;</span>
          <img src={zoomedImage} style={styles.zoomedImg} alt="Zoomed Document" />
        </div>
      )}
    </div>
  );
}

const styles = {
  th: { textAlign: 'left', padding: '15px', backgroundColor: '#F7FAFC', color: '#4A5568', borderBottom: '2px solid #E2E8F0' },
  td: { padding: '15px', color: '#2D3748', borderBottom: '1px solid #E2E8F0' },
  tr: { transition: '0.2s' },
  selectInput: { padding: '10px', borderRadius: '8px', border: '1px solid #E2E8F0', outline: 'none', color: '#4A5568', backgroundColor: 'white' },
  badge: { padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', display: 'inline-block' },
  approveBtn: { backgroundColor: '#1E88E5', color: 'white', border: 'none', padding: '8px 12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  actionBtn: { backgroundColor: '#EDF2F7', color: '#2D3748', border: '1px solid #CBD5E0', padding: '6px 12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  dangerBtn: { backgroundColor: '#FFF5F5', color: '#E53E3E', border: '1px solid #FC8181', padding: '6px 12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  unlockBtn: { backgroundColor: '#EBF8FF', color: '#3182CE', border: '1px solid #63B3ED', padding: '6px 12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  modalOverlay: { position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
  modalContent: { backgroundColor: 'white', padding: '30px', borderRadius: '15px', maxWidth: '90%', boxShadow: '0 10px 25px rgba(0,0,0,0.2)', maxHeight: '90vh', overflowY: 'auto' },
  docsGrid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' },
  imageBox: { display: 'flex', flexDirection: 'column', gap: '6px' },
  imageLabel: { fontSize: '13px', fontWeight: 'bold', color: '#718096', margin: 0 },
  docImage: { width: '100%', height: '130px', objectFit: 'cover', borderRadius: '8px', border: '1px solid #E2E8F0', cursor: 'pointer', transition: 'transform 0.2s ease' },
  zoomOverlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0, 0, 0, 0.85)', zIndex: 9999, display: 'flex', justifyContent: 'center', alignItems: 'center', cursor: 'zoom-out' },
  zoomedImg: { maxWidth: '90%', maxHeight: '90%', objectFit: 'contain', borderRadius: '8px', boxShadow: '0 0 20px rgba(0,0,0,0.5)' },
  closeZoom: { position: 'absolute', top: '20px', right: '30px', color: 'white', fontSize: '40px', fontWeight: 'bold', cursor: 'pointer' }
};