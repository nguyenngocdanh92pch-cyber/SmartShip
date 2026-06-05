import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import AdminLayout from './components/AdminLayout';
import Dashboard from './pages/Dashboard';
import CustomerManagement from './pages/CustomerManagement';
import DriverManagement from './pages/DriverManagement';
import ShipmentManagement from './pages/ShipmentManagement';
import PromotionManagement from './pages/PromotionManagement';
import LiveMonitoring from './pages/LiveMonitoring';
import AdvancedAnalytics from './pages/AdvancedAnalytics';
import ChatbotKnowledge from './pages/ChatbotKnowledge';

// IMPORT TRANG CÀI ĐẶT HỆ THỐNG ĐÃ GỘP CẢ 2 TÍNH NĂNG
import SystemSettings from './pages/SystemSettings';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AdminLayout />}>
          <Route index element={<Dashboard />} />

          <Route path="customers" element={<CustomerManagement />} />
          <Route path="drivers" element={<DriverManagement />} />
          <Route path="shipments" element={<ShipmentManagement />} />
          <Route path="promotions" element={<PromotionManagement />} />
          <Route path="live" element={<LiveMonitoring />} />
          <Route path="analytics" element={<AdvancedAnalytics />} />
          <Route path="settings" element={<SystemSettings />} />
          <Route path="chatbot-knowledge" element={<ChatbotKnowledge />} />
        </Route>
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;