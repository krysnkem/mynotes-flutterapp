import 'package:flutter/material.dart' show BuildContext, ModalRoute;

extension GetArguement on BuildContext {
  T? getArgument<T>() {
    final modalRoute = ModalRoute.of(this);
    if (modalRoute == null) return null;
    final args = modalRoute.settings.arguments;
    if (args == null || args is! T) return null;
    return args as T;
  }
}
