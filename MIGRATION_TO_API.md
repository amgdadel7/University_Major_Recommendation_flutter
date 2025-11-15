# Migration from Mock Data to Real API

## ✅ Completed Migration

تم بنجاح تحويل تطبيق Flutter من استخدام البيانات الوهمية إلى الاستخدام الـ API الحقيقي.

## 📦 What Was Added

### 1. Dependencies
- `http: ^1.1.0` - لإجراء طلبات HTTP

### 2. New Files Created

#### Data Models
- `lib/data/models/university_model.dart` - نموذج بيانات الجامعات
- `lib/data/models/major_model.dart` - نموذج بيانات التخصصات
- `lib/data/models/recommendation_model.dart` - نموذج بيانات التوصيات
- `lib/data/models/application_model.dart` - نموذج بيانات التطبيقات
- `lib/data/models/user_model.dart` - نموذج بيانات المستخدم

#### Services
- `lib/core/services/api_service.dart` - خدمة API مركزية لجميع طلبات HTTP
- `lib/core/constants/api_constants.dart` - ثوابت API URLs و Endpoints

## 🔄 What Was Updated

### 1. Authentication (AuthBloc)
- ✅ تم تحديث `AuthBloc` لاستخدام API الحقيقي للـ Login/Register
- ✅ تم إضافة دعم لحفظ Token في SharedPreferences
- ✅ تم إضافة دعم لـ CheckAuth للمستخدمين المسجلين

### 2. Pages Updated
- ✅ `UniversitiesPage` - جلب قائمة الجامعات من API
- ✅ `RecommendationsPage` - جلب التوصيات من API
- ✅ `ApplicationsListPage` - جلب التطبيقات من API
- ✅ تم إزالة جميع البيانات الوهمية من الصفحات المذكورة

### 3. Features Added
- ✅ Loading states - إظهار CircularProgressIndicator أثناء التحميل
- ✅ Error handling - معالجة الأخطاء وعرض رسائل خطأ
- ✅ Retry functionality - إمكانية إعادة المحاولة عند الفشل
- ✅ Empty states - إظهار رسائل عندما لا توجد بيانات

## 🚀 API Endpoints Used

### Authentication
- `POST /api/v1/auth/login` - تسجيل الدخول
- `POST /api/v1/auth/register` - التسجيل
- `GET /api/v1/auth/me` - الحصول على بيانات المستخدم الحالي

### Universities
- `GET /api/v1/universities` - قائمة الجامعات
- `GET /api/v1/universities/:id/majors` - تخصصات جامعة معينة

### Majors
- `GET /api/v1/majors` - قائمة التخصصات
- `GET /api/v1/majors/:id` - تفاصيل تخصص معين

### Recommendations
- `GET /api/v1/recommendations` - قائمة التوصيات

### Applications
- `GET /api/v1/applications` - قائمة التطبيقات
- `POST /api/v1/applications` - تقديم طلب جديد
- `PATCH /api/v1/applications/:id/status` - تحديث حالة الطلب

## ⚙️ Configuration

### API Base URL
قم بتحديث `API_BASE_URL` في ملف:
`lib/core/constants/api_constants.dart`

```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

**ملاحظة:** لاستخدام API على جهاز Android/iOS حقيقي، يجب تغيير `localhost` إلى IP الفعلي للجهاز الذي يعمل عليه الـ API.

مثال:
```dart
static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
```

أو على الإنتاج:
```dart
static const String baseUrl = 'https://your-domain.com/api/v1';
```

## 🔐 Authentication Flow

1. User logs in → API returns JWT token
2. Token saved in SharedPreferences
3. Token added to all API requests as Bearer token
4. On app restart, token loaded and validated
5. If token invalid, user redirected to login

## 📱 Usage Example

```dart
// Get API service instance
final apiService = ApiService();

// Login
final response = await apiService.login(email, password, role);
final token = response['data']['token'];
apiService.setToken(token);

// Fetch universities
final universities = await apiService.getUniversities();

// Fetch recommendations
final recommendations = await apiService.getRecommendations();
```

## 🧪 Testing

للتحقق من أن كل شيء يعمل:

1. تأكد من تشغيل API server:
```bash
cd API
npm start
```

2. تحقق من أن API يعمل على:
   - Health check: `http://localhost:8000/health`
   - Swagger docs: `http://localhost:8000/api-docs`

3. قم بتشغيل تطبيق Flutter:
```bash
cd University_Major_Recommendation_flutter
flutter run
```

4. جرّب:
   - تسجيل الدخول
   - عرض قائمة الجامعات
   - عرض التوصيات
   - عرض التطبيقات

## ⚠️ Important Notes

1. **CORS Settings**: تأكد من أن الـ API يسمح بـ CORS من تطبيق Flutter
2. **Network**: على Android/iOS، استخدم IP الفعلي بدلاً من localhost
3. **SSL**: للإنتاج، استخدم HTTPS
4. **Token Expiry**: Tokens لها تاريخ انتهاء، يجب تجديدها

## 📝 Next Steps

- [ ] إضافة Pull-to-Refresh للصفحات
- [ ] إضافة Caching للبيانات
- [ ] إضافة Pagination للقوائم الكبيرة
- [ ] تحديث صفحات التفاصيل (University Details, Major Details) لاستخدام API
- [ ] إضافة Offline support
- [ ] إضافة Image caching
- [ ] إضافة Error logging

## 🐛 Troubleshooting

### "Failed to connect"
- تأكد من أن API server يعمل
- تحقق من IP address و Port
- تأكد من إعدادات CORS في API

### "Unauthorized"
- تأكد من إضافة Token بشكل صحيح
- تحقق من أن Token لم ينتهِ صلاحيته
- أعد تسجيل الدخول

### "No data returned"
- تحقق من أن قاعدة البيانات تحتوي على بيانات
- تحقق من API logs
- استخدم Swagger docs للتحقق من الـ endpoints

## 👥 Contributors

تم تنفيذ هذه المهمة بواسطة Auto Agent

## 📅 Date

تم إكمال الهجرة في: 2024

