# دليل الإعداد - Setup Guide

## 🚀 خطوات التشغيل - Setup Steps

### 1️⃣ متطلبات النظام - Prerequisites

قبل البدء، تأكد من تثبيت:
- Flutter SDK (الإصدار 3.0.0 أو أحدث)
- Android Studio أو VS Code
- Git

### 2️⃣ تثبيت Flutter

#### Windows:
```bash
# قم بتحميل Flutter SDK من الموقع الرسمي
# https://docs.flutter.dev/get-started/install/windows

# أضف Flutter إلى PATH
# اتبع التعليمات في الموقع الرسمي
```

#### macOS:
```bash
# قم بتحميل Flutter SDK
# https://docs.flutter.dev/get-started/install/macos

# أضف Flutter إلى PATH
export PATH="$PATH:`pwd`/flutter/bin"
```

### 3️⃣ التحقق من التثبيت - Verify Installation

```bash
flutter doctor
```

### 4️⃣ تثبيت المكتبات - Install Dependencies

```bash
# في مجلد المشروع
cd University_Major_Recommendation_flutter

# تثبيت المكتبات
flutter pub get
```

### 5️⃣ تحميل الخطوط - Download Fonts

يستخدم التطبيق خط Cairo للدعم العربي:

1. قم بزيارة: https://fonts.google.com/specimen/Cairo
2. قم بتحميل الخط
3. ضع الملفات في مجلد `assets/fonts/`:
   - `Cairo-Regular.ttf`
   - `Cairo-Bold.ttf`

### 6️⃣ تشغيل التطبيق - Run the App

```bash
# تشغيل على محاكي أو جهاز متصل
flutter run

# تشغيل في وضع Hot Reload
flutter run --hot
```

### 7️⃣ بناء التطبيق - Build the App

#### Android APK:
```bash
flutter build apk --release
```

#### Android App Bundle:
```bash
flutter build appbundle --release
```

#### iOS:
```bash
flutter build ios --release
```

## 🎨 تخصيص التطبيق - Customization

### تغيير الألوان - Changing Colors

عدّل ملف `lib/core/theme/app_colors.dart`:

```dart
// الألوان الأساسية
static const Color primaryLight = Color(0xFF6366F1);
static const Color secondaryLight = Color(0xFF8B5CF6);
```

### إضافة ترجمات - Adding Translations

1. افتح `assets/translations/ar.json` أو `en.json`
2. أضف المفاتيح والقيم الجديدة
3. استخدمها في الكود:

```dart
Text('your_key'.tr())
```

### إضافة صفحة جديدة - Adding New Page

1. أنشئ ملف الصفحة في `lib/features/your_feature/presentation/pages/`
2. أضف المسار في `lib/core/router/app_router.dart`
3. استخدم التنقل:

```dart
context.push('/your-route');
```

## 🔧 حل المشاكل الشائعة - Troubleshooting

### المشكلة: لا تظهر الترجمات
**الحل:**
```bash
flutter clean
flutter pub get
flutter run
```

### المشكلة: أخطاء في البناء
**الحل:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

### المشكلة: الخطوط لا تعمل
**الحل:**
- تأكد من وجود ملفات الخطوط في `assets/fonts/`
- تأكد من تسجيل الخطوط في `pubspec.yaml`
- قم بتشغيل `flutter clean` ثم `flutter run`

## 📱 اختبار على أجهزة حقيقية - Testing on Real Devices

### Android:
1. فعّل وضع المطور على هاتفك
2. فعّل USB Debugging
3. وصّل الهاتف بالكمبيوتر
4. شغّل `flutter devices` للتأكد
5. شغّل `flutter run`

### iOS:
1. وصّل iPhone بجهاز Mac
2. افتح Xcode
3. قم بتسجيل الدخول بحساب Apple Developer
4. شغّل `flutter run`

## 🎯 الخطوات التالية - Next Steps

1. **الربط بـ Backend:**
   - استبدل البيانات الوهمية (Mock Data) ببيانات حقيقية من API
   - أضف مكتبة `http` أو `dio` للطلبات
   - أنشئ طبقة Repository للتعامل مع البيانات

2. **إضافة Firebase:**
   ```bash
   flutter pub add firebase_core
   flutter pub add firebase_auth
   flutter pub add cloud_firestore
   ```

3. **إضافة التحليلات:**
   ```bash
   flutter pub add firebase_analytics
   ```

4. **إضافة الإشعارات:**
   ```bash
   flutter pub add firebase_messaging
   flutter pub add flutter_local_notifications
   ```

## 📚 موارد إضافية - Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Material Design 3](https://m3.material.io)
- [Flutter Bloc Documentation](https://bloclibrary.dev)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Easy Localization](https://pub.dev/packages/easy_localization)

## 💡 نصائح للتطوير - Development Tips

1. **استخدم Hot Reload:**
   - اضغط `r` في Terminal لإعادة التحميل السريع
   - اضغط `R` لإعادة التشغيل الكامل

2. **استخدم DevTools:**
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

3. **تحسين الأداء:**
   - استخدم `const` constructors حيثما أمكن
   - استخدم `flutter analyze` للتحقق من الكود
   - استخدم `flutter test` لاختبار التطبيق

## 🤝 المساهمة - Contributing

نرحب بمساهماتكم! يرجى:
1. Fork المشروع
2. إنشاء branch جديد للميزة
3. Commit التغييرات
4. Push إلى الـ branch
5. فتح Pull Request

## 📞 الدعم - Support

للمساعدة والاستفسارات:
- فتح Issue في GitHub
- التواصل عبر البريد الإلكتروني

---

**تم التطوير بـ ❤️ باستخدام Flutter**

