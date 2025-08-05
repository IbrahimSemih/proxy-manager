class ProxyServer {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;

  const ProxyServer({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  // JSON serileştirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // JSON'dan nesne oluşturma
  factory ProxyServer.fromJson(Map<String, dynamic> json) {
    return ProxyServer(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  // Kopyalama metodu
  ProxyServer copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
  }) {
    return ProxyServer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProxyServer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProxyServer(id: $id, name: $name, address: $address, createdAt: $createdAt)';
  }
}
