import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class SporcuOzelBilgiController {
  final tc = TextEditingController();
  final lisans = TextEditingController();

  String? kanGrubu;
  Uint8List? foto;
  bool mevcutFoto = false;
  bool fotoDegisti = false;

  void yukle(Map<String, dynamic> data) {
    tc.text = data['tc_kimlik_no']?.toString() ?? '';
    lisans.text = data['lisans_no']?.toString() ?? '';
    kanGrubu = data['kan_grubu']?.toString();
    mevcutFoto = data['has_photo'] == true;

    foto = data['photo'] == null
        ? null
        : base64Decode(data['photo']['data'] as String);

    fotoDegisti = false;
  }

  Map<String, dynamic> toJson() => {
    'tc_kimlik_no': tc.text.trim().isEmpty ? null : tc.text.trim(),
    'lisans_no': lisans.text.trim().isEmpty ? null : lisans.text.trim(),
    'kan_grubu': kanGrubu,
    if (fotoDegisti && foto != null) 'photo': {'data': base64Encode(foto!)},
    if (fotoDegisti && foto == null) 'remove_photo': true,
  };

  void dispose() {
    tc.dispose();
    lisans.dispose();
  }
}

class SporcuOzelAlanlar extends StatefulWidget {
  final SporcuOzelBilgiController controller;

  const SporcuOzelAlanlar({super.key, required this.controller});

  @override
  State<SporcuOzelAlanlar> createState() => _SporcuOzelAlanlarState();
}

class _SporcuOzelAlanlarState extends State<SporcuOzelAlanlar> {
  bool _tcGoster = false;
  bool _seciliyor = false;

  Future<void> _fotoSec() async {
    if (_seciliyor) return;

    setState(() => _seciliyor = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || !mounted) return;

      final file = result.files.single;

      if (file.size > 2 * 1024 * 1024) {
        throw Exception('Fotoğraf en fazla 2 MB olabilir');
      }

      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('Fotoğraf okunamadı');
      }

      setState(() {
        widget.controller.foto = file.bytes;
        widget.controller.fotoDegisti = true;
        widget.controller.mevcutFoto = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _seciliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: c.foto == null
                ? const CircleAvatar(
                    radius: 54,
                    child: Icon(Icons.person, size: 52),
                  )
                : Image.memory(
                    c.foto!,
                    width: 108,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 72),
                  ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _seciliyor ? null : _fotoSec,
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                _seciliyor
                    ? 'Seçiliyor...'
                    : c.mevcutFoto
                    ? 'Fotoğrafı Değiştir'
                    : 'Fotoğraf Seç',
              ),
            ),
            if (c.mevcutFoto)
              TextButton(
                onPressed: () {
                  setState(() {
                    c.foto = null;
                    c.mevcutFoto = false;
                    c.fotoDegisti = true;
                  });
                },
                child: const Text('Fotoğrafı Kaldır'),
              ),
          ],
        ),
        const Text(
          'JPG / PNG · En fazla 2 MB',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: c.tc,
          obscureText: !_tcGoster,
          keyboardType: TextInputType.number,
          maxLength: 11,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'T.C. Kimlik No',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _tcGoster = !_tcGoster),
              tooltip: _tcGoster ? 'Gizle' : 'Göster',
              icon: Icon(_tcGoster ? Icons.visibility_off : Icons.visibility),
            ),
          ),
          validator: (value) {
            if ((value ?? '').isNotEmpty &&
                !RegExp(r'^[1-9][0-9]{10}$').hasMatch(value!)) {
              return '11 rakam gir; ilk rakam 0 olamaz';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: c.kanGrubu ?? '',
          decoration: const InputDecoration(labelText: 'Kan Grubu'),
          items:
              [
                '',
                'A Rh+',
                'A Rh-',
                'B Rh+',
                'B Rh-',
                'AB Rh+',
                'AB Rh-',
                '0 Rh+',
                '0 Rh-',
              ].map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text(v.isEmpty ? 'Bilinmiyor / Belirtilmedi' : v),
                );
              }).toList(),
          onChanged: (v) {
            setState(() => c.kanGrubu = v == '' ? null : v);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: c.lisans,
          maxLength: 64,
          decoration: const InputDecoration(labelText: 'Lisans No'),
        ),
        const Text(
          'Bu bilgiler yalnızca antrenörlere gösterilir. '
          'Eksik bilgileri daha sonra tamamlayabilirsin.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
