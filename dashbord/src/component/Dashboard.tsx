import React, { useState, useEffect } from 'react';
import { 
  Users, 
  DollarSign, 
  Package, 
  TrendingUp, 
  RefreshCw, 
  AlertCircle, 
  CheckCircle2, 
  Search,
  LayoutDashboard,
  ShieldAlert,
  Lock,
  Plus,
  Trash2,
  ShoppingCart,
  MapPin,
  Phone,
  User
} from 'lucide-react';
import './Dashboard.css';

export interface UserItem {
  id: string;
  name: string;
  email: string;
  is_admin: boolean;
  is_banned: boolean;
}

export interface ProductItem {
  id: string;
  title: string;
  price: number;
  rating: number;
  category: string;
  images: string[];
}

export interface OrderItem {
  order_id: string;
  customer_name: string;
  product_name: string;
  quantity: number;
  product_price: number;
  total_amount: number;
  status: string;
  address: string;
  phone: string;
  area: string;
  state: string;
  country: string;
  payment_method: string;
}

export interface Metrics {
  total_users: number;
  total_products: number;
  active_orders: number;
  total_sales: number;
}

const API_BASE_URL = 'http://localhost:8080/api';
const DEFAULT_MASTER_KEY = "MY_SUPER_SECRET_ADMIN_DASHBOARD_LONG_MASTER_KEY_2026_SECURE_ACCESS";

const PREDEFINED_CATEGORIES = [
  "السيارات",
  "عروض السوبر",
  "Choice",
  "أجهزة"
];

