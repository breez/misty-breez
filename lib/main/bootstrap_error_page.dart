import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/error_dialog.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class BootstrapErrorPage extends StatefulWidget {
  final Object error;
  final StackTrace stackTrace;

  const BootstrapErrorPage({super.key, required this.error, required this.stackTrace});

  @override
  State<BootstrapErrorPage> createState() => _BootstrapErrorPageState();
}

class _BootstrapErrorPageState extends State<BootstrapErrorPage> {
  final ScrollController _errorScrollController = ScrollController();
  final ScrollController _stackTraceScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final texts = context.texts();
        final bool? shouldPop = await promptAreYouSure(
          context,
          texts.close_popup_title,
          Text(texts.close_popup_message),
        );
        if (shouldPop ?? false) exit(0);
      },
      child: MaterialApp(
        title: "Misty ${getSystemAppLocalizations().app_name}",
        theme: breezLightTheme,
        localizationsDelegates: localizationsDelegates(),
        supportedLocales: supportedLocales(),
        builder: (BuildContext context, Widget? child) {
          const kMaxTitleTextScaleFactor = 1.3;

          return MediaQuery.withClampedTextScaling(
            maxScaleFactor: kMaxTitleTextScaleFactor,
            child: child!,
          );
        },
        home: Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 40.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: breezLightTheme.iconTheme.color, size: 64),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "Failed to initialize Breez SDK - Liquid",
                        style: breezLightTheme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: breezLightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Error:",
                            style: breezLightTheme.textTheme.labelLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 80,
                              maxHeight: 120,
                            ),
                            child: Theme(
                              data: ThemeData(),
                              child: Scrollbar(
                                thumbVisibility: true,
                                trackVisibility: true,
                                controller: _errorScrollController,
                                child: SingleChildScrollView(
                                  controller: _errorScrollController,
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.error.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          fontFamily: 'monospace',
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: breezLightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stack Trace:",
                            style: breezLightTheme.textTheme.labelLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 160,
                              maxHeight: 240,
                            ),
                            child: Theme(
                              data: ThemeData(),
                              child: Scrollbar(
                                controller: _stackTraceScrollController,
                                child: SingleChildScrollView(
                                  controller: _stackTraceScrollController,
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.stackTrace.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          fontFamily: 'monospace',
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SingleButtonBottomBar(
            stickToBottom: true,
            text: "EXIT",
            onPressed: () {
              exit(1);
            },
          ),
        ),
      ),
    );
  }
}
