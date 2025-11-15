# دليل إعداد API للتطبيق

## المشكلة الشائعة: Connection Refused

إذا كنت تحصل على خطأ `Connection refused`، فهذا يعني أن التطبيق لا يستطيع الاتصال بالـ API.

## الحلول حسب المنصة:

### 1. Android Emulator (المحاكي)

استخدم `10.0.2.2` بدلاً من `localhost`:

1. افتح `lib/core/constants/api_config.dart`
2. غير `baseUrl` إلى:
```dart
static String get baseUrl => 'http://10.0.2.2:8000/api/v1';
```

### 2. iOS Simulator (محاكي iOS)

استخدم `localhost` (يجب أن يعمل مباشرة):
```dart
static String get baseUrl => 'http://localhost:8000/api/v1';
```

### 3. الأجهزة الحقيقية (Android/iOS)

يجب استخدام IP الحاسوب:

1. **ابحث عن IP الحاسوب:**
   - **Windows:** افتح CMD واكتب `ipconfig` → ابحث عن `IPv4 Address`
   - **Mac/Linux:** افتح Terminal واكتب `ifconfig` → ابحث عن `inet`

2. **مثال:** إذا كان IP هو `192.168.1.100`:
   ```dart
   static String get baseUrl => 'http://192.168.1.100:8000/api/v1';
   ```

3. **تأكد من:**
   - الحاسوب والجهاز على نفس الشبكة WiFi
   - جدار الحماية يسمح بالاتصال على المنفذ 8000
   - الـ API يعمل على الحاسوب

### 4. Web/Desktop

استخدم `localhost`:
```dart
static String get baseUrl => 'http://localhost:8000/api/v1';
```

## إعدادات إضافية:

### السماح بالاتصالات في Android (AndroidManifest.xml)

تأكد من وجود هذه الأذونات في `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application
    android:usesCleartextTraffic="true"
    ...>
```

### إعدادات iOS (Info.plist)

تأكد من وجود هذه الإعدادات في `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## اختبار الاتصال:

1. تأكد من أن الـ API يعمل:
   ```bash
   cd university-major-recommendation-api
   npm start
   ```

2. اختبر الاتصال من المتصفح:
   - افتح `http://localhost:8000/health` (أو IP حاسوبك)
   - يجب أن ترى `{"success":true,"message":"API is running"}`

3. إذا لم يعمل، تحقق من:
   - المنفذ 8000 غير مستخدم من برنامج آخر
   - جدار الحماية يسمح بالاتصال
   - العنوان/IP صحيح

## ملاحظات مهمة:

- **للتطوير:** استخدم `10.0.2.2` للمحاكي و IP الحاسوب للأجهزة الحقيقية
- **للإنتاج:** استخدم عنوان API الخاص بك (مثل `https://api.yourdomain.com/api/v1`)
- **الأمان:** تأكد من استخدام HTTPS في الإنتاج

