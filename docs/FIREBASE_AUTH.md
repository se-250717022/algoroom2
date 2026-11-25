# Telefon ve Google girişi

Varsayılan derleme giriş ekranını ve yerel demoyu açar. Gerçek giriş için kendi Firebase projenle bir yetkilendirme derlemesi çalıştır.

1. Firebase Console'da Android uygulamasını `com.roommateapp.roommate` paket adıyla kaydet. Kullanacağın imza anahtarlarının SHA-1 ve SHA-256 parmak izlerini ekle. Geliştirme sertifikasını Android klasöründe `./gradlew signingReport` komutuyla bulabilirsin.
2. Authentication bölümünde Phone ve Google sağlayıcılarını etkinleştir. SMS bölge politikasında Türkiye'ye izin ver. İlk doğrulamada Firebase test numaralarını kullan.
3. Firebase'deki platform yapılandırmasından API key, App ID, Sender ID ve Project ID değerlerini al. Android Google girişi için aynı projenin **Web application OAuth client ID** değerini kullan.
4. Proje kökünde Git tarafından yok sayılan `firebase-auth.local.json` dosyasını oluştur. Örnek alanların değerlerini kendi projenle doldur.

```json
{
  "ROOMMATE_AUTH": "true",
  "FIREBASE_API_KEY": "",
  "FIREBASE_APP_ID": "",
  "FIREBASE_SENDER_ID": "",
  "FIREBASE_PROJECT_ID": "",
  "GOOGLE_WEB_CLIENT_ID": ""
}
```

```powershell
flutter pub get
flutter run --dart-define-from-file=firebase-auth.local.json
```

iOS için iOS Firebase App ID ve API key kullan. `GOOGLE_IOS_CLIENT_ID` alanını ekle. Xcode URL Types içinde tersine çevrilmiş Google iOS client ID ve Firebase Encoded App ID şemalarını kaydet. SMS için Firebase'e APNs anahtarını ekle ve Xcode'da Push Notifications ile Background Modes yetkilerini yapılandır.

Web için web hedefini oluştur, web uygulamasına ait Firebase değerlerini ve `FIREBASE_AUTH_DOMAIN` alanını kullan. Firebase Authentication yetkili alan adlarına kendi geliştirme ve yayın alan adlarını ekle. SMS akışı Firebase reCAPTCHA doğrulamasını kullanır.

Başarılı girişten sonra uygulama kurgusal demo kataloğunu gösterir. Hesap menüsünden oturumu kapatabilirsin. SMS ve Google hesabını aynı kullanıcıya bağlama özelliği bu aşamada bulunmuyor.

[Flutter Firebase telefon doğrulama](https://firebase.google.com/docs/auth/flutter/phone-auth) · [Google giriş akışı](https://firebase.google.com/docs/auth/flutter/federated-auth) · [iOS telefon kurulumu](https://firebase.google.com/docs/auth/ios/phone-auth)
