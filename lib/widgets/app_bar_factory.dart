import 'package:flutter/material.dart';


class AppBarFactory {
  static PreferredSizeWidget build({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBackPress,
    IconData? leadingIcon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(leadingIcon ?? Icons.arrow_back_ios_new_rounded),
              onPressed: onBackPress,
            )
          : null,
    );
  }
}
