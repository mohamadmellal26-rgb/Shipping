package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// Product هيكل المنتج
type Product struct {
	ID       string   `json:"id"`
	Title    string   `json:"title"`
	Price    float64  `json:"price"`
	Rating   float64  `json:"rating"`
	Category string   `json:"category"`
	Images   []string `json:"images"`
}

// Category هيكل التصنيف
type Category struct {
	Name string `json:"name"`
	Icon string `json:"icon"`
}

// User هيكل المستخدم مع كلمة المرور المشفرة وصلاحيات الآدمن
type User struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"` // تخزن مشفرة (Hash)
	IsAdmin  bool   `json:"is_admin"`
	IsBanned bool   `json:"is_banned"`
}

// RegisterRequest هيكل آمن لاستقبال بيانات التسجيل فقط لمنع ثغرات التلاعب بالصلاحيات
type RegisterRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

// Order هيكل الطلب وتفاصيل الشراء والشحن مع معلومات العميل والمنطقة بدقة
type Order struct {
	OrderID       string  `json:"order_id"`
	CustomerID    string  `json:"customer_id"`    // معرف المستخدم للتأكد من الحظر
	CustomerEmail string  `json:"customer_email"` // البريد الإلكتروني للتأكد من الحظر
	CustomerName  string  `json:"customer_name"`
	ProductName   string  `json:"product_name"`
	Quantity      int     `json:"quantity"`
	ProductPrice  float64 `json:"product_price"`
	TotalAmount   float64 `json:"total_amount"`
	Status        string  `json:"status"`         // نشط / مكتمل
	Address       string  `json:"address"`        // العنوان بالتفصيل
	Phone         string  `json:"phone"`          // رقم الهاتف
	Area          string  `json:"area"`           // المنطقة / الحي
	State         string  `json:"state"`          // الولاية أو المقاطعة / المدينة
	Country       string  `json:"country"`        // البلد (الجزائر، فرنسا، إسبانيا، أمريكا...)
	PaymentMethod string  `json:"payment_method"` // طريقة الدفع
}

// Stats هيكل الإحصائيات العامة
type Stats struct {
	TotalUsers    int     `json:"total_users"`
	TotalProducts int     `json:"total_products"`
	ActiveOrders  int     `json:"active_orders"`
	TotalSales    float64 `json:"total_sales"`
}

// هيكل طلب فحص الحالة للمستخدم
type StatusCheckReq struct {
	Email string `json:"email"`
}

// تخزين البيانات
var productsList = []Product{}
var usersList = []User{}
var ordersList = []Order{}

// أسماء ملفات الحفظ الدائم على القرص
const productsFile = "products.json"
const usersFile = "users.json"
const ordersFile = "orders.json"

// دالة حفظ المنتجات في ملف
func saveProducts() {
	file, err := json.MarshalIndent(productsList, "", "  ")
	if err == nil {
		os.WriteFile(productsFile, file, 0644)
	}
}

// دالة تحميل المنتجات من الملف عند بدء التشغيل
func loadProducts() {
	if file, err := os.ReadFile(productsFile); err == nil {
		json.Unmarshal(file, &productsList)
	}
}

// دالة حفظ المستخدمين في ملف
func saveUsers() {
	file, err := json.MarshalIndent(usersList, "", "  ")
	if err == nil {
		os.WriteFile(usersFile, file, 0644)
	}
}

// دالة تحميل المستخدمين من الملف عند بدء التشغيل
func loadUsers() {
	if file, err := os.ReadFile(usersFile); err == nil {
		json.Unmarshal(file, &usersList)
	}
	
	if len(usersList) == 0 {
		hashedAdminPass, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		usersList = append(usersList, User{
			ID:       "1",
			Name:     "مدير النظام",
			Email:    "admin@system.com",
			Password: string(hashedAdminPass),
			IsAdmin:  true,
			IsBanned: false,
		})
		saveUsers()
	}
}

// دالة حفظ الطلبات في ملف
func saveOrders() {
	file, err := json.MarshalIndent(ordersList, "", "  ")
	if err == nil {
		os.WriteFile(ordersFile, file, 0644)
	}
}

