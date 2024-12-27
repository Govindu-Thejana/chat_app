import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final bool isExpanded;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: const Color(0xFFF5F6F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.purpleAccent,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            Transform.rotate(
              angle: isExpanded
                  ? -3.14 / 2
                  : 3.14 / 2, // Rotate 90 degrees if not expanded
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
