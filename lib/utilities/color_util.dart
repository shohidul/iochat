import 'package:flutter/material.dart';
import 'package:simple_shadow/simple_shadow.dart';

class ColorUtil {
  static Color colorFromHex(String? hexColor, Color? defaultColor) {
    Color? color;
    if (hexColor != null) {
      hexColor = hexColor.replaceAll('#', '0xFF');
      var hex = int.parse(hexColor);
      color = Color(hex);
    }
    color ??= defaultColor;
    color ??= Colors.black;
    return color;
  }

  static bool isColorWhite(String? hexColor) {
    Color color = ColorUtil.colorFromHex(hexColor, null);
    return color == Colors.white;
  }

  static Widget applyShadowIfColorWhite(String? hexColor, Widget widget) {
    return ColorUtil.isColorWhite(hexColor)
        ? SimpleShadow(opacity: 0.8, sigma: 8, color: Colors.black, offset: const Offset(0, 0), child: widget)
        : widget;
  }
}
