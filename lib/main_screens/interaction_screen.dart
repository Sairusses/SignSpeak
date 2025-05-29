import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});

  @override
  InteractionScreenState createState() => InteractionScreenState();
}

class InteractionScreenState extends State<InteractionScreen> with AutomaticKeepAliveClientMixin{
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // 👇 Set Android implementation if on Android
    late final PlatformWebViewControllerCreationParams params;
    WebViewPlatform.instance = AndroidWebViewPlatform();

    params = const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) {
        request.grant();
      },
    )
      ..loadRequest(Uri.parse('https://sign.mt'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SignSpeak')),
      body: WebViewWidget(controller: _controller),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
