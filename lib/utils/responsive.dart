import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static int getCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 6;
    if (isTablet(context)) return 4;
    return 2;
  }

  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1400;
    if (isTablet(context)) return 1000;
    return double.infinity;
  }

  static EdgeInsets getPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0);
    }
    return const EdgeInsets.all(16.0);
  }
}

