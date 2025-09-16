import 'package:flutter/material.dart';

class AnimatedPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double activeWidth;
  final double inactiveWidth;

  const AnimatedPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white30,
    this.activeWidth = 20,
    this.inactiveWidth = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? activeWidth : inactiveWidth,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
