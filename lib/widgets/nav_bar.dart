import 'dart:async';

import 'package:iochat/utilities/constants.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter/material.dart';

import '../utilities/di.dart';
import '../utilities/widget_builder.dart';

class CustomNavBar extends StatefulWidget {
  final List navBarData;
  final Completer<InAppWebViewController> controller = locator<Completer<InAppWebViewController>>();
  CustomNavBar({
    Key? key,
    required this.navBarData,
  }) : super(key: key);

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Constants.navBarBackgroudColor,
      shape: const Border(top: BorderSide(color: Constants.navBarBorderColor, width: 0.5)),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getNavButtonWidgets(context),
        ),
      ),
    );
  }

  List<Widget> getNavButtonWidgets(context) {
    List<Widget> buttonWidgets = [];
    List navBarData = widget.navBarData;
    if (navBarData.isEmpty) {
      navBarData = [
        {
          'type': 'ICON_BUTTON',
          'icon': 'arrow-rotate-right',
          'action': {'type': 'OPEN_URL', 'url': Uri.parse(Constants.baseUrl).toString()},
          'iconWeight': 'solid'
        },
        {
          'type': 'ICON_BUTTON',
          'icon': 'arrow-right-from-bracket',
          'action': {'type': 'RESET'}
        }
      ];
    }

    for (Map<String, dynamic> navdata in navBarData) {
      Widget iconButton = buildWidget(Constants.bottom, navdata, context);
      buttonWidgets.add(Expanded(child: iconButton));
    }
    return buttonWidgets;
  }
}
