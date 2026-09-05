import 'dart:convert';
import 'package:http/http.dart' as http;

/// Backend sunucumuzun adresi. Bilgisayarında çalışırken bu adres geçerli.
/// İleride backend'i internete koyduğumuzda burayı gerçek bir URL ile
/// değiştireceğiz (örn. https://poseidon-backend.up.railway.app).
const String apiBaseUrl = 'http://localhost:3000';

/// Tüm veritabanı okuma/yazma işlemleri burada toplanır.
/// Ekranlar artık Firestore'u değil, kendi backend'imizi çağırıyor.
class DatabaseService {
  /// Giriş yaptıktan sonra sunucudan aldığımız token burada tutulur.
  /// Uygulama kapanınca kaybolur (kalıcı hafızaya kaydetmiyoruz, bu yüzden
  /// her açılışta tekrar giriş yapman gerekir — ileride bunu da geliştirebiliriz).
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  bool get girisYapilmisMi => _token != null;

  /// Her isteğe otomatik olarak "Authorization: Bearer <token>" başlığını
  /// ekleyen ortak bir yardımcı fonksiyon. Böylece her fonksiyonda bunu
  /// tekrar tekrar yazmamıza gerek kalmıyor.
  Map<String, String> get _headers {
    final baslik = {'Content-Type': 'application/json'};
    if (_token != null) {
      baslik['Authorization'] = 'Bearer $_token';
    }
    return baslik;
  }

  // ---------------- KİMLİK DOĞRULAMA ----------------

