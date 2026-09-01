import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/database_service.dart';
import 'package:video_player/video_player.dart';

// ---------------- VERİ MODELLERİ ----------------
final DatabaseService dbService = DatabaseService();

class Sporcu {
  final int id;
  final String isim;
  final int dogumYili;
  final String grup;
  final String enIyiDerece;
  final String enIyiDereceStil;
  final String enIyiDereceMesafe;

  const Sporcu({
    required this.id,
    required this.isim,
    required this.dogumYili,
    required this.grup,
    required this.enIyiDerece,
    required this.enIyiDereceStil,
    required this.enIyiDereceMesafe,
  });

  factory Sporcu.fromJson(Map<String, dynamic> veri) {
    return Sporcu(
      id: int.parse(veri['id'].toString()),
      isim: veri['isim']?.toString() ?? '',
      dogumYili: int.tryParse(veri['dogum_yili']?.toString() ?? '') ?? 0,
      grup: veri['grup']?.toString() ?? '',
      enIyiDerece: veri['en_iyi_derece']?.toString() ?? '',
      enIyiDereceStil: veri['en_iyi_derece_stil']?.toString() ?? '',
      enIyiDereceMesafe: veri['en_iyi_derece_mesafe']?.toString() ?? '',
    );
  }
}

class AntrenmanSeti {
  final String kategori;
  final String aciklama;

  const AntrenmanSeti({required this.kategori, required this.aciklama});

  Map<String, dynamic> toMap() => {'kategori': kategori, 'aciklama': aciklama};

  factory AntrenmanSeti.fromMap(Map<String, dynamic> veri) {
    return AntrenmanSeti(
      kategori: veri['kategori'] ?? '',
      aciklama: veri['aciklama'] ?? '',
    );
  }
}

class Antrenman {
  final int id;
  final String baslik;
  final String tarih;
  final String havuz;
  final String sure;
  final List<AntrenmanSeti> setler;

  const Antrenman({
    required this.id,
    required this.baslik,
    required this.tarih,
    required this.havuz,
    required this.sure,
    required this.setler,
  });

  factory Antrenman.fromJson(Map<String, dynamic> veri) {
    final hamSetler = veri['setler'] as List<dynamic>? ?? [];
    return Antrenman(
      id: int.parse(veri['id'].toString()),
      baslik: veri['baslik'] ?? '',
      tarih: veri['tarih'] ?? '',
      havuz: veri['havuz'] ?? '',
      sure: veri['sure'] ?? '',
      setler: hamSetler
          .map((s) => AntrenmanSeti.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class PerformansKaydi {
  final String stil;
  final String mesafe;
  final double derece;
  final String tarih;

  const PerformansKaydi({
    required this.stil,
    required this.mesafe,
    required this.derece,
    required this.tarih,
  });

  factory PerformansKaydi.fromJson(Map<String, dynamic> veri) {
    return PerformansKaydi(
      stil: veri['stil'] ?? 'Serbest',
      mesafe: veri['mesafe'] ?? '50m',
      derece: double.tryParse(veri['derece'].toString()) ?? 0.0,
      tarih: veri['tarih'] ?? '',
    );
  }
}

const List<String> yuzmeStilleri = [
  'Serbest',
  'Sırtüstü',
  'Kurbağalama',
  'Kelebek',
];
const List<String> yuzmeMesafeleri = ['25m', '50m', '100m', '200m'];

// ---------------- TARİH YARDIMCILARI ----------------

const List<String> _turkceAylar = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const List<String> _turkceGunler = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Bir DateTime'ı "20 Mayıs, Pazartesi" biçiminde Türkçe metne çevirir.
String turkceTarihMetni(DateTime tarih) {
  final gunAdi = _turkceGunler[tarih.weekday - 1];
  final ayAdi = _turkceAylar[tarih.month - 1];
  return '${tarih.day} $ayAdi, $gunAdi';
}

/// Bir DateTime'ı veritabanında saklanacak 'yyyy-MM-dd' biçimine çevirir.
String antrenmanTarihiKaydet(DateTime tarih) {
  final ay = tarih.month.toString().padLeft(2, '0');
  final gun = tarih.day.toString().padLeft(2, '0');
  return '${tarih.year}-$ay-$gun';
}

/// 'yyyy-MM-dd' biçimindeki bir antrenman tarihini DateTime'a çevirir.
/// Bu özellikten ÖNCE serbest metinle ("20 Mayıs, Pazartesi" gibi)
/// eklenmiş eski antrenmanlarda parse başarısız olur, null döner —
/// bu antrenmanlar "Son 7 Gün" / "Arşiv" filtrelerinde görünmez.
DateTime? antrenmanTarihiAyristir(String tarih) {
  try {
    return DateTime.parse(tarih);
  } catch (_) {
    return null;
  }
}

final Map<DateTime, List<String>> ornekEtkinlikler = {
  DateTime.utc(2024, 5, 15): ['Türkiye Gelişim Ligi - İstanbul'],
  DateTime.utc(2024, 5, 18): ['Kulüp İçi Test Yarışları'],
  DateTime.utc(2024, 5, 25): ['Bölge Şampiyonası - Çanakkale'],
};

void main() {
  runApp(const PoseidonApp());
}

class PoseidonApp extends StatelessWidget {
  const PoseidonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poseidon OS',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------- GİRİŞ EKRANI ----------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final VideoPlayerController _videoController;
  bool _videoDurduruldu = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/trident_rising.mp4')
          ..setLooping(false)
          ..setVolume(0)
          ..addListener(_videoBitisiniKontrolEt)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController.play();
            }
          });
  }

  void _videoBitisiniKontrolEt() {
    if (_videoDurduruldu) return;
    final deger = _videoController.value;
    if (!deger.isInitialized || deger.duration == Duration.zero) return;

    // Son kareye 100ms'den az kaldıysa VİDEOYU ZORLA DURDUR.
    // Platformun kendi "bitince ne yapacağı" davranışına güvenmiyoruz.
    final kalanSure = deger.duration - deger.position;
    if (kalanSure <= const Duration(milliseconds: 100)) {
      _videoDurduruldu = true;
      _videoController.pause();
    }
  }

  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();

  bool _girisYapiliyor = false;
  bool _sifreGorunuyor = false;

  Future<void> _girisYap() async {
    if (_emailController.text.trim().isEmpty ||
        _sifreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta ve şifre gerekli'),
          backgroundColor: Color(0xFF16251A),
        ),
      );
      return;
    }

    setState(() => _girisYapiliyor = true);

    try {
      final kullanici = await dbService.girisYap(
        _emailController.text.trim(),
        _sifreController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            rol: kullanici['role'],
            veliSporcuId: kullanici['athlete_id'] != null
                ? int.parse(kullanici['athlete_id'].toString())
                : null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: const Color(0xFF351515)),
      );
    } finally {
      if (mounted) {
        setState(() => _girisYapiliyor = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _sifreController.dispose();
    _videoController.removeListener(_videoBitisiniKontrolEt);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ekran = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF02090D),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // =========================================================
          // TAM EKRAN POSEIDON ARKA PLANI
          // =========================================================
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: const Color(0xFF02090D)),
          ),

          // =========================================================
          // KARARTMA KATMANI
          // =========================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.03),
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.38),
                    const Color(0xFF02090D).withOpacity(0.94),
                  ],
                  stops: const [0.0, 0.30, 0.64, 1.0],
                ),
              ),
            ),
          ),

          // =========================================================
          // MOBİL FORM ALANI
          // =========================================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: ekran.height * 0.35),

                      // =================================================
                      // MARKA
                      // =================================================
                      const Text(
                        'POSEIDON',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFEAF1F3),
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(color: Color(0xFF78FF36), blurRadius: 18),
                          ],
                        ),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 1,
                            color: const Color(0xFF75E837),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AKADEMİ',
                            style: TextStyle(
                              color: Color(0xFF8DEB45),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 7,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 40,
                            height: 1,
                            color: const Color(0xFF75E837),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'GÜCÜNÜ KEŞFET, ZİRVEYE YÜKSEL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD0D9DC),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // =================================================
                      // GİRİŞ / KAYIT
                      // =================================================
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'GİRİŞ YAP',
                                  style: TextStyle(
                                    color: Color(0xFF9AF04C),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8BE83E),
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8BE83E,
                                        ).withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  const Text(
                                    'KAYIT OL',
                                    style: TextStyle(
                                      color: Color(0xFF718087),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 2,
                                    color: const Color(0xFF17303A),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // E-POSTA
                      // =================================================
                      _PoseidonLoginInput(
                        controller: _emailController,
                        hint: 'E-posta adresiniz',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      // =================================================
                      // ŞİFRE
                      // =================================================
                      _PoseidonLoginInput(
                        controller: _sifreController,
                        hint: 'Şifre',
                        icon: Icons.lock_outline_rounded,
                        obscureText: !_sifreGorunuyor,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _sifreGorunuyor = !_sifreGorunuyor;
                            });
                          },
                          icon: Icon(
                            _sifreGorunuyor
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF9AA8AD),
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // =================================================
                      // GİRİŞ BUTONU
                      // =================================================
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _girisYapiliyor ? null : _girisYap,
                          style: ElevatedButton.styleFrom(
                            elevation: 12,
                            shadowColor: const Color(
                              0xFF72FF32,
                            ).withOpacity(0.45),
                            backgroundColor: const Color(0xFF8BE052),
                            disabledBackgroundColor: const Color(0xFF477C32),
                            foregroundColor: const Color(0xFF031006),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _girisYapiliyor
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF031006),
                                  ),
                                )
                              : const Text(
                                  'GİRİŞ YAP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // ŞİFREMİ UNUTTUM
                      // =================================================
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SifremiUnuttumEkrani(),
                            ),
                          );
                        },
                        child: const Text(
                          'Şifremi Unuttum',
                          style: TextStyle(
                            color: Color(0xFFD0D8DB),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // =================================================
                      // ALT MARKA
                      // =================================================
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF1C3944),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'POSEIDON OS',
                              style: TextStyle(
                                color: Color(0xFF607279),
                                fontSize: 9,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF1C3944),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- POSEIDON GİRİŞ INPUT ----------------

class _PoseidonLoginInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _PoseidonLoginInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF06141B).withOpacity(0.82),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF36525E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: const Color(0xFF8BE052),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF859399), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF9AA8AD), size: 24),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

