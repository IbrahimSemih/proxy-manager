import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/proxy_server.dart';
import '../widgets/custom_app_bar.dart';

class WebViewScreen extends StatefulWidget {
  final ProxyServer proxy;

  const WebViewScreen({super.key, required this.proxy});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    String url = widget.proxy.address.trim();

    // URL formatını düzenle
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') &&
          !RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}').hasMatch(url)) {
        url = 'https://$url';
      } else {
        url = 'http://$url';
      }
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Progress güncellemesi
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              error = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              this.error = error.description;
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _reload() {
    setState(() {
      isLoading = true;
      error = null;
    });
    controller.reload();
  }

  void _goBack() async {
    if (await controller.canGoBack()) {
      controller.goBack();
    }
  }

  void _goForward() async {
    if (await controller.canGoForward()) {
      controller.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.proxy.name,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: Column(
        children: [
          // Kontrol çubuğu
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Geri butonu
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _goBack,
                  iconSize: 20,
                ),

                // İleri butonu
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _goForward,
                  iconSize: 20,
                ),

                const SizedBox(width: 16),

                // URL göstergesi
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.proxy.address,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Yenile butonu
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _reload,
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Web içeriği
          Expanded(
            child: error != null
                ? _buildErrorView()
                : Stack(
                    children: [
                      WebViewWidget(controller: controller),
                      if (isLoading)
                        Container(
                          color: Colors.white,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Yükleniyor...'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Sayfa Yüklenemedi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reload,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
