import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 5.0;
  static const double xs = 10.0;
  static const double s = 15.0;
  static const double m = 20.0;
  static const double l = 25.0;
  static const double xl = 30.0;
  static const double xxl = 40.0;

  static const EdgeInsets allXXS = EdgeInsets.all(xxs);
  static const EdgeInsets allXS = EdgeInsets.all(xs);
  static const EdgeInsets allS = EdgeInsets.all(s);
  static const EdgeInsets allM = EdgeInsets.all(m);
  static const EdgeInsets allL = EdgeInsets.all(l);

  static const EdgeInsets symHorizontalM = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets symHorizontalL = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets symVerticalM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets symVerticalL = EdgeInsets.symmetric(vertical: l);
}