// دالة تحميل الطلبات من الملف عند بدء التشغيل
func loadOrders() {
	if file, err := os.ReadFile(ordersFile); err == nil {
		json.Unmarshal(file, &ordersList)
	}
}

const MASTER_ADMIN_KEY = "MY_SUPER_SECRET_ADMIN_DASHBOARD_LONG_MASTER_KEY_2026_SECURE_ACCESS"

// تفعيل CORS
func enableCors(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next(w, r)
	}
}

// Middleware لحماية مسارات الداشبورد
func adminAuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "غير مسموح: يرجى إرسال الرمز السري للتحكم في الداشبورد"})
			return
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")
		if token != MASTER_ADMIN_KEY {
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "الرمز السري غير صحيح، الوصول مرفوض"})
			return
		}

		next(w, r)
	}
}

// 1. تسجيل مستخدم جديد (Register)
func registerHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Name = strings.TrimSpace(req.Name)
	req.Password = strings.TrimSpace(req.Password)

	if req.Email == "" || req.Password == "" || req.Name == "" {
		json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "يرجى ملء كافة الحقول المطلوبة"})
		return
	}

	if len(req.Password) <= 8 {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": false, 
			"message": "كلمة المرور يجب أن تكون أكبر من 8 أحرف",
		})
		return
	}

	if !strings.Contains(req.Email, "@") || !strings.HasSuffix(req.Email, ".com") {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": false, 
			"message": "البريد الإلكتروني غير صالح، يجب أن يحتوي على @ وينتهي بـ .com",
		})
		return
	}

	for _, u := range usersList {
		if u.Email == req.Email {
			json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "البريد الإلكتروني مستخدم بالفعل"})
			return
		}
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "فشل معالجة كلمة المرور"})
		return
	}

	newUser := User{
		ID:       "usr_" + time.Now().Format("20060102150405"),
		Name:     req.Name,
		Email:    req.Email,
		Password: string(hashedPassword),
		IsAdmin:  false,
		IsBanned: false,
	}

	usersList = append(usersList, newUser)
	saveUsers()

	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "message": "تم إنشاء الحساب بنجاح"})
}

// 2. تسجيل الدخول (Login)
func loginHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var creds struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&creds); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	creds.Email = strings.ToLower(strings.TrimSpace(creds.Email))

	for _, user := range usersList {
		if user.Email == creds.Email {
			err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(creds.Password))
			if err == nil {
				if user.IsBanned {
					json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "هذا الحساب محظور"})
					return
				}
				
				var dashboardKey string
				if user.IsAdmin {
					dashboardKey = MASTER_ADMIN_KEY
				}

				safeUser := map[string]interface{}{
					"id":        user.ID,
					"name":      user.Name,
					"email":     user.Email,
					"is_admin":  user.IsAdmin,
					"is_banned": user.IsBanned,
				}

				json.NewEncoder(w).Encode(map[string]interface{}{
					"success":      true,
					"message":      "تم تسجيل الدخول بنجاح",
					"admin_secret": dashboardKey,
					"user":         safeUser,
				})
				return
			}
		}
	}

	json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "خطأ في البريد الإلكتروني أو كلمة المرور"})
}

// 3. فحص حالة حظر المستخدم عبر البريد الإلكتروني
func checkUserStatusHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req StatusCheckReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	for _, u := range usersList {
		if u.Email == req.Email {
			json.NewEncoder(w).Encode(map[string]interface{}{
				"success":   true,
				"is_banned": u.IsBanned,
			})
			return
		}
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":   false,
		"message":   "المستخدم غير موجود",
	})
}

// 4. جلب كل المنتجات
func getProducts(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(productsList)
}

// 4.1 جلب المنتجات حسب فئة محددة
func getProductsByCategory(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	categoryName := r.URL.Query().Get("name")
	if categoryName == "" {
		json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "يرجى تحديد اسم الفئة المطلوبة"})
		return
	}

	var filteredProducts []Product
	for _, p := range productsList {
		if strings.EqualFold(p.Category, categoryName) {
			filteredProducts = append(filteredProducts, p)
		}
	}

	json.NewEncoder(w).Encode(filteredProducts)
}

