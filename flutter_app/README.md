# Beatify — Flutter App

Aplikasi music streaming berbasis Flutter dengan fitur streaming online, local music player, playlist, dan autentikasi pengguna.

## Prasyarat

- Flutter SDK >= 3.11.0
- Dart SDK >= 3.11.0
- Android Studio / VS Code dengan Flutter extension
- Android SDK (untuk build Android)
- Xcode (untuk build iOS, hanya di macOS)
- Akun Google Play Console (untuk deploy ke Play Store)

---

## Setup & Instalasi

```bash
# Clone repo
git clone https://github.com/koropati/beatify.git
cd beatify/flutter_app

# Install dependencies
flutter pub get

# Generate mock files (untuk unit test)
dart run build_runner build
```

---

## Menjalankan di Device / Emulator

```bash
# Lihat daftar device yang tersedia
flutter devices

# Jalankan di device tertentu
flutter run -d <device-id>

# Contoh — jalankan di emulator Android
flutter run -d emulator-5554

# Contoh - jalankan di device android
flutter run -d ZP22223GB9

# Jalankan di device fisik yang terhubung via USB
flutter run

# Jalankan dengan mode release (performa lebih baik)
flutter run --release

# Jalankan dengan mode debug (hot reload aktif)
flutter run --debug
```

---

## Build APK

```bash
# Build APK debug (untuk testing)
flutter build apk --debug

# Build APK release (untuk distribusi)
flutter build apk --release

# Build APK split per ABI (ukuran lebih kecil, direkomendasikan)
flutter build apk --split-per-abi --release

# Output file APK ada di:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  (untuk device 64-bit)
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (untuk device 32-bit)
```

---

## Build App Bundle (AAB) — untuk Play Store

```bash
# Build Android App Bundle (format wajib untuk Play Store)
flutter build appbundle --release

# Output ada di:
# build/app/outputs/bundle/release/app-release.aab
```

---

## Setup Signing (Wajib untuk Release)

Sebelum build release, buat keystore terlebih dahulu:

```bash
# Buat keystore baru (jalankan sekali saja, simpan file .jks dengan aman)
keytool -genkey -v -keystore ~/beatify-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias beatify
```

Buat file `android/key.properties`:

```properties
storePassword=<password_keystore>
keyPassword=<password_key>
keyAlias=beatify
storeFile=<path_ke_file>/beatify-keystore.jks
```

Pastikan `android/key.properties` masuk `.gitignore`.

---

## Deploy ke Google Play Store

### 1. Persiapan di Google Play Console

1. Buka [play.google.com/console](https://play.google.com/console)
2. Klik **Create app** → isi nama, bahasa, kategori
3. Lengkapi **App content** (rating, privacy policy, dll.)
4. Masuk ke **Production** → **Create new release**

### 2. Upload AAB

```bash
# Build AAB release
flutter build appbundle --release
```

Upload file `build/app/outputs/bundle/release/app-release.aab` ke Play Console.

### 3. Menggunakan Fastlane (Otomatis)

```bash
# Install fastlane
gem install fastlane

# Setup di folder android/
cd android
fastlane init

# Deploy ke internal testing
fastlane supply --aab ../build/app/outputs/bundle/release/app-release.aab \
  --track internal \
  --json_key path/to/service-account.json \
  --package_name com.satriakode.beatify
```

### 4. Versioning

Update versi di `pubspec.yaml` sebelum setiap release:

```yaml
version: 1.0.0+1
# format: <version_name>+<version_code>
# version_code harus selalu naik di setiap upload ke Play Store
```

---

## Unit Test

```bash
# Jalankan semua test
flutter test

# Jalankan test file tertentu
flutter test test/features/auth/presentation/providers/auth_providers_test.dart

# Jalankan dengan coverage
flutter test --coverage

# Lihat coverage report (perlu lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Perintah Berguna Lainnya

```bash
# Cek masalah di project
flutter analyze

# Format kode
dart format lib/

# Bersihkan build cache
flutter clean && flutter pub get

# Upgrade dependencies
flutter pub upgrade
```
