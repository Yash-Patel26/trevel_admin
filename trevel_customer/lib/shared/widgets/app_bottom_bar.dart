import 'package:flutter/material.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int bookingCount;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.bookingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, "HOME", 0),
              _buildNavItem(Icons.map_outlined, Icons.map, "TRIPS", 1, badgeCount: bookingCount),
              _buildNavItem(Icons.person_outline, Icons.person, "PROFILE", 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOutline, IconData iconFilled, String label, int index, {int badgeCount = 0}) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? iconFilled : iconOutline,
                color: isSelected ? Colors.amber : Colors.black,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.amber : Colors.black,
                ),
              ),
            ],
          ),
          if (badgeCount > 0)
            Positioned(
              top: -5,
              right: -10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
