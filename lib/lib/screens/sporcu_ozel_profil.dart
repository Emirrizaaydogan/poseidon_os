import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/sporcu_ozel_alanlar.dart';

class SporcuOzelProfilKarti extends StatefulWidget {
  final DatabaseService db;
  final int sporcuId;
  final String isim;
  final String grup;

  const SporcuOzelProfilKarti({
    super.key,
    required this.db,
    required this.sporcuId,
    required this.isim,
    required this.grup,
  });

  @override
  State<SporcuOzelProfilKarti> createState() => _SporcuOzelProfilKartiState();
}

class _SporcuOzelProfilKartiState extends State<SporcuOzelProfilKarti> {
  late Future<Map<String, dynamic>> _future;
  bool _tcAcik = false;

  @override
  void initState() {
    super.initState();
    _future = widget.db.sporcuOzelProfilGetir(widget.sporcuId);
  }

  void _yenile() {
    setState(() {
      _tcAcik = false;
      _future = widget.db.sporcuOzelProfilGetir(widget.sporcuId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12181C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Column(
              children: [
                const Text('Sporcu özel bilgileri yüklenemedi.'),
                TextButton(
                  onPressed: _yenile,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            );
          }

          final p = snapshot.data!;
          final tc = p['tc_kimlik_no']?.toString() ?? '';

          final displayed = tc.isEmpty
              ? 'Belirtilmedi'
              : _tcAcik
              ? tc
              : '*********${tc.substring(tc.length - 2)}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(42),
                    child: p['photo'] == null
                        ? const CircleAvatar(
                            radius: 36,
                            child: Icon(Icons.person, size: 38),
                          )
                        : Image.memory(
                            base64Decode(p['photo']['data'] as String),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 48),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isim,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.grup,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (p['photo_unavailable'] == true)
                const Text(
                  'Fotoğraf şu an yüklenemedi.',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              const SizedBox(height: 16),
              Text('Kan grubu: ${p['kan_grubu'] ?? 'Belirtilmedi'}'),
              const SizedBox(height: 8),
              Text('Lisans no: ${p['lisans_no'] ?? 'Belirtilmedi'}'),
              Row(
                children: [
                  Expanded(child: Text('T.C. Kimlik No: $displayed')),
                  if (tc.isNotEmpty)
                    IconButton(
                      tooltip: _tcAcik ? 'Gizle' : 'Göster',
                      onPressed: () => setState(() => _tcAcik = !_tcAcik),
                      icon: Icon(
                        _tcAcik ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Kimlik, Lisans ve Fotoğrafı Düzenle'),
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SporcuOzelProfilDuzenle(
                        db: widget.db,
                        sporcuId: widget.sporcuId,
                        isim: widget.isim,
                        data: p,
                      ),
                    ),
                  );

                  if (changed == true && mounted) {
                    _yenile();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class SporcuOzelProfilDuzenle extends StatefulWidget {
  final DatabaseService db;
  final int sporcuId;
  final String isim;
  final Map<String, dynamic> data;

  const SporcuOzelProfilDuzenle({
    super.key,
    required this.db,
    required this.sporcuId,
    required this.isim,
    required this.data,
  });

  @override
  State<SporcuOzelProfilDuzenle> createState() =>
      _SporcuOzelProfilDuzenleState();
}

class _SporcuOzelProfilDuzenleState extends State<SporcuOzelProfilDuzenle> {
  final _form = GlobalKey<FormState>();
  final _bilgi = SporcuOzelBilgiController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bilgi.yukle(widget.data);
  }

  @override
  void dispose() {
    _bilgi.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_form.currentState!.validate() || _busy) return;

    setState(() => _busy = true);

    try {
      await widget.db.sporcuOzelProfilKaydet(widget.sporcuId, _bilgi.toJson());

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
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.isim),
          foregroundColor: Colors.lightGreenAccent,
        ),
        body: AbsorbPointer(
          absorbing: _busy,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SporcuOzelAlanlar(controller: _bilgi),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _kaydet,
                      child: Text(_busy ? 'Kaydediliyor...' : 'Kaydet'),
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
