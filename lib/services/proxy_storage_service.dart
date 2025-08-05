import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/proxy_server.dart';

class ProxyStorageService {
  static const String _proxiesKey = 'proxy_servers';

  // Singleton pattern
  static final ProxyStorageService _instance = ProxyStorageService._internal();
  factory ProxyStorageService() => _instance;
  ProxyStorageService._internal();

  SharedPreferences? _prefs;

  // SharedPreferences'ı başlat
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Tüm proxy sunucularını getir
  Future<List<ProxyServer>> getAllProxies() async {
    await init();
    final String? proxiesJson = _prefs?.getString(_proxiesKey);

    if (proxiesJson == null || proxiesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> proxiesList = json.decode(proxiesJson);
      return proxiesList
          .map((json) => ProxyServer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Hatalı veri varsa temiz liste döndür
      return [];
    }
  }

  // Yeni proxy sunucu ekle
  Future<bool> addProxy(ProxyServer proxy) async {
    try {
      final proxies = await getAllProxies();

      // Aynı ID'ye sahip proxy varsa ekleme
      if (proxies.any((p) => p.id == proxy.id)) {
        return false;
      }

      proxies.add(proxy);
      await _saveProxies(proxies);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Proxy sunucu güncelle
  Future<bool> updateProxy(ProxyServer proxy) async {
    try {
      final proxies = await getAllProxies();
      final index = proxies.indexWhere((p) => p.id == proxy.id);

      if (index == -1) return false;

      proxies[index] = proxy;
      await _saveProxies(proxies);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Proxy sunucu sil
  Future<bool> deleteProxy(String proxyId) async {
    try {
      final proxies = await getAllProxies();
      proxies.removeWhere((proxy) => proxy.id == proxyId);
      await _saveProxies(proxies);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Proxy'leri kaydet
  Future<void> _saveProxies(List<ProxyServer> proxies) async {
    await init();
    final proxiesJson = json.encode(
      proxies.map((proxy) => proxy.toJson()).toList(),
    );
    await _prefs?.setString(_proxiesKey, proxiesJson);
  }

  // Tüm verileri temizle
  Future<void> clearAll() async {
    await init();
    await _prefs?.remove(_proxiesKey);
  }
}
