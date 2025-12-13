import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Column(
        children: [
          const CustomAppBar(showBackButton: true),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.watch_later_outlined, size: 80, color: Colors.amber),
                   const SizedBox(height: 24),
                   Text(
                     "Coming Soon!",
                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                   ),
                   const SizedBox(height: 12),
                   Text(
                     "We are working hard to bring this feature to you.",
                     style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
