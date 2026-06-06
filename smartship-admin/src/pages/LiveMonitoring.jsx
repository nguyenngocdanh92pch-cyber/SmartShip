import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaTruck, FaExclamationTriangle, FaCheckCircle, FaMotorcycle, FaRoute } from 'react-icons/fa';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

export default function LiveMonitoring() {
  const [liveData, setLiveData] = useState({
    onlineDrivers: 0,
    movingOrders: 0,
    alerts: [],
    mapData: [],
    logs: []
  });

  // KÉO DỮ LIỆU TỪ JAVA MỖI 5 GIÂY (REAL-TIME POLLING)
  useEffect(() => {
    const fetchLiveData = async () => {
      try {
        // 1. Kéo dữ liệu Vận hành (Bản đồ, đơn kẹt, nhật ký...)
        const shipRes = await axios.get('http://localhost:8080/shipments/live');
        
        // 2. Kéo dữ liệu Tài xế thật (Để đếm số người Đang Online)
        let realOnlineCount = 0;
        try {
          const driverRes = await axios.get('http://localhost:8080/users/drivers'); 
          
          // 🚀 ĐÃ SỬA LẠI CHỮ 'ACTIVE': Bắt đúng trạng thái gốc từ Database
          const onlineDriversList = driverRes.data.filter(driver => driver.status === 'ACTIVE' || driver.status === 'ONLINE');
          realOnlineCount = onlineDriversList.length;
        } catch (err) {
          console.log("Chưa gọi được API Tài xế, lấy tạm số lượng tài xế đang kẹp đơn...");
          realOnlineCount = shipRes.data.onlineDrivers; 
        }

        // 3. Gộp data 2 bên lại và đắp lên giao diện
        setLiveData({
          ...shipRes.data,
          onlineDrivers: realOnlineCount // Bơm con số THẬT vào đây!
        });

      } catch (error) {
        console.error("Lỗi khi tải dữ liệu Live:", error);
      }
    };

    fetchLiveData(); // Gọi lần đầu
    const interval = setInterval(fetchLiveData, 5000); // Lặp lại mỗi 5s
    return () => clearInterval(interval);
  }, []);

  const handleAction = (action, orderId) => {
    alert(`Hệ thống đang điều phối tự động lệnh: [${action}] cho đơn hàng ${orderId}.`);
    // Giao diện sẽ tự động cập nhật ở chu kỳ 5 giây tiếp theo khi Backend thay đổi
  };

  const mapCenter = [10.7769, 106.7009];

  // Hàm tạo Icon nhấp nháy
  const createPulseIcon = (colorType) => {
    let colorHex = colorType === 'red' ? '#E53E3E' : colorType === 'green' ? '#38A169' : '#3182CE';
    return L.divIcon({
      className: 'custom-pulse-icon',
      html: `<div class="dot-${colorType}" style="width: 16px; height: 16px; border-radius: 50%; background-color: ${colorHex};"></div>`,
      iconSize: [16, 16],
      iconAnchor: [8, 8]
    });
  };

  return (
    <div style={{ paddingBottom: '50px' }}>
      <style>
        {`
          @keyframes pulse-red { 0% { box-shadow: 0 0 0 0 rgba(229, 62, 62, 0.7); } 70% { box-shadow: 0 0 0 15px rgba(229, 62, 62, 0); } 100% { box-shadow: 0 0 0 0 rgba(229, 62, 62, 0); } }
          @keyframes pulse-green { 0% { box-shadow: 0 0 0 0 rgba(56, 161, 105, 0.7); } 70% { box-shadow: 0 0 0 15px rgba(56, 161, 105, 0); } 100% { box-shadow: 0 0 0 0 rgba(56, 161, 105, 0); } }
          @keyframes pulse-blue { 0% { box-shadow: 0 0 0 0 rgba(49, 130, 206, 0.7); } 70% { box-shadow: 0 0 0 15px rgba(49, 130, 206, 0); } 100% { box-shadow: 0 0 0 0 rgba(49, 130, 206, 0); } }
          .dot-red { animation: pulse-red 2s infinite; }
          .dot-green { animation: pulse-green 2s infinite; }
          .dot-blue { animation: pulse-blue 2s infinite; }
          .leaflet-container { z-index: 1; border-radius: 12px; } 
        `}
      </style>

      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        🗺️ Giám sát Vận hành (Live Operations)
      </h1>

      {/* 1. THANH CHỈ SỐ NHANH */}
      <div style={styles.kpiGrid}>
        <div style={styles.kpiCard}>
          <div style={{...styles.kpiIconBox, backgroundColor: '#EBF8FF', color: '#3182CE'}}><FaMotorcycle size={24}/></div>
          <div><p style={styles.kpiLabel}>Tài xế đang Online</p><h2 style={styles.kpiValue}>{liveData.onlineDrivers}</h2></div>
        </div>
        <div style={styles.kpiCard}>
          <div style={{...styles.kpiIconBox, backgroundColor: '#C6F6D5', color: '#38A169'}}><FaRoute size={24}/></div>
          <div><p style={styles.kpiLabel}>Đơn đang di chuyển</p><h2 style={styles.kpiValue}>{liveData.movingOrders}</h2></div>
        </div>
        <div style={styles.kpiCard}>
          <div style={{...styles.kpiIconBox, backgroundColor: '#FFF5F5', color: '#E53E3E'}}><FaExclamationTriangle size={24}/></div>
          <div><p style={styles.kpiLabel}>Sự cố kẹt đơn</p><h2 style={styles.kpiValue}>{liveData.alerts.length}</h2></div>
        </div>
      </div>
      
      <div style={{ display: 'flex', gap: '20px', height: '600px' }}>
        
        {/* 2. BẢN ĐỒ OPEN STREET MAP */}
        <div style={{ flex: 2, position: 'relative', border: '1px solid #E2E8F0', borderRadius: '12px' }}>
          <MapContainer center={mapCenter} zoom={14} style={{ width: '100%', height: '100%' }}>
            {/* VẼ BẢN ĐỒ MAPBOX CỰC XỊN */}
            <TileLayer
              url="https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoibmdvY2RhbmgwMjAzMjAwNSIsImEiOiJjbW85ZmluejMwOGs4MndvaXU1MDc4aG1xIn0.R9tJL97Mm909Xwt1GE4I3w"
              attribution='Map data &copy; <a href="https://www.mapbox.com/">Mapbox</a>'
            />

            {/* VẼ DỮ LIỆU ĐỊNH VỊ TÀI XẾ TỪ DATABASE */}
            {liveData.mapData.map((driver, index) => (
              <Marker key={`driver-${index}`} position={driver.pos} icon={createPulseIcon(driver.type)}>
                <Popup>{driver.desc}</Popup>
              </Marker>
            ))}

          </MapContainer>

          <div style={{ position: 'absolute', top: '15px', right: '15px', backgroundColor: 'rgba(255,255,255,0.95)', padding: '10px 15px', borderRadius: '8px', boxShadow: '0 2px 10px rgba(0,0,0,0.1)', zIndex: 1000 }}>
            <h4 style={{ margin: '0 0 10px 0', fontSize: '13px' }}>Chú giải</h4>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '12px', marginBottom: '8px' }}><div style={{width:'12px', height:'12px', borderRadius:'50%', backgroundColor:'#38A169'}}></div> Đang giao hàng</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '12px', marginBottom: '8px' }}><div style={{width:'12px', height:'12px', borderRadius:'50%', backgroundColor:'#3182CE'}}></div> Đang đi lấy hàng</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '12px' }}><div style={{width:'12px', height:'12px', borderRadius:'50%', backgroundColor:'#E53E3E'}}></div> Đơn kẹt khẩn cấp</div>
          </div>
        </div>

        {/* 3. KHU VỰC CẢNH BÁO & TIMELINE */}
        <div style={{ flex: 1, backgroundColor: 'white', borderRadius: '12px', padding: '20px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', overflowY: 'auto', border: '1px solid #E2E8F0' }}>
          <h3 style={{ color: '#E53E3E', borderBottom: '2px solid #FEFCBF', paddingBottom: '10px', display: 'flex', alignItems: 'center', gap: '10px', marginTop: 0 }}>
            <FaExclamationTriangle /> Cần Xử Lý Ngay
          </h3>
          
          {/* RENDER SỰ CỐ TỪ DATABASE */}
          {liveData.alerts.length > 0 ? liveData.alerts.map((alert, index) => (
            <div key={index} style={{ marginTop: '15px', borderLeft: '3px solid #E53E3E', paddingLeft: '15px', backgroundColor: '#FFF5F5', padding: '15px', borderRadius: '0 8px 8px 0' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <p style={{ color: '#4A5568', fontWeight: 'bold', margin: '0 0 5px 0' }}>{alert.id}</p>
                <span style={{ fontSize: '11px', color: '#A0AEC0' }}>{alert.time}</span>
              </div>
              <p style={{ fontSize: '13px', color: '#4A5568', margin: '0 0 5px 0' }}>Tài xế: <strong>{alert.driver}</strong></p>
              <p style={{ fontSize: '14px', color: '#E53E3E', margin: '0 0 12px 0', fontWeight: 'bold' }}>⚠️ {alert.issue}</p>
              
              <div style={{ display: 'flex', gap: '10px' }}>
                <button onClick={() => handleAction('Điều phối tự động', alert.id)} style={styles.actionBtn}>Phát đơn lại</button>
              </div>
            </div>
          )) : (
            <p style={{ color: '#38A169', fontSize: '14px', display: 'flex', alignItems: 'center', gap: '5px' }}><FaCheckCircle /> Hệ thống ổn định. Không có đơn kẹt.</p>
          )}

          <h3 style={{ color: '#1E88E5', borderBottom: '2px solid #EBF8FF', paddingBottom: '10px', marginTop: '30px', fontSize: '15px' }}>Nhật ký Vận hành (Live)</h3>
          
          {/* RENDER NHẬT KÝ TỪ DATABASE */}
          {liveData.logs.map((log, index) => (
            <div key={index} style={{ marginTop: '20px', borderLeft: '2px solid #E2E8F0', paddingLeft: '15px', position: 'relative' }}>
               <div style={{ position: 'absolute', left: '-6px', top: '0', width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#3182CE' }}></div>
              <p style={{ color: '#4A5568', fontWeight: 'bold', margin: '0 0 5px 0', fontSize: '14px' }}>Mã đơn: {log.id}</p>
              <p style={{ fontSize: '13px', color: '#718096', margin: 0 }}><FaTruck /> {log.text}</p>
            </div>
          ))}

        </div>
      </div>
    </div>
  );
}

const styles = {
  kpiGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px', marginBottom: '25px' },
  kpiCard: { display: 'flex', alignItems: 'center', backgroundColor: 'white', padding: '15px 20px', borderRadius: '12px', border: '1px solid #E2E8F0' },
  kpiIconBox: { width: '50px', height: '50px', borderRadius: '12px', display: 'flex', justifyContent: 'center', alignItems: 'center', marginRight: '15px' },
  kpiLabel: { margin: 0, color: '#718096', fontSize: '13px', fontWeight: 'bold' },
  kpiValue: { margin: '5px 0 0 0', color: '#2D3748', fontSize: '24px' },
  actionBtn: { backgroundColor: '#DD6B20', color: 'white', border: 'none', padding: '8px 12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', fontSize: '12px', flex: 1 },
  dangerBtn: { backgroundColor: 'white', color: '#E53E3E', border: '1px solid #E53E3E', padding: '8px 12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', fontSize: '12px' }
};