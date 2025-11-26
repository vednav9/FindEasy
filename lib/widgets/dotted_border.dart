import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class DottedBorderCard extends StatelessWidget {
  final Widget child;

  const DottedBorderCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: Colors.orange,
      strokeWidth: 1.5,
      dashPattern: [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.08,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
