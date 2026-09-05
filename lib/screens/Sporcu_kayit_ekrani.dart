import 'package:flutter/material.dart';
import '../services/database_service.dart';

class _YeniVeliAlanlari {
  final email = TextEditingController();
  final sifre = TextEditingController();

  void dispose() {
    email.dispose();
    sifre.dispose();
  }
}

class SporcuKayitEkrani extends StatefulWidget {
  final DatabaseService db;

  const SporcuKayitEkrani({super.key, required this.db});

  @override
  State<SporcuKayitEkrani> createState() => _SporcuKayitEkraniState();
}

class _SporcuKayitEkraniState extends State<SporcuKayitEkrani> {
  final _isim = TextEditingController();
  final _grup = TextEditingController();
  final _sporcuEmail = TextEditingController();
  final _sporcuSifre = TextEditingController();

  final Set<int> _seciliVeliler = {};
  final List<_YeniVeliAlanlari> _yeniVeliler = [];

  late Future<List<dynamic>> _velilerFuture;

  DateTime? _dogumTarihi;
  String? _cinsiyet;
  bool _sporcuHesabiAc = false;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _velilerFuture = widget.db.getKullanicilar();
  }

  @override
  void dispose() {
    _isim.dispose();
    _grup.dispose();
    _sporcuEmail.dispose();
    _sporcuSifre.dispose();

    for (final veli in _yeniVeliler) {
      veli.dispose();
    }

    super.dispose();
  }

  void _mesaj(String metin) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(metin)));
  }

  Future<void> _tarihSec() async {
    final simdi = DateTime.now();

    final tarih = await showDatePicker(
      context: context,
      initialDate: _dogumTarihi ?? DateTime(simdi.year - 10),
      firstDate: DateTime(1900),
      lastDate: simdi,
      helpText: 'Sporcunun doğum tarihi',
    );

    if (tarih == null || !mounted) return;

    setState(() => _dogumTarihi = tarih);
  }

  Widget _alan(
    TextEditingController controller,
    String etiket, {
    bool sifre = false,
    bool email = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_kaydediliyor,
        obscureText: sifre,
        autocorrect: !email && !sifre,
        enableSuggestions: !sifre,
        keyboardType: email ? TextInputType.emailAddress : null,
        decoration: InputDecoration(labelText: etiket),
      ),
    );
  }

  Widget _bolum(String baslik, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303030)),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;

    if (_isim.text.trim().isEmpty ||
        _grup.text.trim().isEmpty ||
        _dogumTarihi == null ||
        _cinsiyet == null) {
      _mesaj('Sporcu adı, grup, doğum tarihi ve cinsiyet gerekli.');
      return;
    }

    final tarih = _dogumTarihi!;

    final veri = <String, dynamic>{
      'athlete': {
        'isim': _isim.text.trim(),
        'grup': _grup.text.trim(),
        'dogum_tarihi':
            '${tarih.year}-'
            '${tarih.month.toString().padLeft(2, '0')}-'
            '${tarih.day.toString().padLeft(2, '0')}',
        'cinsiyet': _cinsiyet,
      },
      'athlete_account': _sporcuHesabiAc
          ? {'email': _sporcuEmail.text.trim(), 'password': _sporcuSifre.text}
          : null,
      'existing_parent_ids': _seciliVeliler.toList(),
      'new_parents': _yeniVeliler
          .map((v) => {'email': v.email.text.trim(), 'password': v.sifre.text})
          .toList(),
    };

    setState(() => _kaydediliyor = true);

    try {
      await widget.db.sporcuTopluKaydet(veri);

      if (!mounted) return;

      _mesaj('Sporcu ve seçilen hesaplar kaydedildi.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _mesaj('$e');
    } finally {
      if (mounted) {
        setState(() => _kaydediliyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_kaydediliyor,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Sporcu ve Veli Kaydı')),
        body: AbsorbPointer(
          absorbing: _kaydediliyor,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _bolum('1. Sporcu Bilgileri', [
                _alan(_isim, 'Ad soyad'),
                _alan(_grup, 'Grup / takım'),

                OutlinedButton.icon(
                  onPressed: _tarihSec,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _dogumTarihi == null
                        ? 'Doğum Tarihi Seç'
                        : '${_dogumTarihi!.day}.'
                              '${_dogumTarihi!.month}.'
                              '${_dogumTarihi!.year}',
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
                  onChanged: (v) {
                    setState(() => _cinsiyet = v);
                  },
                ),
              ]),

              _bolum('2. Sporcu Giriş Hesabı', [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sporcu uygulamaya giriş yapabilsin'),
                  subtitle: const Text(
                    'İsteğe bağlıdır. Veli erişimi için gerekli değil.',
                  ),
                  value: _sporcuHesabiAc,
                  onChanged: (v) {
                    setState(() => _sporcuHesabiAc = v);
                  },
                ),

                if (_sporcuHesabiAc) ...[
                  _alan(_sporcuEmail, 'Sporcunun e-postası', email: true),
                  _alan(_sporcuSifre, 'Şifre — en az 8 karakter', sifre: true),
                ],
              ]),

              _bolum('3. Mevcut Velileri Bağla', [
                const Text(
                  'Sistemde hesabı bulunan velileri seç. '
                  'Birden fazla veli seçebilirsin.',
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 12),

                FutureBuilder<List<dynamic>>(
                  future: _velilerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _velilerFuture = widget.db.getKullanicilar();
                              });
                            },
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      );
                    }

                    final veliler = (snapshot.data ?? [])
                        .where((k) => k['role'] == 'veli')
                        .toList();

                    if (veliler.isEmpty) {
                      return const Text(
                        'Kayıtlı veli hesabı yok. '
                        'Aşağıdan yeni veli ekleyebilirsin.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return Column(
                      children: veliler.map<Widget>((v) {
                        final id = int.parse(v['id'].toString());

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(v['email']?.toString() ?? ''),
                          value: _seciliVeliler.contains(id),
                          onChanged: (secili) {
                            setState(() {
                              if (secili == true) {
                                _seciliVeliler.add(id);
                              } else {
                                _seciliVeliler.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ]),

              _bolum('4. Yeni Veli Hesabı', [
                const Text(
                  'Velinin hesabı yoksa buradan oluştur. '
                  'Yeni hesap bu çocuğa otomatik bağlanır.',
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 12),

                ..._yeniVeliler.map<Widget>((veli) {
                  return Column(
                    key: ObjectKey(veli),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Bu veli alanını kaldır',
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _yeniVeliler.remove(veli);
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              veli.dispose();
                            });
                          },
                        ),
                      ),
                      _alan(veli.email, 'Veli e-postası', email: true),
                      _alan(
                        veli.sifre,
                        'Veli şifresi — en az 8 karakter',
                        sifre: true,
                      ),
                      const Divider(),
                    ],
                  );
                }),

                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _yeniVeliler.add(_YeniVeliAlanlari());
                    });
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Yeni Veli Ekle'),
                ),
              ]),

              ElevatedButton.icon(
                onPressed: _kaydediliyor ? null : _kaydet,
                icon: _kaydediliyor
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _kaydediliyor
                      ? 'Kaydediliyor...'
                      : 'Sporcu ve Hesapları Kaydet',
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
