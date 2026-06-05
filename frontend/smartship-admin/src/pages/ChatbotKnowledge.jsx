import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_URL = 'http://localhost:8080/chatbot/knowledge';

// --- SVG Icons ---
const IconDatabase = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 18, height: 18 }}>
        <path d="M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z" /><polyline points="13 2 13 9 20 9" />
        <line x1="12" y1="18" x2="12" y2="12" /><line x1="9" y1="15" x2="15" y2="15" />
    </svg>
);
const IconEdit = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 18, height: 18 }}>
        <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7" />
        <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z" />
    </svg>
);
const IconEditSm = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 14, height: 14 }}>
        <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7" />
        <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z" />
    </svg>
);
const IconTrash = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 14, height: 14 }}>
        <polyline points="3 6 5 6 21 6" />
        <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6" />
        <path d="M10 11v6" /><path d="M14 11v6" /><path d="M9 6V4h6v2" />
    </svg>
);
const IconZap = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 15, height: 15 }}>
        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
    </svg>
);
const IconSave = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 15, height: 15 }}>
        <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z" />
        <polyline points="17 21 17 13 7 13 7 21" /><polyline points="7 3 7 8 15 8" />
    </svg>
);
const IconX = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 15, height: 15 }}>
        <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
);
const IconSearch = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: 16, height: 16 }}>
        <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
);
const IconBot = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" style={{ width: 34, height: 34 }}>
        <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" />
        <rect x="14" y="14" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
);

