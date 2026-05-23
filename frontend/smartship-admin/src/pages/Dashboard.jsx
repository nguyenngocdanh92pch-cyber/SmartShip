import React, { useState, useEffect } from 'react';
import { FaMoneyBillWave, FaMotorcycle, FaBoxOpen, FaCheckCircle, FaArrowUp, FaArrowDown, FaClock, FaExclamationCircle } from 'react-icons/fa';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import axios from 'axios';

export default function Dashboard() {
  const [stats, setStats] = useState({ 
    doanhThu: 0, tongDonHang: 0, taiXeHoatDong: 0, 
    revTrend: 0, orderTrend: 0 
  });
  const [todayOrdersData, setTodayOrdersData] = useState([]);
  const [recentActivities, setRecentActivities] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchFullData = async () => {
      setIsLoading(true);
      try {
        const [userRes, shipmentRes] = await Promise.all([
          axios.get('http://localhost:8080/users/dashboard-stats'),
          axios.get('http://localhost:8080/shipments/admin/dashboard-stats')
        ]);

        const u = userRes.data;
        const s = shipmentRes.data;

        setStats({
          doanhThu: s.revenue || 0,
          tongDonHang: s.totalOrders || 0,
          taiXeHoatDong: u.activeDrivers || 0,
          revTrend: s.revenueTrend || 0,
          orderTrend: s.orderTrend || 0
        });

        setTodayOrdersData(s.chartData || []);
        setRecentActivities(s.activities || []);

      } catch (error) {
        console.error("Lỗi đồng bộ:", error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchFullData();
  }, []);

  const renderTrend = (value) => (
    <div style={value >= 0 ? styles.kpiTrendPositive : styles.kpiTrendNegative}>
      {value >= 0 ? <FaArrowUp /> : <FaArrowDown />} {Math.abs(value)}% so với hôm qua
    </div>
  );

  return (
    <div style={{ paddingBottom: '50px' }}>
      <h1><FaBoxOpen color="#1E88E5" /> Tổng quan Hệ thống</h1>
      <p>{isLoading ? 'Đang cập nhật dữ liệu thực...' : 'Dữ liệu thời gian thực từ Database'}</p>

      <div style={styles.kpiGrid}>
        <div style={styles.kpiCard}>
          <p style={styles.kpiLabel}>DOANH THU HÔM NAY</p>
          <h2 style={styles.kpiValue}>{stats.doanhThu.toLocaleString()}đ</h2>
          {renderTrend(stats.revTrend)}
        </div>
        
        <div style={styles.kpiCard}>
          <p style={styles.kpiLabel}>TỔNG ĐƠN HÀNG</p>
          <h2 style={styles.kpiValue}>{stats.tongDonHang}</h2>
          {renderTrend(stats.orderTrend)}
        </div>

        <div style={styles.kpiCard}>
          <p style={styles.kpiLabel}>TÀI XẾ HOẠT ĐỘNG</p>
          <h2 style={styles.kpiValue}>{stats.taiXeHoatDong}</h2>
          <div style={styles.kpiTrendPositive}><FaCheckCircle /> Hệ thống ổn định</div>
        </div>

        <div style={styles.kpiCard}>
          <p style={styles.kpiLabel}>HIỆU SUẤT GIAO HÀNG</p>
          <h2 style={styles.kpiValue}>{stats.tongDonHang > 0 ? 98 : 0}%</h2>
          <div style={styles.kpiTrendPositive}><FaArrowUp /> Đang tăng trưởng</div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '20px' }}>
        <div style={styles.chartContainer}>
          <h3>Nhịp độ đặt hàng thực tế</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={todayOrdersData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip cursor={{fill: '#F7FAFC'}} />
              <Bar dataKey="orders" fill="#1E88E5" radius={[4, 4, 0, 0]} barSize={40} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div style={styles.activityContainer}>
          <h3><FaClock /> Hoạt động gần đây</h3>
          {recentActivities.map((act, index) => (
            <div key={index} style={styles.activityItem}>
              <FaCheckCircle color="#38A169" />
              <div><p>{act.text}</p><span>{act.time}</span></div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

const styles = {
  kpiGrid: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginBottom: '25px' },
  kpiCard: { backgroundColor: 'white', padding: '20px', borderRadius: '12px', border: '1px solid #E2E8F0' },
  kpiLabel: { color: '#A0AEC0', fontSize: '11px', fontWeight: 'bold' },
  kpiValue: { fontSize: '24px', margin: '10px 0' },
  kpiTrendPositive: { color: '#38A169', fontSize: '13px', display: 'flex', alignItems: 'center', gap: '5px' },
  kpiTrendNegative: { color: '#E53E3E', fontSize: '13px', display: 'flex', alignItems: 'center', gap: '5px' },
  chartContainer: { flex: 2, backgroundColor: 'white', padding: '20px', borderRadius: '12px', border: '1px solid #E2E8F0' },
  activityContainer: { flex: 1, backgroundColor: 'white', padding: '20px', borderRadius: '12px', border: '1px solid #E2E8F0' },
  activityItem: { display: 'flex', gap: '10px', padding: '10px 0', borderBottom: '1px dashed #E2E8F0' }
};