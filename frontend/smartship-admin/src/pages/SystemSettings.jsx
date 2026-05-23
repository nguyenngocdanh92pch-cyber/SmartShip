import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaSave, FaCogs, FaMapMarkerAlt, FaPlus, FaShieldAlt, FaArrowRight, FaMoneyBillWave, FaTrophy } from 'react-icons/fa';

export default function SystemSettings() {
  const [activeTab, setActiveTab] = useState('operation');

  // ==========================================
  // STATE & LOGIC CHO TAB 1: VẬN HÀNH & PHỤ PHÍ
  // ==========================================
  const [settings, setSettings] = useState({
    baseFare: 15000, pricePerKm: 12000, minFare: 20000,
    vehicleMultiplier: { motorbike: 1.0, van: 1.2, truck: 1.5 },
    surcharge: { peakHour: 15.0, holiday: 20.0, night: 10.0 },
    geofencing: [
      { id: 1, name: 'Sân bay Tân Sơn Nhất', fee: 15000 },
      { id: 2, name: 'Bến xe Miền Đông', fee: 10000 }
    ]
  });

  // Kéo cấu hình Vận hành thật từ Backend
  useEffect(() => {
    axios.get('http://localhost:8080/shipments/settings')
      .then(res => {
        const data = res.data;
        // Nếu Backend trả về rỗng (lần đầu tiên), thì giữ nguyên giá trị mặc định của State.
        if (Object.keys(data).length > 0) {
          setSettings(prev => ({
            ...prev,
            baseFare: data.baseFare ? parseInt(data.baseFare) : prev.baseFare,
            pricePerKm: data.pricePerKm ? parseInt(data.pricePerKm) : prev.pricePerKm,
            minFare: data.minFare ? parseInt(data.minFare) : prev.minFare,
            vehicleMultiplier: {
              motorbike: data['vehicle_motorbike'] ? parseFloat(data['vehicle_motorbike']) : prev.vehicleMultiplier.motorbike,
              van: data['vehicle_van'] ? parseFloat(data['vehicle_van']) : prev.vehicleMultiplier.van,
              truck: data['vehicle_truck'] ? parseFloat(data['vehicle_truck']) : prev.vehicleMultiplier.truck,
            },
            surcharge: {
              peakHour: data['surcharge_peakHour'] ? parseFloat(data['surcharge_peakHour']) : prev.surcharge.peakHour,
              holiday: data['surcharge_holiday'] ? parseFloat(data['surcharge_holiday']) : prev.surcharge.holiday,
              night: data['surcharge_night'] ? parseFloat(data['surcharge_night']) : prev.surcharge.night,
            }
          }));
        }
      })
      .catch(err => console.error("Lỗi kéo cấu hình hệ thống:", err));
  }, []);

  // Hàm xử lý việc gõ số vào input để update State
  const handleSettingChange = (field, subfield, value) => {
    setSettings(prev => {
      if (subfield) {
        return { ...prev, [field]: { ...prev[field], [subfield]: value } };
      }
      return { ...prev, [field]: value };
    });
  };

  // Lưu cấu hình xuống Backend
  const handleSaveOperation = async () => {
    try {
      const payload = {
        baseFare: settings.baseFare.toString(),
        pricePerKm: settings.pricePerKm.toString(),
        minFare: settings.minFare.toString(),
        'vehicle_motorbike': settings.vehicleMultiplier.motorbike.toString(),
        'vehicle_van': settings.vehicleMultiplier.van.toString(),
        'vehicle_truck': settings.vehicleMultiplier.truck.toString(),
        'surcharge_peakHour': settings.surcharge.peakHour.toString(),
        'surcharge_holiday': settings.surcharge.holiday.toString(),
        'surcharge_night': settings.surcharge.night.toString()
      };

      await axios.post('http://localhost:8080/shipments/settings', payload);
      alert("Đã lưu toàn bộ cấu hình Vận hành & Geofencing thành công xuống Database!");
    } catch (error) {
      alert("Lỗi khi lưu cấu hình vận hành!");
      console.error(error);
    }
  };

  // ==========================================
  // STATE & LOGIC CHO TAB 2: THĂNG HẠNG (LEVEL 2)
  // ==========================================
  const [tierConfigs, setTierConfigs] = useState([]);
  const [loadingTiers, setLoadingTiers] = useState(true);

  useEffect(() => {
    axios.get('http://localhost:8080/users/admin/tier-configs')
      .then(res => {
        setTierConfigs(res.data.sort((a, b) => a.id - b.id));
        setLoadingTiers(false);
      })
      .catch(err => {
        console.error("Lỗi tải cấu hình thăng hạng:", err);
        setLoadingTiers(false);
      });
  }, []);

  const handlePointChange = (index, newValue) => {
    const updatedConfigs = [...tierConfigs];
    updatedConfigs[index].minPoints = parseInt(newValue) || 0;
    setTierConfigs(updatedConfigs);
  };

  const handleSaveTiers = async () => {
    try {
      await axios.put('http://localhost:8080/users/admin/tier-configs/update', tierConfigs);
      await axios.put('http://localhost:8080/users/admin/tiers/apply-mass-update', tierConfigs);
      alert("🚀 BÙM! Đã lưu quy tắc mới. Toàn bộ khách hàng đã được hệ thống tự động quét và phong hạng lại thành công!");
    } catch (error) {
      console.error("Lỗi khi quét cập nhật hạng:", error);
      alert("Lỗi khi lưu cấu hình hạng! Vui lòng kiểm tra Terminal Java hoặc Console Web.");
    }
  };

  // ==========================================
  // GIAO DIỆN CHÍNH
  // ==========================================
  return (
    <div style={{ maxWidth: '900px', paddingBottom: '50px', margin: '0 auto' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaCogs style={{ color: '#1E88E5' }} /> Cài đặt hệ thống lõi
      </h1>
      <p style={{ color: '#718096', marginBottom: '30px' }}>Quản lý giá cước, phụ phí và quy tắc thăng hạng tự động.</p>

      {/* THANH MENU TABS */}
      <div style={styles.tabContainer}>
        <button
          style={activeTab === 'operation' ? styles.activeTab : styles.tab}
          onClick={() => setActiveTab('operation')}
        >
          <FaMoneyBillWave /> Cước phí & Vận hành
        </button>
        <button
          style={activeTab === 'tiers' ? styles.activeTab : styles.tab}
          onClick={() => setActiveTab('tiers')}
        >
          <FaTrophy /> Quy tắc Thăng hạng (Level 2)
        </button>
      </div>

      {/* NỘI DUNG TAB 1: VẬN HÀNH */}
      {activeTab === 'operation' && (
        <div style={styles.fadeAnimation}>
          <div style={styles.card}>
            <h3 style={styles.cardTitle}>1. Giá cước cơ bản (VNĐ)</h3>
            <div style={styles.grid3}>
              <div><label style={styles.label}>* Cước mở máy</label><input type="number" style={styles.input} value={settings.baseFare} onChange={(e) => handleSettingChange('baseFare', null, e.target.value)} /></div>
              <div><label style={styles.label}>* Giá mỗi km</label><input type="number" style={styles.input} value={settings.pricePerKm} onChange={(e) => handleSettingChange('pricePerKm', null, e.target.value)} /></div>
              <div><label style={styles.label}>* Giá tối thiểu</label><input type="number" style={styles.input} value={settings.minFare} onChange={(e) => handleSettingChange('minFare', null, e.target.value)} /></div>
            </div>
          </div>

          <div style={styles.card}>
            <h3 style={styles.cardTitle}>2. Hệ số phương tiện giao hàng</h3>
            <div style={styles.grid3}>
              <div><label style={styles.label}>* Xe máy (Tiêu chuẩn)</label><input type="number" step="0.1" style={styles.input} value={settings.vehicleMultiplier.motorbike} onChange={(e) => handleSettingChange('vehicleMultiplier', 'motorbike', e.target.value)} /></div>
              <div><label style={styles.label}>* Xe bán tải (Cồng kềnh)</label><input type="number" step="0.1" style={styles.input} value={settings.vehicleMultiplier.van} onChange={(e) => handleSettingChange('vehicleMultiplier', 'van', e.target.value)} /></div>
              <div><label style={styles.label}>* Xe tải (Hàng lớn)</label><input type="number" step="0.1" style={styles.input} value={settings.vehicleMultiplier.truck} onChange={(e) => handleSettingChange('vehicleMultiplier', 'truck', e.target.value)} /></div>
            </div>
          </div>

          <div style={styles.card}>
            <h3 style={styles.cardTitle}>3. Phụ phí (%) — Áp dụng trên cước tích lũy</h3>
            <div style={styles.grid3}>
              <div><label style={styles.label}>* Giờ cao điểm</label><div style={styles.inputGroup}><input type="number" style={styles.input} value={settings.surcharge.peakHour} onChange={(e) => handleSettingChange('surcharge', 'peakHour', e.target.value)} /> <span style={styles.unit}>%</span></div></div>
              <div><label style={styles.label}>* Ngày lễ</label><div style={styles.inputGroup}><input type="number" style={styles.input} value={settings.surcharge.holiday} onChange={(e) => handleSettingChange('surcharge', 'holiday', e.target.value)} /> <span style={styles.unit}>%</span></div></div>
              <div><label style={styles.label}>* Ban đêm</label><div style={styles.inputGroup}><input type="number" style={styles.input} value={settings.surcharge.night} onChange={(e) => handleSettingChange('surcharge', 'night', e.target.value)} /> <span style={styles.unit}>%</span></div></div>
            </div>
          </div>

          <div style={styles.card}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '2px solid #EBF8FF', paddingBottom: '10px', marginBottom: '20px' }}>
              <h3 style={{ margin: 0, fontSize: '16px', color: '#2D3748' }}>4. Geofencing (Khu vực thu phụ phí)</h3>
              <button style={styles.addBtn}><FaPlus /> Thêm khu vực</button>
            </div>
            {settings.geofencing.map(zone => (
              <div key={zone.id} style={{ display: 'flex', gap: '20px', marginBottom: '15px', alignItems: 'center' }}>
                <FaMapMarkerAlt style={{ color: '#E53E3E' }} />
                <input type="text" style={{ ...styles.input, flex: 2 }} value={zone.name} readOnly />
                <div style={styles.inputGroup}><input type="number" style={styles.input} value={zone.fee} readOnly /> <span style={styles.unit}>VNĐ</span></div>
              </div>
            ))}
          </div>

          <button onClick={handleSaveOperation} style={styles.saveBtn}><FaSave /> LƯU CẤU HÌNH VẬN HÀNH</button>
        </div>
      )}

      {/* NỘI DUNG TAB 2: THĂNG HẠNG LEVEL 2 */}
      {activeTab === 'tiers' && (
        <div style={styles.fadeAnimation}>
          <div style={styles.card}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px', color: '#3182CE' }}>
              <FaShieldAlt size={20} />
              <h3 style={{ margin: 0 }}>Cấu hình quy tắc thăng hạng tự động</h3>
            </div>
            <p style={{ color: '#718096', marginBottom: '30px', fontSize: '14px' }}>
              Hệ thống sẽ dò các mốc điểm dưới đây mỗi khi khách hoàn thành đơn để tự động cập nhật Rank.
            </p>

            {loadingTiers ? (
              <p style={{ textAlign: 'center', color: '#718096' }}>Đang kết nối trung tâm điều khiển Level 2...</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                {tierConfigs.length > 0 ? tierConfigs.map((config, index) => (
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
                        style={{ ...styles.input, width: '120px', textAlign: 'center', fontWeight: 'bold' }}
                        disabled={config.tierName === 'BRONZE'}
                      />
                      <span style={{ color: '#718096' }}>điểm tích lũy</span>
                    </div>
                  </div>
                )) : (
                  <p style={{ textAlign: 'center', color: '#E53E3E' }}>Chưa có dữ liệu cấu hình trong Database!</p>
                )}
              </div>
            )}
          </div>

          <button onClick={handleSaveTiers} style={styles.saveBtn} disabled={tierConfigs.length === 0}>
            <FaSave /> LƯU QUY TẮC THĂNG HẠNG
          </button>
        </div>
      )}
    </div>
  );
}

