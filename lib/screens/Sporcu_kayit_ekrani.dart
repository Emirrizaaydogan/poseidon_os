import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SporcuKayitEkrani extends StatefulWidget {
  final DatabaseService db;
  const SporcuKayitEkrani({super.key, required this.db});
  @override
  State<SporcuKayitEkrani> createState() => _SporcuKayitEkraniState();
}

class _SporcuKayitEkraniState extends State<SporcuKayitEkrani> {
  final _form = GlobalKey<FormState>();
  final _isim = TextEditingController();
  final _grup = TextEditingController();
  final _email = TextEditingController();
  final _sifre = TextEditingController();
  DateTime? _dogum;
  String? _cinsiyet;
  bool _kaydediliyor = false;

  @override
  void dispose() {
    _isim.dispose();
    _grup.dispose();
    _email.dispose();
    _sifre.dispose();
    super.dispose();
  }

  void _mesaj(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _tarihSec() async {
    final simdi = DateTime.now();
    final sonuc = await showDatePicker(
      context: context,
      initialDate: _dogum ?? DateTime(simdi.year - 10),
      firstDate: DateTime(1900),
      lastDate: simdi,
      helpText: 'Sporcunun doğum tarihi',
    );
    if (sonuc != null && mounted) setState(() => _dogum = sonuc);
  }

  Future<void> _kaydet() async {
    if (!_form.currentState!.validate()) return;
    if (_dogum == null || _cinsiyet == null) {
      _mesaj('Doğum tarihi ve cinsiyet seçmelisin');
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await widget.db.sporcuTopluKaydet({
        'athlete': {
          'isim': _isim.text.trim(),
          'grup': _grup.text.trim(),
          'dogum_tarihi': _dogum!.toIso8601String().split('T').first,
          'cinsiyet': _cinsiyet,
        },
        'athlete_account': {
          'email': _email.text.trim().toLowerCase(),
          'password': _sifre.text,
        },
      });
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _mesaj(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  Widget _alan(
    TextEditingController controller,
    String baslik, {
    bool email = false,
    bool sifre = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: sifre,
        autocorrect: !email && !sifre,
        enableSuggestions: !sifre,
        keyboardType: email ? TextInputType.emailAddress : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: baslik,
          filled: true,
          fillColor: const Color(0xFF09141A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (value) {
          final text = value ?? '';
          if (text.trim().isEmpty) return '$baslik gerekli';
          if (email &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text.trim())) {
            return 'Geçerli e-posta gir';
          }
          if (sifre && text.length < 8) return 'En az 8 karakter kullan';
          return null;
        },
      ),
    );
  }

  Widget _bolum(String baslik, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF12181C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF293238)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              color: Colors.lightGreenAccent,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_kaydediliyor,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.lightGreenAccent,
          title: const Text('Yeni Sporcu'),
        ),
        body: AbsorbPointer(
          absorbing: _kaydediliyor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _bolum('Sporcu Bilgileri', [
                      _alan(_isim, 'Ad Soyad'),
                      _alan(_grup, 'Grup'),
                      OutlinedButton.icon(
                        onPressed: _tarihSec,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _dogum == null
                              ? 'Doğum tarihi seç'
                              : '${_dogum!.day}.${_dogum!.month}.${_dogum!.year}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          ChoiceChip(
                            label: const Text('Kız'),
                            selected: _cinsiyet == 'kiz',
                            onSelected: (_) =>
                                setState(() => _cinsiyet = 'kiz'),
                          ),
                          ChoiceChip(
                            label: const Text('Erkek'),
                            selected: _cinsiyet == 'erkek',
                            onSelected: (_) =>
                                setState(() => _cinsiyet = 'erkek'),
                          ),
                        ],
                      ),
                    ]),
                    _bolum('Sporcu Giriş Hesabı', [
                      _alan(_email, 'Sporcu e-postası', email: true),
                      _alan(_sifre, 'Sporcu şifresi', sifre: true),
                      const Text(
                        'Veli kendi hesabını giriş ekranındaki Kayıt Ol '
                        'bölümünden oluşturabilir.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ]),
                    FilledButton.icon(
                      onPressed: _kaydet,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      icon: _kaydediliyor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: Text(
                        _kaydediliyor
                            ? 'Kaydediliyor...'
                            : 'Sporcuyu ve Hesabını Oluştur',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