// ---------------- KAYIT OL EKRANI ----------------

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Future<List<dynamic>>? _kayitSporcularFuture;
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  String _seciliRol = 'antrenor';
  int? _seciliSporcuId;
  bool _kayitOluyor = false;
  @override
  void initState() {
    super.initState();
    _kayitSporcularFuture = dbService.getKayitSporcular();
  }

  Future<void> _kayitOl() async {
    if (_emailController.text.trim().isEmpty ||
        _sifreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('E-posta ve şifre gerekli')));
      return;
    }
    if (_seciliRol == 'veli' && _seciliSporcuId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen çocuğunu seç')));
      return;
    }

    setState(() => _kayitOluyor = true);
    try {
      await dbService.kayitOl(
        email: _emailController.text.trim(),
        sifre: _sifreController.text.trim(),
        rol: _seciliRol,
        sporcuId: _seciliRol == 'veli' ? _seciliSporcuId : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı, şimdi giriş yapabilirsin'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _kayitOluyor = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: const Text(
          'Kayıt Ol',
          style: TextStyle(color: Colors.lightGreenAccent),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _FormAlani(controller: _emailController, etiket: 'E-posta'),
          const SizedBox(height: 12),
          TextField(
            controller: _sifreController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Şifre',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.lightGreenAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Rol', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _RolSecimChip(
                etiket: 'Antrenör',
                deger: 'antrenor',
                seciliRol: _seciliRol,
                onSec: (r) => setState(() => _seciliRol = r),
              ),
              _RolSecimChip(
                etiket: 'Sporcu',
                deger: 'sporcu',
                seciliRol: _seciliRol,
                onSec: (r) => setState(() => _seciliRol = r),
              ),
              _RolSecimChip(
                etiket: 'Veli',
                deger: 'veli',
                seciliRol: _seciliRol,
                onSec: (r) => setState(() => _seciliRol = r),
              ),
            ],
          ),
          if (_seciliRol == 'veli') ...[
            const SizedBox(height: 20),
            const Text(
              'Çocuğun',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _kayitSporcularFuture,
              builder: (context, snapshot) {
                final sporcular = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightGreenAccent,
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sporcular.map((s) {
                    final id = int.parse(s['id'].toString());
                    final seciliMi = _seciliSporcuId == id;
                    return GestureDetector(
                      onTap: () => setState(() => _seciliSporcuId = id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: seciliMi
                              ? Colors.lightGreenAccent
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.lightGreenAccent),
                        ),
                        child: Text(
                          s['isim'] ?? '',
                          style: TextStyle(
                            color: seciliMi ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _kayitOluyor ? null : _kayitOl,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _kayitOluyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Kayıt Ol',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolSecimChip extends StatelessWidget {
  final String etiket;
  final String deger;
  final String seciliRol;
  final ValueChanged<String> onSec;

  const _RolSecimChip({
    required this.etiket,
    required this.deger,
    required this.seciliRol,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final seciliMi = seciliRol == deger;
    return GestureDetector(
      onTap: () => onSec(deger),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seciliMi ? Colors.lightGreenAccent : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.lightGreenAccent),
        ),
        child: Text(
          etiket,
          style: TextStyle(
            color: seciliMi ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------- TRIDENT LOGO ----------------

class TridentIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TridentIcon({
    super.key,
    this.size = 28,
    this.color = Colors.lightGreenAccent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TridentPainter(color: color),
    );
  }
}

class _TridentPainter extends CustomPainter {
  final Color color;
  _TridentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.95),
      paint,
    );
    canvas.drawLine(Offset(w * 0.5, h * 0.4), Offset(w * 0.15, h * 0.1), paint);
    canvas.drawLine(
      Offset(w * 0.15, h * 0.1),
      Offset(w * 0.15, h * 0.35),
      paint,
    );
    canvas.drawLine(Offset(w * 0.5, h * 0.4), Offset(w * 0.85, h * 0.1), paint);
    canvas.drawLine(
      Offset(w * 0.85, h * 0.1),
      Offset(w * 0.85, h * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.05),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TridentPainter oldDelegate) => false;
}

// ---------------- OKLU BUTON ----------------

class OkluButon extends StatelessWidget {
  final String metin;
  final VoidCallback onTap;

  const OkluButon({super.key, required this.metin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9AE637), Color(0xFF5FD858)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metin,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, color: Colors.black, size: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------- İSTATİSTİK KARTI ----------------

class IstatistikKarti extends StatelessWidget {
  final IconData icon;
  final String deger;
  final String etiket;

  const IstatistikKarti({
    super.key,
    required this.icon,
    required this.deger,
    required this.etiket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.lightGreenAccent, size: 20),
          const SizedBox(height: 10),
          Text(
            deger,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiket,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------- ŞİFREMİ UNUTTUM (KOD GÖNDER) ----------------

class SifremiUnuttumEkrani extends StatefulWidget {
  const SifremiUnuttumEkrani({super.key});

  @override
  State<SifremiUnuttumEkrani> createState() => _SifremiUnuttumEkraniState();
}

class _SifremiUnuttumEkraniState extends State<SifremiUnuttumEkrani> {
  final _emailController = TextEditingController();
  bool _gonderiliyor = false;

  Future<void> _kodGonder() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli bir e-posta gir')));
      return;
    }

    setState(() => _gonderiliyor = true);
    try {
      await dbService.sifremiUnuttum(email);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SifreSifirlaEkrani(email: email),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Şifremi Unuttum',
              style: TextStyle(
                color: Colors.lightGreenAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hesabına kayıtlı e-postayı gir, sana 6 haneli bir '
              'sıfırlama kodu gönderelim.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _PoseidonLoginInput(
              controller: _emailController,
              hint: 'E-posta adresiniz',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OkluButon(
                metin: _gonderiliyor ? 'Gönderiliyor...' : 'Kod Gönder',
                onTap: _gonderiliyor ? () {} : _kodGonder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ŞİFRE SIFIRLA (KOD + YENİ ŞİFRE) ----------------

class SifreSifirlaEkrani extends StatefulWidget {
  final String email;

  const SifreSifirlaEkrani({super.key, required this.email});

  @override
  State<SifreSifirlaEkrani> createState() => _SifreSifirlaEkraniState();
}

class _SifreSifirlaEkraniState extends State<SifreSifirlaEkrani> {
  final _kodController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();
  bool _gonderiliyor = false;
  bool _yenidenGonderiliyor = false;

  Future<void> _sifreyiGuncelle() async {
    final kod = _kodController.text.trim();
    final yeniSifre = _yeniSifreController.text.trim();
    final tekrar = _yeniSifreTekrarController.text.trim();

    if (kod.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen 6 haneli kodu gir')));
      return;
    }
    if (yeniSifre.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre en az 6 karakter olmalı')),
      );
      return;
    }
    if (yeniSifre != tekrar) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Şifreler eşleşmiyor')));
      return;
    }

    setState(() => _gonderiliyor = true);
    try {
      await dbService.sifreSifirla(
        email: widget.email,
        kod: kod,
        yeniSifre: yeniSifre,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifren güncellendi, şimdi giriş yapabilirsin'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  Future<void> _koduTekrarGonder() async {
    setState(() => _yenidenGonderiliyor = true);
    try {
      await dbService.sifremiUnuttum(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kod tekrar gönderildi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _yenidenGonderiliyor = false);
    }
  }

  @override
  void dispose() {
    _kodController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kodu Gir',
              style: TextStyle(
                color: Colors.lightGreenAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.email} adresine gönderdiğimiz 6 haneli kodu ve '
              'yeni şifreni gir.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _PoseidonLoginInput(
              controller: _kodController,
              hint: '6 haneli kod',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _PoseidonLoginInput(
              controller: _yeniSifreController,
              hint: 'Yeni şifre',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 14),
            _PoseidonLoginInput(
              controller: _yeniSifreTekrarController,
              hint: 'Yeni şifre (tekrar)',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OkluButon(
                metin: _gonderiliyor ? 'Güncelleniyor...' : 'Şifreyi Güncelle',
                onTap: _gonderiliyor ? () {} : _sifreyiGuncelle,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _yenidenGonderiliyor ? null : _koduTekrarGonder,
                child: Text(
                  _yenidenGonderiliyor
                      ? 'Gönderiliyor...'
                      : 'Kodu tekrar gönder',
                  style: const TextStyle(
                    color: Color(0xFFD0D8DB),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ANA EKRAN (SEKMELİ) ----------------

class HomeScreen extends StatefulWidget {
  final String rol;
  final int? veliSporcuId;

  const HomeScreen({super.key, required this.rol, this.veliSporcuId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  bool get _antrenorMu => widget.rol == 'antrenor';

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AnaSayfaSekmesi(
        antrenorMu: _antrenorMu,
        filtreSporcuId: widget.veliSporcuId,
      ),
      SporcularSekmesi(
        antrenorMu: _antrenorMu,
        filtreSporcuId: widget.veliSporcuId,
      ),
      AntrenmanSekmesi(antrenorMu: _antrenorMu, sporcuId: widget.veliSporcuId),
      TakvimSekmesi(
        antrenorMu: _antrenorMu,
        filtreSporcuId: widget.veliSporcuId,
      ),
      AidatSekmesi(
        antrenorMu: _antrenorMu,
        filtreSporcuId: widget.veliSporcuId,
      ),
      Center(
        child: Text(
          'Profil (${_rolAdi(widget.rol)})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const TridentIcon(size: 22),
            const SizedBox(width: 8),
            Text(
              'POSEIDON OS · ${_rolAdi(widget.rol)}',
              style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.lightGreenAccent),
          onPressed: () {
            dbService.cikisYap();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          // Sadece antrenöre görünen kullanıcı yönetimi kısayolu —
          // bottom nav'a dokunmadan, ayrı bir ekranda açılıyor.
          if (_antrenorMu)
            IconButton(
              icon: const Icon(
                Icons.manage_accounts,
                color: Colors.lightGreenAccent,
              ),
              tooltip: 'Veli / Sporcu Hesapları',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KullaniciYonetimEkrani(),
                  ),
                );
              },
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.lightGreenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sporcular'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Antrenman',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Aidat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _rolAdi(String rol) {
    switch (rol) {
      case 'antrenor':
        return 'Antrenör';
      case 'sporcu':
        return 'Sporcu';
      case 'veli':
        return 'Veli';
      default:
        return '';
    }
  }
}

// ---------------- KULLANICI YÖNETİMİ (VELİ / SPORCU HESAPLARI) ----------------

class KullaniciYonetimEkrani extends StatefulWidget {
  const KullaniciYonetimEkrani({super.key});

  @override
  State<KullaniciYonetimEkrani> createState() => _KullaniciYonetimEkraniState();
}

class _KullaniciYonetimEkraniState extends State<KullaniciYonetimEkrani> {
  late Future<List<dynamic>> _kullanicilarFuture;
  late Future<List<dynamic>> _sporcularFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _kullanicilarFuture = dbService.getKullanicilar();
      _sporcularFuture = dbService.getSporcular();
    });
  }

  Future<void> _kullaniciSil(int id, String email) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Hesabı Kaldır',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$email hesabının erişimi kaldırılsın mı?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      await dbService.kullaniciSil(id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _eslestirmeyiDuzenle(
    Map<String, dynamic> kullanici,
    List<dynamic> sporcular,
  ) async {
    int? seciliId = kullanici['athlete_id'] != null
        ? int.parse(kullanici['athlete_id'].toString())
        : null;

    final sonuc = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kullanici['email']} — Sporcu Eşleştir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Eşleşme Yok'),
                        selected: seciliId == null,
                        onSelected: (_) => setModalState(() => seciliId = null),
                        selectedColor: Colors.grey,
                        labelStyle: TextStyle(
                          color: seciliId == null ? Colors.black : Colors.white,
                        ),
                        backgroundColor: const Color(0xFF1A1A1A),
                      ),
                      ...sporcular.map((s) {
                        final id = int.parse(s['id'].toString());
                        final seciliMi = seciliId == id;
                        return ChoiceChip(
                          label: Text(s['isim'] ?? ''),
                          selected: seciliMi,
                          onSelected: (_) => setModalState(() => seciliId = id),
                          selectedColor: Colors.lightGreenAccent,
                          labelStyle: TextStyle(
                            color: seciliMi ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: const Color(0xFF1A1A1A),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OkluButon(
                      metin: 'Kaydet',
                      onTap: () => Navigator.pop(context, seciliId),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Bottom sheet kapatılırken (dışarı tıklayarak) hiçbir seçim
    // yapılmadıysa güncelleme göndermiyoruz.
    if (sonuc == seciliId && sonuc == null && kullanici['athlete_id'] == null) {
      return;
    }

    try {
      await dbService.kullaniciSporcuEslestir(
        int.parse(kullanici['id'].toString()),
        sonuc,
      );
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _kullaniciEkleFormuAc(List<dynamic> sporcular) async {
    final emailController = TextEditingController();
    final sifreController = TextEditingController();
    String rol = 'veli';
    int? sporcuId;
    bool gonderiliyor = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yeni Hesap Ekle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _RolSecimChip(
                          etiket: 'Veli',
                          deger: 'veli',
                          seciliRol: rol,
                          onSec: (r) => setModalState(() {
                            rol = r;
                            sporcuId = null;
                          }),
                        ),
                        const SizedBox(width: 10),
                        _RolSecimChip(
                          etiket: 'Sporcu',
                          deger: 'sporcu',
                          seciliRol: rol,
                          onSec: (r) => setModalState(() {
                            rol = r;
                            sporcuId = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PoseidonLoginInput(
                      controller: emailController,
                      hint: 'E-posta',
                      icon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 12),
                    _PoseidonLoginInput(
                      controller: sifreController,
                      hint: 'Şifre',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rol == 'veli'
                          ? 'Çocuğu (zorunlu)'
                          : 'Sporcu Kaydıyla Eşleştir (isteğe bağlı)',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (rol == 'sporcu')
                          ChoiceChip(
                            label: const Text('Eşleşme Yok'),
                            selected: sporcuId == null,
                            onSelected: (_) =>
                                setModalState(() => sporcuId = null),
                            selectedColor: Colors.grey,
                            labelStyle: TextStyle(
                              color: sporcuId == null
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          ),
                        ...sporcular.map((s) {
                          final id = int.parse(s['id'].toString());
                          final seciliMi = sporcuId == id;
                          return ChoiceChip(
                            label: Text(s['isim'] ?? ''),
                            selected: seciliMi,
                            onSelected: (_) =>
                                setModalState(() => sporcuId = id),
                            selectedColor: Colors.lightGreenAccent,
                            labelStyle: TextStyle(
                              color: seciliMi ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OkluButon(
                        metin: gonderiliyor ? 'Ekleniyor...' : 'Hesabı Ekle',
                        onTap: gonderiliyor
                            ? () {}
                            : () async {
                                if (emailController.text.trim().isEmpty ||
                                    sifreController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('E-posta ve şifre gerekli'),
                                    ),
                                  );
                                  return;
                                }
                                if (rol == 'veli' && sporcuId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lütfen çocuğunu seç'),
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => gonderiliyor = true);
                                try {
                                  await dbService.kullaniciEkle(
                                    email: emailController.text.trim(),
                                    sifre: sifreController.text.trim(),
                                    rol: rol,
                                    sporcuId: sporcuId,
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                  _reload();
                                } catch (e) {
                                  setModalState(() => gonderiliyor = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Hata: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Veli / Sporcu Hesapları',
          style: TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<dynamic>>(
          future: _sporcularFuture,
          builder: (context, sporcuSnapshot) {
            final sporcular = sporcuSnapshot.data ?? [];
            return FutureBuilder<List<dynamic>>(
              future: _kullanicilarFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightGreenAccent,
                    ),
                  );
                }
                final kullanicilar = snapshot.data ?? [];
                if (kullanicilar.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Henüz kayıtlı veli/sporcu hesabı yok',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: kullanicilar.length,
                  itemBuilder: (context, index) {
                    final k = kullanicilar[index];
                    final rol = k['role'] as String;
                    final sporcuIsmi = k['athlete_isim'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: rol == 'veli'
                                ? Colors.blueGrey
                                : Colors.teal,
                            child: Icon(
                              rol == 'veli'
                                  ? Icons.family_restroom
                                  : Icons.pool,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  k['email'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rol == 'veli' ? 'Veli' : 'Sporcu'} · '
                                  '${sporcuIsmi ?? 'Eşleşme yok'}',
                                  style: TextStyle(
                                    color: sporcuIsmi != null
                                        ? Colors.lightGreenAccent
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.link,
                              color: Colors.grey,
                              size: 20,
                            ),
                            tooltip: 'Sporcu Eşleştir',
                            onPressed: () => _eslestirmeyiDuzenle(k, sporcular),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            tooltip: 'Hesabı Kaldır',
                            onPressed: () => _kullaniciSil(
                              int.parse(k['id'].toString()),
                              k['email'] ?? '',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<List<dynamic>>(
        future: _sporcularFuture,
        builder: (context, snapshot) {
          final sporcular = snapshot.data ?? [];
          return FloatingActionButton.extended(
            backgroundColor: Colors.lightGreenAccent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.person_add),
            label: const Text(
              'Hesap Ekle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _kullaniciEkleFormuAc(sporcular),
          );
        },
      ),
    );
  }
}

// ---------------- ANA SAYFA SEKMESİ ----------------

class AnaSayfaSekmesi extends StatefulWidget {
  final bool antrenorMu;
  final int? filtreSporcuId;

  const AnaSayfaSekmesi({
    super.key,
    required this.antrenorMu,
    this.filtreSporcuId,
  });

  @override
  State<AnaSayfaSekmesi> createState() => _AnaSayfaSekmesiState();
}

class _AnaSayfaSekmesiState extends State<AnaSayfaSekmesi> {
  late Future<List<dynamic>> _sporcularFuture;
  late Future<List<dynamic>> _antrenmanlarFuture;
  late Future<List<dynamic>> _aidatlarFuture;

  @override
  void initState() {
    super.initState();
    _sporcularFuture = dbService.getSporcular();
    _antrenmanlarFuture = dbService.getAntrenmanlar();
    _aidatlarFuture = dbService.getAidatlar(sporcuId: widget.filtreSporcuId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aidat hatırlatma banner'ı — ödeme tarihine 7 gün ve altı kalan varsa göster
          FutureBuilder<List<dynamic>>(
            future: _aidatlarFuture,
            builder: (context, snapshot) {
              final aidatlar = snapshot.data ?? [];

              final simdi = DateTime.now();

              final bugun = DateTime(simdi.year, simdi.month, simdi.day);

              final yaklasanlar = aidatlar.where((a) {
                // Aidat ödenmişse uyarı gösterme
                if (a['odendi'] == true) {
                  return false;
                }

                final sonTarih = DateTime.tryParse(
                  a['son_odeme_tarihi'].toString(),
                );

                if (sonTarih == null) {
                  return false;
                }

                // Saat bilgisini sıfırlıyoruz.
                // Böylece 7 gün hesabı saatten etkilenmiyor.
                final sonGun = DateTime(
                  sonTarih.year,
                  sonTarih.month,
                  sonTarih.day,
                );

                final kalanGun = sonGun.difference(bugun).inDays;

                // Son 7 gün içerisindeyse göster
                return kalanGun >= 0 && kalanGun <= 7;
              }).toList();

              if (yaklasanlar.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1F00),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${yaklasanlar.length} aidat ödemesinin süresi 7 gün içinde doluyor',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          FutureBuilder<List<dynamic>>(
            future: _antrenmanlarFuture,
            builder: (context, snapshot) {
              final tumAntrenmanlar = (snapshot.data ?? [])
                  .map((v) => Antrenman.fromJson(v))
                  .toList();

              final simdi = DateTime.now();
              final bugun = DateTime(simdi.year, simdi.month, simdi.day);

              Antrenman? bugununAntrenmani;
              for (final a in tumAntrenmanlar) {
                final tarih = antrenmanTarihiAyristir(a.tarih);
                if (tarih == null) continue;
                final tarihGunBasi = DateTime(
                  tarih.year,
                  tarih.month,
                  tarih.day,
                );
                if (tarihGunBasi == bugun) {
                  bugununAntrenmani = a;
                  break;
                }
              }

              if (bugununAntrenmani == null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_month, color: Colors.grey, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Bugün için planlanmış antrenman yok',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              final antrenman = bugununAntrenmani;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.lightGreenAccent,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Bugünkü Antrenman',
                          style: TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      antrenman.baslik,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.pool, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          antrenman.havuz,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.timer, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          antrenman.sure,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OkluButon(
                      metin: 'Antrenmanı Gör',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AntrenmanDetayEkrani(
                              antrenman: antrenman,
                              antrenorMu: widget.antrenorMu,
                              sporcuId: widget.filtreSporcuId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Genel Bakış',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _sporcularFuture,
            builder: (context, sporcuSnapshot) {
              final sporcuSayisi = sporcuSnapshot.data?.length ?? 0;
              return FutureBuilder<List<dynamic>>(
                future: _antrenmanlarFuture,
                builder: (context, antrenmanSnapshot) {
                  final antrenmanSayisi = antrenmanSnapshot.data?.length ?? 0;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      IstatistikKarti(
                        icon: Icons.groups,
                        deger: '$sporcuSayisi',
                        etiket: 'Toplam Sporcu',
                      ),
                      IstatistikKarti(
                        icon: Icons.fact_check,
                        deger: '$antrenmanSayisi',
                        etiket: 'Aktif Program',
                      ),
                      const IstatistikKarti(
                        icon: Icons.qr_code_scanner,
                        deger: '0',
                        etiket: 'Bugünkü Yoklama',
                      ),
                      const IstatistikKarti(
                        icon: Icons.emoji_events,
                        deger: '3',
                        etiket: 'Yaklaşan Yarış',
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- SPORCULAR SEKMESİ ----------------

class SporcularSekmesi extends StatefulWidget {
  final bool antrenorMu;
  final int? filtreSporcuId;

  const SporcularSekmesi({
    super.key,
    required this.antrenorMu,
    this.filtreSporcuId,
  });

  @override
  State<SporcularSekmesi> createState() => _SporcularSekmesiState();
}

class _SporcularSekmesiState extends State<SporcularSekmesi> {
  String _seciliStil = 'Serbest';
  String _seciliMesafe = '50m';

  late Future<List<dynamic>> _siralamaFuture;
  late Future<List<dynamic>> _tumSporcularFuture;
  late Future<List<dynamic>> _tumPerformanslarFuture;

  @override
  void initState() {
    super.initState();

    _siralamaFuture = dbService.getSiralama(
      stil: _seciliStil,
      mesafe: _seciliMesafe,
    );

    _tumSporcularFuture = dbService.getSporcular();
    _tumPerformanslarFuture = dbService.getTumPerformanslar();
  }

  void _siralamayiYukle() {
    _siralamaFuture = dbService.getSiralama(
      stil: _seciliStil,
      mesafe: _seciliMesafe,
    );
  }

  void _tumVerileriYenile() {
    setState(() {
      _siralamaFuture = dbService.getSiralama(
        stil: _seciliStil,
        mesafe: _seciliMesafe,
      );

      _tumSporcularFuture = dbService.getSporcular();
      _tumPerformanslarFuture = dbService.getTumPerformanslar();
    });
  }

  void _stilDegistir(String stil) {
    setState(() {
      _seciliStil = stil;
      _siralamayiYukle();
    });
  }

  void _mesafeDegistir(String mesafe) {
    setState(() {
      _seciliMesafe = mesafe;
      _siralamayiYukle();
    });
  }

  Future<void> _silmeyiOnayla(
    BuildContext context,
    Map<String, dynamic> sporcu,
  ) async {
    final onayVerdiMi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Sporcuyu Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '${sporcu['isim']} adlı sporcuyu silmek istediğine emin misin?\n\n'
          'Bu işlem geri alınamaz.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (onayVerdiMi != true) return;

    try {
      await dbService.sporcuSil(int.parse(sporcu['athlete_id'].toString()));

      _tumVerileriYenile();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${sporcu['isim']} silindi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  String _dereceGoster(dynamic derece) {
    final sayi = double.tryParse(derece.toString());

    if (sayi == null) {
      return derece.toString();
    }

    return sayi.toStringAsFixed(2);
  }

  Widget _stilSecim() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: yuzmeStilleri.map((stil) {
          final seciliMi = _seciliStil == stil;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(stil),
              selected: seciliMi,
              onSelected: (_) => _stilDegistir(stil),
              selectedColor: Colors.lightGreenAccent,
              backgroundColor: const Color(0xFF1A1A1A),
              labelStyle: TextStyle(
                color: seciliMi ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _mesafeSecim() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: yuzmeMesafeleri.map((mesafe) {
          final seciliMi = _seciliMesafe == mesafe;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mesafe),
              selected: seciliMi,
              onSelected: (_) => _mesafeDegistir(mesafe),
              selectedColor: const Color(0xFF36525E),
              backgroundColor: const Color(0xFF1A1A1A),
              labelStyle: TextStyle(
                color: seciliMi ? Colors.lightGreenAccent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _siralamadakiSporcuKarti(
    BuildContext context,
    Map<String, dynamic> sporcu,
    int index,
  ) {
    final sira = index + 1;

    String madalya = '';

    if (sira == 1) {
      madalya = '🥇';
    } else if (sira == 2) {
      madalya = '🥈';
    } else if (sira == 3) {
      madalya = '🥉';
    }

    final isim = sporcu['isim']?.toString() ?? '';
    final grup = sporcu['grup']?.toString() ?? '';
    final derece = _dereceGoster(sporcu['derece']);
    final athleteId = int.tryParse(sporcu['athlete_id'].toString());

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: athleteId == null
          ? null
          : () async {
              final mevcutSporcu = Sporcu(
                id: athleteId,
                isim: isim,
                dogumYili: int.tryParse(sporcu['dogum_yili'].toString()) ?? 0,
                grup: grup,
                enIyiDerece: derece,
                enIyiDereceStil: _seciliStil,
                enIyiDereceMesafe: _seciliMesafe,
              );

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SporcuDetayEkrani(
                    sporcu: mevcutSporcu,
                    antrenorMu: widget.antrenorMu,
                  ),
                ),
              );

              if (mounted) {
                _tumVerileriYenile();
              }
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sira <= 3
                ? Colors.lightGreenAccent.withOpacity(0.35)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: madalya.isNotEmpty
                  ? Text(madalya, style: const TextStyle(fontSize: 22))
                  : Text(
                      '$sira',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(width: 10),

            CircleAvatar(
              radius: 21,
              backgroundColor: Colors.lightGreenAccent,
              child: Text(
                isim.isNotEmpty ? isim[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isim,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    grup,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$derece sn',
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_seciliMesafe $_seciliStil',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),

            if (widget.antrenorMu)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _silmeyiOnayla(context, sporcu),
              ),
          ],
        ),
      ),
    );
  }

  Widget _derecesiOlmayanSporcuKarti(
    BuildContext context,
    Map<String, dynamic> veri,
  ) {
    final sporcu = Sporcu.fromJson(veri);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFF2A2A2A),
            child: Text(
              sporcu.isim.isNotEmpty ? sporcu.isim[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sporcu.isim,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sporcu.grup,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Henüz performans kaydı yok',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                ),
              ],
            ),
          ),

          if (widget.antrenorMu)
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PerformansEkleEkrani(sporcuId: sporcu.id),
                  ),
                );

                if (mounted) {
                  _tumVerileriYenile();
                }
              },
              icon: const Icon(Icons.add, size: 17, color: Colors.black),
              label: const Text(
                'Derece Ekle',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _derecesiOlmayanlarBolumu() {
    return FutureBuilder<List<dynamic>>(
      future: _tumSporcularFuture,
      builder: (context, sporcuSnapshot) {
        if (sporcuSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.lightGreenAccent),
            ),
          );
        }

        if (sporcuSnapshot.hasError) {
          return Text(
            'Sporcular yüklenemedi: ${sporcuSnapshot.error}',
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          );
        }

        final tumSporcular = sporcuSnapshot.data ?? [];

        return FutureBuilder<List<dynamic>>(
          future: _tumPerformanslarFuture,
          builder: (context, performansSnapshot) {
            if (performansSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Colors.lightGreenAccent,
                  ),
                ),
              );
            }

            if (performansSnapshot.hasError) {
              return Text(
                'Performanslar yüklenemedi: ${performansSnapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              );
            }

            final tumPerformanslar = performansSnapshot.data ?? [];

            final performansiOlanSporcuIdleri = tumPerformanslar
                .map((p) => int.tryParse(p['athlete_id'].toString()))
                .whereType<int>()
                .toSet();

            final derecesiOlmayanlar = tumSporcular.where((s) {
              final sporcuId = int.tryParse(s['id'].toString());

              if (sporcuId == null) return false;

              return !performansiOlanSporcuIdleri.contains(sporcuId);
            }).toList();

            if (derecesiOlmayanlar.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF101510),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.lightGreenAccent.withOpacity(0.15),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tüm sporcuların en az bir performans kaydı bulunuyor.',
                        style: TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: derecesiOlmayanlar
                  .map<Widget>(
                    (s) => _derecesiOlmayanSporcuKarti(
                      context,
                      Map<String, dynamic>.from(s),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async {
          _tumVerileriYenile();
        },
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<dynamic>>(
          future: _siralamaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.lightGreenAccent,
                ),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 100),
                  Text(
                    'Sıralama yüklenemedi:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final siralama = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Kulüp Sıralaması',
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$_seciliMesafe $_seciliStil',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Yüzme Stili',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                _stilSecim(),

                const SizedBox(height: 18),

                const Text(
                  'Mesafe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                _mesafeSecim(),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.lightGreenAccent.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.lightGreenAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_seciliMesafe $_seciliStil sıralaması',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${siralama.length} sporcu',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (siralama.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.pool, color: Colors.grey, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Bu stil ve mesafede henüz performans kaydı yok.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ...siralama.asMap().entries.map<Widget>(
                    (entry) => _siralamadakiSporcuKarti(
                      context,
                      Map<String, dynamic>.from(entry.value),
                      entry.key,
                    ),
                  ),

                if (widget.antrenorMu) ...[
                  const SizedBox(height: 30),

                  const Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: Colors.orangeAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Derecesi Olmayan Sporcular',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Henüz hiçbir performans kaydı girilmemiş sporcular',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const SizedBox(height: 14),

                  _derecesiOlmayanlarBolumu(),
                ],
              ],
            );
          },
        ),
      ),

      floatingActionButton: widget.antrenorMu
          ? FloatingActionButton(
              backgroundColor: Colors.lightGreenAccent,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SporcuEkleEkrani(),
                  ),
                );

                if (mounted) {
                  _tumVerileriYenile();
                }
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}
// ---------------- SPORCU EKLEME FORMU ----------------

class SporcuEkleEkrani extends StatefulWidget {
  const SporcuEkleEkrani({super.key});

  @override
  State<SporcuEkleEkrani> createState() => _SporcuEkleEkraniState();
}

class _SporcuEkleEkraniState extends State<SporcuEkleEkrani> {
  final _isimController = TextEditingController();
  final _dogumYiliController = TextEditingController();
  final _grupController = TextEditingController();
  final _enIyiDereceController = TextEditingController();
  String? _seciliStil;
  bool _kaydediliyor = false;

  Future<void> _sporcuKaydet() async {
    if (_isimController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İsim boş olamaz')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await dbService.sporcuEkle({
        'isim': _isimController.text.trim(),
        'dogum_yili': int.tryParse(_dogumYiliController.text.trim()) ?? 0,
        'grup': _grupController.text.trim(),
        'en_iyi_derece': _enIyiDereceController.text.trim(),
        'en_iyi_derece_stil': _seciliStil,
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  void dispose() {
    _isimController.dispose();
    _dogumYiliController.dispose();
    _grupController.dispose();
    _enIyiDereceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Yeni Sporcu',
          style: TextStyle(color: Colors.lightGreenAccent),
        ),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FormAlani(controller: _isimController, etiket: 'İsim'),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _dogumYiliController,
              etiket: 'Doğum Yılı',
              sayisalMi: true,
            ),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _grupController,
              etiket: 'Grup (örn. A Takım)',
            ),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _enIyiDereceController,
              etiket: 'En İyi Derece (örn. 27.45)',
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'En İyi Derecenin Stili',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: yuzmeStilleri.map((stil) {
                final seciliMi = _seciliStil == stil;
                return GestureDetector(
                  onTap: () => setState(() => _seciliStil = stil),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: seciliMi
                          ? Colors.lightGreenAccent
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.lightGreenAccent),
                    ),
                    child: Text(
                      stil,
                      style: TextStyle(
                        color: seciliMi ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _kaydediliyor ? null : _sporcuKaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _kaydediliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormAlani extends StatelessWidget {
  final TextEditingController controller;
  final String etiket;
  final bool sayisalMi;

  const _FormAlani({
    required this.controller,
    required this.etiket,
    this.sayisalMi = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: sayisalMi ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: etiket,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.lightGreenAccent),
        ),
      ),
    );
  }
}

// ---------------- SPORCU DETAY EKRANI (PERFORMANS) ----------------

class SporcuDetayEkrani extends StatefulWidget {
  final Sporcu sporcu;
  final bool antrenorMu;

  const SporcuDetayEkrani({
    super.key,
    required this.sporcu,
    required this.antrenorMu,
  });

  @override
  State<SporcuDetayEkrani> createState() => _SporcuDetayEkraniState();
}

class _SporcuDetayEkraniState extends State<SporcuDetayEkrani> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = dbService.getPerformans(widget.sporcu.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: Text(
          widget.sporcu.isim,
          style: const TextStyle(color: Colors.lightGreenAccent),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.lightGreenAccent),
            );
          }
          final kayitlar = (snapshot.data ?? [])
              .map((v) => PerformansKaydi.fromJson(v))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.lightGreenAccent,
                      child: Text(
                        widget.sporcu.isim.isNotEmpty
                            ? widget.sporcu.isim[0]
                            : '?',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sporcu.isim,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.sporcu.dogumYili} · ${widget.sporcu.grup}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Performans Gelişimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (kayitlar.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Henüz performans kaydı yok',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...yuzmeStilleri.map((stil) {
                  final stilKayitlari = kayitlar
                      .where((k) => k.stil == stil)
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.lightGreenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stil,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (stilKayitlari.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Bu stilde henüz kayıt yok',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          ...yuzmeMesafeleri.map((mesafe) {
                            final mesafeKayitlari = stilKayitlari
                                .where((k) => k.mesafe == mesafe)
                                .toList();
                            if (mesafeKayitlari.isEmpty)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 14,
                                left: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mesafe,
                                    style: const TextStyle(
                                      color: Colors.lightGreenAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 150,
                                    padding: const EdgeInsets.fromLTRB(
                                      6,
                                      14,
                                      14,
                                      6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              getTitlesWidget: (value, meta) =>
                                                  Text(
                                                    value.toStringAsFixed(0),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final i = value.toInt();
                                                if (i < 0 ||
                                                    i >= mesafeKayitlari.length)
                                                  return const SizedBox();
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    mesafeKayitlari[i].tarih,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: mesafeKayitlari
                                                .asMap()
                                                .entries
                                                .map(
                                                  (e) => FlSpot(
                                                    e.key.toDouble(),
                                                    e.value.derece,
                                                  ),
                                                )
                                                .toList(),
                                            isCurved: true,
                                            color: Colors.lightGreenAccent,
                                            barWidth: 2.5,
                                            dotData: const FlDotData(
                                              show: true,
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: Colors.lightGreenAccent
                                                  .withOpacity(0.15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...mesafeKayitlari.reversed.map(
                                    (k) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              k.tarih,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            k.derece.toStringAsFixed(2),
                                            style: const TextStyle(
                                              color: Colors.lightGreenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: widget.antrenorMu
          ? FloatingActionButton(
              backgroundColor: Colors.lightGreenAccent,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PerformansEkleEkrani(sporcuId: widget.sporcu.id),
                  ),
                );
                _reload();
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}

// ---------------- PERFORMANS EKLEME FORMU ----------------

class PerformansEkleEkrani extends StatefulWidget {
  final int sporcuId;

  const PerformansEkleEkrani({super.key, required this.sporcuId});

  @override
  State<PerformansEkleEkrani> createState() => _PerformansEkleEkraniState();
}

class _PerformansEkleEkraniState extends State<PerformansEkleEkrani> {
  final _dereceController = TextEditingController();
  final _tarihController = TextEditingController();
  String _seciliStil = 'Serbest';
  String _seciliMesafe = '50m';
  bool _kaydediliyor = false;

  Future<void> _kaydet() async {
    if (_dereceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Derece boş olamaz')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await dbService.performansEkle({
        'athlete_id': widget.sporcuId,
        'stil': _seciliStil,
        'mesafe': _seciliMesafe,
        'derece':
            double.tryParse(
              _dereceController.text.trim().replaceAll(',', '.'),
            ) ??
            0.0,
        'tarih': _tarihController.text.trim(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  void dispose() {
    _dereceController.dispose();
    _tarihController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Yeni Performans Kaydı',
          style: TextStyle(color: Colors.lightGreenAccent),
        ),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Yüzme Stili',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: yuzmeStilleri.map((stil) {
              final seciliMi = _seciliStil == stil;
              return GestureDetector(
                onTap: () => setState(() => _seciliStil = stil),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: seciliMi
                        ? Colors.lightGreenAccent
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightGreenAccent),
                  ),
                  child: Text(
                    stil,
                    style: TextStyle(
                      color: seciliMi ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mesafe',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: yuzmeMesafeleri.map((mesafe) {
              final seciliMi = _seciliMesafe == mesafe;
              return GestureDetector(
                onTap: () => setState(() => _seciliMesafe = mesafe),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: seciliMi
                        ? Colors.lightGreenAccent
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightGreenAccent),
                  ),
                  child: Text(
                    mesafe,
                    style: TextStyle(
                      color: seciliMi ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FormAlani(
            controller: _dereceController,
            etiket: 'Derece - saniye (örn. 27.45)',
          ),
          const SizedBox(height: 12),
          _FormAlani(
            controller: _tarihController,
            etiket: 'Tarih (örn. 10.05)',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _kaydediliyor ? null : _kaydet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _kaydediliyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- ANTRENMAN SEKMESİ ----------------

class AntrenmanSekmesi extends StatefulWidget {
  final bool antrenorMu;
  final int? sporcuId;

  const AntrenmanSekmesi({super.key, required this.antrenorMu, this.sporcuId});

  @override
  State<AntrenmanSekmesi> createState() => _AntrenmanSekmesiState();
}

class _AntrenmanSekmesiState extends State<AntrenmanSekmesi> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = dbService.getAntrenmanlar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GecmisAntrenmanlarEkrani(sporcuId: widget.sporcuId),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.lightGreenAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Geçmiş Antrenmanlar',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              color: Colors.lightGreenAccent,
              backgroundColor: Colors.black,
              child: FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.lightGreenAccent,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final belgeler = snapshot.data ?? [];
                  if (belgeler.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Henüz antrenman eklenmemiş',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: belgeler.length,
                    itemBuilder: (context, index) {
                      final antrenman = Antrenman.fromJson(belgeler[index]);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AntrenmanDetayEkrani(
                                antrenman: antrenman,
                                antrenorMu: widget.antrenorMu,
                                sporcuId: widget.sporcuId,
                              ),
                            ),
                          );
                          _reload();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.lightGreenAccent,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      antrenman.baslik,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.lightGreenAccent,
                                    size: 22,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                antrenman.tarih,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${antrenman.havuz} · ${antrenman.sure}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              if (antrenman.setler.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${antrenman.setler.length} set · Programı görmek için dokun',
                                  style: const TextStyle(
                                    color: Colors.lightGreenAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.antrenorMu
          ? FloatingActionButton(
              backgroundColor: Colors.lightGreenAccent,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AntrenmanEkleEkrani(),
                  ),
                );
                _reload();
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}

// ---------------- GEÇMİŞ ANTRENMANLAR / ARŞİV ----------------

class GecmisAntrenmanlarEkrani extends StatefulWidget {
  final int? sporcuId;

  const GecmisAntrenmanlarEkrani({super.key, this.sporcuId});

  @override
  State<GecmisAntrenmanlarEkrani> createState() =>
      _GecmisAntrenmanlarEkraniState();
}

class _GecmisAntrenmanlarEkraniState extends State<GecmisAntrenmanlarEkrani> {
  late Future<List<dynamic>> _future;

  // true: "Son 7 Gün" görünümü, false: "Arşiv" görünümü
  bool _son7GunSekmesi = true;

  @override
  void initState() {
    super.initState();
    _future = dbService.getAntrenmanlar();
  }

  @override
  Widget build(BuildContext context) {
    final bugun = DateTime.now();
    final bugunGunBasi = DateTime(bugun.year, bugun.month, bugun.day);
    final yediGunOnce = bugunGunBasi.subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: const Text(
          'Geçmiş Antrenmanlar',
          style: TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _GecmisSekmeButonu(
                    etiket: 'Son 7 Gün',
                    secili: _son7GunSekmesi,
                    onTap: () => setState(() => _son7GunSekmesi = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GecmisSekmeButonu(
                    etiket: 'Arşiv',
                    secili: !_son7GunSekmesi,
                    onTap: () => setState(() => _son7GunSekmesi = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightGreenAccent,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final tumAntrenmanlar = (snapshot.data ?? [])
                    .map((v) => Antrenman.fromJson(v))
                    .toList();

                // Her antrenmanı tarihine göre üç kovadan birine ayır:
                // gelecek/parse edilemeyen kayıtlar bu ekranda hiç gösterilmez,
                // sadece geçmişte kalanlar "son 7 gün" ya da "arşiv"e girer.
                final List<Antrenman> son7Gun = [];
                final List<Antrenman> arsiv = [];
                for (final a in tumAntrenmanlar) {
                  final tarih = antrenmanTarihiAyristir(a.tarih);
                  if (tarih == null) continue; // eski serbest metin tarihli
                  final tarihGunBasi = DateTime(
                    tarih.year,
                    tarih.month,
                    tarih.day,
                  );
                  if (tarihGunBasi.isAfter(bugunGunBasi)) {
                    continue; // henüz gerçekleşmemiş antrenman, bu ekranda yok
                  }
                  if (!tarihGunBasi.isBefore(yediGunOnce)) {
                    son7Gun.add(a);
                  } else {
                    arsiv.add(a);
                  }
                }

                // En yeni tarih en üstte görünsün.
                int tarihKarsilastir(Antrenman a, Antrenman b) {
                  final ta = antrenmanTarihiAyristir(a.tarih)!;
                  final tb = antrenmanTarihiAyristir(b.tarih)!;
                  return tb.compareTo(ta);
                }

                son7Gun.sort(tarihKarsilastir);
                arsiv.sort(tarihKarsilastir);

                final gosterilecekler = _son7GunSekmesi ? son7Gun : arsiv;

                if (gosterilecekler.isEmpty) {
                  return Center(
                    child: Text(
                      _son7GunSekmesi
                          ? 'Son 7 günde geçmiş antrenman yok'
                          : 'Arşivde antrenman yok',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: gosterilecekler.length,
                  itemBuilder: (context, index) {
                    final antrenman = gosterilecekler[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AntrenmanDetayEkrani(
                              antrenman: antrenman,
                              antrenorMu: false, // geçmiş kayıt, düzenlenmez
                              sporcuId: widget.sporcuId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    antrenman.baslik,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    antrenman.tarih,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GecmisSekmeButonu extends StatelessWidget {
  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  const _GecmisSekmeButonu({
    required this.etiket,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: secili ? Colors.lightGreenAccent : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: secili ? Colors.lightGreenAccent : const Color(0xFF2A2A2A),
          ),
        ),
        child: Center(
          child: Text(
            etiket,
            style: TextStyle(
              color: secili ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- ANTRENMAN DETAY (PROGRAM + YOKLAMA) ----------------

class AntrenmanDetayEkrani extends StatefulWidget {
  final Antrenman antrenman;
  final bool antrenorMu;
  final int? sporcuId;

  const AntrenmanDetayEkrani({
    super.key,
    required this.antrenman,
    required this.antrenorMu,
    this.sporcuId,
  });

  @override
  State<AntrenmanDetayEkrani> createState() => _AntrenmanDetayEkraniState();
}

class _AntrenmanDetayEkraniState extends State<AntrenmanDetayEkrani> {
  late Future<List<dynamic>> _yoklamaFuture;

  @override
  void initState() {
    super.initState();
    _reloadYoklama();
  }

  void _reloadYoklama() {
    setState(() {
      _yoklamaFuture = dbService.getYoklama(
        antrenmanId: widget.antrenman.id,
        sporcuId: widget.sporcuId,
      );
    });
  }

  /// Saat:dakika biçiminde gösterir (örn. "18:32"). Sunucudan gelen
  /// zaman damgası null ise null döner.
  String? _saatMetni(dynamic zamanDamgasi) {
    if (zamanDamgasi == null) return null;
    try {
      final d = DateTime.parse(zamanDamgasi.toString()).toLocal();
      final saat = d.hour.toString().padLeft(2, '0');
      final dakika = d.minute.toString().padLeft(2, '0');
      return '$saat:$dakika';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<AntrenmanSeti>> gruplanmis = {};
    for (final set in widget.antrenman.setler) {
      gruplanmis.putIfAbsent(set.kategori, () => []).add(set);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: Text(
          widget.antrenman.baslik,
          style: const TextStyle(color: Colors.lightGreenAccent),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.lightGreenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.antrenman.tarih,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.pool,
                    color: Colors.lightGreenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.antrenman.havuz,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.timer,
                    color: Colors.lightGreenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.antrenman.sure,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: _yoklamaFuture,
              builder: (context, snapshot) {
                final kayitlar = snapshot.data ?? [];

                Map<String, dynamic>? kendiKaydi;
                if (!widget.antrenorMu &&
                    widget.sporcuId != null &&
                    kayitlar.isNotEmpty) {
                  kendiKaydi = kayitlar.first as Map<String, dynamic>;
                }
                final girisSaati = kendiKaydi != null
                    ? _saatMetni(kendiKaydi['giris_zamani'])
                    : null;
                final cikisSaati = kendiKaydi != null
                    ? _saatMetni(kendiKaydi['cikis_zamani'])
                    : null;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.lightGreenAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.lightGreenAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.antrenorMu
                                ? 'Yoklama: ${kayitlar.length} kişi'
                                : 'Yoklama',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (widget.antrenorMu)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => YoklamaQREkrani(
                                      antrenman: widget.antrenman,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'QR Göster',
                                style: TextStyle(
                                  color: Colors.lightGreenAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.antrenorMu) ...[
                        const SizedBox(height: 12),
                        if (kayitlar.isEmpty)
                          const Text(
                            'Henüz kimse QR okutmadı',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          )
                        else
                          ...kayitlar.map((k) {
                            final giris = _saatMetni(k['giris_zamani']);
                            final cikis = _saatMetni(k['cikis_zamani']);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      k['athlete_isim'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Giriş: ${giris ?? '—'}',
                                    style: const TextStyle(
                                      color: Colors.lightGreenAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Çıkış: ${cikis ?? '—'}',
                                    style: TextStyle(
                                      color: cikis != null
                                          ? Colors.orangeAccent
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ] else ...[
                        const SizedBox(height: 12),
                        if (widget.sporcuId == null)
                          const Text(
                            'Hesabınız bir sporcu kaydıyla eşleştirilmemiş. '
                            'Antrenörünüzle iletişime geçin.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          )
                        else ...[
                          Row(
                            children: [
                              Icon(
                                girisSaati != null
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: girisSaati != null
                                    ? Colors.lightGreenAccent
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  girisSaati != null
                                      ? 'Derse girdi: $girisSaati'
                                      : 'Henüz derse girmedi',
                                  style: TextStyle(
                                    color: girisSaati != null
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                cikisSaati != null
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: cikisSaati != null
                                    ? Colors.orangeAccent
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cikisSaati != null
                                      ? 'Dersten çıktı: $cikisSaati'
                                      : 'Henüz dersten çıkmadı',
                                  style: TextStyle(
                                    color: cikisSaati != null
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (girisSaati == null)
                                Expanded(
                                  child: OkluButon(
                                    metin: 'Giriş Yap (QR)',
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QrTaramaEkrani(
                                            antrenmanId: widget.antrenman.id,
                                            sporcuId: widget.sporcuId!,
                                            tip: 'giris',
                                          ),
                                        ),
                                      );
                                      _reloadYoklama();
                                    },
                                  ),
                                )
                              else if (cikisSaati == null)
                                Expanded(
                                  child: OkluButon(
                                    metin: 'Çıkış Yap (QR)',
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QrTaramaEkrani(
                                            antrenmanId: widget.antrenman.id,
                                            sporcuId: widget.sporcuId!,
                                            tip: 'cikis',
                                          ),
                                        ),
                                      );
                                      _reloadYoklama();
                                    },
                                  ),
                                )
                              else
                                const Expanded(
                                  child: Text(
                                    'Bugünkü antrenman tamamlandı ✓',
                                    style: TextStyle(
                                      color: Colors.lightGreenAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            if (gruplanmis.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'Bu antrenman için henüz set girilmemiş',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...gruplanmis.entries.map((grup) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grup.key,
                        style: const TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...grup.value.map(
                        (set) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '•  ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  set.aciklama,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ---------------- ANTRENMAN EKLEME FORMU (ÇOKLU SET İLE) ----------------

class AntrenmanEkleEkrani extends StatefulWidget {
  const AntrenmanEkleEkrani({super.key});

  @override
  State<AntrenmanEkleEkrani> createState() => _AntrenmanEkleEkraniState();
}

class _AntrenmanEkleEkraniState extends State<AntrenmanEkleEkrani> {
  final _baslikController = TextEditingController();
  final _havuzController = TextEditingController();
  final _sureController = TextEditingController();
  final _setAciklamaController = TextEditingController();
  DateTime? _seciliTarih;
  String _seciliKategori = 'Isınma';
  final List<String> _kategoriler = ['Isınma', 'Ana Set', 'Soğuma'];
  final List<AntrenmanSeti> _eklenenSetler = [];
  bool _kaydediliyor = false;

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _seciliTarih ?? bugun,
      firstDate: DateTime(bugun.year - 1, 1, 1),
      lastDate: DateTime(bugun.year + 2, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.lightGreenAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF151515),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (secilen == null) return;
    setState(() => _seciliTarih = secilen);
  }

  void _setEkle() {
    if (_setAciklamaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set açıklaması boş olamaz')),
      );
      return;
    }
    setState(() {
      _eklenenSetler.add(
        AntrenmanSeti(
          kategori: _seciliKategori,
          aciklama: _setAciklamaController.text.trim(),
        ),
      );
      _setAciklamaController.clear();
    });
  }

  void _setSil(int index) => setState(() => _eklenenSetler.removeAt(index));

  Future<void> _antrenmanKaydet() async {
    if (_baslikController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Başlık boş olamaz')));
      return;
    }
    if (_seciliTarih == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir tarih seç')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await dbService.antrenmanEkle({
        'baslik': _baslikController.text.trim(),
        'tarih': antrenmanTarihiKaydet(_seciliTarih!),
        'havuz': _havuzController.text.trim(),
        'sure': _sureController.text.trim(),
        'setler': _eklenenSetler.map((s) => s.toMap()).toList(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _havuzController.dispose();
    _sureController.dispose();
    _setAciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Yeni Antrenman',
          style: TextStyle(color: Colors.lightGreenAccent),
        ),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FormAlani(
            controller: _baslikController,
            etiket: 'Başlık (örn. Dayanıklılık + Teknik)',
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _tarihSec,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.lightGreenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _seciliTarih != null
                        ? turkceTarihMetni(_seciliTarih!)
                        : 'Tarih seç',
                    style: TextStyle(
                      color: _seciliTarih != null ? Colors.white : Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormAlani(
            controller: _havuzController,
            etiket: 'Havuz (örn. Havuz 1)',
          ),
          const SizedBox(height: 12),
          _FormAlani(controller: _sureController, etiket: 'Süre (örn. 30dk)'),
          const SizedBox(height: 28),
          const Text(
            'Antrenman Setleri (Drill\'ler)',
            style: TextStyle(
              color: Colors.lightGreenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _kategoriler.map((kategori) {
              final seciliMi = _seciliKategori == kategori;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _seciliKategori = kategori),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: seciliMi
                            ? Colors.lightGreenAccent
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.lightGreenAccent),
                      ),
                      child: Text(
                        kategori,
                        style: TextStyle(
                          color: seciliMi ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FormAlani(
                  controller: _setAciklamaController,
                  etiket: 'örn. 4 x 50m Serbest @1:00',
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _setEkle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                child: const Text(
                  'Ekle',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_eklenenSetler.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Henüz set eklenmedi',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._eklenenSetler.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.lightGreenAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        set.kategori,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        set.aciklama,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () => _setSil(index),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _kaydediliyor ? null : _antrenmanKaydet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _kaydediliyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Antrenmanı Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- QR GÖSTERME EKRANI ----------------

class YoklamaQREkrani extends StatelessWidget {
  final Antrenman antrenman;

  const YoklamaQREkrani({super.key, required this.antrenman});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: const Text(
          'Yoklama - QR Giriş',
          style: TextStyle(color: Colors.lightGreenAccent),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                antrenman.baslik,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: antrenman.id.toString(),
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sporcular bu kodu okutarak yoklamaya katılabilir',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FutureBuilder<List<dynamic>>(
                future: dbService.getYoklama(antrenmanId: antrenman.id),
                builder: (context, snapshot) {
                  final kayitlar = snapshot.data ?? [];
                  return Column(
                    children: [
                      Text(
                        'Şu ana kadar ${kayitlar.length} kişi okuttu',
                        style: const TextStyle(
                          color: Colors.lightGreenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (kayitlar.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: kayitlar.length,
                            itemBuilder: (context, index) {
                              final k = kayitlar[index];
                              final cikisVar = k['cikis_zamani'] != null;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      cikisVar
                                          ? Icons.check_circle
                                          : Icons.login,
                                      color: cikisVar
                                          ? Colors.orangeAccent
                                          : Colors.lightGreenAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      k['athlete_isim'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- QR OKUMA EKRANI ----------------

class QrTaramaEkrani extends StatefulWidget {
  final int antrenmanId;
  final int sporcuId;
  final String tip; // 'giris' ya da 'cikis'

  const QrTaramaEkrani({
    super.key,
    required this.antrenmanId,
    required this.sporcuId,
    required this.tip,
  });

  @override
  State<QrTaramaEkrani> createState() => _QrTaramaEkraniState();
}

class _QrTaramaEkraniState extends State<QrTaramaEkrani> {
  bool _islemTamamlandi = false;

  Future<void> _yoklamaKaydet(String okunanId) async {
    if (_islemTamamlandi) return;
    setState(() => _islemTamamlandi = true);

    final okunanIdInt = int.tryParse(okunanId);
    if (okunanIdInt != widget.antrenmanId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kod bu antrenmana ait değil')),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      if (widget.tip == 'giris') {
        await dbService.yoklamaGirisYap(
          antrenmanId: widget.antrenmanId,
          sporcuId: widget.sporcuId,
        );
      } else {
        await dbService.yoklamaCikisYap(
          antrenmanId: widget.antrenmanId,
          sporcuId: widget.sporcuId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.tip == 'giris' ? 'Giriş alındı ✓' : 'Çıkış alındı ✓',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: Text(
          widget.tip == 'giris' ? 'Giriş İçin QR Okut' : 'Çıkış İçin QR Okut',
          style: const TextStyle(color: Colors.lightGreenAccent),
        ),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barkodlar = capture.barcodes;
          if (barkodlar.isNotEmpty) {
            final deger = barkodlar.first.rawValue;
            if (deger != null) _yoklamaKaydet(deger);
          }
        },
      ),
    );
  }
}

// ---------------- TAKVİM SEKMESİ ----------------

// ---------------- TAKVİM SEKMESİ ----------------

class TakvimSekmesi extends StatefulWidget {
  final bool antrenorMu;
  final int? filtreSporcuId;

  const TakvimSekmesi({
    super.key,
    required this.antrenorMu,
    this.filtreSporcuId,
  });

  @override
  State<TakvimSekmesi> createState() => _TakvimSekmesiState();
}

class _TakvimSekmesiState extends State<TakvimSekmesi> {
  late Future<List<dynamic>> _aidatlarFuture;

  DateTime _odakGun = DateTime.now();
  DateTime? _secilenGun;

  @override
  void initState() {
    super.initState();

    _secilenGun = DateTime.now();

    _aidatlarFuture = _aidatlariGetir();
  }

  Future<List<dynamic>> _aidatlariGetir() {
    return dbService.getAidatlar(sporcuId: widget.filtreSporcuId);
  }

  void _yenile() {
    setState(() {
      _aidatlarFuture = _aidatlariGetir();
    });
  }

  DateTime? _tarihParse(dynamic deger) {
    if (deger == null) return null;

    return DateTime.tryParse(deger.toString());
  }

  bool _ayniGun(DateTime? a, DateTime b) {
    if (a == null) return false;

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<dynamic> _tarihtekiAidatlar(List<dynamic> aidatlar, DateTime gun) {
    return aidatlar.where((aidat) {
      final tarih = _tarihParse(aidat['son_odeme_tarihi']);

      return _ayniGun(tarih, gun);
    }).toList();
  }

  String _tarihFormatla(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  Future<void> _sonOdemeTarihiBelirle(DateTime tarih) async {
    final tarihMetni =
        '${tarih.year}-'
        '${tarih.month.toString().padLeft(2, '0')}-'
        '${tarih.day.toString().padLeft(2, '0')}';

    try {
      await dbService.aidatSonOdemeTarihiGuncelle(tarihMetni);

      if (!mounted) return;

      _yenile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Son ödeme tarihi ${_tarihFormatla(tarih)} olarak belirlendi.',
          ),
          backgroundColor: const Color(0xFF17351B),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: const Color(0xFF351515),
        ),
      );
    }
  }

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();

    final secilen = await showDatePicker(
      context: context,
      initialDate: _secilenGun ?? bugun,
      firstDate: DateTime(bugun.year, bugun.month, bugun.day),
      lastDate: DateTime(bugun.year + 2, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.lightGreenAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF151515),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen == null) return;

    setState(() {
      _secilenGun = secilen;
      _odakGun = secilen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: FutureBuilder<List<dynamic>>(
        future: _aidatlarFuture,
        builder: (context, snapshot) {
          final aidatlar = snapshot.data ?? [];

          final secilenAidatlar = _secilenGun == null
              ? <dynamic>[]
              : _tarihtekiAidatlar(aidatlar, _secilenGun!);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2024, 1, 1),
                lastDay: DateTime(2028, 12, 31),
                focusedDay: _odakGun,
                selectedDayPredicate: (gun) {
                  return isSameDay(_secilenGun, gun);
                },
                eventLoader: (gun) {
                  final bulunanlar = _tarihtekiAidatlar(aidatlar, gun);

                  return bulunanlar.map((e) => 'aidat').toList();
                },
                onDaySelected: (secilen, odaklanan) {
                  setState(() {
                    _secilenGun = secilen;
                    _odakGun = odaklanan;
                  });
                },
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white),
                  outsideTextStyle: TextStyle(color: Colors.grey),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.lightGreenAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.lightGreenAccent,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.grey),
                  weekendStyle: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 10),

              if (widget.antrenorMu)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _tarihSec,
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Son Ödeme Tarihi Belirle',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Expanded(
                child: _secilenGun == null
                    ? const Center(
                        child: Text(
                          'Bir gün seçin',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : secilenAidatlar.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_available,
                                color: Colors.grey,
                                size: 42,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tarihFormatla(_secilenGun!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Bu tarihte son ödeme tarihi bulunmuyor.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: secilenAidatlar.length,
                        itemBuilder: (context, index) {
                          final aidat = secilenAidatlar[index];

                          final odendi = aidat['odendi'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: odendi
                                    ? Colors.lightGreenAccent
                                    : Colors.orangeAccent.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  odendi
                                      ? Icons.check_circle
                                      : Icons.payments_outlined,
                                  color: odendi
                                      ? Colors.lightGreenAccent
                                      : Colors.orangeAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Aidat Son Ödeme Tarihi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _tarihFormatla(_secilenGun!),
                                        style: const TextStyle(
                                          color: Colors.lightGreenAccent,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  odendi ? 'Ödendi' : 'Ödenmedi',
                                  style: TextStyle(
                                    color: odendi
                                        ? Colors.lightGreenAccent
                                        : Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
// ---------------- AİDAT SEKMESİ ----------------

String _guncelAy() {
  final simdi = DateTime.now();
  return '${simdi.year}-${simdi.month.toString().padLeft(2, '0')}';
}

class AidatSekmesi extends StatefulWidget {
  final bool antrenorMu;
  final int? filtreSporcuId;

  const AidatSekmesi({
    super.key,
    required this.antrenorMu,
    this.filtreSporcuId,
  });

  @override
  State<AidatSekmesi> createState() => _AidatSekmesiState();
}

class _AidatSekmesiState extends State<AidatSekmesi> {
  late Future<List<dynamic>> _sporcularFuture;
  late Future<List<dynamic>> _aidatlarFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _sporcularFuture = dbService.getSporcular();
      _aidatlarFuture = dbService.getAidatlar();
    });
  }

  Map<String, dynamic>? _buAyinAidati(List<dynamic> aidatlar, int sporcuId) {
    final ay = _guncelAy();
    try {
      return aidatlar.firstWhere(
        (a) =>
            int.parse(a['athlete_id'].toString()) == sporcuId && a['ay'] == ay,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _aidatOlustur(int sporcuId) async {
    try {
      await dbService.aidatEkle({
        'athlete_id': sporcuId,
        'ay': _guncelAy(),
        'tutar': 1750,
        'son_odeme_tarihi': DateTime.now()
            .add(const Duration(days: 10))
            .toIso8601String()
            .substring(0, 10),
      });
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata (oluştur): $e')));
      }
    }
  }

  Future<void> _odendiIsaretle(int aidatId) async {
    try {
      await dbService.aidatOdendiIsaretle(aidatId);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata (ödeme): $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<dynamic>>(
          future: _sporcularFuture,
          builder: (context, sporcuSnapshot) {
            if (sporcuSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.lightGreenAccent,
                ),
              );
            }
            var sporcular = sporcuSnapshot.data ?? [];
            if (widget.filtreSporcuId != null) {
              sporcular = sporcular
                  .where(
                    (s) =>
                        int.parse(s['id'].toString()) == widget.filtreSporcuId,
                  )
                  .toList();
            }

            return FutureBuilder<List<dynamic>>(
              future: _aidatlarFuture,
              builder: (context, aidatSnapshot) {
                final aidatlar = aidatSnapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${_guncelAy()} Aidat Durumu',
                      style: const TextStyle(
                        color: Colors.lightGreenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...sporcular.map((s) {
                      final sporcu = Sporcu.fromJson(s);
                      final aidat = _buAyinAidati(aidatlar, sporcu.id);
                      final odendiMi = aidat != null && aidat['odendi'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: odendiMi
                                ? Colors.lightGreenAccent
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              odendiMi
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: odendiMi
                                  ? Colors.lightGreenAccent
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sporcu.isim,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (aidat != null)
                                    Text(
                                      odendiMi
                                          ? 'Ödendi'
                                          : 'Son ödeme: ${aidat['son_odeme_tarihi'].toString().substring(0, 10)}',
                                      style: TextStyle(
                                        color: odendiMi
                                            ? Colors.lightGreenAccent
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Bu ay için aidat kaydı yok',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (aidat == null && widget.antrenorMu)
                              TextButton(
                                onPressed: () => _aidatOlustur(sporcu.id),
                                child: const Text(
                                  'Oluştur',
                                  style: TextStyle(
                                    color: Colors.lightGreenAccent,
                                  ),
                                ),
                              )
                            else if (aidat != null && !odendiMi)
                              TextButton(
                                onPressed: () => _odendiIsaretle(
                                  int.parse(aidat['id'].toString()),
                                ),
                                child: const Text(
                                  'Ödendi İşaretle',
                                  style: TextStyle(
                                    color: Colors.lightGreenAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