// 5. إضافة منتج جديد
func addProduct(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var p Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	productsList = append(productsList, p)
	saveProducts()
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "message": "تم إضافة المنتج بنجاح"})
}

// 6. جلب التصنيفات
func getCategories(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	categories := []Category{
		{Name: "كل الأصناف", Icon: "menu"},
		{Name: "السيارات", Icon: "directions_car"},
		{Name: "عروض السوبر", Icon: "local_offer"},
		{Name: "Choice", Icon: "thumb_up"},
		{Name: "أجهزة", Icon: "devices"},
	}
	json.NewEncoder(w).Encode(categories)
}

// 7. إنشاء طلب شراء جديد مع التحقق الصارم والدقيق من حالة الحظر (بالإيميل أو المعرف)
func createOrderHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var newOrder Order
	if err := json.NewDecoder(r.Body).Decode(&newOrder); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	newOrder.CustomerEmail = strings.ToLower(strings.TrimSpace(newOrder.CustomerEmail))

	for _, u := range usersList {
		if ((newOrder.CustomerID != "" && u.ID == newOrder.CustomerID) || 
			(newOrder.CustomerEmail != "" && u.Email == newOrder.CustomerEmail)) && u.IsBanned {
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"success": false,
				"message": "عذراً، هذا الحساب محظور ولا يمكنه إتمام عمليات الشراء",
			})
			return
		}
	}

	if newOrder.CustomerName == "" || newOrder.Address == "" || newOrder.Phone == "" || newOrder.State == "" || newOrder.Country == "" {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": false, 
			"message": "يرجى إدخال كافة تفاصيل الشحن المطلوبة (الاسم، العنوان، رقم الهاتف، الولاية/المدينة، البلد)",
		})
		return
	}

	if newOrder.OrderID == "" {
		newOrder.OrderID = "ord_" + time.Now().Format("20060102150405")
	}
	if newOrder.Status == "" {
		newOrder.Status = "نشط"
	}
	if newOrder.PaymentMethod == "" {
		newOrder.PaymentMethod = "الدفع عند الاستلام"
	}

	ordersList = append(ordersList, newOrder)
	saveOrders()

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":  true,
		"message":  "تم تأكيد طلب الشراء بنجاح (الدفع عند الاستلام)",
		"order_id": newOrder.OrderID,
	})
}

// --- مسارات لوحة التحكم والمراقبة ---

func getAdminUsers(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(usersList)
}

func getAdminOrders(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var responseOrders []map[string]interface{}
	for _, order := range ordersList {
		status := order.Status
		
		for _, u := range usersList {
			if ((order.CustomerID != "" && u.ID == order.CustomerID) || 
				(order.CustomerEmail != "" && u.Email == order.CustomerEmail)) && u.IsBanned {
				status = "محظور (صاحب الحساب محظور)"
				break
			}
		}

		orderMap := map[string]interface{}{
			"order_id":       order.OrderID,
			"customer_id":    order.CustomerID,
			"customer_email": order.CustomerEmail,
			"customer_name":  order.CustomerName,
			"product_name":   order.ProductName,
			"quantity":       order.Quantity,
			"product_price":  order.ProductPrice,
			"total_amount":   order.TotalAmount,
			"status":         status,
			"address":        order.Address,
			"phone":          order.Phone,
			"area":           order.Area,
			"state":          order.State,
			"country":        order.Country,
			"payment_method": order.PaymentMethod,
		}
		responseOrders = append(responseOrders, orderMap)
	}

	json.NewEncoder(w).Encode(responseOrders)
}

