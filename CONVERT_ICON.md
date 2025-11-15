# دليل سريع لتحويل الأيقونة SVG إلى PNG

## الطريقة الأسهل (أونلاين)

1. **افتح أحد هذه المواقع:**
   - [CloudConvert SVG to PNG](https://cloudconvert.com/svg-to-png)
   - [Convertio SVG to PNG](https://convertio.co/svg-png/)
   - [SVG2PNG](https://svgtopng.com/)

2. **قم بالتحويل:**
   - ارفع ملف `assets/icons/app_icon.svg`
   - اضبط الحجم على: **1024 x 1024** بكسل
   - اضبط الخلفية على: **أبيض** أو **شفاف**
   - حمّل النتيجة واحفظها كـ `assets/icons/app_icon.png`

3. **لأيقونة Adaptive (Android):**
   - كرر نفس الخطوة
   - لكن احذف الخلفية الدائرية البنفسجية من الصورة (اتركها شفافة)
   - احفظ النتيجة كـ `assets/icons/app_icon_foreground.png`

## بعد التحويل

قم بتنفيذ هذه الأوامر:

```bash
cd "University_Major_Recommendation_flutter"
flutter pub get
flutter pub run flutter_launcher_icons
flutter clean
flutter pub get
```

ثم أعد بناء التطبيق.

