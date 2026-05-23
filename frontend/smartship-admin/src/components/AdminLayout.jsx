import { Outlet, Link, useLocation } from 'react-router-dom';
import { 
  FaChartLine, FaBox, FaBullhorn, FaMapMarkedAlt, 
  FaCogs, FaChartBar, FaUserFriends, FaMotorcycle 
} from 'react-icons/fa';

export default function AdminLayout() {
  const location = useLocation();
  const activeStyle = { backgroundColor: '#EBF8FF', color: '#1E88E5', borderRadius: '8px' };
  const getLinkStyle = (path) => ({ ...navItem, ...(location.pathname === path ? activeStyle : {}) });

  return (
    <div style={{ display: 'flex', height: '100vh', backgroundColor: '#F7FAFC' }}>
      <div style={{ width: '260px', backgroundColor: 'white', borderRight: '1px solid #E2E8F0', padding: '20px', display: 'flex', flexDirection: 'column' }}>
        <h2 style={{ color: '#1E88E5', textAlign: 'center', marginBottom: '40px' }}>SMARTSHIP</h2>
        
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '5px', overflowY: 'auto', paddingRight: '5px' }}>
          
          <p style={menuGroupTitle}>Quản lý Đối tác & Đơn</p>
          <Link to="/" style={getLinkStyle('/')}><FaChartLine /> Tổng quan</Link>
          <Link to="/customers" style={getLinkStyle('/customers')}><FaUserFriends /> Khách hàng</Link>
          <Link to="/drivers" style={getLinkStyle('/drivers')}><FaMotorcycle /> Tài xế</Link>
          <Link to="/shipments" style={getLinkStyle('/shipments')}><FaBox /> Đơn hàng</Link>
          <Link to="/promotions" style={getLinkStyle('/promotions')}><FaBullhorn /> Khuyến mãi (FCM)</Link>

          <p style={menuGroupTitle}>Vận hành & Hệ thống</p>
          <Link to="/live" style={getLinkStyle('/live')}><FaMapMarkedAlt /> Giám sát Live</Link>
          <Link to="/analytics" style={getLinkStyle('/analytics')}><FaChartBar /> Báo cáo doanh thu</Link>
          <Link to="/settings" style={getLinkStyle('/settings')}><FaCogs /> Cài đặt hệ thống</Link>

        </nav>
      </div>
      <div style={{ flex: 1, padding: '40px', overflowY: 'auto' }}>
        <Outlet />
      </div>
    </div>
  );
}

const navItem = { display: 'flex', alignItems: 'center', gap: '12px', padding: '12px 15px', textDecoration: 'none', color: '#4A5568', fontWeight: '600', transition: '0.3s' };
const menuGroupTitle = { fontSize: '12px', fontWeight: 'bold', color: '#A0AEC0', textTransform: 'uppercase', marginTop: '15px', marginBottom: '5px', paddingLeft: '10px' };