// Hàm lấy màu sắc cho từng Rank
const getTierColor = (tier) => {
  const colors = { DIAMOND: '#3182CE', PLATINUM: '#475569', GOLD: '#D69E2E', SILVER: '#718096', BRONZE: '#C05621' };
  return colors[tier] || '#CBD5E0';
};

// CSS Styles
const styles = {
  tabContainer: { display: 'flex', gap: '10px', marginBottom: '25px', borderBottom: '2px solid #E2E8F0' },
  tab: { padding: '12px 20px', border: 'none', backgroundColor: 'transparent', color: '#718096', fontWeight: 'bold', fontSize: '15px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', transition: '0.3s' },
  activeTab: { padding: '12px 20px', border: 'none', backgroundColor: 'transparent', color: '#1E88E5', fontWeight: 'bold', fontSize: '15px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', borderBottom: '3px solid #1E88E5' },
  fadeAnimation: { animation: 'fadeIn 0.3s ease-in-out' },
  card: { backgroundColor: 'white', padding: '25px', borderRadius: '12px', boxShadow: '0 2px 10px rgba(0,0,0,0.05)', marginBottom: '25px', border: '1px solid #E2E8F0' },
  cardTitle: { margin: '0 0 20px 0', fontSize: '16px', color: '#2D3748', borderBottom: '2px solid #EBF8FF', paddingBottom: '10px' },
  grid3: { display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px' },
  label: { display: 'block', fontSize: '13px', fontWeight: 'bold', color: '#4A5568', marginBottom: '8px' },
  input: { width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #CBD5E0', outline: 'none', boxSizing: 'border-box' },
  inputGroup: { display: 'flex', alignItems: 'center', gap: '10px', flex: 1 },
  unit: { fontWeight: 'bold', color: '#4A5568' },
  addBtn: { backgroundColor: '#EBF8FF', color: '#1E88E5', border: 'none', padding: '5px 10px', borderRadius: '5px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '5px', fontWeight: 'bold' },
  saveBtn: { display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', backgroundColor: '#1E88E5', color: 'white', padding: '15px 30px', border: 'none', borderRadius: '8px', fontSize: '16px', fontWeight: 'bold', cursor: 'pointer', width: '100%', boxShadow: '0 4px 6px rgba(30, 136, 229, 0.2)' },
  tierRow: { display: 'flex', alignItems: 'center', padding: '15px', backgroundColor: '#F7FAFC', border: '1px solid #E2E8F0', borderRadius: '8px' },
  dot: { width: '12px', height: '12px', borderRadius: '50%' },
};