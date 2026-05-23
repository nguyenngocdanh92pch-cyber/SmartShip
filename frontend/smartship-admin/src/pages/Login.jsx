import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios'; // Thêm dòng này để gọi API Backend
import { useState } from 'react';

export default function Login() {
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault(); 
    
    try {
      // 1. Gõ cửa Backend (Lưu ý: Thay số 8080 bằng cổng Auth Service thực tế của Cường đang chạy)
      const response = await axios.post('http://localhost:8080/auth/login', {
        phone_number: phone,
        password: password
      });

      // 2. Nếu Backend báo OK, lưu lại "vé thông hành" (JWT Token)
      localStorage.setItem('adminToken', response.data.token);
      
      // 3. Phá cửa vào thẳng trang Dashboard
      navigate('/admin/dashboard');

    } catch (error) {
      // 4. Bắt lỗi nếu sai mật khẩu hoặc sđt
      console.error("Lỗi đăng nhập:", error);
      alert("Đăng nhập thất bại! Hãy kiểm tra lại số điện thoại hoặc mật khẩu.");
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h2 style={styles.title}>SmartShip Admin</h2>
        <p style={styles.subtitle}>Đăng nhập hệ thống quản trị</p>

        <form onSubmit={handleLogin} style={styles.form}>
          <div style={styles.inputGroup}>
            <label style={styles.label}>Số điện thoại</label>
            <input 
              type="text" 
              placeholder="Nhập số điện thoại..." 
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              style={styles.input} 
              required 
            />
          </div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>Mật khẩu</label>
            <input 
              type="password" 
              placeholder="Nhập mật khẩu..." 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={styles.input} 
              required 
            />
          </div>

          <button type="submit" style={styles.button}>
            ĐĂNG NHẬP
          </button>
        </form>
      </div>
    </div>
  );
}

// Chỗ này tui viết CSS trực tiếp vào file cho Xuân dễ quản lý
const styles = {
  container: {
    display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh',
  },
  card: {
    backgroundColor: 'white', padding: '40px', borderRadius: '10px',
    boxShadow: '0 4px 12px rgba(0,0,0,0.1)', width: '350px', textAlign: 'center'
  },
  title: { color: '#1E88E5', marginBottom: '5px', fontSize: '24px' }, // Xanh dương SmartShip
  subtitle: { color: 'gray', marginBottom: '30px', fontSize: '14px' },
  form: { display: 'flex', flexDirection: 'column', gap: '15px' },
  inputGroup: { textAlign: 'left' },
  label: { display: 'block', marginBottom: '5px', fontSize: '14px', fontWeight: 'bold' },
  input: { 
    width: '100%', padding: '10px', boxSizing: 'border-box',
    borderRadius: '5px', border: '1px solid #ccc', fontSize: '14px'
  },
  button: {
    backgroundColor: '#1E88E5', color: 'white', padding: '12px',
    border: 'none', borderRadius: '5px', cursor: 'pointer',
    fontSize: '16px', fontWeight: 'bold', marginTop: '10px'
  }
};