# إعداد Windows لـ Flutter

## المشكلة: Building with plugins requires symlink support

عندما تحصل على هذه الرسالة:
```
Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

## الحل السريع:

### الطريقة 1: تفعيل Developer Mode (الأسهل)

1. **افتح إعدادات Windows:**
   - اضغط `Windows + I` أو
   - اكتب في CMD/PowerShell:
     ```powershell
     start ms-settings:developers
     ```

2. **في إعدادات Developer:**
   - ابحث عن "Developer Mode" أو "وضع المطور"
   - فعّل "Developer Mode" أو "Use developer features"
   - قد يطلب منك إعادة تشغيل الكمبيوتر

3. **بعد إعادة التشغيل:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### الطريقة 2: تفعيل Symlink من PowerShell (Administrator)

إذا لم تريد تفعيل Developer Mode، يمكنك تفعيل symlink يدوياً:

1. **افتح PowerShell كـ Administrator:**
   - اضغط `Windows + X`
   - اختر "Windows PowerShell (Admin)" أو "Terminal (Admin)"

2. **شغّل هذا الأمر:**
   ```powershell
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "SymlinkEvaluation" -Value 1 -PropertyType DWord -Force
   ```

3. **أعد تشغيل الكمبيوتر**

4. **جرّب مرة أخرى:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### الطريقة 3: استخدام Flutter بدون Symlinks (مؤقت)

إذا كنت تريد تجنب المشكلة مؤقتاً:

```bash
flutter run --no-sound-null-safety
```

أو استخدم:
```bash
flutter build apk --no-sound-null-safety
```

## ملاحظات مهمة:

- **Developer Mode** هو الحل الأفضل والأكثر أماناً
- بعد تفعيله، لن تواجه هذه المشكلة مرة أخرى
- لا يؤثر Developer Mode على أمان النظام بشكل كبير
- إذا كنت تستخدم Windows 11، قد يكون المسار مختلف قليلاً

## التحقق من أن المشكلة تم حلها:

بعد تفعيل Developer Mode، شغّل:
```bash
flutter doctor
```

يجب أن ترى أن كل شيء يعمل بشكل صحيح.

