import 'package:flutter/cupertino.dart';
import 'package:misty_breez/handlers/handlers.dart';

abstract class Handler {
  HandlerContextProvider<StatefulWidget>? contextProvider;

  void init(HandlerContextProvider<StatefulWidget> contextProvider) {
    this.contextProvider = contextProvider;
  }

  void dispose() {
    contextProvider = null;
  }
}