// --- Styles ---
const styles = `
  @import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,300&family=Instrument+Serif:ital@0;1&display=swap');

  .ck-root {
    font-family: 'DM Sans', sans-serif;
    background: #f8f7f4;
    min-height: 100vh;
    padding: 28px 24px 60px;
    color: #0d0f12;
    --accent: #2563eb;
    --accent-soft: #eff3ff;
    --accent-glow: rgba(37,99,235,0.12);
    --danger: #dc2626;
    --danger-soft: #fef2f2;
    --ink: #0d0f12;
    --ink-soft: #5a6070;
    --ink-muted: #9aa0ad;
    --surface: #f8f7f4;
    --surface-2: #f0eee9;
    --white: #ffffff;
    --border: rgba(15,18,20,0.08);
    --border-strong: rgba(15,18,20,0.14);
    --radius: 14px;
    --radius-sm: 8px;
  }

  .ck-root * { box-sizing: border-box; }

  /* Header */
  .ck-header { display:flex; align-items:flex-end; justify-content:space-between; margin-bottom:28px; gap:16px; flex-wrap:wrap; }
  .ck-eyebrow { font-size:11px; font-weight:500; letter-spacing:0.12em; text-transform:uppercase; color:var(--accent); margin-bottom:4px; display:flex; align-items:center; gap:6px; }
  .ck-eyebrow::before { content:''; display:inline-block; width:18px; height:2px; background:var(--accent); border-radius:2px; }
  .ck-title { font-family:'Instrument Serif',serif; font-size:30px; font-weight:400; color:var(--ink); line-height:1.15; letter-spacing:-0.02em; }
  .ck-subtitle { font-size:13px; color:var(--ink-soft); margin-top:5px; font-weight:300; }
  .ck-stat-chip { background:var(--white); border:1px solid var(--border); border-radius:100px; padding:6px 14px 6px 10px; font-size:13px; font-weight:500; color:var(--ink-soft); display:flex; align-items:center; gap:6px; white-space:nowrap; }
  .ck-stat-chip .dot { width:7px; height:7px; background:#22c55e; border-radius:50%; animation:ck-pulse 2s ease-in-out infinite; }
  @keyframes ck-pulse { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:0.6;transform:scale(0.85)} }

  /* Layout */
  .ck-layout { display:grid; grid-template-columns:340px 1fr; gap:16px; align-items:start; }
  @media(max-width:900px){ .ck-layout{grid-template-columns:1fr;} }

  /* Form Panel */
  .ck-form-panel { background:var(--white); border:1px solid var(--border); border-radius:var(--radius); overflow:hidden; position:sticky; top:20px; }
  .ck-form-head { padding:20px 22px 18px; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:12px; background:linear-gradient(135deg,#f0f4ff 0%,#fafafa 100%); transition:background 0.3s; }
  .ck-form-panel.editing .ck-form-head { background:linear-gradient(135deg,#fff7ed 0%,#fafafa 100%); }
  .ck-form-icon { width:38px; height:38px; background:var(--accent); border-radius:10px; display:flex; align-items:center; justify-content:center; flex-shrink:0; color:white; transition:background 0.3s; }
  .ck-form-panel.editing .ck-form-icon { background:#f97316; }
  .ck-form-head-text h2 { font-size:15px; font-weight:600; color:var(--ink); letter-spacing:-0.01em; }
  .ck-form-head-text p { font-size:12px; color:var(--ink-muted); margin-top:1px; }
  .ck-form-body { padding:20px 22px 22px; }
  .ck-field { margin-bottom:16px; }
  .ck-label { display:block; font-size:12px; font-weight:600; color:var(--ink); letter-spacing:0.01em; margin-bottom:7px; }
  .ck-label .sub { font-weight:400; color:var(--ink-muted); }
  .ck-input, .ck-textarea { width:100%; background:var(--surface); border:1px solid var(--border-strong); border-radius:var(--radius-sm); padding:10px 13px; font-family:'DM Sans',sans-serif; font-size:13.5px; color:var(--ink); outline:none; transition:all 0.18s ease; resize:none; }
  .ck-input::placeholder,.ck-textarea::placeholder { color:var(--ink-muted); }
  .ck-input:focus,.ck-textarea:focus { background:var(--white); border-color:var(--accent); box-shadow:0 0 0 3px var(--accent-glow); }
  .ck-textarea { height:120px; line-height:1.6; }

  /* Buttons */
  .ck-btn-row { display:flex; gap:9px; margin-top:4px; }
  .ck-btn { display:flex; align-items:center; justify-content:center; gap:7px; padding:10px 16px; border-radius:var(--radius-sm); font-family:'DM Sans',sans-serif; font-size:13.5px; font-weight:600; cursor:pointer; border:none; transition:all 0.15s ease; outline:none; }
  .ck-btn-primary { flex:1; background:var(--accent); color:white; }
  .ck-btn-primary:hover:not(:disabled) { background:#1d4ed8; transform:translateY(-1px); box-shadow:0 4px 14px rgba(37,99,235,0.3); }
  .ck-btn-primary:active:not(:disabled) { transform:translateY(0); box-shadow:none; }
  .ck-btn-primary:disabled { opacity:0.6; cursor:not-allowed; }
  .ck-btn-secondary { background:var(--surface); color:var(--ink-soft); border:1px solid var(--border-strong); }
  .ck-btn-secondary:hover { background:var(--surface-2); }

  /* Spinner */
  .ck-spinner { width:15px; height:15px; border:2px solid rgba(255,255,255,0.35); border-top-color:white; border-radius:50%; animation:ck-spin 0.7s linear infinite; }
  @keyframes ck-spin { to{transform:rotate(360deg)} }

  /* Editing Banner */
  .ck-editing-banner { display:flex; align-items:center; gap:8px; background:#fff7ed; border:1px solid rgba(249,115,22,0.2); border-radius:var(--radius-sm); padding:9px 12px; margin-bottom:14px; font-size:12.5px; color:#9a3412; font-weight:500; }

  /* List Panel */
  .ck-list-panel { background:var(--white); border:1px solid var(--border); border-radius:var(--radius); overflow:hidden; display:flex; flex-direction:column; min-height:540px; }
  .ck-list-head { padding:18px 22px; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:12px; }
  .ck-search-wrap { flex:1; position:relative; }
  .ck-search-icon { position:absolute; left:12px; top:50%; transform:translateY(-50%); color:var(--ink-muted); display:flex; pointer-events:none; }
  .ck-search { width:100%; background:var(--surface); border:1px solid var(--border-strong); border-radius:var(--radius-sm); padding:9px 13px 9px 38px; font-family:'DM Sans',sans-serif; font-size:13.5px; color:var(--ink); outline:none; transition:all 0.18s ease; }
  .ck-search::placeholder { color:var(--ink-muted); }
  .ck-search:focus { background:var(--white); border-color:var(--accent); box-shadow:0 0 0 3px var(--accent-glow); }
  .ck-count-badge { background:var(--accent-soft); color:var(--accent); font-size:12px; font-weight:600; padding:5px 11px; border-radius:100px; white-space:nowrap; }
  .ck-list-body { flex:1; overflow-y:auto; padding:14px 16px; }
  .ck-list-body::-webkit-scrollbar{width:4px} .ck-list-body::-webkit-scrollbar-track{background:transparent} .ck-list-body::-webkit-scrollbar-thumb{background:var(--border-strong);border-radius:4px}

  /* Card */
  .ck-card { position:relative; background:var(--white); border:1px solid var(--border); border-radius:var(--radius-sm); padding:16px 16px 14px 20px; margin-bottom:10px; transition:all 0.2s ease; overflow:hidden; }
  .ck-card::before { content:''; position:absolute; left:0; top:0; bottom:0; width:3px; background:var(--border-strong); border-radius:3px 0 0 3px; transition:all 0.2s ease; }
  .ck-card:hover { border-color:rgba(37,99,235,0.2); box-shadow:0 2px 16px rgba(0,0,0,0.05); transform:translateY(-1px); }
  .ck-card:hover::before { background:var(--accent); }
  .ck-card-inner { display:flex; justify-content:space-between; align-items:flex-start; gap:12px; }
  .ck-card-content { flex:1; min-width:0; }
  .ck-card-title { font-size:14px; font-weight:600; color:var(--ink); margin-bottom:6px; letter-spacing:-0.01em; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .ck-card-body { font-size:12.5px; color:var(--ink-soft); line-height:1.65; display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden; }
  .ck-card-actions { display:flex; gap:2px; flex-shrink:0; opacity:0; transition:opacity 0.15s ease; background:var(--surface); border:1px solid var(--border); border-radius:var(--radius-sm); padding:3px; align-self:flex-start; }
  .ck-card:hover .ck-card-actions { opacity:1; }
  .ck-action-btn { width:30px; height:30px; border-radius:6px; border:none; background:transparent; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:all 0.15s ease; color:var(--ink-soft); }
  .ck-action-btn.edit:hover { background:var(--accent-soft); color:var(--accent); }
  .ck-action-btn.del:hover { background:var(--danger-soft); color:var(--danger); }
  .ck-card-divider { width:1px; background:var(--border); margin:4px 2px; }

  /* Empty state */
  .ck-empty { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; padding:60px 32px; text-align:center; }
  .ck-empty-icon { width:72px; height:72px; background:var(--surface-2); border-radius:50%; display:flex; align-items:center; justify-content:center; margin-bottom:20px; color:var(--ink-muted); }
  .ck-empty h3 { font-size:15px; font-weight:600; color:var(--ink); margin-bottom:8px; }
  .ck-empty p { font-size:13px; color:var(--ink-soft); max-width:280px; line-height:1.6; }
`;

