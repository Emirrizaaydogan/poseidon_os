import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class YoklamaPaneli extends StatefulWidget {
  final DatabaseService db;
  final bool antrenorMu;
  final int? antrenmanId;
  final int? sporcuId;

  const YoklamaPaneli({
    super.key,
    required this.db,
    required this.antrenorMu,
    this.antrenmanId,
    this.sporcuId,
  });

  @override
  State<YoklamaPaneli> createState() => _YoklamaPaneliState();
}

class _YoklamaPaneliState extends State<YoklamaPaneli>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>>? _liste;
  String? _hata;
  String _arama = '';
  bool _okuyor = false;
  bool _aktif = true;
  int? _kaydedilen;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _yukle();

    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_aktif && _kaydedilen == null) {
        _yukle();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _aktif = state == AppLifecycleState.resumed;
    if (_aktif) _yukle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _yukle() async {
    if (_okuyor) return;
    _okuyor = true;

    try {
      final rows = await widget.db.getYoklama(
        antrenmanId: widget.antrenmanId,
        sporcuId: widget.sporcuId,
      );

      if (!mounted) return;

      setState(() {
        _liste = rows.map((r) => Map<String, dynamic>.from(r)).toList();
        _hata = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hata = 'Yoklama yenilenemedi. Tekrar dene.';
        });
      }
    } finally {
      _okuyor = false;
    }
  }

  Future<void> _isaretle(int id, bool giris) async {
    if (_kaydedilen != null || widget.antrenmanId == null) {
      return;
    }

    setState(() => _kaydedilen = id);

    try {
      if (giris) {
        await widget.db.yoklamaGirisYap(
          antrenmanId: widget.antrenmanId!,
          sporcuId: id,
        );
      } else {
        await widget.db.yoklamaCikisYap(
          antrenmanId: widget.antrenmanId!,
          sporcuId: id,
        );
      }

      if (mounted) {
        setState(() => _liste = null);

        while (_okuyor && mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        if (mounted) await _yukle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _kaydedilen = null);
      }
    }
  }

  String _zaman(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '—';

    final d = parsed.toUtc().add(const Duration(hours: 3));

    String p(int n) => n.toString().padLeft(2, '0');

    return '${p(d.day)}.${p(d.month)}.${d.year} '
        '${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final all = _liste ?? <Map<String, dynamic>>[];
    final coach = widget.antrenorMu && widget.antrenmanId != null;

    final filtered = all.where((r) {
      final metin = '${r['athlete_isim']} ${r['grup'] ?? ''}'.toLowerCase();

      return metin.contains(_arama.toLowerCase());
    }).toList();

    final rows = widget.antrenmanId == null
        ? filtered.take(5).toList()
        : filtered;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF343E29)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color: Colors.lightGreenAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.antrenmanId == null
                      ? 'Çocuğumun son yoklamaları'
                      : 'Antrenman Yoklaması',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _kaydedilen == null ? _yukle : null,
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh, color: Colors.lightGreenAccent),
              ),
            ],
          ),
          const Text(
            'Türkiye saati · Ekran açıkken 20 saniyede yenilenir',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          if (_hata != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$_hata Önceki bilgiler güncel olmayabilir.',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (_liste == null && _hata == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          if (coach && _liste != null) ...[
            const SizedBox(height: 12),
            Text(
              '${all.where((r) => r['giris_zamani'] != null).length} girdi · '
              '${all.where((r) => r['cikis_zamani'] != null).length} çıktı · '
              '${all.length} sporcu',
              style: const TextStyle(color: Colors.lightGreenAccent),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _arama = v),
              decoration: const InputDecoration(
                hintText: 'Sporcu veya grup ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_liste != null && rows.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Gösterilecek yoklama kaydı yok.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...rows.map((r) {
            final id = int.parse(r['athlete_id'].toString());
            final giris = r['giris_zamani'] != null;
            final cikis = r['cikis_zamani'] != null;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r['athlete_isim']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (r['training_baslik'] != null)
                    Text(
                      '${r['training_baslik']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    cikis
                        ? 'Dersten çıktı'
                        : giris
                        ? 'Derste'
                        : 'Henüz giriş işaretlenmedi',
                    style: TextStyle(
                      color: cikis
                          ? Colors.orangeAccent
                          : Colors.lightGreenAccent,
                    ),
                  ),
                  Text(
                    'Girdi: ${_zaman(r['giris_zamani'])}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Çıktı: ${_zaman(r['cikis_zamani'])}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (coach) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.lightGreenAccent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed:
                              !giris && _kaydedilen == null && _hata == null
                              ? () => _isaretle(id, true)
                              : null,
                          icon: const Icon(Icons.login),
                          label: const Text('Girdi'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              giris &&
                                  !cikis &&
                                  _kaydedilen == null &&
                                  _hata == null
                              ? () => _isaretle(id, false)
                              : null,
                          icon: const Icon(Icons.logout),
                          label: const Text('Çıktı'),
                        ),
                        if (_kaydedilen == id)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
