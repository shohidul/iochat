import 'package:iochat/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utilities/action_decider.dart';
import '../utilities/color_util.dart';

Widget buildBottomSheet(String parent, dynamic data, BuildContext context) {
  List<Widget> widgets = [];
  List<dynamic> wlist = data['items'];

  for (var element in wlist) {
    String type = element['type'];
    if (Constants.bottomSheetItem == type) {
      String? icon = element['icon'];
      String? iconWeight = data['iconWeight'];
      iconWeight ??= Constants.bottomSheetIconWeight;

      String? colorString = element['color'];
      String? label = element['label'];

      Widget widget = TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Constants.onPressColor,
          padding: EdgeInsets.zero,
          fixedSize: const Size.fromHeight(Constants.bottomSheetButtonHeight),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () {
          Navigator.of(context).pop();
          customAction(parent, element['action'], context);
        },
        child: Container(
          padding: const EdgeInsets.only(left: Constants.bottomSheetInset, right: Constants.bottomSheetInset),
          child: Row(
            children: [
              SizedBox(
                width: Constants.bottomSheetIconWidth,
                height: Constants.bottomSheetIconHeight,
                child: SvgPicture.asset(
                  'assets/fontawesome/$iconWeight/$icon.svg',
                  colorFilter: ColorFilter.mode(ColorUtil.colorFromHex(colorString, Constants.bottomSheetIconColor), BlendMode.srcIn),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: Constants.bottomSheetTextMarginLeft),
                child: Text(
                  label ?? '',
                  style: const TextStyle(
                      color: Colors.black,
                      letterSpacing: Constants.bottomSheetLetterSpacing,
                      fontWeight: Constants.bottomSheetFontWeight,
                      fontSize: Constants.bottomSheetFontSize),
                ),
              )
            ],
          ),
        ),
      );
      widgets.add(widget);
    } else if (Constants.bottomSheetDivider == type) {
      Widget widget = const Row(
        children: <Widget>[
          Expanded(
              child: Padding(
            padding: EdgeInsets.only(
                left: Constants.bottomSheetInset + Constants.bottomSheetIconWidth + Constants.bottomSheetTextMarginLeft,
                right: Constants.bottomSheetInset),
            child: Divider(
              thickness: 0.5,
              color: Constants.bottomSheetDividerColor,
            ),
          ))
        ],
      );
      widgets.add(widget);
    }
  }

  showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      //   backgroundColor: Colors.brown,
      builder: (BuildContext context) {
        double boxHeightRatio =
            wlist.length * Constants.bottomSheetButtonHeight / (MediaQuery.of(context).size.height - 80);
        return SafeArea(
          child: SizedBox(
              height: wlist.length > 1 ? MediaQuery.of(context).size.height * boxHeightRatio : 100,
              child: Column(children: <Widget>[
                topDividerWidget(),
                Expanded(
                  child: ListView(children: widgets),
                ),
              ])),
        );
      }).then((value) {
    return value;
  });
  return const Text('Element Type Not Found!');
}

Widget topDividerWidget() {
  Widget widget = Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 9),
        child: SizedBox(
          width: 44,
          height: 6,
          child: Container(
              decoration: BoxDecoration(
            color: Constants.bottomSheetHandleColor,
            borderRadius: BorderRadius.circular(6),
          )),
        ),
      ),
    ],
  );
  return widget;
}