export default function ChatbotKnowledge() {
    const [rules, setRules] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [editingId, setEditingId] = useState(null);
    const [title, setTitle] = useState('');
    const [content, setContent] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => { fetchRules(); }, []);

    const fetchRules = async () => {
        try {
            const response = await axios.get(API_URL);
            setRules(response.data);
        } catch (error) {
            console.error('Lỗi khi tải dữ liệu:', error);
            alert('Không thể kết nối đến API Gateway (Port 8080).');
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsLoading(true);
        try {
            if (editingId) {
                await axios.put(`${API_URL}/${editingId}`, { title, content });
            } else {
                await axios.post(API_URL, { title, content });
            }
            resetForm();
            fetchRules();
        } catch (error) {
            console.error('Lỗi lưu dữ liệu:', error);
            alert('Có lỗi xảy ra khi lưu dữ liệu!');
        } finally {
            setIsLoading(false);
        }
    };

    const handleEdit = (rule) => {
        setEditingId(rule.id);
        setTitle(rule.title);
        setContent(rule.content);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Xóa quy định này? AI sẽ không còn nhớ kiến thức này.')) return;
        try {
            await axios.delete(`${API_URL}/${id}`);
            if (editingId === id) resetForm();
            fetchRules();
        } catch (error) {
            console.error('Lỗi khi xóa:', error);
            alert('Không thể xóa dữ liệu!');
        }
    };

    const resetForm = () => {
        setEditingId(null);
        setTitle('');
        setContent('');
    };

    const filteredRules = rules.filter(rule =>
        rule.title?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        rule.content?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const isEditing = !!editingId;

    return (
        <>
            <style>{styles}</style>
            <div className="ck-root">

                {/* Header */}
                <div className="ck-header">
                    <div>
                        <div className="ck-eyebrow">SmartShip AI</div>
                        <h1 className="ck-title">Tri thức Chatbot</h1>
                        <p className="ck-subtitle">Quản lý quy định và chính sách huấn luyện trợ lý ảo</p>
                    </div>
                    <div className="ck-stat-chip">
                        <span className="dot"></span>
                        <span>{rules.length} quy định</span>
                    </div>
                </div>

                <div className="ck-layout">

                    {/* Form Panel */}
                    <div className={`ck-form-panel${isEditing ? ' editing' : ''}`}>
                        <div className="ck-form-head">
                            <div className="ck-form-icon">
                                {isEditing ? <IconEdit /> : <IconDatabase />}
                            </div>
                            <div className="ck-form-head-text">
                                <h2>{isEditing ? 'Chỉnh sửa quy định' : 'Nạp kiến thức mới'}</h2>
                                <p>{isEditing ? 'Cập nhật nội dung hiện có' : 'AI sẽ học ngay sau khi lưu'}</p>
                            </div>
                        </div>

                        <div className="ck-form-body">
                            {isEditing && (
                                <div className="ck-editing-banner">
                                    <IconEdit />
                                    Đang chỉnh sửa quy định đã có
                                </div>
                            )}

                            <form onSubmit={handleSubmit}>
                                <div className="ck-field">
                                    <label className="ck-label" htmlFor="inp-title">Tiêu đề quy định</label>
                                    <input
                                        className="ck-input"
                                        id="inp-title"
                                        type="text"
                                        placeholder="VD: Chính sách giá cước hỏa tốc..."
                                        value={title}
                                        onChange={(e) => setTitle(e.target.value)}
                                        required
                                    />
                                </div>

                                <div className="ck-field">
                                    <label className="ck-label" htmlFor="inp-content">
                                        Nội dung chi tiết <span className="sub">— dữ liệu AI sẽ học</span>
                                    </label>
                                    <textarea
                                        className="ck-textarea"
                                        id="inp-content"
                                        placeholder="Nhập quy định, giá tiền, điều kiện áp dụng..."
                                        value={content}
                                        onChange={(e) => setContent(e.target.value)}
                                        required
                                    />
                                </div>

                                <div className="ck-btn-row">
                                    <button type="submit" className="ck-btn ck-btn-primary" disabled={isLoading}>
                                        {isLoading
                                            ? <><div className="ck-spinner" /><span>Đang xử lý...</span></>
                                            : isEditing
                                                ? <><IconSave /><span>Lưu thay đổi</span></>
                                                : <><IconZap /><span>Nạp vào AI</span></>
                                        }
                                    </button>
                                    {isEditing && (
                                        <button type="button" className="ck-btn ck-btn-secondary" onClick={resetForm}>
                                            <IconX /> Hủy
                                        </button>
                                    )}
                                </div>
                            </form>
                        </div>
                    </div>

                    {/* List Panel */}
                    <div className="ck-list-panel">
                        <div className="ck-list-head">
                            <div className="ck-search-wrap">
                                <div className="ck-search-icon"><IconSearch /></div>
                                <input
                                    className="ck-search"
                                    type="text"
                                    placeholder="Tìm kiếm quy định, từ khóa..."
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                />
                            </div>
                            <div className="ck-count-badge">{filteredRules.length} mục</div>
                        </div>

                        <div className="ck-list-body">
                            {filteredRules.length > 0 ? (
                                filteredRules.map((rule) => (
                                    <div className="ck-card" key={rule.id}>
                                        <div className="ck-card-inner">
                                            <div className="ck-card-content">
                                                <div className="ck-card-title">{rule.title}</div>
                                                <div className="ck-card-body">{rule.content}</div>
                                            </div>
                                            <div className="ck-card-actions">
                                                <button
                                                    className="ck-action-btn edit"
                                                    onClick={() => handleEdit(rule)}
                                                    title="Chỉnh sửa"
                                                >
                                                    <IconEditSm />
                                                </button>
                                                <div className="ck-card-divider" />
                                                <button
                                                    className="ck-action-btn del"
                                                    onClick={() => handleDelete(rule.id)}
                                                    title="Xóa"
                                                >
                                                    <IconTrash />
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="ck-empty">
                                    <div className="ck-empty-icon"><IconBot /></div>
                                    <h3>{rules.length === 0 ? 'Dữ liệu AI đang trống' : 'Không tìm thấy kết quả'}</h3>
                                    <p>
                                        {rules.length === 0
                                            ? 'Chưa có quy định nào. Dùng form bên trái để nạp kiến thức đầu tiên cho AI.'
                                            : `Không tìm thấy nội dung khớp với "${searchQuery}". Thử từ khóa khác.`}
                                    </p>
                                </div>
                            )}
                        </div>
                    </div>

                </div>
            </div>
        </>
    );
}