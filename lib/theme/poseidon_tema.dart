import 'package:flutter/material.dart';

/// Shared Poseidon palette. Status/grade/event colors are defined separately.
class PoseidonRenkler {
  PoseidonRenkler._();

  static const zemin = Color(0xFF07152B);
  static const kart = Color(0xFF102D35);
  static const alan = Color(0xFF153740);
  static const kenar = Color(0xFF345451);
  static const secim = Color(0xFF284B46);
  static const vurgu = Color(0xFFC7D6A9);
  static const ikincilYazi = Color(0xFFA7BAB7);
}

/// A single continuous backdrop behind the app's Navigator.
class PoseidonArkaPlan extends StatelessWidget {
  final Widget child;

  const PoseidonArkaPlan({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    PoseidonRenkler.zemin,
                    Color(0xFF143C3D),
                    Color(0xFF050E22),
                  ],
                  stops: [0, 0.50, 1],
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.95),
                    radius: 1.1,
                    colors: [Color(0x663C7161), Color(0x003C7161)],
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
