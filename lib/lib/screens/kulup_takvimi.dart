import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';

const _turler = {'yaris': 'Yarış', 'tatil': 'Tatil', 'odeme': 'Ödeme'};

Color _renk(String tur) => switch (tur) {
  'yaris' => Colors.lightGreenAccent,
  'tatil' => Colors.yellow,
  _ => Colors.redAccent,
};

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _gun(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';

class KulupTakvimi extends StatefulWidget {
  final DatabaseService db;
  final bool antrenorMu;
  final int? sporcuId;
  final Widget Function(Map<String, dynamic>, VoidCallback) aidatKarti;

  const KulupTakvimi({
    super.key,
    required this.db,
    required this.antrenorMu,
    required this.aidatKarti,
    this.sporcuId,
  });

  @override
  State<KulupTakvimi> createState() => _KulupTakvimiState();
}

class _KulupTakvimiState extends State<KulupTakvimi> {
  late Future<List<List<dynamic>>> _future;
  DateTime _odak = DateTime.now();
  DateTime _secili = DateTime.now();
  bool _siliyor = false;

  @override
  void initState() {
    super.initState();
    _future = _getir();
  }

  Future<List<List<dynamic>>> _getir() => Future.wait([
    widget.db.takvimEtkinlikleriGetir(),
    widget.db.getAidatlar(sporcuId: widget.sporcuId),
  ]);

  Future<void> _yenile() async {
    final next = _getir();
    setState(() => _future = next);

    try {
      await next;
    } catch (_) {
      // Hata FutureBuilder içinde gösterilir.
    }
  }

  void _aidatYenile() {
    _yenile();
  }

  String _odemeZamani(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '');

    if (d == null) {
      return 'Ödeme tarihi belirtilmemiş';
    }

    final tr = d.toUtc().add(const Duration(hours: 3));

    return '${_gun(tr)} '
        '${tr.hour.toString().padLeft(2, '0')}:'
        '${tr.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _odemeGecmisiniAc(List<dynamic> aidatlar) async {
    final odenenler = aidatlar.where((a) => a['odendi'] == true).toList();

    // En son ödeme en üstte.
    odenenler.sort((a, b) {
      final ad = DateTime.tryParse(a['odeme_tarihi']?.toString() ?? '');
      final bd = DateTime.tryParse(b['odeme_tarihi']?.toString() ?? '');

      if (ad == null && bd == null) {
        return (b['ay'] ?? '').toString().compareTo((a['ay'] ?? '').toString());
      }

      if (ad == null) return 1;
      if (bd == null) return -1;

      return bd.compareTo(ad);
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101010),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.85,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ödeme Geçmişim (${odenenler.length})',
                        style: const TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Seçili çocuğun tüm dönemlerde ödendi olarak '
                  'kaydedilmiş aidatları. Saatler Türkiye saatidir.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: odenenler.isEmpty
                    ? const Center(
                        child: Text('Henüz ödenmiş aidat kaydı bulunmuyor.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: odenenler.length,
                        itemBuilder: (context, index) {
                          final aidat = Map<String, dynamic>.from(
                            odenenler[index],
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ödeme: ${_odemeZamani(aidat['odeme_tarihi'])}',
                                style: const TextStyle(
                                  color: Colors.lightGreenAccent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              widget.aidatKarti(aidat, _aidatYenile),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _formAc([Map<String, dynamic>? event]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _TakvimFormu(db: widget.db, gun: _secili, event: event),
      ),
    );

    if (changed == true && mounted) {
      await _yenile();
    }
  }

  Future<void> _sil(Map<String, dynamic> event) async {
    if (_siliyor) return;

    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Etkinliği sil'),
        content: Text('${event['baslik']} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    setState(() => _siliyor = true);

    try {
      await widget.db.takvimEtkinligiSil(int.parse(event['id'].toString()));

      if (mounted) await _yenile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _siliyor = false);
    }
  }

  List<dynamic> _gundekiler(List<dynamic> rows, DateTime day, String key) {
    return rows.where((r) {
      final d = DateTime.tryParse(r[key]?.toString() ?? '');
      return d != null && isSameDay(d, day);
    }).toList();
  }

  Widget _nokta(String tur) => Container(
    width: 7,
    height: 7,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(color: _renk(tur), shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Takvim yüklenemedi.'),
                TextButton(
                  onPressed: _yenile,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data![0];
        final dues = snapshot.data![1];
        final selected = _gundekiler(events, _secili, 'tarih');
        final selectedDues = _gundekiler(dues, _secili, 'son_odeme_tarihi');
        final odenenAidatlar = selectedDues
            .where((a) => a['odendi'] == true)
            .toList();

        final bekleyenAidatlar = selectedDues
            .where((a) => a['odendi'] != true)
            .toList();

        return RefreshIndicator(
          onRefresh: _yenile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Kulüp Takvimi',
                      style: TextStyle(
                        color: Colors.lightGreenAccent,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _yenile,
                    tooltip: 'Yenile',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              TableCalendar<String>(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2100, 12, 31),
                focusedDay: _odak,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (d) => isSameDay(d, _secili),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _secili = selected;
                    _odak = focused;
                  });
                },
                onPageChanged: (focused) {
                  _odak = focused;
                },
                eventLoader: (day) {
                  final turler = _gundekiler(
                    events,
                    day,
                    'tarih',
                  ).map((e) => e['tur'].toString()).toSet();

                  if (_gundekiler(dues, day, 'son_odeme_tarihi').isNotEmpty) {
                    turler.add('odeme');
                  }

                  return _turler.keys.where(turler.contains).toList();
                },
                calendarBuilders: CalendarBuilders<String>(
                  markerBuilder: (context, day, types) {
                    if (types.isEmpty) return null;

                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: types.map(_nokta).toList(),
                      ),
                    );
                  },
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF424242),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF263238),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayTextStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // Renk açıklamaları.
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: _turler.entries.map((e) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _nokta(e.key),
                      const SizedBox(width: 4),
                      Text(e.value),
                    ],
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              Text(
                _gun(_secili),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!widget.antrenorMu && widget.sporcuId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _odemeGecmisiniAc(dues),
                    icon: const Icon(Icons.history),
                    label: const Text('Ödeme Geçmişim'),
                  ),
                ),
              if (widget.antrenorMu)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: FilledButton.icon(
                    onPressed: () => _formAc(),
                    icon: const Icon(Icons.add),
                    label: const Text('Seçili Güne Etkinlik Ekle'),
                  ),
                ),

              if (selected.isEmpty && selectedDues.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Bu gün için etkinlik veya ödeme kaydı yok.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              ...selected.map((raw) {
                final e = Map<String, dynamic>.from(raw);
                final tur = e['tur'].toString();
                final docs = List<String>.from(e['belgeler'] ?? []);

                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _renk(tur)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _turler[tur] ?? '',
                        style: TextStyle(
                          color: _renk(tur),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${e['baslik']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if ((e['aciklama'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${tur == 'tatil' ? 'Tatil nedeni: ' : ''}'
                          '${e['aciklama']}',
                        ),
                      ],

                      if (tur == 'yaris') ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Hazırlanması gereken belgeler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (docs.isEmpty)
                          const Text('Belge listesi belirtilmedi.'),
                        ...docs.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('• $d'),
                          ),
                        ),
                      ],

                      if (widget.antrenorMu)
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _siliyor ? null : () => _formAc(e),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Düzenle'),
                            ),
                            TextButton.icon(
                              onPressed: _siliyor ? null : () => _sil(e),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              label: const Text('Sil'),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),

              if (widget.antrenorMu) ...[
                const SizedBox(height: 20),

                const Text(
                  'Seçili günün aidat durumu',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Son ödeme tarihi bu gün olan aidatlar.',
                  style: TextStyle(color: Colors.grey),
                ),

                if (selectedDues.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Bu güne bağlı aidat kaydı bulunmuyor.'),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Ödeyenler (${odenenAidatlar.length} aidat)',
                    style: const TextStyle(
                      color: Colors.lightGreenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...odenenAidatlar.map(
                  (a) => widget.aidatKarti(
                    Map<String, dynamic>.from(a),
                    _aidatYenile,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Ödemeyenler (${bekleyenAidatlar.length} aidat)',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...bekleyenAidatlar.map(
                  (a) => widget.aidatKarti(
                    Map<String, dynamic>.from(a),
                    _aidatYenile,
                  ),
                ),
              ] else ...[
                if (selectedDues.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Aidat ödemeleri',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                ...selectedDues.map(
                  (a) => widget.aidatKarti(
                    Map<String, dynamic>.from(a),
                    _aidatYenile,
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _TakvimFormu extends StatefulWidget {
  final DatabaseService db;
  final DateTime gun;
  final Map<String, dynamic>? event;

  const _TakvimFormu({required this.db, required this.gun, this.event});

  @override
  State<_TakvimFormu> createState() => _TakvimFormuState();
}

class _TakvimFormuState extends State<_TakvimFormu> {
  final _form = GlobalKey<FormState>();
  final _baslik = TextEditingController();
  final _aciklama = TextEditingController();
  final _belgeler = TextEditingController();

  late DateTime _tarih;
  String _tur = 'yaris';
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    final e = widget.event;
    _tarih = e == null ? widget.gun : DateTime.parse(e['tarih']);

    if (e != null) {
      _tur = e['tur'];
      _baslik.text = e['baslik'];
      _aciklama.text = e['aciklama'] ?? '';
      _belgeler.text = List<String>.from(e['belgeler'] ?? []).join('\n');
    }
  }

  @override
  void dispose() {
    _baslik.dispose();
    _aciklama.dispose();
    _belgeler.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_busy || !_form.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      await widget.db.takvimEtkinligiKaydet(
        {
          'tur': _tur,
          'baslik': _baslik.text.trim(),
          'tarih': _iso(_tarih),
          'aciklama': _aciklama.text.trim(),
          'belgeler': _tur == 'yaris'
              ? _belgeler.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
              : [],
        },
        id: widget.event == null
            ? null
            : int.parse(widget.event!['id'].toString()),
      );

      if (!mounted) return;

      setState(() => _busy = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.event == null ? 'Takvime Ekle' : 'Etkinliği Düzenle',
          ),
        ),
        body: AbsorbPointer(
          absorbing: _busy,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  value: _tur,
                  decoration: const InputDecoration(labelText: 'Etkinlik türü'),
                  items: _turler.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _tur = v);
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_gun(_tarih)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _tarih,
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                    );

                    if (d != null && mounted) {
                      setState(() => _tarih = d);
                    }
                  },
                ),
                TextFormField(
                  controller: _baslik,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Başlık yaz' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aciklama,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: _tur == 'tatil'
                        ? 'Tatil nedeni (zorunlu)'
                        : 'Açıklama',
                  ),
                  validator: (v) =>
                      _tur == 'tatil' && (v == null || v.trim().isEmpty)
                      ? 'Tatil nedenini yaz'
                      : null,
                ),
                if (_tur == 'yaris')
                  TextFormField(
                    controller: _belgeler,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 6030,
                    decoration: const InputDecoration(
                      labelText: 'Gerekli belgeler',
                      hintText: 'Her satıra bir belge yaz',
                      helperText:
                          'En fazla 30 belge; her belge en fazla 200 karakter.',
                    ),
                    validator: (v) {
                      final docs = (v ?? '')
                          .split('\n')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();

                      return docs.length > 30 || docs.any((s) => s.length > 200)
                          ? 'Belge sayısını veya uzunluğunu azalt'
                          : null;
                    },
                  ),
                if (_tur == 'odeme')
                  const Text(
                    'Bu kayıt ödeme hatırlatmasıdır; '
                    'otomatik aidat borcu oluşturmaz.',
                    style: TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _kaydet,
                  child: Text(_busy ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
