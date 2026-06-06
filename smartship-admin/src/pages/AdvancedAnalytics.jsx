import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, PieChart, Pie, Cell, Legend 
} from 'recharts';
import { FaMoneyBillWave, FaChartLine, FaBox, FaTimesCircle } from 'react-icons/fa';

export default function AdvancedAnalytics() {
  // 1. CHUẨN BỊ STATE ĐỂ ĐÓN DATA TỪ BACKEND
  const [analytics, setAnalytics] = useState({
    totalRevenue: 0,
    totalCompleted: 0,
    cancelRate: 0,
    revenueChart: [],
    peakHourChart: [],
    vehicleChart: []
  });
  const [loading, setLoading] = useState(true);

  // 2. KÉO DATA TỪ API KHI TRANG VỪA LOAD (Tự động Refresh mỗi 15 giây)
  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        // 🚀 ĐÃ SỬA: Thêm chữ /shipments/ vào đúng đường dẫn API
        const response = await axios.get('http://localhost:8080/shipments/analytics');
        setAnalytics(response.data);
        setLoading(false);
      } catch (error) {
        console.error("Lỗi khi tải dữ liệu Analytics:", error);
        setLoading(false);
      }
    };

    fetchAnalytics();
    const interval = setInterval(fetchAnalytics, 15000); // 15s refresh 1 lần
    return () => clearInterval(interval);
  }, []);

  const COLORS = ['#1E88E5', '#38A169', '#DD6B20'];

  // Hàm format tiền VNĐ
  const formatVNĐ = (value) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

  if (loading) {
    return <div style={{ padding: '50px', textAlign: 'center', fontSize: '18px', color: '#718096' }}>Đang tải dữ liệu báo cáo...</div>;
  }

  return (
    <div style={{ paddingBottom: '50px' }}>
      <h1 style={{ color: '#2D3748', marginBottom: '25px', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <FaChartLine style={{ color: '#1E88E5' }}/> Phân tích Kinh doanh & Doanh thu
      </h1>

      {/* 1. KHỐI KPI CHỈ SỐ NHANH (Bơm data thật vào) */}
      <div style={styles.kpiGrid}>
        <div style={styles.kpiCard}>
          <div style={styles.kpiIconBox}><FaMoneyBillWave style={{ color: '#38A169', fontSize: '24px' }} /></div>
          <div><p style={styles.kpiLabel}>Tổng doanh thu (VNĐ)</p><h2 style={styles.kpiValue}>{formatVNĐ(analytics.totalRevenue)}</h2></div>
        </div>
        <div style={styles.kpiCard}>
          <div style={{ ...styles.kpiIconBox, backgroundColor: '#EBF8FF' }}><FaBox style={{ color: '#3182CE', fontSize: '24px' }} /></div>
          <div><p style={styles.kpiLabel}>Tổng đơn thành công</p><h2 style={styles.kpiValue}>{analytics.totalCompleted}</h2></div>
        </div>
        <div style={styles.kpiCard}>
          <div style={{ ...styles.kpiIconBox, backgroundColor: '#FFF5F5' }}><FaTimesCircle style={{ color: '#E53E3E', fontSize: '24px' }} /></div>
          <div><p style={styles.kpiLabel}>Tỷ lệ hủy đơn</p><h2 style={{ ...styles.kpiValue, color: '#E53E3E' }}>{analytics.cancelRate}%</h2></div>
        </div>
      </div>

      {/* 2. BIỂU ĐỒ DOANH THU CHÍNH */}
      <div style={styles.chartCard}>
        <h3 style={styles.chartTitle}>Xu hướng doanh thu 7 ngày gần nhất</h3>
        <div style={{ height: '350px', width: '100%' }}>
          <ResponsiveContainer>
            {/* Nhét mảng revenueChart từ Backend vào đây */}
            <AreaChart data={analytics.revenueChart} margin={{ top: 10, right: 30, left: 20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1E88E5" stopOpacity={0.8}/>
                  <stop offset="95%" stopColor="#1E88E5" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
              <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#718096'}} />
              {/* Nếu doanh thu cao quá (tiền triệu), tự chia 1000k cho dễ nhìn trục Y */}
              <YAxis tickFormatter={(val) => val >= 1000000 ? (val / 1000000) + 'M' : (val / 1000) + 'k'} axisLine={false} tickLine={false} tick={{fill: '#718096'}} />
              <Tooltip formatter={(value) => formatVNĐ(value)} labelStyle={{ color: '#2D3748', fontWeight: 'bold' }} />
              <Area type="monotone" dataKey="revenue" name="Doanh thu" stroke="#1E88E5" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* 3. KHỐI BIỂU ĐỒ PHỤ (CHIA ĐÔI MÀN HÌNH) */}
      <div style={styles.subGrid}>
        {/* Biểu đồ Tròn: Tỷ trọng phương tiện (DỮ LIỆU THẬT) */}
        <div style={styles.chartCard}>
          <h3 style={styles.chartTitle}>Tỷ trọng phương tiện giao hàng</h3>
          <div style={{ height: '250px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie 
                  data={analytics.vehicleChart} 
                  innerRadius={60} 
                  outerRadius={80} 
                  paddingAngle={5} 
                  dataKey="value" 
                  nameKey="name" // Đã thêm dòng này để lấy tên Xe từ DB
                >
                  {analytics.vehicleChart.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                {/* Đổi tooltip thành chữ "đơn" vì DB trả về số lượng đếm được */}
                <Tooltip formatter={(value) => value + ' đơn'} />
                <Legend verticalAlign="bottom" height={36} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Biểu đồ Cột: Khung giờ vàng */}
        <div style={styles.chartCard}>
          <h3 style={styles.chartTitle}>Khung giờ cao điểm (Lượng đơn)</h3>
          <div style={{ height: '250px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={analytics.peakHourChart} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="hour" tickFormatter={(val) => val + ':00'} tick={{fontSize: 12, fill: '#718096'}} axisLine={false} tickLine={false} />
                <YAxis tick={{fontSize: 12, fill: '#718096'}} axisLine={false} tickLine={false} />
                <Tooltip cursor={{fill: '#EDF2F7'}} labelFormatter={(label) => label + ':00'} />
                <Bar dataKey="orders" name="Số đơn" fill="#38A169" radius={[4, 4, 0, 0]} barSize={30} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}

const styles = {
  kpiGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px', marginBottom: '25px' },
  kpiCard: { display: 'flex', alignItems: 'center', backgroundColor: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 2px 10px rgba(0,0,0,0.03)', border: '1px solid #E2E8F0' },
  kpiIconBox: { width: '60px', height: '60px', borderRadius: '12px', backgroundColor: '#C6F6D5', display: 'flex', justifyContent: 'center', alignItems: 'center', marginRight: '20px' },
  kpiLabel: { margin: 0, color: '#718096', fontSize: '14px', fontWeight: 'bold' },
  kpiValue: { margin: '5px 0 0 0', color: '#2D3748', fontSize: '24px' },
  chartCard: { backgroundColor: 'white', padding: '25px', borderRadius: '12px', boxShadow: '0 2px 10px rgba(0,0,0,0.03)', border: '1px solid #E2E8F0', marginBottom: '25px' },
  chartTitle: { margin: '0 0 20px 0', fontSize: '16px', color: '#4A5568', borderBottom: '1px solid #E2E8F0', paddingBottom: '10px' },
  subGrid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }
};