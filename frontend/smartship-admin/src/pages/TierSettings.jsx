import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaSave, FaCog, FaArrowRight, FaShieldAlt } from 'react-icons/fa';

export default function TierSettings() {
  const [configs, setConfigs] = useState([]);
  const [loading, setLoading] = useState(true);

  // 1. Kéo cấu hình mốc điểm qua API Gateway (Thêm /users)
  useEffect(() => {
    axios.get('http://localhost:8080/users/admin/tier-configs')
      .then(res => {
        // Sắp xếp theo ID để đảm bảo thứ tự Đồng -> Kim Cương không bị nhảy lung tung
        setConfigs(res.data.sort((a, b) => a.id - b.id));
        setLoading(false);
      })
      .catch(err => {
        console.error("Lỗi tải cấu hình:", err);
        setLoading(false); // Dừng trạng thái loading để hiện thông báo
        alert("Không thể kết nối Backend! Hãy kiểm tra xem UserService đã chạy và đã mở @CrossOrigin chưa.");
      });
  }, []);

  // 2. Xử lý khi Admin thay đổi số điểm
  const handlePointChange = (index, newValue) => {
    const updatedConfigs = [...configs];
    updatedConfigs[index].minPoints = parseInt(newValue) || 0;
    setConfigs(updatedConfigs);
  };

  // 3. Lưu mốc điểm mới xuống Database qua API Gateway (Thêm /users)
  const handleSave = async () => {
    try {
      await axios.put('http://localhost:8080/users/admin/tier-configs/update', configs);
      alert("🚀 Hệ thống SmartShip đã cập nhật mốc thăng hạng mới!");
    } catch (error) {
      console.error("Lỗi lưu cấu hình:", error);
      alert("Lỗi khi lưu cấu hình! Vui lòng kiểm tra Console (F12).");
    }
  };

  // Trạng thái chờ khi đang gọi API
  if (loading) {
    return (
      <div style={{ padding: '40px', textAlign: 'center', color: '#718096' }}>
        <div style={styles.spinner}></div>
        <p>Đang kết nối trung tâm điều khiển Level 2...</p>
      </div>
    );
  }

  return (
    <div style={{ padding: '20px' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaCog style={{ color: '#718096' }} /> Cài đặt Hệ thống (Level 2)
      </h1>

      <div style={{ backgroundColor: 'white', padding: '30px', borderRadius: '15px', boxShadow: '0 4px 15px rgba(0,0,0,0.05)', maxWidth: '800px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px', color: '#3182CE' }}>
          <FaShieldAlt />
          <h3 style={{ margin: 0 }}>Cấu hình quy tắc thăng hạng tự động</h3>
        </div>
        
        <p style={{ color: '#718096', marginBottom: '30px', fontSize: '14px' }}>
          Hệ thống sẽ dò các mốc điểm dưới đây mỗi khi khách hoàn thành đơn để tự động cập nhật Rank.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
          {configs.length > 0 ? configs.map((config, index) => (
            <div key={config.id} style={styles.tierRow}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '15px', width: '200px' }}>
                <div style={{ ...styles.dot, backgroundColor: getTierColor(config.tierName) }}></div>
                <span style={{ fontWeight: 'bold', color: '#2D3748' }}>Hạng {config.tierName}</span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '15px', flex: 1 }}>
                <FaArrowRight style={{ color: '#CBD5E0' }} />
                <span>Từ</span>
                <input 
                  type="number" 
                  value={config.minPoints}
                  onChange={(e) => handlePointChange(index, e.target.value)}
                  style={styles.pointInput}
                  disabled={config.tierName === 'BRONZE'} 
                />
                <span style={{ color: '#718096' }}>điểm tích lũy</span>
              </div>
            </div>
          )) : (
            <p style={{textAlign: 'center', color: '#E53E3E'}}>Chưa có dữ liệu cấu hình trong Database!</p>
          )}
        </div>

        <button 
          onClick={handleSave} 
          style={styles.saveBtn}
          disabled={configs.length === 0}
        >
          <FaSave /> Lưu cấu hình hệ thống
        </button>
      </div>
    </div>
  );
}

const getTierColor = (tier) => {
  const colors = { DIAMOND: '#3182CE', PLATINUM: '#475569', GOLD: '#D69E2E', SILVER: '#718096', BRONZE: '#C05621' };
  return colors[tier] || '#CBD5E0';
};

const styles = {
  tierRow: { display: 'flex', alignItems: 'center', padding: '20px', backgroundColor: '#F7FAFC', border: '1px solid #E2E8F0', borderRadius: '10px', transition: '0.3s' },
  dot: { width: '12px', height: '12px', borderRadius: '50%' },
  pointInput: { padding: '10px', borderRadius: '8px', border: '2px solid #E2E8F0', width: '120px', textAlign: 'center', fontWeight: 'bold', outline: 'none', fontSize: '16px', color: '#2D3748' },
  saveBtn: { marginTop: '30px', backgroundColor: '#3182CE', color: 'white', border: 'none', padding: '15px 30px', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '16px', boxShadow: '0 4px 6px rgba(49, 130, 206, 0.2)' },
  spinner: { width: '40px', height: '40px', border: '4px solid #f3f3f3', borderTop: '4px solid #3182ce', borderRadius: '50%', margin: '0 auto 10px', animation: 'spin 1s linear infinite' }
};

// Lưu ý: Nhớ thêm @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } } vào file CSS của bạn để spinner xoay nhé!