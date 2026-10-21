import 'package:flutter/material.dart';
import '../services/database_service.dart';

class VeliOnayEkrani extends StatefulWidget {
  final DatabaseService db;
  final bool antrenorMu;
  final VoidCallback? onKontrol;
  final VoidCallback? onCikis;

  const VeliOnayEkrani({
    super.key,
    required this.db,
    required this.antrenorMu,
    this.onKontrol,
    this.onCikis,
  });

  @override
  State<VeliOnayEkrani> createState() => _VeliOnayEkraniState();
}

class _VeliOnayEkraniState extends State<VeliOnayEkrani> {
  static const _lime = Color(0xFFB2FF59);
  List<dynamic> _liste = [];
  bool _yukleniyor = true;
  bool _islem = false;
  bool _sadeceBekleyen = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  String _mesaj(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final liste = await widget.db.veliBasvurulariniGetir();
      if (mounted) setState(() => _liste = liste);
    } catch (e) {
      if (mounted) setState(() => _hata = _mesaj(e));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _karar(Map<String, dynamic> b, bool onay) async {
    String not = '';
    final kabul = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151C20),
        title: Text(onay ? 'Veli bağlantısını onayla' : 'Başvuruyu reddet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${b['parent_email']} → ${b['athlete_name']}'),
              const SizedBox(height: 16),
              Text(
                onay
                    ? 'Bu kişinin çocuğun velisi olduğunu kulüp kayıtlarından veya kendisiyle görüşerek doğruladın mı?'
                    : 'Veliye gösterilecek kısa bir ret nedeni yaz.',
              ),
              if (!onay) ...[
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => not = value.trim(),
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Ret nedeni'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(onay ? 'Doğruladım, onayla' : 'Reddet'),
          ),
        ],
      ),
    );
    if (kabul != true || !mounted) return;
    if (!onay && not.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ret nedeni boş olamaz.')));
      return;
    }
    setState(() => _islem = true);
    try {
      await widget.db.veliBasvurusuKararVer(
        int.parse(b['id'].toString()),
        onay: onay,
        not: not,
      );
      if (!mounted) return;
      await _yukle();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_mesaj(e))));
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  Future<void> _cocukEkle() async {
    setState(() => _islem = true);
    try {
      final cocuklar = await widget.db.getKayitSporcular();
      if (!mounted) return;
      final secimler = <int>{};
      final secilenler = await showDialog<List<int>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, guncelle) => AlertDialog(
            backgroundColor: const Color(0xFF151C20),
            title: const Text('Çocuğunu seç'),
            content: SizedBox(
              width: 440,
              height: 280,
              child: cocuklar.isEmpty
                  ? const Center(
                      child: Text(
                        'Başvuruya uygun çocuk bulunmuyor. Antrenörünle iletişime geç.',
                      ),
                    )
                  : ListView(
                      children: cocuklar.map((c) {
                        final id = int.parse(c['id'].toString());
                        return CheckboxListTile(
                          activeColor: _lime,
                          checkColor: Colors.black,
                          title: Text('${c['isim']}'),
                          subtitle: Text(
                            '${c['grup'] ?? ''} · ${c['dogum_yili'] ?? ''}',
                          ),
                          value: secimler.contains(id),
                          onChanged: (value) => guncelle(() {
                            if (value == true) {
                              secimler.add(id);
                            } else {
                              secimler.remove(id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: secimler.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, secimler.toList()),
                child: const Text('Onaya gönder'),
              ),
            ],
          ),
        ),
      );
      if (secilenler == null || !mounted) return;
      await widget.db.veliBasvurusuOlustur(secilenler);
      if (mounted) await _yukle();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_mesaj(e))));
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  Widget _kart(Map<String, dynamic> b) {
    final status = b['status'];
    final renk = status == 'onaylandi'
        ? _lime
        : status == 'reddedildi'
        ? Colors.redAccent
        : Colors.amber;
    final yazi = status == 'onaylandi'
        ? 'Onaylandı'
        : status == 'reddedildi'
        ? 'Reddedildi'
        : 'Onay bekliyor';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12181C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b['athlete_name']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${b['grup'] ?? ''} · ${b['dogum_yili'] ?? ''}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (widget.antrenorMu) ...[
            const SizedBox(height: 8),
            Text(
              'Veli hesabı: ${b['parent_email']}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            yazi,
            style: TextStyle(color: renk, fontWeight: FontWeight.bold),
          ),
          if (b['source'] == 'gecis' && status == 'bekliyor')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Mevcut eşleşme için doğrulama gerekiyor.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          if ('${b['review_note'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${b['review_note']}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          if (widget.antrenorMu && status == 'bekliyor') ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _islem ? null : () => _karar(b, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Onayla'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  onPressed: _islem ? null : () => _karar(b, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Reddet'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gorunen = _liste
        .where(
          (b) =>
              !widget.antrenorMu ||
              !_sadeceBekleyen ||
              b['status'] == 'bekliyor',
        )
        .toList();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _lime,
        title: Text(
          widget.antrenorMu ? 'Veli Onayları' : 'Çocuk Bağlantılarım',
        ),
        actions: [
          IconButton(
            tooltip: 'Durumu yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _yukleniyor || _islem
                ? null
                : () async {
                    await _yukle();
                    if (mounted) widget.onKontrol?.call();
                  },
          ),
          if (widget.onCikis != null)
            IconButton(
              tooltip: 'Çıkış yap',
              onPressed: _islem ? null : widget.onCikis,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : _hata != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _hata!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.antrenorMu
                          ? 'Veliyi doğruladıktan sonra çocuğun bilgilerine erişimini onayla.'
                          : 'Çocuğunun bilgileri, antrenör eşleşmeni onayladıktan sonra açılır. Durumu yenile düğmesinden kontrol edebilirsin.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    if (widget.antrenorMu)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Yalnızca bekleyenler',
                          style: TextStyle(color: Colors.white),
                        ),
                        activeColor: _lime,
                        value: _sadeceBekleyen,
                        onChanged: (v) => setState(() => _sadeceBekleyen = v),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _lime,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _islem ? null : _cocukEkle,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Çocuk için başvuru yap'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (gorunen.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Gösterilecek başvuru bulunmuyor.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      ...gorunen.map(
                        (b) => _kart(Map<String, dynamic>.from(b)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