func getAdminStats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	totalSales := 0.0
	activeOrdersCount := 0

	for _, order := range ordersList {
		isUserBanned := false
		for _, u := range usersList {
			if ((order.CustomerID != "" && u.ID == order.CustomerID) || 
				(order.CustomerEmail != "" && u.Email == order.CustomerEmail)) && u.IsBanned {
				isUserBanned = true
				break
			}
		}

		if !isUserBanned {
			totalSales += order.TotalAmount
			if order.Status == "نشط" {
				activeOrdersCount++
			}
		}
	}

	stats := Stats{
		TotalUsers:    len(usersList),
		TotalProducts: len(productsList),
		ActiveOrders:  activeOrdersCount,
		TotalSales:    totalSales,
	}

	json.NewEncoder(w).Encode(stats)
}

func banUserHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		UserID string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	found := false
	for i, user := range usersList {
		if user.ID == req.UserID {
			usersList[i].IsBanned = !usersList[i].IsBanned
			found = true
			break
		}
	}

	if !found {
		json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "المستخدم غير موجود"})
		return
	}

	saveUsers()
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "message": "تم تحديث حالة الحظر بنجاح"})
}

func deleteUserHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" && r.Method != "DELETE" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		UserID string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	found := false
	newUsersList := []User{}
	for _, user := range usersList {
		if user.ID == req.UserID {
			if user.IsAdmin && user.ID == "1" {
				json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "لا يمكنك حذف حساب المدير الرئيسي للنظام"})
				return
			}
			found = true
			continue
		}
		newUsersList = append(newUsersList, user)
	}

	if !found {
		json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "المستخدم غير موجود"})
		return
	}

	usersList = newUsersList
	saveUsers()
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "message": "تم حذف المستخدم بنجاح"})
}

// دالة حذف المنتج مع حذف طلباته المرتبطة تلقائياً
func deleteProductHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != "POST" && r.Method != "DELETE" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		ProductID string `json:"product_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	found := false
	var deletedProductTitle string
	newList := []Product{}
	for _, p := range productsList {
		if p.ID == req.ProductID {
			deletedProductTitle = p.Title
			found = true
			continue
		}
		newList = append(newList, p)
	}

	if !found {
		json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "message": "المنتج غير موجود"})
		return
	}

	productsList = newList
	saveProducts()

	// حذف الطلبات المرتبطة بهذا المنتج تلقائياً
	if deletedProductTitle != "" {
		newOrdersList := []Order{}
		for _, ord := range ordersList {
			if !strings.Contains(ord.ProductName, deletedProductTitle) {
				newOrdersList = append(newOrdersList, ord)
			}
		}
		ordersList = newOrdersList
		saveOrders()
	}

	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "message": "تم حذف المنتج وطلباته المرتبطة بنجاح"})
}

func main() {
	loadProducts()
	loadUsers()
	loadOrders()

	mux := http.NewServeMux()
	
	mux.HandleFunc("/api/auth/register", enableCors(registerHandler))
	mux.HandleFunc("/api/auth/login", enableCors(loginHandler))
	mux.HandleFunc("/api/auth/check-status", enableCors(checkUserStatusHandler))

	mux.HandleFunc("/api/products", enableCors(getProducts))
	mux.HandleFunc("/api/products/category", enableCors(getProductsByCategory))
	mux.HandleFunc("/api/products/add", enableCors(addProduct))
	mux.HandleFunc("/api/categories", enableCors(getCategories))
	mux.HandleFunc("/api/orders/create", enableCors(createOrderHandler))
	
	mux.HandleFunc("/api/admin/stats", enableCors(adminAuthMiddleware(getAdminStats)))
	mux.HandleFunc("/api/admin/users", enableCors(adminAuthMiddleware(getAdminUsers)))
	mux.HandleFunc("/api/admin/orders", enableCors(adminAuthMiddleware(getAdminOrders)))
	mux.HandleFunc("/api/admin/users/ban", enableCors(adminAuthMiddleware(banUserHandler)))
	mux.HandleFunc("/api/admin/users/delete", enableCors(adminAuthMiddleware(deleteUserHandler)))
	mux.HandleFunc("/api/products/delete", enableCors(adminAuthMiddleware(deleteProductHandler)))

	log.Println("🚀 Secure Go Backend with Validation is running on http://localhost:8080")
	http.ListenAndServe(":8080", mux)
}