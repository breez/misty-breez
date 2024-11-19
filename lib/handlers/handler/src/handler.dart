import 'package:flutter/cupertino.dart';
import 'package:l_breez/handlers/handler/src/mixin/handler_context_provider.dart';

abstract class Handler {
  HandlerContextProvider<StatefulWidget>? contextProvider;

  void init(HandlerContextProvider<StatefulWidget> contextProvider) {
    this.contextProvider = contextProvider;
  }

  void dispose() {
    contextProvider = null;
  }
}
