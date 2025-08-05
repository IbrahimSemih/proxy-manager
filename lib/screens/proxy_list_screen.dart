import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/proxy_server.dart';
import '../services/proxy_storage_service.dart';
import '../widgets/proxy_card.dart';
import '../widgets/custom_app_bar.dart';
import 'add_proxy_screen.dart';

class ProxyListScreen extends StatefulWidget {
  const ProxyListScreen({super.key});

  @override
  State<ProxyListScreen> createState() => _ProxyListScreenState();
}

class _ProxyListScreenState extends State<ProxyListScreen> {
  final ProxyStorageService _storageService = ProxyStorageService();
  List<ProxyServer> _proxies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProxies();
  }

  Future<void> _loadProxies() async {
    setState(() => _isLoading = true);
    try {
      final proxies = await _storageService.getAllProxies();
      setState(() {
        _proxies = proxies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sunucular yüklenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _deleteProxy(ProxyServer proxy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sunucuyu Sil'),
        content: Text(
          '${proxy.name} sunucusunu silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _storageService.deleteProxy(proxy.id);
      if (success) {
        _loadProxies();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sunucu silindi')));
        }
      }
    }
  }

  Future<void> _navigateToAddProxy() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddProxyScreen()),
    );

    if (result == true) {
      _loadProxies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kayıtlı Sunucular',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddProxy,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _proxies.isEmpty
          ? _buildEmptyState()
          : _buildProxyList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Henüz sunucu eklenmemiş',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk sunucunuzu eklemek için\nyukarıdaki "Ekle" butonuna dokunun',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _navigateToAddProxy,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('İlk Sunucuyu Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProxyUrl(ProxyServer proxy) async {
    String url = proxy.address.trim();

    // URL formatını düzenle
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Eğer URL protokol ile başlamıyorsa, https ekle
      if (url.contains('.') && !url.contains('/')) {
        // Basit domain: youtube.com
        url = 'https://$url';
      } else if (url.contains('.') && url.contains('/')) {
        // Domain with path: youtube.com/watch?v=xyz
        url = 'https://$url';
      } else if (RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}').hasMatch(url)) {
        // IP adresi: 192.168.1.100 veya 192.168.1.100:8080
        url = 'http://$url';
      } else {
        // Diğer durumlar için https dene
        url = 'https://$url';
      }
    }

    try {
      final Uri uri = Uri.parse(url);

      // Önce direkt açmayı dene
      bool launched = false;

      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        launched = true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${proxy.name} açılıyor: $url'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        launched = false;
      }

      // İlk deneme başarısızsa, http ile dene
      if (!launched && url.startsWith('https://')) {
        final httpUrl = url.replaceFirst('https://', 'http://');
        try {
          final httpUri = Uri.parse(httpUrl);
          await launchUrl(httpUri, mode: LaunchMode.externalApplication);
          launched = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${proxy.name} açılıyor: $httpUrl'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          launched = false;
        }
      }

      // Hiçbiri işe yaramazsa hata göster
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${proxy.name} açılamadı. URL: ${proxy.address}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Kopyala',
              textColor: Colors.white,
              onPressed: () {
                // URL'i panoya kopyalayabilir
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geçersiz URL: ${proxy.address}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProxyList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _proxies.length,
      itemBuilder: (context, index) {
        final proxy = _proxies[index];
        return ProxyCard(
          proxy: proxy,
          onTap: () => _openProxyUrl(proxy),
          onDelete: () => _deleteProxy(proxy),
        );
      },
    );
  }
}
