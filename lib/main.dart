import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC WebView',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // <-- Đã sửa lỗi useMaterialScheme
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://webrtc.github.io/samples/src/content/getusermedia/gum/',
  );
  final TextEditingController _headersController = TextEditingController(
    text: '{"X-Custom-Header": "Value"}',
  );

  void _openWebView() async {
    // Xin quyền Micro và Camera trước khi mở Webview cho WebRTC
    await [Permission.camera, Permission.microphone].request();

    String urlText = _urlController.text.trim();
    if (urlText.isEmpty) return;

    if (!urlText.startsWith('http://') && !urlText.startsWith('https://')) {
      urlText = 'https://$urlText';
    }

    Map<String, String> headers = {};
    if (_headersController.text.trim().isNotEmpty) {
      try {
        Map<String, dynamic> parsedJson = jsonDecode(_headersController.text);
        headers = parsedJson.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Headers phải đúng định dạng JSON!')),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: urlText, headers: headers),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Config WebView & WebRTC')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _headersController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Headers (JSON format)',
                hintText: '{"Authorization": "Bearer token"}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openWebView,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('OK - Mở Webview', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;
  final Map<String, String> headers;

  const WebViewScreen({super.key, required this.url, required this.headers});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      );

    // Cấp quyền Media (Camera/Microphone) cho WebRTC trên Android Native Webview
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = controller.platform as AndroidWebViewController;
      
      androidController.setMediaPlaybackRequiresUserGesture(false);
          
      // Callback tự động chấp nhận quyền từ trang web (getUserMedia) - Đã cập nhật Type chuẩn
      androidController.setOnPlatformPermissionRequest(
        (request) {
          request.grant();
        },
      );
    }

    controller.loadRequest(
      Uri.parse(widget.url),
      headers: widget.headers,
    );

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.url)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
