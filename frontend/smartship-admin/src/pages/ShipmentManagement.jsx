import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaBox, FaSearch, FaFilter, FaEye, FaTimes, FaMapMarkerAlt, FaMotorcycle, FaTrashAlt, FaExclamationTriangle } from 'react-icons/fa';

export default function ShipmentManagement() {
  const [shipments, setShipments] = useState([]);
  const [loading, setLoading] = useState(true);

  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('ALL');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [showAdvancedFilter, setShowAdvancedFilter] = useState(false);
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [filterDate, setFilterDate] = useState('');

  const fetchShipments = async () => {
    try {
      const response = await axios.get('http://localhost:8080/shipments/list');
      console.log("Dữ liệu thô từ API:", response.data); // Bật lên để debug

      let dataArray = [];
      // Đảm bảo dữ liệu là mảng trước khi sort
      if (Array.isArray(response.data)) {
        dataArray = response.data;
      } else if (response.data && Array.isArray(response.data.data)) {
        // Đề phòng trường hợp sau này backend bọc thêm wrapper { data: [...] }
        dataArray = response.data.data;
      } else {
        console.warn("Cảnh báo: Dữ liệu trả về không phải là mảng!", response.data);
      }

      // Chỉ sort khi chắc chắn có data
      if (dataArray.length > 0) {
        const sortedData = dataArray.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        setShipments(sortedData);
      } else {
        setShipments([]);
      }

      setLoading(false);
    } catch (error) {
      console.error("Lỗi khi kéo dữ liệu đơn hàng:", error);
      setLoading(false);
    }
  };

  // KÉO DỮ LIỆU THẬT & TỰ ĐỘNG REFRESH MỖI 10 GIÂY
  useEffect(() => {
    fetchShipments();

    const intervalId = setInterval(() => {
      fetchShipments();
    }, 10000);

    return () => clearInterval(intervalId);
  }, []);

  const getWaitTimeMins = (createdAt) => {
    if (!createdAt) return 0;
    return Math.floor((new Date() - new Date(createdAt)) / 60000);
  };

  const getWaitTimeText = (createdAt) => {
    const diffMins = getWaitTimeMins(createdAt);
    if (diffMins < 60) return `${diffMins} phút`;
    const diffHours = Math.floor(diffMins / 60);
    return `${diffHours} giờ ${diffMins % 60} phút`;
  };

  const formatTime = (dateString) => {
    if (!dateString) return '--:-- --/--';
    const date = new Date(dateString);
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')} ${date.getDate()}/${date.getMonth() + 1}`;
  };

  const stuckOrders = shipments.filter(s => s.status === 'PENDING' && getWaitTimeMins(s.createdAt) >= 10);

  const handleCancelOrder = async (orderId) => {
    if (window.confirm(`Admin có chắc chắn muốn HỦY ÉP BUỘC đơn hàng SH-${orderId} trên toàn hệ thống không?`)) {
      try {
        await axios.put(`http://localhost:8080/shipments/cancel/${orderId}`);
        alert(`Đã hủy thành công đơn hàng SH-${orderId} trên Database!`);
        setSelectedOrder(null);
        fetchShipments(); // 🚀 ÉP LOAD LẠI DATA
      } catch (error) {
        alert("Lỗi khi hủy đơn! Kỹ sư trưởng hãy kiểm tra lại Backend nhé.");
      }
    }
  };

  const handleRepublish = async (id) => {
    if (!window.confirm(`Xác nhận nới rộng bán kính tìm kiếm cho đơn SH-${id} (Từ 3km -> 7km)? Giá cước vẫn giữ nguyên.`)) {
      return;
    }
    try {
      await axios.put(`http://localhost:8080/shipments/republish/${id}`);
      alert(`Đã mở rộng bán kính quét và phát lại tín hiệu cho đơn SH-${id} thành công!`);
      fetchShipments(); // 🚀 ÉP LOAD LẠI DATA SAU KHI THÔNG BÁO XONG
    } catch (error) {
      alert("Lỗi khi phát lại đơn! Hãy kiểm tra Backend.");
    }
  };

  const handleRepublishAll = async () => {
    if (!window.confirm(`Xác nhận phát lại TOÀN BỘ ${stuckOrders.length} đơn hàng đang kẹt? Giá cước vẫn giữ nguyên.`)) {
      return;
    }
    try {
      await axios.put(`http://localhost:8080/shipments/republish-all`);
      alert(`Đã mở rộng bán kính quét và phát lại tín hiệu cho ${stuckOrders.length} đơn thành công!`);
      fetchShipments(); // 🚀 ÉP LOAD LẠI DATA ĐỂ XÓA CÁI BẢNG ĐỎ ĐI
    } catch (error) {
      alert("Lỗi khi phát lại hàng loạt! Hãy kiểm tra Backend.");
    }
  };

  const clearFilters = () => { setSearchTerm(''); setFilterStatus('ALL'); setMinPrice(''); setMaxPrice(''); setFilterDate(''); };

  const filteredOrders = shipments.filter(order => {
    const matchStatus = filterStatus === 'ALL' || order.status === filterStatus;
    const keyword = String(searchTerm).toLowerCase();

    const matchSearch =
      String(order.id).toLowerCase().includes(keyword) ||
      (order.pickupAddress && order.pickupAddress.toLowerCase().includes(keyword)) ||
      (order.packageDescription && order.packageDescription.toLowerCase().includes(keyword)) ||
      (order.senderId && String(order.senderId).includes(keyword)) ||
      (order.driverId && String(order.driverId).includes(keyword));

    const matchMinPrice = minPrice === '' || order.shippingCost >= parseInt(minPrice);
    const matchMaxPrice = maxPrice === '' || order.shippingCost <= parseInt(maxPrice);

    const orderDate = order.createdAt ? order.createdAt.substring(0, 10) : '';
    const matchDate = filterDate === '' || orderDate === filterDate;

    return matchStatus && matchSearch && matchMinPrice && matchMaxPrice && matchDate;
  });

  const getStatusBadge = (status) => {
    switch (status) {
      case 'PENDING': return <span style={{ ...styles.badge, backgroundColor: '#FEFCBF', color: '#B7791F' }}>Chờ tài xế</span>;
      case 'ACCEPTED': return <span style={{ ...styles.badge, backgroundColor: '#EBF8FF', color: '#3182CE' }}>Đã nhận đơn</span>;
      case 'PICKED_UP': return <span style={{ ...styles.badge, backgroundColor: '#E9D8FD', color: '#805AD5' }}>Đang giao</span>;
      case 'DELIVERED':
      case 'COMPLETED': return <span style={{ ...styles.badge, backgroundColor: '#C6F6D5', color: '#22543D' }}>Hoàn thành</span>;
      case 'CANCELLED': return <span style={{ ...styles.badge, backgroundColor: '#FED7D7', color: '#C53030' }}>Đã hủy</span>;
      default: return <span>{status}</span>;
    }
  };

  return (
    <div style={{ paddingBottom: '50px', position: 'relative' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaBox style={{ color: '#DD6B20' }} /> Quản lý Đơn hàng & Vận đơn
      </h1>

      <div style={{ display: 'flex', gap: '15px', marginBottom: showAdvancedFilter ? '15px' : '20px', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'white', padding: '10px 15px', borderRadius: '8px', border: '1px solid #E2E8F0', flex: 1, minWidth: '250px' }}>
          <FaSearch style={{ color: '#A0AEC0', marginRight: '10px' }} />
          <input type="text" placeholder="Tìm kiếm theo Mã đơn, Địa chỉ, ID Khách/TX..." style={{ border: 'none', outline: 'none', width: '100%' }} value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
        </div>
        <select style={styles.selectInput} value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
          <option value="ALL">Tất cả trạng thái</option>
          <option value="PENDING">Chờ tài xế</option>
          <option value="ACCEPTED">Đã nhận đơn</option>
          <option value="PICKED_UP">Đang giao</option>
          <option value="DELIVERED">Hoàn thành</option>
          <option value="CANCELLED">Đã hủy</option>
        </select>
        <button onClick={() => setShowAdvancedFilter(!showAdvancedFilter)} style={showAdvancedFilter ? styles.filterBtnActive : styles.filterBtn}>
          <FaFilter /> Lọc nâng cao
        </button>
      </div>

      {showAdvancedFilter && (
        <div style={{ backgroundColor: '#F7FAFC', padding: '20px', borderRadius: '8px', border: '1px dashed #CBD5E0', marginBottom: '20px', display: 'flex', gap: '20px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div><label style={styles.label}>Ngày tạo đơn:</label><input type="date" style={styles.selectInput} value={filterDate} onChange={(e) => setFilterDate(e.target.value)} /></div>
          <div><label style={styles.label}>Giá cước tối thiểu (VNĐ):</label><input type="number" placeholder="VD: 20000" style={styles.selectInput} value={minPrice} onChange={(e) => setMinPrice(e.target.value)} /></div>
          <div><label style={styles.label}>Giá cước tối đa (VNĐ):</label><input type="number" placeholder="VD: 100000" style={styles.selectInput} value={maxPrice} onChange={(e) => setMaxPrice(e.target.value)} /></div>
          <button onClick={clearFilters} style={styles.clearBtn}><FaTrashAlt /> Xóa bộ lọc</button>
        </div>
      )}

      {stuckOrders.length > 0 && (
        <div style={{ backgroundColor: '#FFF5F5', border: '1px solid #FC8181', borderRadius: '12px', marginBottom: '25px', overflow: 'hidden' }}>
          <div style={{ padding: '15px 20px', backgroundColor: '#FED7D7', color: '#C53030', fontWeight: 'bold', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <FaExclamationTriangle /> Cảnh báo: Có {stuckOrders.length} đơn hàng bị kẹt chờ tài xế quá lâu!
            </div>

            <button onClick={handleRepublishAll} style={{ backgroundColor: '#C53030', color: 'white', border: 'none', padding: '8px 15px', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold', fontSize: '13px', boxShadow: '0 2px 4px rgba(0,0,0,0.1)', transition: '0.2s' }}>
              Phát lại TẤT CẢ ({stuckOrders.length})
            </button>
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <tbody>
              {stuckOrders.slice(0, 3).map(order => (
                <tr key={order.id} style={{ borderBottom: '1px solid #FC8181' }}>
                  <td style={{ ...styles.td, color: '#C53030', padding: '12px 20px' }}><strong>SH-{order.id}</strong></td>
                  <td style={{ ...styles.td, padding: '12px 20px' }}>KH #{order.senderId}</td>
                  <td style={{ ...styles.td, padding: '12px 20px' }}>Lấy: {order.pickupAddress?.substring(0, 20)}...</td>
                  <td style={{ ...styles.td, padding: '12px 20px' }}><span style={{ color: '#E53E3E', fontWeight: 'bold' }}>Chờ: {getWaitTimeText(order.createdAt)}</span></td>
                  <td style={{ ...styles.td, padding: '12px 20px', textAlign: 'right' }}>
                    <button onClick={() => handleRepublish(order.id)} style={{ backgroundColor: '#DD6B20', color: 'white', border: 'none', padding: '8px 15px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', fontSize: '12px', transition: '0.2s' }}>
                      Phát lại đơn ngay
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <h3 style={{ color: '#4A5568', marginBottom: '15px', fontSize: '16px' }}>Danh sách toàn bộ đơn hàng</h3>
      <div style={{ backgroundColor: 'white', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              <th style={styles.th}>Mã đơn</th><th style={styles.th}>Hành trình & Đồ vật</th><th style={styles.th}>Người gửi / Tài xế</th>
              <th style={styles.th}>Phí ship</th><th style={styles.th}>Trạng thái</th><th style={styles.th}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="6" style={{ textAlign: 'center', padding: '30px', color: '#718096' }}>Đang tải dữ liệu vận đơn...</td></tr>
            ) : filteredOrders.length > 0 ? filteredOrders.map(order => (
              <tr key={order.id} style={styles.tr}>
                <td style={styles.td}><strong>SH-{order.id}</strong><br /><span style={{ fontSize: '12px', color: '#A0AEC0' }}>{formatTime(order.createdAt)}</span></td>
                <td style={styles.td}>
                  <div style={{ fontSize: '13px', marginBottom: '4px' }}><span style={{ color: '#3182CE', fontWeight: 'bold' }}>Lấy hàng:</span> {order.pickupAddress}</div>
                  <div style={{ fontSize: '13px', marginBottom: '4px' }}><span style={{ color: '#38A169', fontWeight: 'bold' }}>Đồ vật:</span> {order.packageDescription || 'Không có mô tả'}</div>

                  {/* 🚀 BẢNG DANH SÁCH CHÍNH: HIỂN THỊ CHI TIẾT XE */}
                  <div style={{ fontSize: '13px' }}>
                    <span style={{ color: '#DD6B20', fontWeight: 'bold' }}>Phương tiện:</span>{' '}
                    {order.driverId ? (
                      <span>
                        {order.vehicleType}
                        {order.driverVehicleBrand ? ` - ${order.driverVehicleBrand} ${order.driverVehicleModel} (${order.driverVehicleColor})` : ''}
                        {' - '}<strong>BKS: <span style={{ color: '#E53E3E' }}>{order.driverLicensePlate || 'Đang cập nhật'}</span></strong>
                      </span>
                    ) : (
                      <span style={{ color: '#A0AEC0', fontStyle: 'italic' }}>Chưa có TX nhận</span>
                    )}
                  </div>
                </td>
                <td style={styles.td}>
                  <div style={{ fontSize: '13px', marginBottom: '4px' }}>Gửi: <strong>KH #{order.senderId || 'N/A'}</strong></div>
                  <div style={{ fontSize: '13px' }}>TX: <strong style={{ color: !order.driverId ? '#E53E3E' : '#2D3748' }}>{order.driverId ? `TX #${order.driverId}` : 'Chưa có'}</strong></div>
                </td>
                <td style={styles.td}><strong>{order.shippingCost ? order.shippingCost.toLocaleString() : 0}đ</strong></td>
                <td style={styles.td}>{getStatusBadge(order.status)}</td>
                <td style={styles.td}><button onClick={() => setSelectedOrder(order)} style={styles.iconBtn}><FaEye /> Chi tiết</button></td>
              </tr>
            )) : (
              <tr><td colSpan="6" style={{ textAlign: 'center', padding: '30px', color: '#718096' }}>Không tìm thấy đơn hàng nào phù hợp với bộ lọc.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* MODAL CHI TIẾT */}
      {selectedOrder && (
        <div style={styles.modalOverlay}>
          <div style={styles.modalContent}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #E2E8F0', paddingBottom: '15px', marginBottom: '20px' }}>
              <h2 style={{ margin: '0', color: '#2D3748' }}>Chi tiết Đơn hàng: <span style={{ color: '#1E88E5' }}>SH-{selectedOrder.id}</span></h2>
              <button onClick={() => setSelectedOrder(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#A0AEC0' }}><FaTimes size={24} /></button>
            </div>
            <div style={{ display: 'flex', gap: '30px' }}>
              <div style={{ flex: 1 }}>
                <h4 style={{ margin: '0 0 15px 0', color: '#4A5568' }}>Thông tin lấy hàng</h4>
                <div style={{ backgroundColor: '#F7FAFC', padding: '15px', borderRadius: '8px', marginBottom: '20px' }}>
                  <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}><FaMapMarkerAlt color="#3182CE" /> <div><small>Địa chỉ lấy hàng:</small><br /><strong>{selectedOrder.pickupAddress}</strong></div></div>
                  <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}><FaBox color="#38A169" /> <div><small>Mô tả gói hàng:</small><br /><strong>{selectedOrder.packageDescription || 'Không có mô tả'}</strong></div></div>

                  {/* 🚀 MODAL CHI TIẾT: HIỂN THỊ CHI TIẾT XE */}
                  <div style={{ display: 'flex', gap: '10px' }}>
                    <FaMotorcycle color="#DD6B20" style={{ marginTop: '3px' }} />
                    <div>
                      <small>Phương tiện giao hàng:</small><br />
                      {selectedOrder.driverId ? (
                        <>
                          <strong>{selectedOrder.vehicleType} {selectedOrder.driverVehicleBrand ? `- ${selectedOrder.driverVehicleBrand} ${selectedOrder.driverVehicleModel}` : ''}</strong><br />
                          <span style={{ fontSize: '13px' }}>Màu sắc: <strong>{selectedOrder.driverVehicleColor || 'Chưa rõ'}</strong> | Biển số: <strong style={{ color: '#E53E3E' }}>{selectedOrder.driverLicensePlate || 'Chưa rõ'}</strong></span>
                        </>
                      ) : (
                        <span style={{ color: '#A0AEC0', fontStyle: 'italic' }}>Đang chờ tài xế nhận đơn...</span>
                      )}
                    </div>
                  </div>
                </div>
                <h4 style={{ margin: '0 0 15px 0', color: '#4A5568' }}>Trạng thái hiện tại</h4>
                <div>{getStatusBadge(selectedOrder.status)}</div>
              </div>
              <div style={{ flex: 1 }}>
                <h4 style={{ margin: '0 0 15px 0', color: '#4A5568' }}>Thông kết đối tác</h4>
                <div style={{ backgroundColor: 'white', border: '1px solid #E2E8F0', padding: '15px', borderRadius: '8px', marginBottom: '15px' }}>
                  <p style={{ margin: '0 0 5px 0', fontSize: '13px' }}>Khách hàng ID: <strong>#{selectedOrder.senderId || 'N/A'}</strong></p>
                  <p style={{ margin: 0, fontSize: '13px' }}>Tài xế ID: <strong style={{ color: selectedOrder.driverId ? '#2D3748' : '#E53E3E' }}>{selectedOrder.driverId ? `#${selectedOrder.driverId}` : 'Chưa có'}</strong></p>
                </div>
                <h4 style={{ margin: '0 0 15px 0', color: '#4A5568' }}>Chi tiết cước phí</h4>
                <div style={{ backgroundColor: 'white', border: '1px solid #E2E8F0', padding: '15px', borderRadius: '8px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '5px', fontSize: '13px' }}><span>Cước phí vận chuyển:</span> <strong>{selectedOrder.shippingCost ? selectedOrder.shippingCost.toLocaleString() : 0}đ</strong></div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingTop: '10px', borderTop: '1px dashed #E2E8F0', marginTop: '10px' }}>
                    <span style={{ fontWeight: 'bold' }}>Tổng cộng:</span> <strong style={{ color: '#1E88E5', fontSize: '18px' }}>{selectedOrder.shippingCost ? selectedOrder.shippingCost.toLocaleString() : 0}đ</strong>
                  </div>
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '25px', paddingTop: '15px', borderTop: '1px solid #E2E8F0' }}>
              {selectedOrder.status !== 'DELIVERED' && selectedOrder.status !== 'COMPLETED' && selectedOrder.status !== 'CANCELLED' && (
                <button onClick={() => handleCancelOrder(selectedOrder.id)} style={styles.dangerBtn}>Hủy ép buộc</button>
              )}
              <button onClick={() => setSelectedOrder(null)} style={styles.primaryBtn}>Đóng</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const styles = {
  th: { textAlign: 'left', padding: '15px', backgroundColor: '#F7FAFC', color: '#4A5568', borderBottom: '2px solid #E2E8F0' },
  td: { padding: '15px', color: '#2D3748', borderBottom: '1px solid #E2E8F0' },
  tr: { transition: '0.2s' },
  badge: { padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', display: 'inline-block' },
  selectInput: { padding: '10px', borderRadius: '8px', border: '1px solid #E2E8F0', outline: 'none', color: '#4A5568', backgroundColor: 'white', cursor: 'pointer' },
  label: { display: 'block', fontSize: '12px', fontWeight: 'bold', color: '#718096', marginBottom: '5px' },
  filterBtn: { backgroundColor: '#EDF2F7', color: '#2D3748', border: '1px solid #CBD5E0', padding: '10px 15px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px', transition: '0.2s' },
  filterBtnActive: { backgroundColor: '#1E88E5', color: 'white', border: '1px solid #1E88E5', padding: '10px 15px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px', transition: '0.2s' },
  clearBtn: { backgroundColor: 'transparent', color: '#E53E3E', border: 'none', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px', padding: '10px' },
  iconBtn: { backgroundColor: 'transparent', color: '#1E88E5', border: 'none', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  modalOverlay: { position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
  modalContent: { backgroundColor: 'white', padding: '30px', borderRadius: '15px', width: '700px', maxWidth: '90%', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' },
  dangerBtn: { backgroundColor: 'white', color: '#E53E3E', border: '1px solid #E53E3E', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' },
  primaryBtn: { backgroundColor: '#1E88E5', color: 'white', border: 'none', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' }
};