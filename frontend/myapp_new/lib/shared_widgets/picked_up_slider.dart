import 'package:flutter/material.dart';

class PickedUpSlider extends StatelessWidget {
  final String text;
  final VoidCallback onConfirm;

  const PickedUpSlider({
    super.key,
    required this.text,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
          Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) => onConfirm(),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
