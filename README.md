# poseidon_os

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
-------------VELİ KAYIT------------------
deneme@gmail.com-12345678   
emiraydogan02@gmail.com-12345678
----------------YAPILMASI GEREKENLER-------------------
+*Antremanlar ekranında bulunan antremanlar için o sekmede geçmiş antremanlar bölümü olsun oraya girildiğinde sadece son 7 günde olan antremanlar gözüksün 7 günden sonraki antremanlar silinsin.+(Zamanla kontrol et )
+*Fiziksel uygunluk karnesi oluşturulsun.Çocukların vücut kütle indeksi,otur eriş testi,Sırt kaşıma Test,flamingo denge testi.Antremanlara yeterli katılım yapıp yapmadığınıda sistemdeki giriş çıkışlardan alsın.
++*Antrenör her öğrencinin bütün stillerini değerlendireceği bir panel olsun.Örneğin Geliştirilmeli-orta düzey-başarılı şeklinde 
+*Qr kod yoklmasında sadece sayılar gözüküyo velinin çocuğunun giriş ve çıkışını takip etmesi gerekiyor--claude  emiraydogan02
-----PROFİL Sekmesi------------
+*Bu karneler sporcu ve veli arayüzünde profil sekmesinde gözüksün-2230656819 cloud
+*Sporcu ve Veli profilinde yüzücünün yarıştığı yarışlar ile yaptığı dereceleri gösterelim-2230656819 cloud
-------SPORCU PANELİ------------
---------------GÜvenlik----------
*Şifremi unuttum işlemi için domain alınmalı
                                 DEĞİŞİKLİKLER
+-yarış derecelerinde mesafeleri 400-800-1500 şeklinde eklemeleri yap
+-1,2,3,4,5 şeklinde derecelendirme sistemi getirilicek karneye.
+-Altyapı ve performans grubunun antremanları ayrı olucak.Her grup kendi antremanını görsün.
-Veli kayıt oluşturduğunda antrenöre onay kodu gelsin.Antrenör onay vermeden veli hesap oluşturmasın.
+-Veli ödeme geçmişini görebilsin.Tarihlere göre ayarla 
+-Takvim sekmesinde yarışlar,ödeme,tatiller farklı renkler ile belirlensin.
-Veli grafiklri olan karneyi göremiyr onu düzelt
+-Takvim sekmesinde gözüken yarış tarihlerinde o yarışta kullanılması gereken belgeleri veliler görsün.
-Uygulama başında sözleşme onay formu gelecek.
1. Veli–çocuk eşleşmesinin doğrulanması
Şu an listeden boşta olan çocuğu seçmek, o çocuğun gerçekten velisi olduğunu kanıtlamıyor. Yanlış kişi bir çocuğu seçebilir.
İstediğin kayıt akışını koruyabiliriz: veli kayıt olur, çocuğunu seçer; antrenör eşleşmeyi onaylayınca çocuğun bilgileri açılır. Antrenöre yalnızca bir onay işlemi düşer.
2. Aidat yetkileri ve ödeme onayı
İncelediğim index.js içindeki /dues/:id/pay işleminde giriş kontrolü var, ancak aidatın hangi veliye ait olduğu kontrol edilmiyor. Bu, yayına çıkmadan düzeltilmeli. Ekrandaki butonu gizlemek yeterli değil; sunucu her istekte yetkiyi doğrulamalı. OWASP Cheat Sheet Series
Ödeme akışını da şöyle tamamlamak daha doğru olur:
Ödenmedi → Veli dekont gönderdi → Onay bekliyor → Antrenör onayladı → Ödendi
3. Uygulama kapalıyken bildirim
Yoklama bilgisinin panelde görünmesiyle telefona bildirim gelmesi farklı şeyler. Hazırladığımız yoklama paneli açıkken yenileniyor; uygulama kapalıyken giriş–çıkış bildirimi gönderen sistem henüz kurulmadı.
4. Karne değerlendirmelerinin dayanağı
Teknik değerlendirmede belirlediğin ortalama > 3 kuralı net. Ancak fiziksel testlerde kullanılan yaş/cinsiyet eşikleri kodda sabit. Bunların antrenör tarafından kabul edilen kaynaklarla doğrulanması gerekiyor. Ayrıca sadece doğum yılı bilinen çocuklarda kesin yaşa dayalı değerlendirmeyi eksiksizmiş gibi göstermemeliyiz.
5. Günlük kullanımda hataları düzeltme
Antrenörün yanlış girdiği yoklama, derece, karne veya antrenmanı düzeltebilmesi, kimin neyi değiştirdiğinin kaydedilmesi önemli. Kulüpten ayrılan öğrenciyi tamamen silmek yerine pasife alma da geçmiş kayıtları korur.
6. Yayınlama ve gerçek kullanım denemesi
Bilgisayarına bağlı çalışmayı bırakıp HTTPS üzerinden erişilebilir hâle getirmeliyiz. Ardından birkaç veliyle telefonda kayıt, kardeşler arasında geçiş, karne karşılaştırma, dekont yükleme ve şifre sıfırlama akışlarını denemeliyiz. Düzenli yedekleme ve yedekten geri yükleme kontrolü de bu aşamanın parçası olmalı.
