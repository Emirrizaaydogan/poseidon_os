import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/database_service.dart';

// ---------------- VERİ MODELLERİ ----------------

class Sporcu {
  final int id;
  final String isim;
  final int dogumYili;
  final String grup;
  final String enIyiDerece;

  const Sporcu({
    required this.id,
    required this.isim,
    required this.dogumYili,
    required this.grup,
    required this.enIyiDerece,
  });

  factory Sporcu.fromJson(Map<String, dynamic> veri) {
    return Sporcu(
      id: int.parse(veri['id'].toString()),
      isim: veri['isim'] ?? '',
      dogumYili: veri['dogum_yili'] ?? 0,
      grup: veri['grup'] ?? '',
      enIyiDerece: veri['en_iyi_derece'] ?? '',
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
      setler: hamSetler.map((s) => AntrenmanSeti.fromMap(Map<String, dynamic>.from(s))).toList(),
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

const List<String> yuzmeStilleri = ['Serbest', 'Sırtüstü', 'Kurbağalama', 'Kelebek'];
const List<String> yuzmeMesafeleri = ['25m', '50m', '100m', '200m'];

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
        SnackBar(
          content: Text('$e'),
          backgroundColor: const Color(0xFF351515),
        ),
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
            child: Image.asset(
              'assets/images/poseidon_mizrak.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter, // center yerine topCenter yapıldı
            ),
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
                      SizedBox(
                        height: ekran.height * 0.35,
                      ),

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
                            Shadow(
                              color: Color(0xFF78FF36),
                              blurRadius: 18,
                            ),
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
                                        color: const Color(0xFF8BE83E)
                                            .withOpacity(0.6),
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
                            shadowColor:
                                const Color(0xFF72FF32).withOpacity(0.45),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Şifre yenileme özelliği yakında eklenecek.',
                              ),
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
        border: Border.all(
          color: const Color(0xFF36525E),
          width: 1.2,
        ),
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        cursorColor: const Color(0xFF8BE052),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF859399),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF9AA8AD),
            size: 24,
          ),
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
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  String _seciliRol = 'antrenor';
  int? _seciliSporcuId;
  bool _kayitOluyor = false;

  Future<void> _kayitOl() async {
    if (_emailController.text.trim().isEmpty || _sifreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta ve şifre gerekli')));
      return;
    }
    if (_seciliRol == 'veli' && _seciliSporcuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen çocuğunu seç')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarılı, şimdi giriş yapabilirsin')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
        title: const Text('Kayıt Ol', style: TextStyle(color: Colors.lightGreenAccent)),
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
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.lightGreenAccent)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Rol', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _RolSecimChip(etiket: 'Antrenör', deger: 'antrenor', seciliRol: _seciliRol, onSec: (r) => setState(() => _seciliRol = r)),
              _RolSecimChip(etiket: 'Sporcu', deger: 'sporcu', seciliRol: _seciliRol, onSec: (r) => setState(() => _seciliRol = r)),
              _RolSecimChip(etiket: 'Veli', deger: 'veli', seciliRol: _seciliRol, onSec: (r) => setState(() => _seciliRol = r)),
            ],
          ),
          if (_seciliRol == 'veli') ...[
            const SizedBox(height: 20),
            const Text('Çocuğun', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: dbService.getSporcular(),
              builder: (context, snapshot) {
                final sporcular = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.lightGreenAccent));
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: seciliMi ? Colors.lightGreenAccent : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.lightGreenAccent),
                        ),
                        child: Text(s['isim'] ?? '',
                            style: TextStyle(color: seciliMi ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _kayitOluyor
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold)),
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

  const _RolSecimChip({required this.etiket, required this.deger, required this.seciliRol, required this.onSec});

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
        child: Text(etiket, style: TextStyle(color: seciliMi ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}


// ---------------- TRIDENT LOGO ----------------

class TridentIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TridentIcon({super.key, this.size = 28, this.color = Colors.lightGreenAccent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _TridentPainter(color: color));
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
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.95), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.4), Offset(w * 0.15, h * 0.1), paint);
    canvas.drawLine(Offset(w * 0.15, h * 0.1), Offset(w * 0.15, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.4), Offset(w * 0.85, h * 0.1), paint);
    canvas.drawLine(Offset(w * 0.85, h * 0.1), Offset(w * 0.85, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.05), paint);
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
          gradient: const LinearGradient(colors: [Color(0xFF9AE637), Color(0xFF5FD858)]),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(metin, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
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

  const IstatistikKarti({super.key, required this.icon, required this.deger, required this.etiket});

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
          Text(deger, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(etiket, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
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
      const AnaSayfaSekmesi(),
      SporcularSekmesi(antrenorMu: _antrenorMu, filtreSporcuId: widget.veliSporcuId),
      AntrenmanSekmesi(antrenorMu: _antrenorMu),
      const TakvimSekmesi(),
      AidatSekmesi(antrenorMu: _antrenorMu, filtreSporcuId: widget.veliSporcuId),
      Center(child: Text('Profil (${_rolAdi(widget.rol)})', style: const TextStyle(color: Colors.white))),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const TridentIcon(size: 22),
            const SizedBox(width: 8),
            Text('POSEIDON OS · ${_rolAdi(widget.rol)}',
                style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
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
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Antrenman'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Takvim'),
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

// ---------------- ANA SAYFA SEKMESİ ----------------

class AnaSayfaSekmesi extends StatefulWidget {
  const AnaSayfaSekmesi({super.key});

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
    _aidatlarFuture = dbService.getAidatlar();
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
              final yaklasanlar = aidatlar.where((a) {
                if (a['odendi'] == true) return false;
                final sonTarih = DateTime.tryParse(a['son_odeme_tarihi'].toString());
                if (sonTarih == null) return false;
                final kalanGun = sonTarih.difference(simdi).inDays;
                return kalanGun <= 7 && kalanGun >= 0;
              }).toList();

              if (yaklasanlar.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1F00),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orangeAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${yaklasanlar.length} aidat ödemesinin süresi 7 gün içinde doluyor',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
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
                    Icon(Icons.calendar_month, color: Colors.lightGreenAccent, size: 16),
                    SizedBox(width: 6),
                    Text('Bugünkü Antrenman',
                        style: TextStyle(color: Colors.lightGreenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Dayanıklılık + Teknik',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.pool, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text('Havuz', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    SizedBox(width: 12),
                    Icon(Icons.timer, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text('25dk', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 18),
                OkluButon(metin: 'Antrenmanı Gör', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Genel Bakış', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                      IstatistikKarti(icon: Icons.groups, deger: '$sporcuSayisi', etiket: 'Toplam Sporcu'),
                      IstatistikKarti(icon: Icons.fact_check, deger: '$antrenmanSayisi', etiket: 'Aktif Program'),
                      const IstatistikKarti(icon: Icons.qr_code_scanner, deger: '0', etiket: 'Bugünkü Yoklama'),
                      const IstatistikKarti(icon: Icons.emoji_events, deger: '3', etiket: 'Yaklaşan Yarış'),
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

  const SporcularSekmesi({super.key, required this.antrenorMu, this.filtreSporcuId});

  @override
  State<SporcularSekmesi> createState() => _SporcularSekmesiState();
}

class _SporcularSekmesiState extends State<SporcularSekmesi> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = dbService.getSporcular();
    });
  }

  Future<void> _silmeyiOnayla(BuildContext context, Sporcu sporcu) async {
    final onayVerdiMi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sporcuyu Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '${sporcu.isim} adlı sporcuyu silmek istediğine emin misin? Bu işlem geri alınamaz, sporcuya ait tüm performans ve aidat kayıtları da silinecek.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (onayVerdiMi != true) return;

    try {
      await dbService.sporcuSil(sporcu.id);
      _reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${sporcu.isim} silindi')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.lightGreenAccent));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            var belgeler = snapshot.data ?? [];

            if (widget.filtreSporcuId != null) {
              belgeler = belgeler.where((b) => int.parse(b['id'].toString()) == widget.filtreSporcuId).toList();
            }

            if (belgeler.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Text(
                      widget.filtreSporcuId != null ? 'Sporcu bulunamadı' : 'Henüz sporcu eklenmemiş',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: belgeler.length,
              itemBuilder: (context, index) {
                final sporcu = Sporcu.fromJson(belgeler[index]);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SporcuDetayEkrani(sporcu: sporcu, antrenorMu: widget.antrenorMu)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.lightGreenAccent,
                          child: Text(sporcu.isim.isNotEmpty ? sporcu.isim[0] : '?',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sporcu.isim, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${sporcu.dogumYili} · ${sporcu.grup}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(sporcu.enIyiDerece,
                            style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (widget.antrenorMu) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _silmeyiOnayla(context, sporcu),
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
      floatingActionButton: widget.antrenorMu
          ? FloatingActionButton(
              backgroundColor: Colors.lightGreenAccent,
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SporcuEkleEkrani()));
                _reload();
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
  bool _kaydediliyor = false;

  Future<void> _sporcuKaydet() async {
    if (_isimController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İsim boş olamaz')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await dbService.sporcuEkle({
        'isim': _isimController.text.trim(),
        'dogum_yili': int.tryParse(_dogumYiliController.text.trim()) ?? 0,
        'grup': _grupController.text.trim(),
        'en_iyi_derece': _enIyiDereceController.text.trim(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
        title: const Text('Yeni Sporcu', style: TextStyle(color: Colors.lightGreenAccent)),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FormAlani(controller: _isimController, etiket: 'İsim'),
            const SizedBox(height: 12),
            _FormAlani(controller: _dogumYiliController, etiket: 'Doğum Yılı', sayisalMi: true),
            const SizedBox(height: 12),
            _FormAlani(controller: _grupController, etiket: 'Grup (örn. A Takım)'),
            const SizedBox(height: 12),
            _FormAlani(controller: _enIyiDereceController, etiket: 'En İyi Derece (örn. 27.45)'),
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
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

  const _FormAlani({required this.controller, required this.etiket, this.sayisalMi = false});

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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.lightGreenAccent)),
      ),
    );
  }
}

// ---------------- SPORCU DETAY EKRANI (PERFORMANS) ----------------

class SporcuDetayEkrani extends StatefulWidget {
  final Sporcu sporcu;
  final bool antrenorMu;

  const SporcuDetayEkrani({super.key, required this.sporcu, required this.antrenorMu});

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
        title: Text(widget.sporcu.isim, style: const TextStyle(color: Colors.lightGreenAccent)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.lightGreenAccent));
          }
          final kayitlar = (snapshot.data ?? []).map((v) => PerformansKaydi.fromJson(v)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.lightGreenAccent,
                      child: Text(widget.sporcu.isim.isNotEmpty ? widget.sporcu.isim[0] : '?',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.sporcu.isim, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${widget.sporcu.dogumYili} · ${widget.sporcu.grup}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Performans Gelişimi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (kayitlar.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('Henüz performans kaydı yok', style: TextStyle(color: Colors.grey))),
                )
              else
                ...yuzmeStilleri.map((stil) {
                  final stilKayitlari = kayitlar.where((k) => k.stil == stil).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(stil, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (stilKayitlari.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Text('Bu stilde henüz kayıt yok', style: TextStyle(color: Colors.grey, fontSize: 12))),
                          )
                        else
                          ...yuzmeMesafeleri.map((mesafe) {
                            final mesafeKayitlari = stilKayitlari.where((k) => k.mesafe == mesafe).toList();
                            if (mesafeKayitlari.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14, left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mesafe, style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 150,
                                    padding: const EdgeInsets.fromLTRB(6, 14, 14, 6),
                                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              getTitlesWidget: (value, meta) =>
                                                  Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.grey, fontSize: 8)),
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final i = value.toInt();
                                                if (i < 0 || i >= mesafeKayitlari.length) return const SizedBox();
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(mesafeKayitlari[i].tarih, style: const TextStyle(color: Colors.grey, fontSize: 8)),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: mesafeKayitlari.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.derece)).toList(),
                                            isCurved: true,
                                            color: Colors.lightGreenAccent,
                                            barWidth: 2.5,
                                            dotData: const FlDotData(show: true),
                                            belowBarData: BarAreaData(show: true, color: Colors.lightGreenAccent.withOpacity(0.15)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...mesafeKayitlari.reversed.map((k) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(k.tarih, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                            Text(k.derece.toStringAsFixed(2),
                                                style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                      )),
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
                  MaterialPageRoute(builder: (context) => PerformansEkleEkrani(sporcuId: widget.sporcu.id)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Derece boş olamaz')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await dbService.performansEkle({
        'athlete_id': widget.sporcuId,
        'stil': _seciliStil,
        'mesafe': _seciliMesafe,
        'derece': double.tryParse(_dereceController.text.trim().replaceAll(',', '.')) ?? 0.0,
        'tarih': _tarihController.text.trim(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
        title: const Text('Yeni Performans Kaydı', style: TextStyle(color: Colors.lightGreenAccent)),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Yüzme Stili', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: yuzmeStilleri.map((stil) {
              final seciliMi = _seciliStil == stil;
              return GestureDetector(
                onTap: () => setState(() => _seciliStil = stil),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: seciliMi ? Colors.lightGreenAccent : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightGreenAccent),
                  ),
                  child: Text(stil,
                      style: TextStyle(color: seciliMi ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text('Mesafe', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: yuzmeMesafeleri.map((mesafe) {
              final seciliMi = _seciliMesafe == mesafe;
              return GestureDetector(
                onTap: () => setState(() => _seciliMesafe = mesafe),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: seciliMi ? Colors.lightGreenAccent : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightGreenAccent),
                  ),
                  child: Text(mesafe,
                      style: TextStyle(color: seciliMi ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FormAlani(controller: _dereceController, etiket: 'Derece - saniye (örn. 27.45)'),
          const SizedBox(height: 12),
          _FormAlani(controller: _tarihController, etiket: 'Tarih (örn. 10.05)'),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
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

  const AntrenmanSekmesi({super.key, required this.antrenorMu});

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
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: Colors.lightGreenAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.lightGreenAccent));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            final belgeler = snapshot.data ?? [];
            if (belgeler.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Henüz antrenman eklenmemiş', style: TextStyle(color: Colors.grey))),
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
                          builder: (context) => AntrenmanDetayEkrani(antrenman: antrenman, antrenorMu: widget.antrenorMu)),
                    );
                    _reload();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.lightGreenAccent, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(antrenman.baslik,
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.lightGreenAccent, size: 22),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(antrenman.tarih, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('${antrenman.havuz} · ${antrenman.sure}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        if (antrenman.setler.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('${antrenman.setler.length} set · Programı görmek için dokun',
                              style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 12)),
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
      floatingActionButton: widget.antrenorMu
          ? FloatingActionButton(
              backgroundColor: Colors.lightGreenAccent,
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const AntrenmanEkleEkrani()));
                _reload();
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}

// ---------------- ANTRENMAN DETAY (PROGRAM + YOKLAMA) ----------------

class AntrenmanDetayEkrani extends StatefulWidget {
  final Antrenman antrenman;
  final bool antrenorMu;

  const AntrenmanDetayEkrani({super.key, required this.antrenman, required this.antrenorMu});

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
      _yoklamaFuture = dbService.getYoklama(widget.antrenman.id);
    });
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
        title: Text(widget.antrenman.baslik, style: const TextStyle(color: Colors.lightGreenAccent)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.lightGreenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.antrenman.tarih, style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 20),
                  const Icon(Icons.pool, color: Colors.lightGreenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.antrenman.havuz, style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 20),
                  const Icon(Icons.timer, color: Colors.lightGreenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.antrenman.sure, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: _yoklamaFuture,
              builder: (context, snapshot) {
                final gelenSayisi = snapshot.data?.length ?? 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.lightGreenAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.lightGreenAccent),
                      const SizedBox(width: 10),
                      Text('Yoklama: $gelenSayisi kişi geldi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (widget.antrenorMu)
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => YoklamaQREkrani(antrenman: widget.antrenman)));
                          },
                          child: const Text('QR Göster', style: TextStyle(color: Colors.lightGreenAccent)),
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QrTaramaEkrani(antrenmanId: widget.antrenman.id)),
                            );
                            _reloadYoklama();
                          },
                          child: const Text('QR Okut', style: TextStyle(color: Colors.lightGreenAccent)),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            if (gruplanmis.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('Bu antrenman için henüz set girilmemiş', style: TextStyle(color: Colors.grey))),
              )
            else
              ...gruplanmis.entries.map((grup) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grup.key, style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...grup.value.map((set) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  ', style: TextStyle(color: Colors.white, fontSize: 15)),
                                Expanded(child: Text(set.aciklama, style: const TextStyle(color: Colors.white, fontSize: 15))),
                              ],
                            ),
                          )),
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
  final _tarihController = TextEditingController();
  final _havuzController = TextEditingController();
  final _sureController = TextEditingController();
  final _setAciklamaController = TextEditingController();
  String _seciliKategori = 'Isınma';
  final List<String> _kategoriler = ['Isınma', 'Ana Set', 'Soğuma'];
  final List<AntrenmanSeti> _eklenenSetler = [];
  bool _kaydediliyor = false;

  void _setEkle() {
    if (_setAciklamaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set açıklaması boş olamaz')));
      return;
    }
    setState(() {
      _eklenenSetler.add(AntrenmanSeti(kategori: _seciliKategori, aciklama: _setAciklamaController.text.trim()));
      _setAciklamaController.clear();
    });
  }

  void _setSil(int index) => setState(() => _eklenenSetler.removeAt(index));

  Future<void> _antrenmanKaydet() async {
    if (_baslikController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık boş olamaz')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await dbService.antrenmanEkle({
        'baslik': _baslikController.text.trim(),
        'tarih': _tarihController.text.trim(),
        'havuz': _havuzController.text.trim(),
        'sure': _sureController.text.trim(),
        'setler': _eklenenSetler.map((s) => s.toMap()).toList(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _tarihController.dispose();
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
        title: const Text('Yeni Antrenman', style: TextStyle(color: Colors.lightGreenAccent)),
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FormAlani(controller: _baslikController, etiket: 'Başlık (örn. Dayanıklılık + Teknik)'),
          const SizedBox(height: 12),
          _FormAlani(controller: _tarihController, etiket: 'Tarih (örn. 20 Mayıs, Pazartesi)'),
          const SizedBox(height: 12),
          _FormAlani(controller: _havuzController, etiket: 'Havuz (örn. Havuz 1)'),
          const SizedBox(height: 12),
          _FormAlani(controller: _sureController, etiket: 'Süre (örn. 30dk)'),
          const SizedBox(height: 28),
          const Text('Antrenman Setleri (Drill\'ler)', style: TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
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
                        color: seciliMi ? Colors.lightGreenAccent : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.lightGreenAccent),
                      ),
                      child: Text(kategori,
                          style: TextStyle(color: seciliMi ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FormAlani(controller: _setAciklamaController, etiket: 'örn. 4 x 50m Serbest @1:00')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _setEkle,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16)),
                child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_eklenenSetler.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Henüz set eklenmedi', style: TextStyle(color: Colors.grey)))
          else
            ..._eklenenSetler.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.lightGreenAccent, borderRadius: BorderRadius.circular(6)),
                      child: Text(set.kategori, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(set.aciklama, style: const TextStyle(color: Colors.white))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), onPressed: () => _setSil(index)),
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
                  backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _kaydediliyor
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Antrenmanı Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Yoklama - QR Giriş', style: TextStyle(color: Colors.lightGreenAccent)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(antrenman.baslik, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: antrenman.id.toString(), size: 220, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('Sporcular bu kodu okutarak yoklamaya katılabilir', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FutureBuilder<List<dynamic>>(
                future: dbService.getYoklama(antrenman.id),
                builder: (context, snapshot) {
                  final sayi = snapshot.data?.length ?? 0;
                  return Text('Şu ana kadar $sayi kişi okuttu', style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold));
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

  const QrTaramaEkrani({super.key, required this.antrenmanId});

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu kod bu antrenmana ait değil')));
        Navigator.pop(context);
      }
      return;
    }

    try {
      await dbService.yoklamaEkle({'training_id': okunanIdInt});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yoklama alındı ✓')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
        title: const Text('QR Kodu Okut', style: TextStyle(color: Colors.lightGreenAccent)),
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

class TakvimSekmesi extends StatefulWidget {
  const TakvimSekmesi({super.key});

  @override
  State<TakvimSekmesi> createState() => _TakvimSekmesiState();
}

class _TakvimSekmesiState extends State<TakvimSekmesi> {
  DateTime _odakGun = DateTime.utc(2024, 5, 15);
  DateTime? _secilenGun = DateTime.utc(2024, 5, 15);

  List<String> _gununEtkinlikleri(DateTime gun) {
    final anahtar = DateTime.utc(gun.year, gun.month, gun.day);
    return ornekEtkinlikler[anahtar] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final etkinlikler = _secilenGun != null ? _gununEtkinlikleri(_secilenGun!) : <String>[];

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _odakGun,
            selectedDayPredicate: (gun) => isSameDay(_secilenGun, gun),
            eventLoader: _gununEtkinlikleri,
            onDaySelected: (secilen, odaklanan) => setState(() {
              _secilenGun = secilen;
              _odakGun = odaklanan;
            }),
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white),
              outsideTextStyle: TextStyle(color: Colors.grey),
              todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              markerDecoration: BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(color: Colors.lightGreenAccent, fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.lightGreenAccent),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.lightGreenAccent),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.grey), weekendStyle: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: etkinlikler.isEmpty
                ? const Center(child: Text('Bu günde etkinlik yok', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: etkinlikler.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.lightGreenAccent, size: 20),
                            const SizedBox(width: 10),
                            Text(etkinlikler[index], style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
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

  const AidatSekmesi({super.key, required this.antrenorMu, this.filtreSporcuId});

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
      return aidatlar.firstWhere((a) => int.parse(a['athlete_id'].toString()) == sporcuId && a['ay'] == ay);
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
        'son_odeme_tarihi': DateTime.now().add(const Duration(days: 10)).toIso8601String().substring(0, 10),
      });
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata (oluştur): $e')));
      }
    }
  }

  Future<void> _odendiIsaretle(int aidatId) async {
    try {
      await dbService.aidatOdendiIsaretle(aidatId);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata (ödeme): $e')));
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
              return const Center(child: CircularProgressIndicator(color: Colors.lightGreenAccent));
            }
            var sporcular = sporcuSnapshot.data ?? [];
            if (widget.filtreSporcuId != null) {
              sporcular = sporcular.where((s) => int.parse(s['id'].toString()) == widget.filtreSporcuId).toList();
            }

            return FutureBuilder<List<dynamic>>(
              future: _aidatlarFuture,
              builder: (context, aidatSnapshot) {
                final aidatlar = aidatSnapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${_guncelAy()} Aidat Durumu',
                        style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
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
                          border: Border.all(color: odendiMi ? Colors.lightGreenAccent : Colors.grey.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              odendiMi ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: odendiMi ? Colors.lightGreenAccent : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sporcu.isim, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  if (aidat != null)
                                    Text(
                                      odendiMi ? 'Ödendi' : 'Son ödeme: ${aidat['son_odeme_tarihi'].toString().substring(0, 10)}',
                                      style: TextStyle(color: odendiMi ? Colors.lightGreenAccent : Colors.grey, fontSize: 12),
                                    )
                                  else
                                    const Text('Bu ay için aidat kaydı yok', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (aidat == null && widget.antrenorMu)
                              TextButton(
                                onPressed: () => _aidatOlustur(sporcu.id),
                                child: const Text('Oluştur', style: TextStyle(color: Colors.lightGreenAccent)),
                              )
                            else if (aidat != null && !odendiMi)
                              TextButton(
                                onPressed: () => _odendiIsaretle(int.parse(aidat['id'].toString())),
                                child: const Text('Ödendi İşaretle', style: TextStyle(color: Colors.lightGreenAccent)),
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