export const Dashboard: React.FC = () => {
  const [adminToken, setAdminToken] = useState<string>(
    localStorage.getItem('admin_token') || DEFAULT_MASTER_KEY
  );
  
  const [metrics, setMetrics] = useState<Metrics>({ total_users: 0, total_products: 0, active_orders: 0, total_sales: 0 });
  const [users, setUsers] = useState<UserItem[]>([]);
  const [products, setProducts] = useState<ProductItem[]>([]);
  const [orders, setOrders] = useState<OrderItem[]>([]);
  
  const [loading, setLoading] = useState<boolean>(true);
  const [isLiveApi, setIsLiveApi] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'users' | 'products' | 'orders'>('overview');
  const [searchTerm, setSearchTerm] = useState<string>('');

  const [showAddProductModal, setShowAddProductModal] = useState<boolean>(false);
  const [newTitle, setNewTitle] = useState<string>('');
  const [newPrice, setNewPrice] = useState<string>('');
  const [newCategory, setNewCategory] = useState<string>(PREDEFINED_CATEGORIES[0]);
  const [newRating, setNewRating] = useState<string>('5.0');
  const [newImage, setNewImage] = useState<string>('');

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);
    try {
      const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      };

      const [statsRes, usersRes, productsRes, ordersRes] = await Promise.all([
        fetch(`${API_BASE_URL}/admin/stats`, { headers }),
        fetch(`${API_BASE_URL}/admin/users`, { headers }),
        fetch(`${API_BASE_URL}/products`, { headers }),
        fetch(`${API_BASE_URL}/admin/orders`, { headers })
      ]);

      if (!statsRes.ok || !usersRes.ok || !ordersRes.ok) {
        if (statsRes.status === 401 || statsRes.status === 403) {
          throw new Error('الرمز السري غير صحيح. يرجى التحقق من الرمز الثابت الطويل.');
        }
        throw new Error('فشل جلب البيانات من السيرفر');
      }

      const statsData: Metrics = await statsRes.json();
      const usersData: UserItem[] = await usersRes.json();
      const productsData: ProductItem[] = await productsRes.json();
      const ordersData: OrderItem[] = await ordersRes.json();

      setMetrics(statsData);
      setUsers(usersData || []);
      setProducts(productsData || []);
      setOrders(ordersData || []);
      setIsLiveApi(true);
    } catch (err: any) {
      console.error("خطأ في الاتصال بالخادم:", err);
      setError(err.message || "تعذر الاتصال بالسيرفر الحقيقي على (port 8080).");
      setIsLiveApi(false);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, [adminToken]);

  const handleToggleBan = async (userId: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/admin/users/ban`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({ user_id: userId })
      });

      const result = await response.json();
      if (result.success) {
        fetchDashboardData();
      } else {
        alert(result.message || "فشل تحديث حالة الحظر");
      }
    } catch (err) {
      console.error("خطأ في الاتصال:", err);
      alert("حدث خطأ أثناء الاتصال بالخادم");
    }
  };

  const handleAddProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle || !newPrice || !newCategory) {
      alert("يرجى ملء الحقول الأساسية للمنتج (العنوان، السعر، الفئة)");
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/products/add`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          id: 'p_' + Date.now(),
          title: newTitle,
          price: parseFloat(newPrice) || 0,
          rating: parseFloat(newRating) || 5.0,
          category: newCategory,
          images: newImage ? [newImage] : []
        })
      });

      const result = await response.json();
      if (result.success) {
        alert(result.message || "تم إضافة المنتج بنجاح");
        setNewTitle('');
        setNewPrice('');
        setNewCategory(PREDEFINED_CATEGORIES[0]);
        setNewRating('5.0');
        setNewImage('');
        setShowAddProductModal(false);
        fetchDashboardData();
      } else {
        alert("فشل إضافة المنتج");
      }
    } catch (err) {
      console.error("خطأ أثناء إضافة المنتج:", err);
      alert("تعذر الاتصال بالسيرفر لإضافة المنتج");
    }
  };

  const handleDeleteProduct = async (productId: string) => {
    if (!window.confirm("هل أنت متأكد من رغبتك في حذف هذا المنتج؟")) return;

    try {
      const response = await fetch(`${API_BASE_URL}/products/delete`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({ product_id: productId })
      });

      const result = await response.json();
      if (result.success) {
        alert(result.message || "تم حذف المنتج بنجاح");
        fetchDashboardData();
      } else {
        alert(result.message || "فشل حذف المنتج");
      }
    } catch (err) {
      console.error("خطأ أثناء الاتصال لحذف المنتج:", err);
      alert("حدث خطأ أثناء الاتصال بالسيرفر للحذف");
    }
  };

  const filteredUsers = users.filter(u => 
    u.name?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    u.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredProducts = products.filter(p => 
    p.title?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.category?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredOrders = orders.filter(o =>
    o.customer_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    o.phone?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    o.country?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    o.state?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading && !isLiveApi && !error) {
    return (
      <div className="dash-loading-screen">
        <div className="dash-loading-content">
          <RefreshCw className="dash-spinner text-orange-500" />
          <span>جاري الاتصال بسيرفر Go والمراقبة...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard-container" dir="rtl">
      
      {/* Header */}
      <header className="dash-header">
        <div>
          <h1 className="dash-title">
            <LayoutDashboard className="dash-icon text-orange-500" />
            لوحة مراقبة المشرفين (Admin Dashboard)
          </h1>
          <p className="dash-subtitle">
            متصل بـ Go Backend عبر الرمز الثابت الطويل على: <code>localhost:8080/api/admin/...</code>
          </p>
        </div>

        <div className="dash-header-actions">
          {isLiveApi ? (
            <span className="dash-badge dash-badge-success">
              <CheckCircle2 size={14} /> السيرفر متصل ومتحكم به
            </span>
          ) : (
            <span className="dash-badge dash-badge-error">
              <AlertCircle size={14} /> خطأ في الرمز أو الاتصال
            </span>
          )}

          <div className="dash-token-box">
            <Lock size={14} className="text-orange-500" />
            <input 
              type="text" 
              value={adminToken} 
              onChange={(e) => {
                setAdminToken(e.target.value);
                localStorage.setItem('admin_token', e.target.value);
              }}
              placeholder="الرمز الثابت الطويل..."
              className="dash-token-input"
            />
          </div>

          <button onClick={fetchDashboardData} className="dash-btn dash-btn-secondary">
            <RefreshCw size={16} /> تحديث البيانات
          </button>
        </div>
      </header>

      {error && (
        <div className="dash-error-banner">
          <span>{error}</span>
          <span>تأكد من مطابقة الرمز الطويل الموجود في ملف الـ Go</span>
        </div>
      )}

      {/* Metrics Cards */}
      <div className="dash-metrics-grid">
        <div className="dash-card">
          <div className="dash-card-header">
            <span>إجمالي المبيعات (Total Sales)</span>
            <DollarSign className="text-emerald-500" size={20} />
          </div>
          <div className="dash-card-value text-emerald-400">
            ${metrics.total_sales?.toLocaleString() || 0}
          </div>
          <span className="dash-card-footer text-emerald-500">
            <TrendingUp size={12} /> بيانات مباشرة من السيرفر
          </span>
        </div>

        <div className="dash-card">
          <div className="dash-card-header">
            <span>إجمالي المستخدمين</span>
            <Users className="text-blue-500" size={20} />
          </div>
          <div className="dash-card-value">
            {metrics.total_users || 0}
          </div>
          <span className="dash-card-footer">مسجلين في قاعدة البيانات</span>
        </div>

        <div className="dash-card">
          <div className="dash-card-header">
            <span>إجمالي المنتجات</span>
            <Package className="text-orange-500" size={20} />
          </div>
          <div className="dash-card-value">
            {metrics.total_products || 0}
          </div>
          <span className="dash-card-footer">منتجات متوفرة</span>
        </div>

        <div className="dash-card">
          <div className="dash-card-header">
            <span>الطلبات النشطة</span>
            <ShoppingCart className="text-purple-500" size={20} />
          </div>
          <div className="dash-card-value text-purple-400">
            {metrics.active_orders || orders.length}
          </div>
          <span className="dash-card-footer text-purple-400">طلبات الشحن المسجلة</span>
        </div>
      </div>

      {/* Tabs & Search */}
      <div className="dash-nav-bar">
        <div className="dash-tabs">
          <button
            onClick={() => setActiveTab('overview')}
            className={`dash-tab-btn ${activeTab === 'overview' ? 'active' : ''}`}
          >
            نظرة عامة
          </button>
          <button
            onClick={() => setActiveTab('users')}
            className={`dash-tab-btn ${activeTab === 'users' ? 'active' : ''}`}
          >
            المستخدمين ({users.length})
          </button>
          <button
            onClick={() => setActiveTab('products')}
            className={`dash-tab-btn ${activeTab === 'products' ? 'active' : ''}`}
          >
            المنتجات ({products.length})
          </button>
          <button
            onClick={() => setActiveTab('orders')}
            className={`dash-tab-btn ${activeTab === 'orders' ? 'active' : ''}`}
          >
            الطلبات والشحن ({orders.length})
          </button>

          <button
            onClick={() => setShowAddProductModal(true)}
            className="dash-btn dash-btn-primary"
          >
            <Plus size={16} /> إضافة منتج جديد
          </button>
        </div>

        <div className="dash-search-box">
          <Search size={16} className="dash-search-icon" />
          <input
            type="text"
            placeholder="بحث بالاسم، الهاتف أو البلد..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="dash-search-input"
          />
        </div>
      </div>

      {/* Add Product Modal */}
      {showAddProductModal && (
        <div className="dash-modal-overlay">
          <div className="dash-modal">
            <h3 className="dash-modal-title">
              <Package size={20} className="text-orange-500" />
              إضافة منتج جديد ضمن الفئات المحددة
            </h3>
            
            <form onSubmit={handleAddProduct} className="dash-form">
              <div className="dash-form-group">
                <label>عنوان المنتج</label>
                <input 
                  type="text"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="مثال: سماعات لاسلكية"
                  required
                />
              </div>

              <div className="dash-form-row">
                <div className="dash-form-group">
                  <label>السعر ($)</label>
                  <input 
                    type="number"
                    step="0.01"
                    value={newPrice}
                    onChange={(e) => setNewPrice(e.target.value)}
                    placeholder="99.99"
                    required
                  />
                </div>
                <div className="dash-form-group">
                  <label>التقييم (Rating)</label>
                  <input 
                    type="number"
                    step="0.1"
                    max="5"
                    min="1"
                    value={newRating}
                    onChange={(e) => setNewRating(e.target.value)}
                  />
                </div>
              </div>

              <div className="dash-form-group">
                <label>اختر الفئة المحددة</label>
                <select
                  value={newCategory}
                  onChange={(e) => setNewCategory(e.target.value)}
                  required
                >
                  {PREDEFINED_CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              <div className="dash-form-group">
                <label>رابط الصورة (Image URL)</label>
                <input 
                  type="text"
                  value={newImage}
                  onChange={(e) => setNewImage(e.target.value)}
                  placeholder="https://example.com/image.jpg"
                />
              </div>

              <div className="dash-modal-actions">
                <button
                  type="button"
                  onClick={() => setShowAddProductModal(false)}
                  className="dash-btn dash-btn-dark"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="dash-btn dash-btn-primary"
                >
                  حفظ وإضافة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Users Table */}
      {(activeTab === 'overview' || activeTab === 'users') && (
        <div className="dash-section">
          <h2 className="dash-section-title">
            <Users size={20} className="text-orange-500" /> قائمة المستخدمين في السيرفر
          </h2>
          <div className="dash-table-container">
            <table className="dash-table">
              <thead>
                <tr>
                  <th>المعرف (ID)</th>
                  <th>الاسم</th>
                  <th>البريد الإلكتروني</th>
                  <th>الصلاحية</th>
                  <th>الحالة</th>
                  <th>الإجراء (الحظر)</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.length > 0 ? (
                  filteredUsers.map((user) => (
                    <tr key={user.id}>
                      <td className="font-mono text-neutral-500">#{user.id}</td>
                      <td className="font-medium">{user.name}</td>
                      <td className="font-mono text-neutral-400">{user.email}</td>
                      <td>
                        <span className={`dash-tag ${user.is_admin ? 'dash-tag-admin' : 'dash-tag-user'}`}>
                          {user.is_admin ? 'مدير (Admin)' : 'مستخدم عادي'}
                        </span>
                      </td>
                      <td>
                        <span className={`dash-status-badge ${!user.is_banned ? 'active' : 'banned'}`}>
                          {!user.is_banned ? 'نشط' : 'محظور'}
                        </span>
                      </td>
                      <td>
                        <button
                          onClick={() => handleToggleBan(user.id)}
                          className={`dash-action-btn ${user.is_banned ? 'unban' : 'ban'}`}
                        >
                          <ShieldAlert size={14} />
                          {user.is_banned ? 'إلغاء الحظر' : 'حظر المستخدم'}
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="dash-empty">لا توجد حسابات مسجلة حالياً في السيرفر</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Products Table */}
      {(activeTab === 'overview' || activeTab === 'products') && (
        <div className="dash-section">
          <h2 className="dash-section-title">
            <Package size={20} className="text-orange-500" /> المنتجات المضافة في المتجر
          </h2>
          <div className="dash-table-container">
            <table className="dash-table">
              <thead>
                <tr>
                  <th>كود المنتج</th>
                  <th>عنوان المنتج</th>
                  <th>الفئة</th>
                  <th>السعر</th>
                  <th>التقييم</th>
                  <th>الإجراء</th>
                </tr>
              </thead>
              <tbody>
                {filteredProducts.length > 0 ? (
                  filteredProducts.map((prod) => (
                    <tr key={prod.id}>
                      <td className="font-mono text-neutral-500">#{prod.id}</td>
                      <td className="font-medium">{prod.title}</td>
                      <td className="text-orange-400 font-medium">{prod.category}</td>
                      <td className="font-mono text-emerald-400 font-semibold">${prod.price?.toFixed(2) || '0.00'}</td>
                      <td className="font-mono text-amber-400">⭐ {prod.rating || 0}</td>
                      <td>
                        <button
                          onClick={() => handleDeleteProduct(prod.id)}
                          className="dash-action-btn delete"
                        >
                          <Trash2 size={14} /> حذف
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="dash-empty">لا توجد منتجات مضافة في السيرفر حالياً</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Orders Table */}
      {(activeTab === 'overview' || activeTab === 'orders') && (
        <div className="dash-section">
          <h2 className="dash-section-title">
            <ShoppingCart size={20} className="text-orange-500" /> سجل الطلبات وتفاصيل الشحن والعملاء
          </h2>
          <div className="dash-table-container">
            <table className="dash-table">
              <thead>
                <tr>
                  <th>رقم الطلب</th>
                  <th>المشتري</th>
                  <th>المنتجات والكمية</th>
                  <th>المبلغ الإجمالي</th>
                  <th>عنوان التوصيل (البلد، الولاية، العنوان)</th>
                  <th>رقم الهاتف</th>
                  <th>الحالة</th>
                </tr>
              </thead>
              <tbody>
                {filteredOrders.length > 0 ? (
                  filteredOrders.map((ord) => (
                    <tr key={ord.order_id}>
                      <td className="font-mono text-orange-400">#{ord.order_id}</td>
                      <td className="font-medium flex items-center gap-1.5">
                        <User size={14} className="text-neutral-400" />
                        {ord.customer_name}
                      </td>
                      <td>
                        <div className="font-medium">{ord.product_name}</div>
                        <span className="text-xs text-neutral-500 font-mono">الكمية: {ord.quantity}</span>
                      </td>
                      <td className="font-mono text-emerald-400 font-bold">${ord.total_amount?.toFixed(2) || '0.00'}</td>
                      <td className="text-xs">
                        <div className="dash-order-location">
                          <MapPin size={12} /> {ord.country} - {ord.state}
                        </div>
                        <div className="text-neutral-400 mt-0.5">{ord.area}، {ord.address}</div>
                      </td>
                      <td className="font-mono text-xs flex items-center gap-1">
                        <Phone size={14} className="text-neutral-500" />
                        {ord.phone}
                      </td>
                      <td>
                        <span className="dash-order-status">{ord.status || 'نشط'}</span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="dash-empty">لا توجد طلبات شراء مسجلة حالياً</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

    </div>
  );
};

export default Dashboard;