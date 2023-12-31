import 'package:iochat/utilities/constants.dart';
import 'package:iochat/utilities/color_util.dart';
import 'package:iochat/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'action_decider.dart';

Widget buildWidget(String parent, dynamic data, BuildContext context) {
  String? type = data['type'];
  if (Constants.logo == type) {
    return InkWell(
      child: Image.network(data['src'], height: 50.0),
      onTap: () {
        if (data['action'] != null) {
          customAction(parent, data['action'], context);
        }
      },
    );
  } else if (Constants.title == type) {
    String? label = data['label'];
    String? hexColor = data['color'];

    return Text(label ?? '',
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ColorUtil.colorFromHex(hexColor, Constants.appBarTitleColor),
          fontSize: Constants.appBarTitleFontSize,
          fontWeight: Constants.appBarTitleFontWeight,
          letterSpacing: Constants.appBarTitleLetterSpacing,
        ));
  } else if (Constants.iconButton == type) {
    int unreadCount = data['unreadCount'] ?? 0;
    IconButton iconButton = IconButton(
        highlightColor: Colors.transparent, // Constants.onPressColor.withOpacity(.12),
        splashColor: Colors.transparent, // Constants.onPressColor.withOpacity(.2),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          if (data['action'] != null) {
            customAction(parent, data['action'], context, data: data);
          }
        },
        icon: unreadCount > 0 ? getBadgeIcon(unreadCount, data) : getIcon(data));

    var actionType = data['action']['type'];
    if (Constants.goBack == actionType) {
      Widget widget = GestureDetector(
        child: iconButton,
        onLongPress: () async {
          await reloadWebView();
        },
      );
      return widget;
    }
    return iconButton;
  } else if (Constants.textButton == type) {
    String? label = data['label'];
    String? hexColor = data['color'];
    return TextButton(
      onPressed: () {
        if (data['action'] != null) {
          customAction(parent, data['action'], context, data: data);
        }
      },
      child: Text(
        label ?? '',
        style: TextStyle(color: ColorUtil.colorFromHex(hexColor, Colors.black)),
      ),
    );
  } else if (Constants.bottomSheet == type) {
    buildBottomSheet(parent, data, context);
  }
  return const Text('Element Type Not Found!');
}

Badge getBadgeIcon(int unreadCount, data) {
  return Badge(
    backgroundColor: Constants.badgeColor,
    label: Text(unreadCount.toString(),
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
    child: getIcon(data),
  );
}

SvgPicture getIcon(data) {
  String? hexColor = data['color'];

  String? iconWeight = data['iconWeight'];
  iconWeight ??= Constants.iconWeight;

  double? iconSize;
  int? size = data['iconSize'];

  if (size != null) {
    iconSize = size.toDouble();
  }
  iconSize ??= Constants.iconSize;

  String? icon = data['icon'];
  return SvgPicture.asset(
    'assets/fontawesome/$iconWeight/$icon.svg',
    height: iconSize,
    colorFilter: ColorFilter.mode(ColorUtil.colorFromHex(hexColor, Constants.iconColor), BlendMode.srcIn),
  );
}
