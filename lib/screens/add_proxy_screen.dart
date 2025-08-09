import 'package:flutter/material.dart';
import '../models/proxy_server.dart';
import '../services/proxy_storage_service.dart';
import '../widgets/custom_app_bar.dart';

class AddProxyScreen extends StatefulWidget {
  const AddProxyScreen({super.key});

  @override
  State<AddProxyScreen> createState() => _AddProxyScreenState();
}

class _AddProxyScreenState extends State<AddProxyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ProxyStorageService _storageService = ProxyStorageService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sunucu adı gereklidir';
    }
    if (value.trim().length < 2) {
      return 'Sunucu adı en az 2 karakter olmalıdır';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sunucu adresi gereklidir';
    }

    final trimmedValue = value.trim();

    // IP adresi kontrolü (port ile birlikte) - Geçerli IP aralığı kontrolü
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(:[0-9]+)?$',
    );

    // Basit domain kontrolü - En az bir harf içermeli
    final domainRegex = RegExp(
      r'^(?=.*[a-zA-Z])[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)*$',
    );

    // URL kontrolü (http/https ile başlayan) - Domain ve IP destekli
    final urlRegex = RegExp(
      r'^https?:\/\/((www\.)?[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)*|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))(:[0-9]+)?(\/.*)?$',
    );

    // www ile başlayan domain kontrolü
    final wwwDomainRegex = RegExp(
      r'^www\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)*(\/.*)?$',
    );

    // Path ile domain kontrolü (domain.com/path formatı)
    final domainWithPathRegex = RegExp(
      r'^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)+(\/.*)+$',
    );

    if (ipRegex.hasMatch(trimmedValue) ||
        domainRegex.hasMatch(trimmedValue) ||
        urlRegex.hasMatch(trimmedValue) ||
        wwwDomainRegex.hasMatch(trimmedValue) ||
        domainWithPathRegex.hasMatch(trimmedValue)) {
      return null;
    }

    return 'Geçerli bir IP adresi, domain veya URL girin';
  }

  Future<void> _saveProxy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final proxy = ProxyServer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        createdAt: DateTime.now(),
      );

      final success = await _storageService.addProxy(proxy);

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sunucu başarıyla eklendi')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sunucu eklenirken hata oluştu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beklenmeyen bir hata oluştu')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Yeni Sunucu',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sunucu Ekle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Yeni bir sunucu veya web sitesi\nekleyin',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Sunucu Adı
              const Text(
                'Sunucu Adı *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: _validateName,
                decoration: const InputDecoration(
                  hintText: 'Örn: Ana Sunucu, YouTube, Test',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sunucu Adresi
              const Text(
                'Sunucu Adresi *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                validator: _validateAddress,
                decoration: const InputDecoration(
                  hintText: 'http://213.248.190.61:72/smart/',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Örnekler
              const Text(
                'Örnekler:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  '• IP → 192.168.1.100\n'
                  '• Domain → example.com\n'
                  '• URL → https://www.youtube.com\n'
                  '• Proxy → http://213.248.190.61:72/smart/',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 40),

              // Kaydet butonu
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProxy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24), // Alt boşluk eklendi
            ],
          ),
        ),
      ),
    );
  }
}
