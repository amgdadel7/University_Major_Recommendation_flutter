# تعليمات إنشاء أيقونة التطبيق - بوصلة الطالب

## الخطوات المطلوبة

### 1. تحويل SVG إلى PNG
تم إنشاء ملف `app_icon.svg` يحتوي على تصميم الأيقونة. تحتاج إلى تحويله إلى PNG بحجم 1024x1024 بكسل.

#### باستخدام أدوات الإنترنت:
- استخدم [CloudConvert](https://cloudconvert.com/svg-to-png) أو [Convertio](https://convertio.co/svg-png/)
- ارفع ملف `app_icon.svg`
- اضبط الحجم على 1024x1024 بكسل
- حمّل النتيجة كـ `app_icon.png` في نفس المجلد

#### باستخدام Inkscape (مجاني):
```bash
inkscape app_icon.svg --export-filename=app_icon.png --export-width=1024 --export-height=1024
```

#### باستخدام ImageMagick:
```bash
convert -background none -density 1024 app_icon.svg -resize 1024x1024 app_icon.png
```

### 2. إنشاء أيقونة Adaptive Foreground
للأيقونة التكيفية في Android، تحتاج إلى نسخة بدون خلفية:

1. افتح `app_icon.png` في محرر صور
2. احذف الخلفية الدائرية البنفسجية (اترك الخلفية شفافة)
3. احرص على أن المحتوى المهم يبقى في المنطقة المركزية (432x432 بكسل من الوسط)
4. احفظ كـ `app_icon_foreground.png`

### 3. توليد جميع الأيقونات
بعد تحضير الملفين PNG، قم بتشغيل:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

سيتم إنشاء جميع أحجام الأيقونات المطلوبة لـ Android و iOS تلقائياً.

## تصميم الأيقونة

الأيقونة تحتوي على:
- **بوصلة** (Compass): تمثل التوجيه والمساعدة في إيجاد الاتجاه الصحيح
- **رمز أكاديمي** (قبعة تخرج): تمثل الطالب والتعليم
- **ألوان**:
  - البنفسجي (#6B46C1): اللون الأساسي للتطبيق
  - الذهبي (#F59E0B): يرمز للإنجاز والأهداف
  - الأبيض: للوضوح والاحترافية

## ملاحظات مهمة

- تأكد من أن الملفات `app_icon.png` و `app_icon_foreground.png` موجودة في `assets/icons/`
- حجم كل ملف يجب أن يكون 1024x1024 بكسل
- الأيقونة التكيفية تحتاج خلفية شفافة في `app_icon_foreground.png`
- بعد توليد الأيقونات، قم بإعادة بناء التطبيق: `flutter clean && flutter pub get && flutter build`

