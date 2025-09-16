import 'package:flutter/material.dart';

class AnimatedIntroSlide extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback onGetStarted;
  final double parallaxOffset;
  final TextStyle? titleStyle; // ✅ Add this
  final TextStyle? descriptionStyle; // ✅ And this

  const AnimatedIntroSlide({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.isCurrent,
    required this.isLast,
    required this.onGetStarted,
    required this.parallaxOffset,
    this.titleStyle, // ✅ Optional
    this.descriptionStyle, // ✅ Optional
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment(parallaxOffset * 0.5, 0),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style:
                    titleStyle ??
                    const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style:
                    descriptionStyle ??
                    const TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (isLast)
                ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Get Started"),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}
