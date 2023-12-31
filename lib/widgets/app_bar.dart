import 'package:iochat/utilities/constants.dart';
import 'package:iochat/utilities/widget_builder.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<dynamic, dynamic> appBarData;

  const CustomAppBar(this.appBarData, {Key? key}) : super(key: key);
  // String? statusBarIconColor;
  @override
  Widget build(BuildContext context) {
    bool hasLeadingWidget = appBarData['left'] != null;
    bool hasCenterWidget = appBarData['center'] != null;
    bool hasActionButton = appBarData['right'] != null;

    List<Widget> widgets = [];

    if (hasLeadingWidget) {
      List<dynamic> leadingChildren = appBarData['left'];
      for (var element in leadingChildren) {
        // statusBarIconColor = element['color']; // same as appBar leading icon color
        // String? hexColor = element['color'];
        Widget widget = buildWidget(Constants.top, element, context);
        widgets.add(Flexible(fit: FlexFit.loose, child: widget));
      }
    } else {
      // a blank widget
      widgets.add(const Flexible(
          fit: FlexFit.loose,
          child: SizedBox(
            width: 40,
            height: 40,
          )));
    }

    if (hasCenterWidget) {
      List<dynamic> centerChildren = appBarData['center'];
      for (var element in centerChildren) {
        // String? hexColor = element['color'];
        Widget widget = buildWidget(Constants.top, element, context);
        widgets.add(Flexible(flex: 5, fit: FlexFit.tight, child: widget));
      }
    }

    if (hasActionButton) {
      List<dynamic> rightChildren = appBarData['right'];
      for (var element in rightChildren) {
        // String? hexColor = element['color'];
        Widget widget = buildWidget(Constants.top, element, context);
        widgets.add(Flexible(fit: FlexFit.loose, child: widget));
      }
    } else {
      // a blank widget
      widgets.add(const Flexible(
          fit: FlexFit.loose,
          child: SizedBox(
            width: 40,
            height: 40,
          )));
    }

    return AppBar(
      backgroundColor: Constants.appBarBackgroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      // systemOverlayStyle: ColorUtil.isColorWhite(statusBarIconColor)
      //     ? const SystemUiOverlayStyle(
      //         statusBarColor: Constants.appBarBackgroundColor,
      //         statusBarIconBrightness: Brightness.light,
      //         statusBarBrightness: Brightness.dark)
      //     : const SystemUiOverlayStyle(
      //         statusBarColor: Constants.appBarBackgroundColor,
      //         statusBarIconBrightness: Brightness.dark,
      //         statusBarBrightness: Brightness.light),
      automaticallyImplyLeading: false,
      shape: const Border(bottom: BorderSide(color: Constants.appBarBorderColor, width: 0.5)),
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(right: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widgets,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(Constants.appBarHeight);
  }
}
