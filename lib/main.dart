import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/database_service.dart';
import 'package:video_player/video_player.dart';
import 'screens/sporcu_kayit_ekrani.dart';

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
  final String? dogumTarihi;
  final String? cinsiyet;

  const Sporcu({
    required this.id,
    required this.isim,
    required this.dogumYili,
    required this.grup,
    required this.enIyiDerece,
    required this.enIyiDereceStil,
    required this.enIyiDereceMesafe,
    this.dogumTarihi,
    this.cinsiyet,
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
      dogumTarihi: veri['dogum_tarihi']?.toString(),
      cinsiyet: veri['cinsiyet']?.toString(),
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
    const vurgu = Colors.lightGreenAccent;
    const kartRengi = Color(0xFF141414);
    const alanRengi = Color(0xFF1A1A1A);
    const kenarRengi = Color(0xFF303030);

    final temelTema = ThemeData.dark();

    final yuvarlakSekil = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final tema = temelTema.copyWith(
      primaryColor: vurgu,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: kartRengi,
      dividerColor: kenarRengi,

      colorScheme: const ColorScheme.dark(
        primary: vurgu,
        onPrimary: Colors.black,
        secondary: vurgu,
        onSecondary: Colors.black,
        surface: kartRengi,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.black,
      ),

      appBarTheme: temelTema.appBarTheme.copyWith(
        backgroundColor: Colors.black,
        foregroundColor: vurgu,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: vurgu),
        titleTextStyle: const TextStyle(
          color: vurgu,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: temelTema.cardTheme.copyWith(
        color: kartRengi,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kenarRengi),
        ),
      ),

      bottomSheetTheme: temelTema.bottomSheetTheme.copyWith(
        backgroundColor: kartRengi,
        modalBackgroundColor: kartRengi,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: temelTema.dialogTheme.copyWith(
        backgroundColor: kartRengi,
        surfaceTintColor: Colors.transparent,
        shape: yuvarlakSekil,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: alanRengi,
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.grey),
        prefixIconColor: vurgu,
        suffixIconColor: vurgu,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: kenarRengi),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: kenarRengi),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: vurgu, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vurgu,
          foregroundColor: Colors.black,
          disabledBackgroundColor: kenarRengi,
          disabledForegroundColor: Colors.grey,
          elevation: 0,
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: yuvarlakSekil,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vurgu,
          disabledForegroundColor: Colors.grey,
          side: const BorderSide(color: kenarRengi),
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: yuvarlakSekil,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vurgu,
          minimumSize: const Size(48, 44),
        ),
      ),

      chipTheme: temelTema.chipTheme.copyWith(
        backgroundColor: alanRengi,
        selectedColor: const Color(0xFF243B16),
        disabledColor: alanRengi,
        checkmarkColor: vurgu,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: kenarRengi),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),

      listTileTheme: temelTema.listTileTheme.copyWith(
        textColor: Colors.white,
        iconColor: Colors.grey,
        selectedColor: vurgu,
        selectedTileColor: const Color(0xFF1C2B14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      floatingActionButtonTheme: temelTema.floatingActionButtonTheme.copyWith(
        backgroundColor: vurgu,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: yuvarlakSekil,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: vurgu,
        linearTrackColor: alanRengi,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: vurgu,
        selectionColor: Color(0x553EFF00),
        selectionHandleColor: vurgu,
      ),

      snackBarTheme: temelTema.snackBarTheme.copyWith(
        backgroundColor: const Color(0xFF252525),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: vurgu,
        behavior: SnackBarBehavior.floating,
        shape: yuvarlakSekil,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Poseidon OS',
      theme: tema,
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
          if (_seciliRol == 'sporcu')
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Kayıttan sonra antrenörün hesabını sporcu kaydınla eşleştirecek. Ardından yeniden giriş yapabilirsin.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
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

      ProfilSekmesi(rol: widget.rol, sporcuId: widget.veliSporcuId),
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

// ========================================================
// PROFİL / KARNE YÖNETİMİ
// ========================================================

class ProfilSekmesi extends StatelessWidget {
  final String rol;
  final int? sporcuId;

  const ProfilSekmesi({super.key, required this.rol, this.sporcuId});

  @override
  Widget build(BuildContext context) {
    if (rol == 'antrenor') {
      return const AntrenorKarneYonetimi();
    }

    if (sporcuId == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Bu hesap henüz bir sporcuya bağlanmamış. Antrenöründen Veli / Sporcu Hesapları ekranında eşleştirme yapmasını iste.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return VeliSporcuKarneProfili(sporcuId: sporcuId!);
  }
}

class VeliSporcuKarneProfili extends StatefulWidget {
  final int sporcuId;

  const VeliSporcuKarneProfili({super.key, required this.sporcuId});

  @override
  State<VeliSporcuKarneProfili> createState() => _VeliSporcuKarneProfiliState();
}

class _VeliSporcuKarneProfiliState extends State<VeliSporcuKarneProfili> {
  late Future<List<dynamic>> _karnelerFuture;

  @override
  void initState() {
    super.initState();

    _karnelerFuture = dbService.getKarneler(sporcuId: widget.sporcuId);
  }

  void _yenile() {
    setState(() {
      _karnelerFuture = dbService.getKarneler(sporcuId: widget.sporcuId);
    });
  }

  String _tarihGoster(dynamic hamTarih) {
    if (hamTarih == null) return '-';

    final tarih = DateTime.tryParse(hamTarih.toString());

    if (tarih == null) {
      return hamTarih.toString();
    }

    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: RefreshIndicator(
        onRefresh: () async {
          _yenile();
        },
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<dynamic>>(
          future: _karnelerFuture,
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
                    'Karneler yüklenemedi:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final karneler = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Sporcu Karnesi',
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Gelişim ve değerlendirme geçmişi',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 22),

                if (karneler.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 45,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Colors.grey,
                          size: 42,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Henüz karne bulunmuyor',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Antrenör tarafından oluşturulan karneler burada görünecek.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ...karneler.map<Widget>((karne) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KarneDetayEkrani(
                              karne: Map<String, dynamic>.from(karne),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF292929)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2A1E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_outlined,
                                color: Colors.lightGreenAccent,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gelişim Karnesi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    _tarihGoster(karne['test_date']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
// ========================================================
// KARNE DETAY EKRANI
// ========================================================

class KarneDetayEkrani extends StatelessWidget {
  final Map<String, dynamic> karne;

  const KarneDetayEkrani({super.key, required this.karne});

  String _tarihGoster(dynamic hamTarih) {
    if (hamTarih == null) return '-';

    final tarih = DateTime.tryParse(hamTarih.toString());

    if (tarih == null) {
      return hamTarih.toString();
    }

    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  Map<String, dynamic> _mapAl(dynamic veri) {
    if (veri == null) {
      return {};
    }

    if (veri is Map<String, dynamic>) {
      return veri;
    }

    if (veri is Map) {
      return Map<String, dynamic>.from(veri);
    }

    return {};
  }

  String _deger(dynamic deger) {
    if (deger == null) return '-';

    if (deger is num) {
      if (deger % 1 == 0) {
        return deger.toInt().toString();
      }

      return deger.toString();
    }

    return deger.toString();
  }

  String _etiket(String anahtar) {
    const etiketler = {
      // ANTROPOMETRİK
      'ayak_uzunlugu': 'Ayak Uzunluğu',
      'ayak_genisligi': 'Ayak Genişliği',
      'boy': 'Boy',
      'el_genisligi': 'El Genişliği',
      'el_uzunlugu': 'El Uzunluğu',
      'gogus_cevresi': 'Göğüs Çevresi',
      'kulac_uzunlugu': 'Kulaç Uzunluğu',
      'oturma_yuksekligi': 'Oturma Yüksekliği',
      'vucut_agirligi': 'Vücut Ağırlığı',

      // MOTORİK
      'vki': 'Vücut Kütle İndeksi',
      'otur_eris': 'Otur-Eriş Testi',
      'sirt_kasima_sag': 'Sırt Kaşıma - Sağ',
      'sirt_kasima_sol': 'Sırt Kaşıma - Sol',
      'flamingo': 'Flamingo Denge Testi',

      // TEMEL YÜZME
      'tahtali_serbest_ayak_nefes': 'Tahtalı Serbest Ayak + Nefes',
      'tahtali_sirt_ayak': 'Tahtalı Sırt Ayak',
      'yuzustu_sirtustu_kayma': 'Yüzüstü / Sırtüstü Kayma',
      'suda_kalma_10sn': 'Suda Kalma - 10 sn',
      'suda_ilerleme_12_5m': 'Suda İlerleme - 12,5 m',

      // SERBEST
      'ileri_uzanma': 'İleri Uzanma',
      'nefes_bas_vucut': 'Nefeste Baş / Vücut Pozisyonu',
      '25m_serbest': '25 m Serbest',

      // SIRTÜSTÜ
      'omuz_rotasyonu': 'Omuz Rotasyonu',
      'bas_vucut_pozisyonu': 'Baş / Vücut Pozisyonu',
      '25m_sirtustu': '25 m Sırtüstü',

      // KURBAĞALAMA
      'kol_mekanigi_simetri': 'Kol Mekaniği / Simetri',
      'nefes_zamanlamasi': 'Nefes Zamanlaması',
      'streamline_pozisyonu': 'Streamline Pozisyonu',
      'streamline': 'Streamline Pozisyonu', // eski kayıt uyumluluğu
      '25m_kurbagalama': '25 m Kurbağalama',

      // KELEBEK
      'ayak_mekanigi_dolphin': 'Ayak Mekaniği / İki Dolphin',
      '25m_kelebek': '25 m Kelebek',

      // ORTAK
      'kol_mekanigi': 'Kol Mekaniği',
      'ayak_mekanigi': 'Ayak Mekaniği',
    };

    return etiketler[anahtar] ?? anahtar;
  }

  Widget _bolumBasligi(IconData icon, String baslik) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.lightGreenAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            baslik,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sayisalBolum({
    required String baslik,
    required IconData icon,
    required Map<String, dynamic> veriler,
    required Map<String, String> birimler,
  }) {
    if (veriler.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBasligi(icon, baslik),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF292929)),
          ),
          child: Column(
            children: veriler.entries.map((entry) {
              final birim = birimler[entry.key] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF252525))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _etiket(entry.key),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${_deger(entry.value)}'
                      '${birim.isEmpty ? '' : ' $birim'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  String _stilGenelDurumu(Map<String, dynamic> veriler) {
    if (veriler.isEmpty) {
      return 'degerlendirilmedi';
    }

    final iyiSayisi = veriler.values
        .where((deger) => deger.toString() == 'iyi')
        .length;

    final gelistirilmeliSayisi = veriler.values
        .where((deger) => deger.toString() == 'gelistirilmeli')
        .length;

    // Her yüzme stilinde 5 değerlendirme maddesi var.
    // Beşi de tamamlanmadan genel stil sonucu üretmiyoruz.
    if (iyiSayisi + gelistirilmeliSayisi < 5) {
      return 'degerlendirilmedi';
    }

    // Çoğunluk kuralı: 3 veya daha fazla "İyi" => stil genel olarak İYİ.
    return iyiSayisi >= 3 ? 'iyi' : 'gelistirilmeli';
  }

  Widget _teknikBolum({
    required String baslik,
    required Map<String, dynamic> veriler,
    bool genelSonucGoster = false,
  }) {
    if (veriler.isEmpty) {
      return const SizedBox.shrink();
    }

    final genelDurum = genelSonucGoster
        ? _stilGenelDurumu(veriler)
        : 'degerlendirilmedi';
    final stilIyiMi = genelDurum == 'iyi';
    final genelDegerlendirildiMi = genelDurum != 'degerlendirilmedi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pool, color: Colors.lightGreenAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                baslik,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (genelSonucGoster)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: !genelDegerlendirildiMi
                      ? Colors.grey
                      : stilIyiMi
                      ? Colors.lightGreenAccent
                      : Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  !genelDegerlendirildiMi
                      ? 'DEĞERLENDİRİLMEDİ'
                      : stilIyiMi
                      ? 'İYİ'
                      : 'GELİŞTİRİLMELİ',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        ...veriler.entries.map((entry) {
          final durum = entry.value.toString();
          final iyiMi = durum == 'iyi';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iyiMi
                    ? Colors.lightGreenAccent.withOpacity(0.25)
                    : Colors.orangeAccent.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _etiket(entry.key),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: iyiMi
                        ? Colors.lightGreenAccent
                        : Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    iyiMi ? 'İYİ' : 'GELİŞTİRİLMELİ',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final antropometrik = _mapAl(karne['anthropometric']);

    final motorTestleri = _mapAl(karne['motor_tests']);

    final temelYuzme = _mapAl(karne['basic_swim']);

    final serbest = _mapAl(karne['freestyle']);

    final sirtustu = _mapAl(karne['backstroke']);

    final kurbagalama = _mapAl(karne['breaststroke']);

    final kelebek = _mapAl(karne['butterfly']);

    final antrenorNotu = karne['coach_note']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: const Text(
          'Gelişim Karnesi',
          style: TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===============================================
          // ÜST BİLGİ
          // ===============================================
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.lightGreenAccent.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'POSEIDON AKADEMİ',
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  karne['athlete_isim']?.toString() ?? 'Sporcu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.grey,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tarihGoster(karne['test_date']),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),

                    if (karne['grup'] != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.groups, color: Colors.grey, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        karne['grup'].toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ===============================================
          // ANTROPOMETRİK
          // ===============================================
          _sayisalBolum(
            baslik: 'Antropometrik Ölçümler',
            icon: Icons.straighten,
            veriler: antropometrik,
            birimler: const {
              'ayak_uzunlugu': 'cm',
              'ayak_genisligi': 'cm',
              'boy': 'cm',
              'el_genisligi': 'cm',
              'el_uzunlugu': 'cm',
              'gogus_cevresi': 'cm',
              'kulac_uzunlugu': 'cm',
              'oturma_yuksekligi': 'cm',
              'vucut_agirligi': 'kg',
            },
          ),

          // ===============================================
          // MOTORİK
          // ===============================================
          _sayisalBolum(
            baslik: 'Fiziksel / Motorik Testler',
            icon: Icons.accessibility_new,
            veriler: motorTestleri,
            birimler: const {
              'otur_eris': 'cm',
              'sirt_kasima_sag': 'cm',
              'sirt_kasima_sol': 'cm',
              'flamingo': 'adet',
              'vki': '',
            },
          ),

          // ===============================================
          // TEKNİK
          // ===============================================
          _teknikBolum(baslik: 'Temel Yüzme', veriler: temelYuzme),

          _teknikBolum(
            baslik: 'Serbest Teknik',
            veriler: serbest,
            genelSonucGoster: true,
          ),

          _teknikBolum(
            baslik: 'Sırtüstü Teknik',
            veriler: sirtustu,
            genelSonucGoster: true,
          ),

          _teknikBolum(
            baslik: 'Kurbağalama Teknik',
            veriler: kurbagalama,
            genelSonucGoster: true,
          ),

          _teknikBolum(
            baslik: 'Kelebek Teknik',
            veriler: kelebek,
            genelSonucGoster: true,
          ),

          // ===============================================
          // ANTRENÖR NOTU
          // ===============================================
          if (antrenorNotu.trim().isNotEmpty) ...[
            _bolumBasligi(Icons.edit_note, 'Antrenör Yorumu'),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF292929)),
              ),
              child: Text(
                antrenorNotu,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}
// ========================================================
// ANTRENÖR - KARNE YÖNETİMİ
// ========================================================

class AntrenorKarneYonetimi extends StatefulWidget {
  const AntrenorKarneYonetimi({super.key});

  @override
  State<AntrenorKarneYonetimi> createState() => _AntrenorKarneYonetimiState();
}

class _AntrenorKarneYonetimiState extends State<AntrenorKarneYonetimi> {
  late Future<List<dynamic>> _sporcularFuture;

  @override
  void initState() {
    super.initState();
    _sporcularFuture = dbService.getSporcular();
  }

  void _yenile() {
    setState(() {
      _sporcularFuture = dbService.getSporcular();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: RefreshIndicator(
        onRefresh: () async {
          _yenile();
        },
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<dynamic>>(
          future: _sporcularFuture,
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
                    'Sporcular yüklenemedi:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final sporcular = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Karne Yönetimi',
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Karne oluşturmak veya geçmiş ölçümleri görmek için bir sporcu seç.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 20),

                if (sporcular.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Henüz sporcu bulunmuyor',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...sporcular.map<Widget>((veri) {
                    final sporcu = Sporcu.fromJson(
                      Map<String, dynamic>.from(veri),
                    );

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SporcuKarneleriEkrani(sporcu: sporcu),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF292929)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.lightGreenAccent,
                              child: Text(
                                sporcu.isim.isNotEmpty
                                    ? sporcu.isim[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

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
                                    '${sporcu.dogumYili} · ${sporcu.grup}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons.description_outlined,
                              color: Colors.lightGreenAccent,
                            ),

                            const SizedBox(width: 6),

                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ========================================================
// SEÇİLEN SPORCUNUN KARNELERİ
// ========================================================

class SporcuKarneleriEkrani extends StatefulWidget {
  final Sporcu sporcu;

  const SporcuKarneleriEkrani({super.key, required this.sporcu});

  @override
  State<SporcuKarneleriEkrani> createState() => _SporcuKarneleriEkraniState();
}

class _SporcuKarneleriEkraniState extends State<SporcuKarneleriEkrani> {
  late Future<List<dynamic>> _karnelerFuture;

  @override
  void initState() {
    super.initState();
    _karnelerFuture = dbService.getKarneler(sporcuId: widget.sporcu.id);
  }

  void _yenile() {
    setState(() {
      _karnelerFuture = dbService.getKarneler(sporcuId: widget.sporcu.id);
    });
  }

  String _tarihGoster(dynamic hamTarih) {
    if (hamTarih == null) return '-';

    final tarih = DateTime.tryParse(hamTarih.toString());

    if (tarih == null) {
      return hamTarih.toString();
    }

    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  Map<String, dynamic> _karneMapAl(dynamic veri) {
    if (veri == null) return {};
    if (veri is Map<String, dynamic>) return veri;
    if (veri is Map) return Map<String, dynamic>.from(veri);
    return {};
  }

  double? _karneSayiAl(Map<String, dynamic> karne, String bolum, String alan) {
    final map = _karneMapAl(karne[bolum]);
    final deger = map[alan];
    if (deger == null) return null;
    if (deger is num) return deger.toDouble();
    return double.tryParse(deger.toString().replaceAll(',', '.'));
  }

  int? _testYasi(Map<String, dynamic> karne) {
    final testTarihi = DateTime.tryParse(karne['test_date']?.toString() ?? '');
    if (testTarihi == null) return null;

    DateTime? dogumTarihi = DateTime.tryParse(
      karne['dogum_tarihi']?.toString() ?? '',
    );

    if (dogumTarihi == null && widget.sporcu.dogumYili > 0) {
      dogumTarihi = DateTime(widget.sporcu.dogumYili, 1, 1);
    }

    if (dogumTarihi == null) return null;

    var yas = testTarihi.year - dogumTarihi.year;
    final dogumGunuGecmedi =
        testTarihi.month < dogumTarihi.month ||
        (testTarihi.month == dogumTarihi.month &&
            testTarihi.day < dogumTarihi.day);
    if (dogumGunuGecmedi) yas--;
    return yas;
  }

  String _cinsiyet(Map<String, dynamic> karne) {
    final ham = karne['cinsiyet']?.toString().trim().toLowerCase() ?? '';
    if (ham == 'erkek' || ham == 'male' || ham == 'e') return 'erkek';
    if (ham == 'kız' ||
        ham == 'kiz' ||
        ham == 'kadın' ||
        ham == 'kadin' ||
        ham == 'female' ||
        ham == 'k') {
      return 'kiz';
    }
    return '';
  }

  Map<String, double>? _oturErisNormu(int yas, String cinsiyet) {
    if (cinsiyet != 'erkek' && cinsiyet != 'kiz') return null;
    if (yas >= 6 && yas <= 9) {
      return cinsiyet == 'erkek'
          ? {'min': 15, 'max': 20}
          : {'min': 17, 'max': 22};
    }
    if (yas >= 10 && yas <= 12) {
      return cinsiyet == 'erkek'
          ? {'min': 16, 'max': 22}
          : {'min': 18, 'max': 24};
    }
    if (yas >= 13 && yas <= 15) {
      return cinsiyet == 'erkek'
          ? {'min': 18, 'max': 24}
          : {'min': 20, 'max': 27};
    }
    if (yas >= 16 && yas <= 17) {
      return cinsiyet == 'erkek'
          ? {'min': 20, 'max': 28}
          : {'min': 24, 'max': 30};
    }
    return null;
  }

  Map<String, double>? _flamingoNormu(int yas) {
    if (yas >= 6 && yas <= 9) return {'min': 5, 'max': 8};
    if (yas >= 10 && yas <= 12) return {'min': 4, 'max': 6};
    if (yas >= 13 && yas <= 15) return {'min': 3, 'max': 5};
    if (yas >= 16 && yas <= 17) return {'min': 2, 'max': 4};
    return null;
  }

  Map<String, double>? _sirtKasimaNormu(int yas) {
    if (yas >= 6 && yas <= 9) return {'min': 2, 'max': 5};
    if (yas >= 10 && yas <= 12) return {'min': 0, 'max': 3};
    if (yas >= 13 && yas <= 15) return {'min': 0, 'max': 0};
    if (yas >= 16 && yas <= 17) return {'min': -2, 'max': 2};
    return null;
  }

  String? _fizikselDurum({
    required Map<String, dynamic> karne,
    required String test,
    required double deger,
  }) {
    final yas = _testYasi(karne);
    if (yas == null) return null;

    if (test == 'otur_eris') {
      final norm = _oturErisNormu(yas, _cinsiyet(karne));
      if (norm == null) return null;
      if (deger > norm['max']!) return 'iyi';
      if (deger >= norm['min']!) return 'normal';
      return 'gelistirilmeli';
    }

    if (test == 'flamingo') {
      final norm = _flamingoNormu(yas);
      if (norm == null) return null;
      // Flamingo testinde düşük düşme sayısı daha iyidir.
      if (deger < norm['min']!) return 'iyi';
      if (deger <= norm['max']!) return 'normal';
      return 'gelistirilmeli';
    }

    if (test == 'sirt_kasima') {
      final norm = _sirtKasimaNormu(yas);
      if (norm == null) return null;
      if (deger > norm['max']!) return 'iyi';
      if (deger >= norm['min']!) return 'normal';
      return 'gelistirilmeli';
    }

    if (test == 'vki') {
      // VKİ ham sayıdan değil, yaş+cinsiyete göre persentilden değerlendirilir.
      // Backend/karneye vki_persentil geldiğinde renk sınıflaması otomatik çalışır.
      final motor = _karneMapAl(karne['motor_tests']);
      final pHam = motor['vki_persentil'] ?? karne['vki_persentil'];
      final p = pHam is num
          ? pHam.toDouble()
          : double.tryParse(pHam?.toString().replaceAll(',', '.') ?? '');
      if (p == null) return null;
      if (p >= 5 && p < 85) return 'normal';
      // VKİ'de hedef "sağlıklı aralık"tır; düşük/fazla değerleri "iyi" diye göstermiyoruz.
      return 'gelistirilmeli';
    }

    return null;
  }

  Color _durumRengi(String? durum) {
    switch (durum) {
      case 'iyi':
        return const Color(0xFF42C5C7);
      case 'normal':
        return const Color(0xFFC9BFE7);
      case 'gelistirilmeli':
        return const Color(0xFFF56A86);
      default:
        return const Color(0xFF2E4F8F);
    }
  }

  String _durumEtiketi(String? durum) {
    switch (durum) {
      case 'iyi':
        return 'İYİ';
      case 'normal':
        return 'NORMAL';
      case 'gelistirilmeli':
        return 'GELİŞTİRİLMELİ';
      default:
        return 'DEĞERLENDİRİLEMEDİ';
    }
  }

  int _teknikDurumSayisi(Map<String, dynamic> karne, String arananDurum) {
    const bolumler = [
      'basic_swim',
      'freestyle',
      'backstroke',
      'breaststroke',
      'butterfly',
    ];

    var toplam = 0;
    for (final bolum in bolumler) {
      final map = _karneMapAl(karne[bolum]);
      toplam += map.values
          .where((deger) => deger.toString() == arananDurum)
          .length;
    }
    return toplam;
  }

  String _degerMetni(double deger, String birim) {
    final sayi = deger % 1 == 0
        ? deger.toInt().toString()
        : deger.toStringAsFixed(2);
    return '$sayi${birim.isEmpty ? '' : ' $birim'}';
  }

  String _farkMetni(double fark, String birim) {
    final mutlak = fark.abs();
    final sayi = mutlak % 1 == 0
        ? mutlak.toInt().toString()
        : mutlak.toStringAsFixed(2);
    final isaret = fark > 0
        ? '+'
        : fark < 0
        ? '-'
        : '';
    return '$isaret$sayi${birim.isEmpty ? '' : ' $birim'}';
  }

  Widget _gelisimSatiri({
    required String etiket,
    required double eski,
    required double yeni,
    required String birim,
  }) {
    final fark = yeni - eski;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiket,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Text(
            '${_degerMetni(eski, birim)} → ${_degerMetni(yeni, birim)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _farkMetni(fark, birim),
              style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gelisimOzetiKarti(List<dynamic> hamKarneler) {
    if (hamKarneler.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF292929)),
        ),
        child: const Row(
          children: [
            Icon(Icons.insights, color: Colors.grey, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gelişim karşılaştırması için en az 2 karne gerekli.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final karneler = hamKarneler
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    karneler.sort((a, b) {
      final aTarih = DateTime.tryParse(a['test_date']?.toString() ?? '');
      final bTarih = DateTime.tryParse(b['test_date']?.toString() ?? '');
      if (aTarih == null && bTarih == null) return 0;
      if (aTarih == null) return 1;
      if (bTarih == null) return -1;
      return bTarih.compareTo(aTarih);
    });

    final son = karneler[0];
    final onceki = karneler[1];

    final alanlar = <Map<String, String>>[
      {
        'bolum': 'anthropometric',
        'alan': 'boy',
        'etiket': 'Boy',
        'birim': 'cm',
      },
      {
        'bolum': 'anthropometric',
        'alan': 'kulac_uzunlugu',
        'etiket': 'Kulaç Uzunluğu',
        'birim': 'cm',
      },
      {
        'bolum': 'anthropometric',
        'alan': 'vucut_agirligi',
        'etiket': 'Vücut Ağırlığı',
        'birim': 'kg',
      },
      {
        'bolum': 'motor_tests',
        'alan': 'otur_eris',
        'etiket': 'Otur-Eriş',
        'birim': 'cm',
      },
      {
        'bolum': 'motor_tests',
        'alan': 'flamingo',
        'etiket': 'Flamingo',
        'birim': 'adet',
      },
      {'bolum': 'motor_tests', 'alan': 'vki', 'etiket': 'VKİ', 'birim': ''},
    ];

    final sayisalSatirlar = <Widget>[];
    for (final alan in alanlar) {
      final eski = _karneSayiAl(onceki, alan['bolum']!, alan['alan']!);
      final yeni = _karneSayiAl(son, alan['bolum']!, alan['alan']!);
      if (eski == null || yeni == null) continue;
      sayisalSatirlar.add(
        _gelisimSatiri(
          etiket: alan['etiket']!,
          eski: eski,
          yeni: yeni,
          birim: alan['birim']!,
        ),
      );
    }

    final eskiIyi = _teknikDurumSayisi(onceki, 'iyi');
    final yeniIyi = _teknikDurumSayisi(son, 'iyi');
    final eskiGelistirilmeli = _teknikDurumSayisi(onceki, 'gelistirilmeli');
    final yeniGelistirilmeli = _teknikDurumSayisi(son, 'gelistirilmeli');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101510),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.lightGreenAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.lightGreenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Son Gelişim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_tarihGoster(onceki['test_date'])} → ${_tarihGoster(son['test_date'])}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          if (sayisalSatirlar.isNotEmpty) ...[
            const SizedBox(height: 15),
            ...sayisalSatirlar,
          ],
          const SizedBox(height: 4),
          const Divider(color: Color(0xFF292929)),
          const SizedBox(height: 8),
          const Text(
            'Teknik Değerlendirme',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'İYİ',
                        style: TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$eskiIyi → $yeniIyi  (${yeniIyi - eskiIyi >= 0 ? '+' : ''}${yeniIyi - eskiIyi})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'GELİŞTİRİLMELİ',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$eskiGelistirilmeli → $yeniGelistirilmeli  (${yeniGelistirilmeli - eskiGelistirilmeli >= 0 ? '+' : ''}${yeniGelistirilmeli - eskiGelistirilmeli})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _siraliKarneler(List<dynamic> hamKarneler) {
    final karneler = hamKarneler
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    karneler.sort((a, b) {
      final aTarih = DateTime.tryParse(a['test_date']?.toString() ?? '');
      final bTarih = DateTime.tryParse(b['test_date']?.toString() ?? '');
      if (aTarih == null && bTarih == null) return 0;
      if (aTarih == null) return 1;
      if (bTarih == null) return -1;
      return aTarih.compareTo(bTarih);
    });

    return karneler;
  }

  Widget _sayisalGelisimGrafigi({
    required List<Map<String, dynamic>> karneler,
    required String baslik,
    required String bolum,
    required String alan,
    required String birim,
    List<Map<String, dynamic>> seviyeBantlari = const [],
    String? normTesti,
  }) {
    final degerler = <double?>[];

    for (final karne in karneler) {
      degerler.add(_karneSayiAl(karne, bolum, alan));
    }

    final doluDegerler = degerler.whereType<double>().toList();

    if (doluDegerler.length < 2) {
      return const SizedBox.shrink();
    }

    double enBuyuk = doluDegerler.reduce((a, b) => a > b ? a : b);

    for (final bant in seviyeBantlari) {
      final max = (bant['max'] as num?)?.toDouble();
      if (max != null && max > enBuyuk) {
        enBuyuk = max;
      }
    }

    double maxY = enBuyuk <= 0 ? 10 : enBuyuk * 1.12;
    if (maxY < 10) maxY = 10;

    const grafikArkaPlan = Color(0xFFF7F0E6);
    const sutunRengi = Color(0xFF2E4F8F);
    const eksenRengi = Color(0xFF334155);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF292929)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (birim.isNotEmpty)
                Text(
                  birim,
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 10, 8),
            decoration: BoxDecoration(
              color: grafikArkaPlan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  if (seviyeBantlari.isNotEmpty)
                    Positioned.fill(
                      left: 34,
                      right: 2,
                      top: 4,
                      bottom: 31,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: seviyeBantlari.map((bant) {
                              final min =
                                  (bant['min'] as num?)?.toDouble() ?? 0;
                              final max =
                                  (bant['max'] as num?)?.toDouble() ?? 0;
                              final renk =
                                  bant['renk'] as Color? ?? Colors.transparent;

                              final yukseklik = constraints.maxHeight;
                              final ust =
                                  yukseklik *
                                  (1 - (max / maxY).clamp(0.0, 1.0));
                              final alt =
                                  yukseklik * ((min / maxY).clamp(0.0, 1.0));

                              return Positioned(
                                left: 0,
                                right: 0,
                                top: ust,
                                bottom: alt,
                                child: Container(color: renk),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFF6B7280).withOpacity(0.20),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Color(0xFF64748B)),
                          bottom: BorderSide(color: Color(0xFF64748B)),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                                style: const TextStyle(
                                  color: eksenRengi,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 31,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= karneler.length) {
                                return const SizedBox.shrink();
                              }

                              final tarih = _tarihGoster(
                                karneler[index]['test_date'],
                              );

                              return Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  tarih,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: eksenRengi,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(karneler.length, (index) {
                        final deger = degerler[index] ?? 0;
                        final durum =
                            normTesti == null || degerler[index] == null
                            ? null
                            : _fizikselDurum(
                                karne: karneler[index],
                                test: normTesti,
                                deger: deger,
                              );

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: deger,
                              width: 24,
                              color: normTesti == null
                                  ? sutunRengi
                                  : _durumRengi(durum),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ],
                          showingTooltipIndicators: const [],
                        );
                      }),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final deger = degerler[group.x];
                            if (deger == null) return null;
                            return BarTooltipItem(
                              '${_degerMetni(deger, birim)}\n'
                              '${_tarihGoster(karneler[group.x]['test_date'])}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (seviyeBantlari.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: seviyeBantlari.map((bant) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: bant['renk'] as Color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      bant['etiket']?.toString() ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          if (normTesti != null) ...[
            const SizedBox(height: 11),
            Builder(
              builder: (context) {
                int? sonIndex;
                for (var i = degerler.length - 1; i >= 0; i--) {
                  if (degerler[i] != null) {
                    sonIndex = i;
                    break;
                  }
                }
                if (sonIndex == null) return const SizedBox.shrink();
                final sonDeger = degerler[sonIndex]!;
                final durum = _fizikselDurum(
                  karne: karneler[sonIndex],
                  test: normTesti,
                  deger: sonDeger,
                );
                final yas = _testYasi(karneler[sonIndex]);
                final cinsiyet = _cinsiyet(karneler[sonIndex]);
                final bilgiEksik = durum == null;
                final renk = _durumRengi(durum);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: bilgiEksik
                        ? const Color(0xFF222222)
                        : renk.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: bilgiEksik
                          ? Colors.grey.shade800
                          : renk.withOpacity(0.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: bilgiEksik ? Colors.grey : renk,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          bilgiEksik
                              ? (normTesti == 'vki'
                                    ? 'VKİ için yaş+cinsiyete göre persentil bilgisi gerekli.'
                                    : 'Yaş/cinsiyet bilgisi eksik olduğu için norm değerlendirmesi yapılamadı.')
                              : '${_durumEtiketi(durum)} · ${yas ?? '-'} yaş${cinsiyet.isEmpty ? '' : ' · ${cinsiyet == 'erkek' ? 'Erkek' : 'Kız'}'}',
                          style: TextStyle(
                            color: bilgiEksik ? Colors.grey : renk,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _teknikGelisimGrafigi(List<Map<String, dynamic>> karneler) {
    if (karneler.length < 2) return const SizedBox.shrink();

    final iyiDegerleri = <int>[];
    final gelistirilmeliDegerleri = <int>[];

    for (final karne in karneler) {
      iyiDegerleri.add(_teknikDurumSayisi(karne, 'iyi'));
      gelistirilmeliDegerleri.add(_teknikDurumSayisi(karne, 'gelistirilmeli'));
    }

    final enBuyukIyi = iyiDegerleri.reduce((a, b) => a > b ? a : b);
    final enBuyukGel = gelistirilmeliDegerleri.reduce((a, b) => a > b ? a : b);
    final enBuyuk = enBuyukIyi > enBuyukGel ? enBuyukIyi : enBuyukGel;
    final maxY = (enBuyuk + 3).toDouble();

    const iyiRengi = Color(0xFF42C5C7);
    const gelistirilmeliRengi = Color(0xFFF56A86);
    const grafikArkaPlan = Color(0xFFF7F0E6);
    const eksenRengi = Color(0xFF334155);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF292929)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teknik Değerlendirme Gelişimi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            children: [
              Icon(Icons.square, color: iyiRengi, size: 12),
              SizedBox(width: 5),
              Text('İyi', style: TextStyle(color: Colors.grey, fontSize: 10)),
              SizedBox(width: 16),
              Icon(Icons.square, color: gelistirilmeliRengi, size: 12),
              SizedBox(width: 5),
              Text(
                'Geliştirilmeli',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 10, 8),
            decoration: BoxDecoration(
              color: grafikArkaPlan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFF6B7280).withOpacity(0.20),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Color(0xFF64748B)),
                      bottom: BorderSide(color: Color(0xFF64748B)),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: eksenRengi,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 31,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= karneler.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              _tarihGoster(karneler[index]['test_date']),
                              style: const TextStyle(
                                color: eksenRengi,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(karneler.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: iyiDegerleri[index].toDouble(),
                          width: 12,
                          color: iyiRengi,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                        BarChartRodData(
                          toY: gelistirilmeliDegerleri[index].toDouble(),
                          width: 12,
                          color: gelistirilmeliRengi,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gelisimGrafikleri(List<dynamic> hamKarneler) {
    final karneler = _siraliKarneler(hamKarneler);

    if (karneler.length < 2) {
      return const SizedBox.shrink();
    }

    final grafikler = <Widget>[
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Boy Gelişimi',
        bolum: 'anthropometric',
        alan: 'boy',
        birim: 'cm',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Kulaç Uzunluğu',
        bolum: 'anthropometric',
        alan: 'kulac_uzunlugu',
        birim: 'cm',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Vücut Ağırlığı',
        bolum: 'anthropometric',
        alan: 'vucut_agirligi',
        birim: 'kg',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Vücut Kütle İndeksi',
        bolum: 'motor_tests',
        alan: 'vki',
        birim: '',
        normTesti: 'vki',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Otur-Eriş Testi',
        bolum: 'motor_tests',
        alan: 'otur_eris',
        birim: 'cm',
        normTesti: 'otur_eris',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Sırt Kaşıma Testi · Sağ',
        bolum: 'motor_tests',
        alan: 'sirt_kasima_sag',
        birim: 'cm',
        normTesti: 'sirt_kasima',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Sırt Kaşıma Testi · Sol',
        bolum: 'motor_tests',
        alan: 'sirt_kasima_sol',
        birim: 'cm',
        normTesti: 'sirt_kasima',
      ),
      _sayisalGelisimGrafigi(
        karneler: karneler,
        baslik: 'Flamingo Denge Testi',
        bolum: 'motor_tests',
        alan: 'flamingo',
        birim: 'adet',
        normTesti: 'flamingo',
      ),
      _teknikGelisimGrafigi(karneler),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.lightGreenAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Gelişim Grafikleri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Her ölçüm, test tarihindeki yaş ve uygun olduğunda cinsiyet normuna göre değerlendirilir.',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _NormLejant(renk: Color(0xFF42C5C7), metin: 'İyi'),
            _NormLejant(renk: Color(0xFFC9BFE7), metin: 'Normal'),
            _NormLejant(renk: Color(0xFFF56A86), metin: 'Geliştirilmeli'),
          ],
        ),
        const SizedBox(height: 14),
        ...grafikler,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        title: Text(
          '${widget.sporcu.isim} · Karneler',
          style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _yenile();
        },
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,

        child: FutureBuilder<List<dynamic>>(
          future: _karnelerFuture,
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
                    'Karneler yüklenemedi:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final karneler = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---------------- SPORCU BİLGİSİ ----------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.lightGreenAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.lightGreenAccent,
                        child: Text(
                          widget.sporcu.isim.isNotEmpty
                              ? widget.sporcu.isim[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
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

                            const SizedBox(height: 4),

                            Text(
                              '${widget.sporcu.dogumYili} · ${widget.sporcu.grup}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _gelisimOzetiKarti(karneler),

                if (karneler.length >= 2) ...[
                  const SizedBox(height: 24),
                  _gelisimGrafikleri(karneler),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Geçmiş Karneler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2A1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${karneler.length} karne',
                        style: const TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (karneler.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Colors.grey,
                          size: 42,
                        ),

                        SizedBox(height: 12),

                        Text(
                          'Henüz karne oluşturulmamış',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'İlk ölçüm karnesini oluşturmak için aşağıdaki + butonunu kullan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ...karneler.map<Widget>((karne) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KarneDetayEkrani(
                              karne: Map<String, dynamic>.from(karne),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2A1E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_outlined,
                                color: Colors.lightGreenAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ölçüm Karnesi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _tarihGoster(karne['test_date']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightGreenAccent,
        foregroundColor: Colors.black,
        onPressed: () async {
          final kaydedildi = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => KarneOlusturEkrani(sporcu: widget.sporcu),
            ),
          );
          if (kaydedildi == true && mounted) {
            _yenile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Karne',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _NormLejant extends StatelessWidget {
  final Color renk;
  final String metin;

  const _NormLejant({required this.renk, required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(metin, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

// ========================================================
// KARNE OLUŞTURMA EKRANI
// ========================================================

class KarneOlusturEkrani extends StatefulWidget {
  final Sporcu sporcu;

  const KarneOlusturEkrani({super.key, required this.sporcu});

  @override
  State<KarneOlusturEkrani> createState() => _KarneOlusturEkraniState();
}

class _KarneOlusturEkraniState extends State<KarneOlusturEkrani> {
  DateTime _testTarihi = DateTime.now();

  bool _kaydediliyor = false;

  // =====================================================
  // ANTROPOMETRİK
  // =====================================================

  final _ayakUzunluguController = TextEditingController();

  final _ayakGenisligiController = TextEditingController();

  final _boyController = TextEditingController();

  final _elGenisligiController = TextEditingController();

  final _elUzunluguController = TextEditingController();

  final _gogusCevresiController = TextEditingController();

  final _kulacUzunluguController = TextEditingController();

  final _oturmaYuksekligiController = TextEditingController();

  final _vucutAgirligiController = TextEditingController();

  // =====================================================
  // MOTORİK TESTLER
  // =====================================================

  final _oturErisController = TextEditingController();

  final _sirtKasimaSagController = TextEditingController();

  final _sirtKasimaSolController = TextEditingController();

  final _flamingoController = TextEditingController();

  // =====================================================
  // ANTRENÖR NOTU
  // =====================================================

  final _notController = TextEditingController();

  // =====================================================
  // TEKNİK DEĞERLENDİRMELER
  // =====================================================

  final Map<String, String> _temelYuzme = {};
  final Map<String, String> _serbest = {};
  final Map<String, String> _sirtustu = {};
  final Map<String, String> _kurbagalama = {};
  final Map<String, String> _kelebek = {};

  // =====================================================
  // SAYI DÖNÜŞÜMÜ
  // =====================================================

  double? _sayi(TextEditingController controller) {
    final metin = controller.text.trim().replaceAll(',', '.');

    if (metin.isEmpty) {
      return null;
    }

    return double.tryParse(metin);
  }

  // =====================================================
  // VKİ
  // =====================================================

  double? _vkiHesapla() {
    final boyCm = _sayi(_boyController);
    final kilo = _sayi(_vucutAgirligiController);

    if (boyCm == null ||
        kilo == null ||
        boyCm < 30 ||
        boyCm > 300 ||
        kilo <= 0) {
      return null;
    }

    final boyMetre = boyCm / 100;

    return kilo / (boyMetre * boyMetre);
  }

  // =====================================================
  // TARİH
  // =====================================================

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _testTarihi,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.lightGreenAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF171717),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      setState(() {
        _testTarihi = secilen;
      });
    }
  }

  String _veritabaniTarihi(DateTime tarih) {
    return '${tarih.year}-'
        '${tarih.month.toString().padLeft(2, '0')}-'
        '${tarih.day.toString().padLeft(2, '0')}';
  }

  String _gosterimTarihi(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  // =====================================================
  // BOŞ OLMAYAN SAYILARI JSON'A EKLE
  // =====================================================

  void _sayisalAlanEkle(
    Map<String, dynamic> harita,
    String anahtar,
    TextEditingController controller,
  ) {
    final deger = _sayi(controller);

    if (deger != null) {
      harita[anahtar] = deger;
    }
  }

  // =====================================================
  // KAYDET
  // =====================================================

  String? _olcumHatasi() {
    final alanlar = <TextEditingController, String>{
      _ayakUzunluguController: 'Ayak uzunluğu',
      _ayakGenisligiController: 'Ayak genişliği',
      _boyController: 'Boy',
      _elGenisligiController: 'El genişliği',
      _elUzunluguController: 'El uzunluğu',
      _gogusCevresiController: 'Göğüs çevresi',
      _kulacUzunluguController: 'Kulaç uzunluğu',
      _oturmaYuksekligiController: 'Oturma yüksekliği',
      _vucutAgirligiController: 'Vücut ağırlığı',
      _oturErisController: 'Otur-eriş',
      _sirtKasimaSagController: 'Sırt kaşıma sağ',
      _sirtKasimaSolController: 'Sırt kaşıma sol',
      _flamingoController: 'Flamingo',
    };
    for (final alan in alanlar.entries) {
      if (alan.key.text.trim().isEmpty) continue;
      final v = _sayi(alan.key);
      if (v == null || !v.isFinite)
        return '${alan.value}: geçerli bir sayı gir.';
      final esneklik = [
        _oturErisController,
        _sirtKasimaSagController,
        _sirtKasimaSolController,
      ].contains(alan.key);
      if (!esneklik && alan.key != _flamingoController && v <= 0) {
        return '${alan.value}: sıfırdan büyük olmalı.';
      }
      if (alan.key == _boyController && (v < 30 || v > 300)) {
        return 'Boyu santimetre olarak gir: örneğin 1,57 yerine 157.';
      }
      if (alan.key == _flamingoController &&
          (v < 0 || v != v.roundToDouble())) {
        return 'Flamingo hata sayısı sıfır veya pozitif tam sayı olmalı.';
      }
    }
    return null;
  }

  Future<void> _kaydet() async {
    final hata = _olcumHatasi();
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata)));
      return;
    }
    final antropometrik = <String, dynamic>{};

    _sayisalAlanEkle(antropometrik, 'ayak_uzunlugu', _ayakUzunluguController);

    _sayisalAlanEkle(antropometrik, 'ayak_genisligi', _ayakGenisligiController);

    _sayisalAlanEkle(antropometrik, 'boy', _boyController);

    _sayisalAlanEkle(antropometrik, 'el_genisligi', _elGenisligiController);

    _sayisalAlanEkle(antropometrik, 'el_uzunlugu', _elUzunluguController);

    _sayisalAlanEkle(antropometrik, 'gogus_cevresi', _gogusCevresiController);

    _sayisalAlanEkle(antropometrik, 'kulac_uzunlugu', _kulacUzunluguController);

    _sayisalAlanEkle(
      antropometrik,
      'oturma_yuksekligi',
      _oturmaYuksekligiController,
    );

    _sayisalAlanEkle(antropometrik, 'vucut_agirligi', _vucutAgirligiController);

    final motorTestleri = <String, dynamic>{};

    _sayisalAlanEkle(motorTestleri, 'otur_eris', _oturErisController);

    _sayisalAlanEkle(
      motorTestleri,
      'sirt_kasima_sag',
      _sirtKasimaSagController,
    );

    _sayisalAlanEkle(
      motorTestleri,
      'sirt_kasima_sol',
      _sirtKasimaSolController,
    );

    _sayisalAlanEkle(motorTestleri, 'flamingo', _flamingoController);

    final vki = _vkiHesapla();

    if (vki != null) {
      motorTestleri['vki'] = double.parse(vki.toStringAsFixed(2));
    }

    if (antropometrik.isEmpty &&
        motorTestleri.isEmpty &&
        _temelYuzme.isEmpty &&
        _serbest.isEmpty &&
        _sirtustu.isEmpty &&
        _kurbagalama.isEmpty &&
        _kelebek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karne için en az bir ölçüm veya değerlendirme gir.'),
        ),
      );

      return;
    }

    setState(() {
      _kaydediliyor = true;
    });

    try {
      await dbService.karneEkle({
        'athlete_id': widget.sporcu.id,

        'test_date': _veritabaniTarihi(_testTarihi),

        'anthropometric': antropometrik,

        'motor_tests': motorTestleri,

        'basic_swim': _temelYuzme,

        'freestyle': _serbest,

        'backstroke': _sirtustu,

        'breaststroke': _kurbagalama,

        'butterfly': _kelebek,

        'coach_note': _notController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karne başarıyla kaydedildi ✓'),
          backgroundColor: Color(0xFF17351B),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Karne kaydedilemedi: $e'),
          backgroundColor: const Color(0xFF351515),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _kaydediliyor = false;
        });
      }
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _ayakUzunluguController.dispose();
    _ayakGenisligiController.dispose();
    _boyController.dispose();
    _elGenisligiController.dispose();
    _elUzunluguController.dispose();
    _gogusCevresiController.dispose();
    _kulacUzunluguController.dispose();
    _oturmaYuksekligiController.dispose();
    _vucutAgirligiController.dispose();

    _oturErisController.dispose();
    _sirtKasimaSagController.dispose();
    _sirtKasimaSolController.dispose();
    _flamingoController.dispose();

    _notController.dispose();

    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final vki = _vkiHesapla();

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,

        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),

        title: Text(
          '${widget.sporcu.isim} · Yeni Karne',
          style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =================================================
          // TARİH
          // =================================================
          _KarneBolumBasligi(icon: Icons.calendar_month, baslik: 'Test Tarihi'),

          const SizedBox(height: 10),

          InkWell(
            onTap: _tarihSec,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.lightGreenAccent),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _gosterimTarihi(_testTarihi),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // =================================================
          // ANTROPOMETRİK
          // =================================================
          _KarneBolumBasligi(
            icon: Icons.straighten,
            baslik: 'Antropometrik Ölçümler',
          ),

          const SizedBox(height: 12),

          _KarneSayisalAlan(
            controller: _ayakUzunluguController,
            etiket: 'Ayak Uzunluğu',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _ayakGenisligiController,
            etiket: 'Ayak Genişliği',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _boyController,
            etiket: 'Boy (ör. 157)',
            birim: 'cm',
            onChanged: (_) {
              setState(() {});
            },
          ),

          _KarneSayisalAlan(
            controller: _elGenisligiController,
            etiket: 'El Genişliği',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _elUzunluguController,
            etiket: 'El Uzunluğu',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _gogusCevresiController,
            etiket: 'Göğüs Çevresi',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _kulacUzunluguController,
            etiket: 'Kulaç Uzunluğu',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _oturmaYuksekligiController,
            etiket: 'Oturma Yüksekliği',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _vucutAgirligiController,
            etiket: 'Vücut Ağırlığı',
            birim: 'kg',
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 12),

          // =================================================
          // VKİ
          // =================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101510),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.lightGreenAccent.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_weight_outlined,
                  color: Colors.lightGreenAccent,
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Vücut Kütle İndeksi',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),

                Text(
                  vki == null ? 'Boy ve kilo gir' : vki.toStringAsFixed(2),
                  style: TextStyle(
                    color: vki == null ? Colors.grey : Colors.lightGreenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // =================================================
          // MOTORİK
          // =================================================
          _KarneBolumBasligi(
            icon: Icons.accessibility_new,
            baslik: 'Fiziksel / Motorik Testler',
          ),

          const SizedBox(height: 12),

          _KarneSayisalAlan(
            controller: _oturErisController,
            etiket: 'Otur-Eriş Testi',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _sirtKasimaSagController,
            etiket: 'Sırt Kaşıma Testi - Sağ',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _sirtKasimaSolController,
            etiket: 'Sırt Kaşıma Testi - Sol',
            birim: 'cm',
          ),

          _KarneSayisalAlan(
            controller: _flamingoController,
            etiket: 'Flamingo Denge Testi',
            birim: 'adet',
          ),

          const SizedBox(height: 28),

          // =================================================
          // TEMEL YÜZME
          // =================================================
          _KarneTeknikBolumu(
            baslik: 'Temel Yüzme',
            icon: Icons.pool,
            degerler: _temelYuzme,
            maddeler: const {
              'tahtali_serbest_ayak_nefes': 'Tahtalı Serbest Ayak + Nefes',

              'tahtali_sirt_ayak': 'Tahtalı Sırt Ayak',

              'yuzustu_sirtustu_kayma': 'Yüzüstü / Sırtüstü Kayma',

              'suda_kalma_10sn': 'Suda Kalma - 10 sn',

              'suda_ilerleme_12_5m': 'Suda İlerleme - 12,5 m',
            },
            onChanged: () {
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // =================================================
          // SERBEST
          // =================================================
          _KarneTeknikBolumu(
            baslik: 'Serbest Teknik',
            icon: Icons.pool,
            degerler: _serbest,
            maddeler: const {
              'kol_mekanigi': 'Kol Mekaniği - Çekiş / İtiş / Toparlanma',

              'ileri_uzanma': 'İleri Uzanma',

              'ayak_mekanigi': 'Ayak Mekaniği',

              'nefes_bas_vucut': 'Nefeste Baş / Vücut Pozisyonu',

              '25m_serbest': '25 m Serbest',
            },
            onChanged: () {
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // =================================================
          // SIRTÜSTÜ
          // =================================================
          _KarneTeknikBolumu(
            baslik: 'Sırtüstü Teknik',
            icon: Icons.pool,
            degerler: _sirtustu,
            maddeler: const {
              'kol_mekanigi': 'Kol Mekaniği',

              'omuz_rotasyonu': 'Omuz Rotasyonu',

              'ayak_mekanigi': 'Ayak Mekaniği',

              'bas_vucut_pozisyonu': 'Baş / Vücut Pozisyonu',

              '25m_sirtustu': '25 m Sırtüstü',
            },
            onChanged: () {
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // =================================================
          // KURBAĞALAMA
          // =================================================
          _KarneTeknikBolumu(
            baslik: 'Kurbağalama Teknik',
            icon: Icons.pool,
            degerler: _kurbagalama,
            maddeler: const {
              'kol_mekanigi_simetri': 'Kol Mekaniği / Simetri',

              'ayak_mekanigi': 'Ayak Mekaniği',

              'nefes_zamanlamasi': 'Nefes Zamanlaması',

              'streamline_pozisyonu': 'Streamline Pozisyonu',

              '25m_kurbagalama': '25 m Kurbağalama',
            },
            onChanged: () {
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // =================================================
          // KELEBEK
          // =================================================
          _KarneTeknikBolumu(
            baslik: 'Kelebek Teknik',
            icon: Icons.pool,
            degerler: _kelebek,
            maddeler: const {
              'kol_mekanigi': 'Kol Mekaniği',

              'ayak_mekanigi_dolphin': 'Ayak Mekaniği / İki Dolphin',

              'nefes_zamanlamasi': 'Nefes Zamanlaması',

              'bas_vucut_pozisyonu': 'Baş / Vücut Pozisyonu',

              '25m_kelebek': '25 m Kelebek',
            },
            onChanged: () {
              setState(() {});
            },
          ),

          const SizedBox(height: 28),

          // =================================================
          // NOT
          // =================================================
          _KarneBolumBasligi(icon: Icons.edit_note, baslik: 'Antrenör Yorumu'),

          const SizedBox(height: 12),

          TextField(
            controller: _notController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Sporcunun gelişimi hakkında not...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF171717),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.lightGreenAccent),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // =================================================
          // KAYDET
          // =================================================
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                foregroundColor: Colors.black,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              icon: _kaydediliyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.save),

              label: Text(
                _kaydediliyor ? 'Kaydediliyor...' : 'Karneyi Kaydet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ========================================================
// KARNE FORM YARDIMCILARI
// ========================================================

class _KarneBolumBasligi extends StatelessWidget {
  final IconData icon;
  final String baslik;

  const _KarneBolumBasligi({required this.icon, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightGreenAccent, size: 20),

        const SizedBox(width: 8),

        Text(
          baslik,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _KarneSayisalAlan extends StatelessWidget {
  final TextEditingController controller;
  final String etiket;
  final String birim;

  final ValueChanged<String>? onChanged;

  const _KarneSayisalAlan({
    required this.controller,
    required this.etiket,
    required this.birim,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: TextField(
        controller: controller,

        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),

        onChanged: onChanged,

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          labelText: etiket,

          labelStyle: const TextStyle(color: Colors.grey),

          suffixText: birim,

          suffixStyle: const TextStyle(color: Colors.lightGreenAccent),

          filled: true,

          fillColor: const Color(0xFF171717),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(color: Colors.lightGreenAccent),
          ),
        ),
      ),
    );
  }
}

class _KarneTeknikBolumu extends StatelessWidget {
  final String baslik;
  final IconData icon;

  final Map<String, String> degerler;

  final Map<String, String> maddeler;

  final VoidCallback onChanged;

  const _KarneTeknikBolumu({
    required this.baslik,
    required this.icon,
    required this.degerler,
    required this.maddeler,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _KarneBolumBasligi(icon: icon, baslik: baslik),

        const SizedBox(height: 12),

        ...maddeler.entries.map((madde) {
          final secili = degerler[madde.key];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),

            padding: const EdgeInsets.all(13),

            decoration: BoxDecoration(
              color: const Color(0xFF171717),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: const Color(0xFF292929)),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  madde.value,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _KarneDegerlendirmeButonu(
                        metin: 'İYİ',

                        secili: secili == 'iyi',

                        iyiMi: true,

                        onTap: () {
                          degerler[madde.key] = 'iyi';

                          onChanged();
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _KarneDegerlendirmeButonu(
                        metin: 'GELİŞTİRİLMELİ',

                        secili: secili == 'gelistirilmeli',

                        iyiMi: false,

                        onTap: () {
                          degerler[madde.key] = 'gelistirilmeli';

                          onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _KarneDegerlendirmeButonu extends StatelessWidget {
  final String metin;
  final bool secili;
  final bool iyiMi;
  final VoidCallback onTap;

  const _KarneDegerlendirmeButonu({
    required this.metin,
    required this.secili,
    required this.iyiMi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = iyiMi ? Colors.lightGreenAccent : Colors.orangeAccent;

    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(8),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),

        decoration: BoxDecoration(
          color: secili ? renk : const Color(0xFF222222),

          borderRadius: BorderRadius.circular(8),

          border: Border.all(
            color: secili ? renk : Colors.grey.withOpacity(0.3),
          ),
        ),

        alignment: Alignment.center,

        child: Text(
          metin,

          style: TextStyle(
            color: secili ? Colors.black : Colors.grey,

            fontSize: 10,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ---------------- KULLANICI YÖNETİMİ (VELİ / SPORCU HESAPLARI) ----------------
class KullaniciYonetimEkrani extends StatefulWidget {
  const KullaniciYonetimEkrani({super.key});
  @override
  State<KullaniciYonetimEkrani> createState() => _KullaniciYonetimEkraniState();
}

class _KullaniciYonetimEkraniState extends State<KullaniciYonetimEkrani> {
  late Future<List<List<dynamic>>> _verilerFuture;
  String _rolFiltresi = 'veli';
  bool _islemSuruyor = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _verilerFuture = Future.wait<List<dynamic>>([
        dbService.getKullanicilar(),
        dbService.getSporcular(),
      ]);
    });
  }

  Future<void> _yenile() async {
    _reload();
    try {
      await _verilerFuture;
    } catch (_) {
      // Hata FutureBuilder içinde gösterilir.
    }
  }

  String _sporcuAciklamasi(dynamic s) {
    final yil = s['dogum_yili']?.toString() ?? '-';
    final grup = s['grup']?.toString() ?? '-';
    return 'Doğum yılı: $yil · Grup: $grup · Sporcu No: ${s['id']}';
  }

  Future<void> _eslestirmeyiDuzenle(Map<String, dynamic> kullanici) async {
    if (_islemSuruyor) return;
    setState(() => _islemSuruyor = true);
    try {
      // Her açılışta sunucudan al: önceki ekranın listesi kullanılmaz.
      final veriler = await Future.wait<List<dynamic>>([
        dbService.getSporcular(),
        dbService.getKullanicilar(),
      ]);
      if (!mounted) return;
      final sporcular = veriler[0];
      final hesaplar = veriler[1];
      final guncel = hesaplar.firstWhere(
        (k) => k['id'].toString() == kullanici['id'].toString(),
        orElse: () => null,
      );
      if (guncel == null)
        throw Exception('Bu hesap artık listede yok. Listeyi yenile.');
      final veliMi = guncel['role'] == 'veli';
      int? seciliId = int.tryParse(guncel['athlete_id']?.toString() ?? '');
      String arama = '';
      final sonuc = await showModalBottomSheet<Map<String, int?>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF141414),
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final liste = sporcular
                .where(
                  (s) => '${s['isim']} ${s['id']} ${s['grup']}'
                      .toLowerCase()
                      .contains(arama.toLowerCase()),
                )
                .toList();
            final seciliMevcut =
                seciliId == null ||
                sporcular.any((s) => s['id'].toString() == seciliId.toString());
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        veliMi
                            ? 'Velinin Çocuğunu Seç'
                            : 'Sporcu Hesabını Eşleştir',
                        style: const TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${veliMi ? 'Veli hesabı' : 'Sporcu hesabı'}: ${guncel['email']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kulüpteki sporcu kayıtları listelenir. Çocuğun ayrıca giriş hesabı olması gerekmez.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Çocuk adı, grup veya sporcu numarası ara',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setModalState(() => arama = v),
                      ),
                      if (!seciliMevcut)
                        const Text(
                          'Önceki sporcu kaydı bulunamadı. Yeni bir sporcu seç veya bağlantıyı kaldır.',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      Expanded(
                        child: ListView(
                          children: [
                            ListTile(
                              leading: Icon(
                                seciliId == null
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                              title: const Text(
                                'Bağlantı yok / bağlantıyı kaldır',
                              ),
                              onTap: () => setModalState(() => seciliId = null),
                            ),
                            if (liste.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  sporcular.isEmpty
                                      ? 'Kayıtlı sporcu yok. Önce Sporcular bölümünden ekle.'
                                      : 'Aramaya uygun sporcu bulunamadı.',
                                ),
                              ),
                            ...liste.map<Widget>((s) {
                              final id = int.parse(s['id'].toString());
                              final girisHesabiVar = hesaplar.any(
                                (k) =>
                                    k['role'] == 'sporcu' &&
                                    k['athlete_id']?.toString() ==
                                        id.toString(),
                              );
                              return ListTile(
                                selected: seciliId == id,
                                selectedColor: Colors.lightGreenAccent,
                                leading: Icon(
                                  seciliId == id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                ),
                                title: Text(
                                  s['isim']?.toString() ?? 'İsimsiz sporcu',
                                ),
                                subtitle: Text(
                                  '${_sporcuAciklamasi(s)}\n${girisHesabiVar ? 'Sporcu giriş hesabı bağlı' : 'Sporcu giriş hesabı bağlı değil'}',
                                ),
                                isThreeLine: true,
                                onTap: () => setModalState(() => seciliId = id),
                              );
                            }),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Vazgeç'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: !seciliMevcut
                                ? null
                                : () => Navigator.pop(
                                    sheetContext,
                                    <String, int?>{'athlete_id': seciliId},
                                  ),
                            child: const Text('Eşleştirmeyi Kaydet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      if (sonuc == null || !mounted) return;
      await dbService.kullaniciSporcuEslestir(
        int.parse(guncel['id'].toString()),
        sonuc['athlete_id'],
      );
      if (!mounted) return;
      await _yenile();
      if (!mounted) return;
      final secilen = sporcular.firstWhere(
        (s) => s['id'].toString() == sonuc['athlete_id']?.toString(),
        orElse: () => null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            secilen == null
                ? '${guncel['email']}: bağlantı kaldırıldı.'
                : '${guncel['email']} → ${secilen['isim']} eşleştirildi. İlgili hesap yeniden giriş yapmalı.',
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  Future<void> _yeniHesapAc() async {
    if (_islemSuruyor) return;
    setState(() => _islemSuruyor = true);
    try {
      final sporcular = await dbService.getSporcular();
      if (!mounted) return;
      await _kullaniciEkleFormuAc(sporcular);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
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
        title: const Text('Veli / Sporcu Hesapları'),
        actions: [
          IconButton(
            tooltip: 'Listeyi Yenile',
            onPressed: _islemSuruyor ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final rol in ['veli', 'sporcu', 'tumu'])
                  ChoiceChip(
                    label: Text(
                      rol == 'veli'
                          ? 'Veliler'
                          : rol == 'sporcu'
                          ? 'Sporcu Hesapları'
                          : 'Tümü',
                    ),
                    selected: _rolFiltresi == rol,
                    onSelected: (_) => setState(() => _rolFiltresi = rol),
                  ),
              ],
            ),
          ),
          if (_islemSuruyor) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _yenile,
              child: FutureBuilder<List<List<dynamic>>>(
                future: _verilerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('${snapshot.error}'),
                        ),
                        TextButton(
                          onPressed: _reload,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    );
                  }
                  final veriler = snapshot.data!;
                  final kullanicilar = veriler[0]
                      .where(
                        (k) =>
                            _rolFiltresi == 'tumu' || k['role'] == _rolFiltresi,
                      )
                      .toList();
                  kullanicilar.sort(
                    (a, b) => (a['athlete_id'] == null ? 0 : 1).compareTo(
                      b['athlete_id'] == null ? 0 : 1,
                    ),
                  );
                  final sporcular = {
                    for (final s in veriler[1]) s['id'].toString(): s,
                  };
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    children: [
                      if (kullanicilar.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Bu bölümde kayıtlı hesap yok.'),
                        ),
                      ...kullanicilar.map<Widget>((ham) {
                        final k = Map<String, dynamic>.from(ham);
                        final veliMi = k['role'] == 'veli';
                        final cocuk = sporcular[k['athlete_id']?.toString()];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${veliMi ? 'Veli hesabı' : 'Sporcu hesabı'}: ${k['email']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  cocuk != null
                                      ? '${veliMi ? 'Çocuğu' : 'Bağlı sporcu'}: ${cocuk['isim']}'
                                      : k['athlete_id'] == null
                                      ? 'Henüz eşleştirilmedi'
                                      : 'Bağlı sporcu kaydı bulunamadı',
                                  style: TextStyle(
                                    color: cocuk == null
                                        ? Colors.orangeAccent
                                        : Colors.lightGreenAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (cocuk != null)
                                  Text(
                                    _sporcuAciklamasi(cocuk),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _islemSuruyor
                                          ? null
                                          : () => _eslestirmeyiDuzenle(k),
                                      icon: const Icon(Icons.link),
                                      label: Text(
                                        veliMi
                                            ? 'Çocuğunu Seç / Değiştir'
                                            : 'Sporcu Kaydını Seç',
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Giriş Hesabını Kaldır',
                                      onPressed: _islemSuruyor
                                          ? null
                                          : () => _kullaniciSil(
                                              int.parse(k['id'].toString()),
                                              k['email']?.toString() ?? '',
                                            ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _islemSuruyor ? null : _yeniHesapAc,
        icon: const Icon(Icons.person_add),
        label: const Text('Hesap Ekle'),
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
            IconButton(
              tooltip: 'Sporcu Bilgilerini Düzenle',
              icon: const Icon(Icons.edit, color: Colors.lightGreenAccent),
              onPressed: () async {
                await sporcuBilgileriniDuzenle(context, sporcu.id);
                if (mounted) _tumVerileriYenile();
              },
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
                    builder: (context) => SporcuKayitEkrani(db: dbService),
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

Future<void> sporcuBilgileriniDuzenle(BuildContext context, int id) async {
  try {
    final sporcular = await dbService.getSporcular();
    final veri = sporcular.firstWhere(
      (s) => s['id'].toString() == id.toString(),
    );
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SporcuEkleEkrani(
          sporcu: Sporcu.fromJson(Map<String, dynamic>.from(veri)),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class SporcuEkleEkrani extends StatefulWidget {
  final Sporcu? sporcu;
  const SporcuEkleEkrani({super.key, this.sporcu});

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
  DateTime? _dogumTarihi;
  String? _cinsiyet;

  @override
  void initState() {
    super.initState();
    final s = widget.sporcu;
    if (s == null) return;
    _isimController.text = s.isim;
    _dogumYiliController.text = s.dogumYili > 0 ? '${s.dogumYili}' : '';
    _grupController.text = s.grup;
    _enIyiDereceController.text = s.enIyiDerece;
    _seciliStil = yuzmeStilleri.contains(s.enIyiDereceStil)
        ? s.enIyiDereceStil
        : null;
    _dogumTarihi = DateTime.tryParse(s.dogumTarihi ?? '');
    final c = s.cinsiyet?.toLowerCase();
    _cinsiyet = ['erkek', 'male', 'e'].contains(c)
        ? 'erkek'
        : ['kız', 'kiz', 'kadın', 'kadin', 'female', 'k'].contains(c)
        ? 'kiz'
        : null;
  }

  Future<void> _dogumTarihiSec() async {
    final simdi = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate:
          _dogumTarihi != null &&
              !_dogumTarihi!.isAfter(simdi) &&
              _dogumTarihi!.year >= 1900
          ? _dogumTarihi!
          : simdi,
      firstDate: DateTime(1900),
      lastDate: simdi,
    );
    if (secilen == null || !mounted) return;
    setState(() {
      _dogumTarihi = secilen;
      _dogumYiliController.text = '${secilen.year}';
    });
  }

  Future<void> _sporcuKaydet() async {
    if (_isimController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İsim boş olamaz')));
      return;
    }
    if (_dogumTarihi == null || _cinsiyet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğum tarihi ve cinsiyet seçmelisin.')),
      );
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      final veri = <String, dynamic>{
        'isim': _isimController.text.trim(),
        'dogum_yili': _dogumTarihi!.year,
        'dogum_tarihi':
            '${_dogumTarihi!.year}-${_dogumTarihi!.month.toString().padLeft(2, '0')}-${_dogumTarihi!.day.toString().padLeft(2, '0')}',
        'cinsiyet': _cinsiyet,
        'grup': _grupController.text.trim(),
        'en_iyi_derece': _enIyiDereceController.text.trim(),
        'en_iyi_derece_stil': _seciliStil,
      };
      if (widget.sporcu == null) {
        await dbService.sporcuEkle(veri);
      } else {
        await dbService.sporcuGuncelle(widget.sporcu!.id, veri);
      }
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
        title: Text(
          widget.sporcu == null ? 'Yeni Sporcu' : 'Sporcu Bilgilerini Düzenle',
          style: TextStyle(color: Colors.lightGreenAccent),
        ),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FormAlani(controller: _isimController, etiket: 'İsim'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _kaydediliyor ? null : _dogumTarihiSec,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _dogumTarihi == null
                    ? 'Doğum Tarihi Seç'
                    : 'Doğum Tarihi: ${_dogumTarihi!.day}.${_dogumTarihi!.month}.${_dogumTarihi!.year}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _cinsiyet,
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
              items: const [
                DropdownMenuItem(value: 'erkek', child: Text('Erkek')),
                DropdownMenuItem(value: 'kiz', child: Text('Kız')),
              ],
              onChanged: _kaydediliyor
                  ? null
                  : (v) => setState(() => _cinsiyet = v),
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
  late Sporcu _sporcu;

  @override
  void initState() {
    super.initState();
    _sporcu = widget.sporcu;
    _reload();
  }

  void _reload() {
    setState(() {
      _future = dbService.getPerformans(_sporcu.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
        actions: [
          if (widget.antrenorMu)
            IconButton(
              tooltip: 'Sporcu Bilgilerini Düzenle',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await sporcuBilgileriniDuzenle(context, _sporcu.id);
                if (!mounted) return;
                try {
                  final liste = await dbService.getSporcular();
                  final veri = liste.firstWhere(
                    (s) => s['id'].toString() == _sporcu.id.toString(),
                  );
                  if (!mounted) return;
                  setState(
                    () => _sporcu = Sporcu.fromJson(
                      Map<String, dynamic>.from(veri),
                    ),
                  );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
            ),
        ],
        title: Text(
          _sporcu.isim,
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
                        _sporcu.isim.isNotEmpty ? _sporcu.isim[0] : '?',
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
                          _sporcu.isim,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_sporcu.dogumYili} · ${_sporcu.grup}',
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
                        PerformansEkleEkrani(sporcuId: _sporcu.id),
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
