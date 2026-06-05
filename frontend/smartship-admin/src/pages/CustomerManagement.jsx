import React, { useState, useEffect } from 'react';
import { FaCrown, FaSearch, FaEye, FaTimes, FaBan, FaCheck, FaHistory, FaStar, FaBox, FaMedal } from 'react-icons/fa';
import axios from 'axios';

export default function CustomerManagement() {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterTier, setFilterTier] = useState('ALL');
  
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [customers, setCustomers] = useState([]);

  useEffect(() => {
    const fetchCustomers = async () => {
      try {
        // ĐÃ SỬA CÁCH A: Cập nhật đường dẫn chuẩn vào Gateway -> UserService
        // Nhớ check lại xem /profiles có đúng với @RequestMapping trong Controller của bạn chưa nhé!
        const response = await axios.get('http://localhost:8080/users/customers');
        const realDataFromDB = response.data;

        const mappedCustomers = realDataFromDB.map(user => ({
          rawId: user.userId, 
          id: `KH-${user.userId}`, 
          name: user.fullName || 'Khách hàng mới', 
          phone: user.phone || '090xxxxxxx',       
          totalOrders: user.totalOrders || 0, 
          tier: user.tier && user.tier !== 'STANDARD' ? user.tier : 'BRONZE',      
          points: user.rewardPoints || 0, 
          status: user.status || 'ACTIVE',    
          joinDate: '30/04/2026', 
          history: [] 
        }));
        setCustomers(mappedCustomers);
      } catch (error) {
        console.error("Lỗi khi kéo danh hàng:", error);
      }
    };
    fetchCustomers();
  }, []);

  const handleViewDetails = async (customer) => {
    setSelectedCustomer(customer); 
    try {
      const res = await axios.get(`http://localhost:8080/shipments/admin/customer-history/${customer.rawId}`);
      const realHistory = res.data.map(order => ({
        id: `SH-${order.id}`,
        date: order.createdAt || 'Gần đây',
        fee: order.shippingCost || 0,
        status: order.status
      }));
      setSelectedCustomer(prev => ({ ...prev, history: realHistory }));
    } catch (error) {
      setSelectedCustomer(prev => ({ ...prev, history: [] }));
    }
  };

  const filteredCustomers = customers.filter(c => {
    const matchTier = filterTier === 'ALL' || c.tier === filterTier;
    const keyword = searchTerm.toLowerCase();
    const matchSearch = (c.name || '').toLowerCase().includes(keyword) || 
                        (c.phone || '').includes(keyword) || 
                        (c.id || '').toLowerCase().includes(keyword);
    return matchTier && matchSearch;
  });

  const handleToggleBlock = (id, currentStatus, name) => {
    const isBlocked = currentStatus === 'BLOCKED';
    const action = isBlocked ? 'MỞ KHÓA' : 'KHÓA';
    if(window.confirm(`Bạn có chắc muốn ${action} tài khoản của khách hàng ${name}?`)) {
      const updated = customers.map(c => c.id === id ? { ...c, status: isBlocked ? 'ACTIVE' : 'BLOCKED' } : c);
      setCustomers(updated);
      if (selectedCustomer && selectedCustomer.id === id) {
        setSelectedCustomer({ ...selectedCustomer, status: isBlocked ? 'ACTIVE' : 'BLOCKED' });
      }
    }
  };

  const getTierBadge = (tier) => {
    switch(tier) {
      case 'DIAMOND': return <span style={styles.badgeDiamond}><FaCrown style={{marginRight:'3px'}}/> KIM CƯƠNG</span>;
      case 'PLATINUM': return <span style={styles.badgePlatinum}><FaStar style={{marginRight:'3px'}}/> BẠCH KIM</span>;
      case 'GOLD': return <span style={styles.badgeGold}><FaMedal style={{marginRight:'3px'}}/> VÀNG</span>;
      case 'SILVER': return <span style={styles.badgeSilver}><FaMedal style={{marginRight:'3px'}}/> BẠC</span>;
      case 'BRONZE': return <span style={styles.badgeBronze}><FaMedal style={{marginRight:'3px'}}/> ĐỒNG</span>;
      default: return <span style={styles.badgeBronze}><FaMedal style={{marginRight:'3px'}}/> ĐỒNG</span>;
    }
  };

  return (
    <div style={{ paddingBottom: '50px' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaCrown style={{ color: '#F6E05E' }} /> Quản lý Khách hàng (Người gửi)
      </h1>
      
      <div style={{ display: 'flex', gap: '15px', marginBottom: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'white', padding: '10px 15px', borderRadius: '8px', border: '1px solid #E2E8F0', flex: 1 }}>
          <FaSearch style={{ color: '#A0AEC0', marginRight: '10px' }} />
          <input 
            type="text" placeholder="Tìm theo Mã KH, Tên, SĐT..." 
            style={{ border: 'none', outline: 'none', width: '100%' }} 
            value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <select style={styles.selectInput} value={filterTier} onChange={(e) => setFilterTier(e.target.value)}>
          <option value="ALL">Tất cả Hạng thành viên</option>
          <option value="DIAMOND">💎 Hạng Kim Cương</option>
          <option value="PLATINUM">💠 Hạng Bạch Kim</option>
          <option value="GOLD">🥇 Hạng Vàng</option>
          <option value="SILVER">🥈 Hạng Bạc</option>
          <option value="BRONZE">🥉 Hạng Đồng</option>
        </select>
      </div>

      <div style={{ backgroundColor: 'white', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              <th style={styles.th}>Mã KH</th><th style={styles.th}>Khách hàng</th>
              <th style={styles.th}>Tổng đơn</th><th style={styles.th}>Điểm thưởng</th>
              <th style={styles.th}>Hạng thành viên</th><th style={styles.th}>Trạng thái</th><th style={styles.th}>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {filteredCustomers.length > 0 ? filteredCustomers.map(c => (
              <tr key={c.id} style={styles.tr}>
                <td style={styles.td}><strong>{c.id}</strong></td>
                <td style={styles.td}>
                  <div><strong>{c.name}</strong></div>
                  <div style={{ fontSize: '12px', color: '#718096' }}>{c.phone}</div>
                </td>
                <td style={styles.td}><strong>{c.totalOrders}</strong> đơn</td>
                <td style={styles.td}><span style={{ color: '#DD6B20', fontWeight: 'bold' }}>{c.points.toLocaleString()}</span></td>
                <td style={styles.td}>{getTierBadge(c.tier)}</td>
                <td style={styles.td}>
                  {c.status === 'ACTIVE' 
                    ? <span style={{ color: '#38A169', fontWeight: 'bold', fontSize: '13px' }}>Đang hoạt động</span> 
                    : <span style={{ color: '#E53E3E', fontWeight: 'bold', fontSize: '13px' }}>Bị khóa</span>}
                </td>
                <td style={styles.td}>
                  <button onClick={() => handleViewDetails(c)} style={styles.iconBtn}><FaEye /> Chi tiết</button>
                </td>
              </tr>
            )) : (
              <tr><td colSpan="7" style={{textAlign: 'center', padding: '30px', color: '#718096'}}>Không tìm thấy khách hàng nào.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {selectedCustomer && (
        <div style={styles.modalOverlay}>
          <div style={styles.modalContent}>
            
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #E2E8F0', paddingBottom: '15px', marginBottom: '20px' }}>
              <h2 style={{ margin: 0, color: '#2D3748', display: 'flex', alignItems: 'center', gap: '10px' }}>
                Hồ sơ: <span style={{ color: '#1E88E5' }}>{selectedCustomer.id}</span>
              </h2>
              <button onClick={() => setSelectedCustomer(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#A0AEC0' }}><FaTimes size={24} /></button>
            </div>

            <div style={{ display: 'flex', gap: '30px' }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '20px' }}>
                  <div style={{ width: '60px', height: '60px', borderRadius: '50%', backgroundColor: '#EBF8FF', color: '#3182CE', display: 'flex', justifyContent: 'center', alignItems: 'center', fontSize: '24px', fontWeight: 'bold' }}>
                    {selectedCustomer.name.charAt(0)}
                  </div>
                  <div>
                    <h3 style={{ margin: '0 0 5px 0', color: '#2D3748' }}>{selectedCustomer.name}</h3>
                    <p style={{ margin: 0, color: '#718096', fontSize: '14px' }}>{selectedCustomer.phone}</p>
                  </div>
                </div>

                <div style={{ backgroundColor: '#F7FAFC', padding: '15px', borderRadius: '8px', border: '1px solid #E2E8F0' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px', fontSize: '14px' }}><span>Ngày tham gia:</span> <strong>{selectedCustomer.joinDate}</strong></div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px', fontSize: '14px' }}><span>Hạng thành viên:</span> {getTierBadge(selectedCustomer.tier)}</div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px', fontSize: '14px' }}><span>Tổng đơn:</span> <strong>{selectedCustomer.totalOrders} đơn</strong></div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px' }}><span>Điểm:</span> <strong style={{ color: '#DD6B20' }}>{selectedCustomer.points.toLocaleString()} pt</strong></div>
                </div>
              </div>

              <div style={{ flex: 1.5 }}>
                <h4 style={{ margin: '0 0 15px 0', color: '#4A5568', display: 'flex', alignItems: 'center', gap: '8px' }}><FaHistory /> Lịch sử đơn hàng gần đây</h4>
                
                {selectedCustomer.history && selectedCustomer.history.length > 0 ? (
                  <div style={{ border: '1px solid #E2E8F0', borderRadius: '8px', overflow: 'hidden', maxHeight: '200px', overflowY: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                      <thead style={{ backgroundColor: '#F7FAFC', position: 'sticky', top: 0 }}>
                        <tr><th style={{padding: '10px', textAlign: 'left', color: '#718096'}}>Mã đơn</th><th style={{padding: '10px', textAlign: 'left', color: '#718096'}}>Ngày</th><th style={{padding: '10px', textAlign: 'left', color: '#718096'}}>Cước phí</th><th style={{padding: '10px', textAlign: 'left', color: '#718096'}}>Trạng thái</th></tr>
                      </thead>
                      <tbody>
                        {selectedCustomer.history.map((order, idx) => (
                          <tr key={idx} style={{ borderTop: '1px solid #E2E8F0' }}>
                            <td style={{padding: '10px'}}><strong>{order.id}</strong></td>
                            <td style={{padding: '10px'}}>{order.date}</td>
                            <td style={{padding: '10px'}}>{order.fee.toLocaleString()}đ</td>
                            <td style={{padding: '10px'}}>
                              {order.status === 'COMPLETED' ? <span style={{color: '#38A169'}}>Hoàn thành</span> :
                               order.status === 'CANCELLED' ? <span style={{color: '#E53E3E'}}>Đã hủy</span> : 
                               <span style={{color: '#3182CE'}}>Đang giao ({order.status})</span>}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <div style={{ padding: '20px', textAlign: 'center', backgroundColor: '#F7FAFC', borderRadius: '8px', color: '#A0AEC0', fontSize: '14px' }}>
                    <FaBox size={24} style={{ marginBottom: '10px', color: '#CBD5E0' }} /><br/>
                    Khách hàng này chưa có đơn hàng nào.
                  </div>
                )}
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '15px', borderTop: '1px solid #E2E8F0', paddingTop: '20px', marginTop: '20px' }}>
              {selectedCustomer.status === 'ACTIVE' ? (
                <button onClick={() => handleToggleBlock(selectedCustomer.id, selectedCustomer.status, selectedCustomer.name)} style={styles.dangerBtn}><FaBan /> Khóa tài khoản</button>
              ) : (
                <button onClick={() => handleToggleBlock(selectedCustomer.id, selectedCustomer.status, selectedCustomer.name)} style={styles.successBtn}><FaCheck /> Mở khóa tài khoản</button>
              )}
              <button onClick={() => setSelectedCustomer(null)} style={styles.primaryBtn}>Đóng</button>
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
  selectInput: { padding: '10px', borderRadius: '8px', border: '1px solid #E2E8F0', outline: 'none', color: '#4A5568', backgroundColor: 'white' },
  iconBtn: { backgroundColor: 'transparent', color: '#1E88E5', border: 'none', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  
  badgeDiamond: { backgroundColor: '#EBF8FF', color: '#3182CE', padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #3182CE', display: 'inline-flex', alignItems: 'center' },
  badgePlatinum: { backgroundColor: '#F1F5F9', color: '#475569', padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #94A3B8', display: 'inline-flex', alignItems: 'center' },
  badgeGold: { backgroundColor: '#FEFCBF', color: '#B7791F', padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #B7791F', display: 'inline-flex', alignItems: 'center' },
  badgeSilver: { backgroundColor: '#EDF2F7', color: '#718096', padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #CBD5E0', display: 'inline-flex', alignItems: 'center' },
  badgeBronze: { backgroundColor: '#FFFAF0', color: '#C05621', padding: '5px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #DD6B20', display: 'inline-flex', alignItems: 'center' },
  
  modalOverlay: { position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
  modalContent: { backgroundColor: 'white', padding: '30px', borderRadius: '15px', width: '800px', maxWidth: '95%', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' },
  primaryBtn: { backgroundColor: '#E2E8F0', color: '#4A5568', border: 'none', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' },
  dangerBtn: { backgroundColor: '#FFF5F5', color: '#E53E3E', border: '1px solid #FC8181', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
  successBtn: { backgroundColor: '#C6F6D5', color: '#22543D', border: '1px solid #68D391', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' }
};