  Future<Map<String, dynamic>> girisYap(String email, String sifre) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': sifre}),
    );
    final govde = jsonDecode(response.body);
    if (response.statusCode == 200) {
      setToken(govde['token']);
      return govde;
    }
    throw Exception(govde['mesaj'] ?? 'Giriş yapılamadı');
  }

  Future<void> kayitOl({
    required String email,
    required String sifre,
    required String rol,
    int? sporcuId,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': sifre,
        'role': rol,
        'athlete_id': sporcuId,
      }),
    );
    if (response.statusCode != 201) {
      final govde = jsonDecode(response.body);
      throw Exception(govde['mesaj'] ?? 'Kayıt oluşturulamadı');
    }
  }

  void cikisYap() {
    setToken(null);
  }

  // ---------------- ORTAK HATA KONTROLÜ ----------------

  /// 401 (giriş gerekli) ya da 403 (yetki yok) gibi durumlarda,
  /// sunucunun gönderdiği gerçek mesajı kullanıcıya gösterelim.
  Never _hataFirlat(http.Response response, String varsayilanMesaj) {
    String mesaj = varsayilanMesaj;
    try {
      final govde = jsonDecode(response.body);
      if (govde is Map && govde['mesaj'] is String) {
        mesaj = govde['mesaj'] as String;
      }
    } on FormatException {
      // HTML veya boş hata yanıtında varsayılan mesaj kullanılır.
    }
    throw Exception(mesaj);
  }

  // ---------------- SPORCULAR ----------------

  Future<List<dynamic>> getSporcular() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/athletes'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _hataFirlat(response, 'Sporcular getirilemedi');
  }

  /// Kayıt ekranında veli çocuğunu seçebilsin diye
  /// giriş yapmadan sporcu listesini getirir.
  Future<List<dynamic>> getKayitSporcular() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/athletes/register-list'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _hataFirlat(response, 'Kayıt için sporcular getirilemedi');
  }

  Future<void> sporcuEkle(Map<String, dynamic> veri) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/athletes'),
      headers: _headers,
      body: jsonEncode(veri),
    );

    if (response.statusCode != 201) {
      _hataFirlat(response, 'Sporcu eklenemedi');
    }
  }

  Future<void> sporcuGuncelle(int id, Map<String, dynamic> veri) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl/athletes/$id'),
      headers: _headers,
      body: jsonEncode(veri),
    );
    if (response.statusCode != 200) {
      _hataFirlat(response, 'Sporcu güncellenemedi');
    }
  }

  Future<void> sporcuSil(int id) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/athletes/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      _hataFirlat(response, 'Sporcu silinemedi');
    }
  }

  // ---------------- ANTRENMANLAR ----------------

  Future<List<dynamic>> getAntrenmanlar() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/trainings'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _hataFirlat(response, 'Antrenmanlar getirilemedi');
  }

  Future<void> antrenmanEkle(Map<String, dynamic> veri) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/trainings'),
      headers: _headers,
      body: jsonEncode(veri),
    );
    if (response.statusCode != 201) {
      _hataFirlat(response, 'Antrenman eklenemedi');
    }
  }

  // ---------------- PERFORMANS ----------------

  Future<List<dynamic>> getPerformans(int sporcuId) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/performance?athleteId=$sporcuId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _hataFirlat(response, 'Performans kayıtları getirilemedi');
  }

  Future<void> performansEkle(Map<String, dynamic> veri) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/performance'),
      headers: _headers,
      body: jsonEncode(veri),
    );
    if (response.statusCode != 201) {
      _hataFirlat(response, 'Performans kaydı eklenemedi');
    }
  }

  Future<List<dynamic>> getTumPerformanslar() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/performance'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _hataFirlat(response, 'Performans kayıtları getirilemedi');
  }

  Future<List<dynamic>> getSiralama({
    required String stil,
    required String mesafe,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$apiBaseUrl/rankings'
        '?stil=${Uri.encodeComponent(stil)}'
        '&mesafe=${Uri.encodeComponent(mesafe)}',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _hataFirlat(response, 'Sıralama getirilemedi');
  }
  // ---------------- SPORCU KARNELERİ ----------------

  Future<void> karneEkle(Map<String, dynamic> veri) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/report-cards'),
      headers: _headers,
      body: jsonEncode(veri),
    );

    if (response.statusCode != 201) {
      _hataFirlat(response, 'Karne oluşturulamadı');
    }
  }

  Future<List<dynamic>> getKarneler({int? sporcuId}) async {
    final url = sporcuId != null
        ? '$apiBaseUrl/report-cards?athleteId=$sporcuId'
        : '$apiBaseUrl/report-cards';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _hataFirlat(response, 'Karneler getirilemedi');
  }

  Future<Map<String, dynamic>> getKarne(int karneId) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/report-cards/$karneId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    _hataFirlat(response, 'Karne getirilemedi');
  }
  // ---------------- YOKLAMA (GİRİŞ / ÇIKIŞ) ----------------

  /// [antrenmanId] ve/veya [sporcuId] verilirse sonuçlar buna göre filtrelenir.
  /// Antrenör hiçbirini vermezse tüm kayıtları görür; veli/sporcu için
  /// backend zaten sadece kendi sporcusununkini döner.
  Future<List<dynamic>> getYoklama({int? antrenmanId, int? sporcuId}) async {
    final parametreler = <String>[];
    if (antrenmanId != null) parametreler.add('trainingId=$antrenmanId');
    if (sporcuId != null) parametreler.add('athleteId=$sporcuId');
    final sorgu = parametreler.isNotEmpty ? '?${parametreler.join('&')}' : '';

    final response = await http.get(
      Uri.parse('$apiBaseUrl/attendance$sorgu'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _hataFirlat(response, 'Yoklama kayıtları getirilemedi');
  }

  /// QR okutularak derse GİRİŞ kaydı oluşturur.
  Future<void> yoklamaGirisYap({
    required int antrenmanId,
    required int sporcuId,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/attendance'),
      headers: _headers,
      body: jsonEncode({
        'training_id': antrenmanId,
        'athlete_id': sporcuId,
        'tip': 'giris',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _hataFirlat(response, 'Giriş kaydedilemedi');
    }
  }

  /// QR okutularak dersten ÇIKIŞ kaydı oluşturur.
  Future<void> yoklamaCikisYap({
    required int antrenmanId,
    required int sporcuId,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/attendance'),
      headers: _headers,
      body: jsonEncode({
        'training_id': antrenmanId,
        'athlete_id': sporcuId,
        'tip': 'cikis',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _hataFirlat(response, 'Çıkış kaydedilemedi');
    }
  }

  // ---------------- AİDAT ----------------

  Future<List<dynamic>> getAidatlar({int? sporcuId}) async {
    final url = sporcuId != null
        ? '$apiBaseUrl/dues?athleteId=$sporcuId'
        : '$apiBaseUrl/dues';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _hataFirlat(response, 'Aidatlar getirilemedi');
  }

  Future<void> aidatEkle(Map<String, dynamic> veri) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/dues'),
      headers: _headers,
      body: jsonEncode(veri),
    );

    if (response.statusCode != 201) {
      _hataFirlat(response, 'Aidat eklenemedi');
    }
  }

  Future<void> aidatOdendiIsaretle(int aidatId) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/dues/$aidatId/pay'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      _hataFirlat(response, 'Ödeme işaretlenemedi');
    }
  }

  /// Antrenörün belirlediği son ödeme tarihini
  /// mevcut ayın aidatlarına uygular.
  Future<void> aidatSonOdemeTarihiGuncelle(String tarih, {String? ay}) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/dues/deadline'),
      headers: _headers,
      body: jsonEncode({'tarih': tarih, 'ay': ay ?? _guncelAyApi()}),
    );

    if (response.statusCode != 200) {
      _hataFirlat(response, 'Aidat son ödeme tarihi güncellenemedi');
    }
  }

  String _guncelAyApi() {
    final simdi = DateTime.now();

    return '${simdi.year}-'
        '${simdi.month.toString().padLeft(2, '0')}';
  }

  // ---------------- KULLANICI YÖNETİMİ (VELİ / SPORCU HESAPLARI) ----------------

  /// Antrenör panelinde: sisteme kayıtlı tüm veli/sporcu hesaplarını listeler.
  Future<List<dynamic>> getKullanicilar() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/users'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _hataFirlat(response, 'Kullanıcılar getirilemedi');
  }

  /// Antrenör, doğrudan bir veli/sporcu hesabı açar; isterse aynı anda
  /// bir sporcu kaydıyla eşleştirir (sporcuId null bırakılabilir).
  Future<void> kullaniciEkle({
    required String email,
    required String sifre,
    required String rol,
    int? sporcuId,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/users'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': sifre,
        'role': rol,
        'athlete_id': sporcuId,
      }),
    );
    if (response.statusCode != 201) {
      _hataFirlat(response, 'Kullanıcı eklenemedi');
    }
  }

  /// Var olan bir veli/sporcu hesabının bağlı olduğu sporcuyu değiştirir.
  Future<void> kullaniciSporcuEslestir(int kullaniciId, int? sporcuId) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/users/$kullaniciId/link-athlete'),
      headers: _headers,
      body: jsonEncode({'athlete_id': sporcuId}),
    );
    if (response.statusCode != 200) {
      _hataFirlat(response, 'Eşleştirme güncellenemedi');
    }
    final sonuc = jsonDecode(response.body);
    if (sonuc is! Map ||
        sonuc['id']?.toString() != kullaniciId.toString() ||
        !sonuc.containsKey('athlete_id') ||
        sonuc['athlete_id']?.toString() != sporcuId?.toString()) {
      throw Exception(
        'Sunucu beklenen eşleştirmeyi doğrulamadı. Listeyi yenileyip kontrol et.',
      );
    }
    // Okuma yolunda da aynı bağlantının döndüğünü kontrol et.
    final hesaplar = await getKullanicilar();
    final hesap = hesaplar.firstWhere(
      (k) => k['id'].toString() == kullaniciId.toString(),
      orElse: () => null,
    );
    if (hesap == null ||
        hesap['athlete_id']?.toString() != sporcuId?.toString()) {
      throw Exception(
        'Kaydetme yanıtı alındı ancak hesap listesinde eşleştirme doğrulanamadı. Listeyi yenile.',
      );
    }
  }

  /// Bir veli/sporcu hesabının erişimini tamamen kaldırır.
  Future<void> kullaniciSil(int id) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/users/$id'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      _hataFirlat(response, 'Kullanıcı silinemedi');
    }
  }

  // ---------------- ŞİFRE SIFIRLAMA ----------------

  /// E-posta adresine 6 haneli bir sıfırlama kodu gönderilmesini ister.
  Future<void> sifremiUnuttum(String email) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      _hataFirlat(response, 'Kod gönderilemedi');
    }
  }

  /// E-postaya gelen kod ile yeni şifreyi belirler.
  Future<void> sifreSifirla({
    required String email,
    required String kod,
    required String yeniSifre,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'kod': kod, 'yeniSifre': yeniSifre}),
    );
    if (response.statusCode != 200) {
      _hataFirlat(response, 'Şifre güncellenemedi');
    }
  }
}
