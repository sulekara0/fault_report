# Firebase Kurulum Rehberi

## Web için Firebase Hatası Çözümü

Bu dosya Firebase "api-key-not-valid" hatasını çözmek için adım adım rehberdir.

## 1. Firebase Console'a Gidin

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi seçin: `fault-8506366`

## 2. Web App Ayarları

1. Sol menüden "Project Settings" (Proje Ayarları) seçin
2. "General" sekmesinde aşağıya kaydırın
3. "Your apps" bölümünde web app'inizi bulun
4. ⚙️ (ayarlar) ikonuna tıklayın
5. "Firebase SDK snippet" altında "Config" seçin

## 3. Doğru Konfigürasyonu Kopyalayın

Şu şekilde bir config görmelisiniz:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...", // Bu 39 karakter uzunluğunda olmalı
  authDomain: "fault-8506366.firebaseapp.com",
  projectId: "fault-8506366",
  storageBucket: "fault-8506366.appspot.com",
  messagingSenderId: "884446641689",
  appId: "1:884446641689:web:...",
  measurementId: "G-..."
};
```

## 4. Firebase_options.dart Dosyasını Güncelleyin

`lib/firebase_options.dart` dosyasındaki web konfigürasyonunu yukarıdaki değerlerle güncelleyin.

## 5. Authentication Ayarları

1. Firebase Console'da "Authentication" seçin
2. "Sign-in method" sekmesine gidin
3. "Email/Password" yöntemini etkinleştirin

## 6. Firestore Database Ayarları

1. Firebase Console'da "Firestore Database" seçin
2. Database'i etkinleştirin
3. Test modunda başlatın (geliştirme için)

## 7. Web Domain Ayarları

1. Authentication > Settings > Authorized domains
2. Localhost ve domain'inizi ekleyin:
   - `localhost`
   - `127.0.0.1`
   - Canlı domain'iniz (varsa)

## Olası Hatalar ve Çözümleri

### "api-key-not-valid"
- API anahtarının doğru ve tam olduğundan emin olun
- Web uygulaması için doğru config kullandığınızdan emin olun

### "operation-not-allowed"
- Firebase Console'da Email/Password authentication'ın etkin olduğundan emin olun

### "network-request-failed"
- İnternet bağlantınızı kontrol edin
- CORS sorunu varsa development için --disable-web-security kullanın

## Test Adımları

1. Web uygulamasını çalıştırın: `flutter run -d chrome`
2. Admin Login sayfasına gidin
3. "İlk Admin Hesabını Oluştur" butonuna tıklayın
4. Formu doldurun ve test edin

## Önemli Notlar

- API anahtarı public'tir, gizli değildir
- Firebase kuralları ile güvenliği sağlayın
- Production'da Firestore kurallarını güncelleyin
