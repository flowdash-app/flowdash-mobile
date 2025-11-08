class Instance {
  final String id;
  final String name;
  final String url;
  final bool active;
  final DateTime? lastConnectedAt;
  final DateTime? createdAt;
  
  const Instance({
    required this.id,
    required this.name,
    required this.url,
    required this.active,
    this.lastConnectedAt,
    this.createdAt,
  });
  
  Instance copyWith({
    String? id,
    String? name,
    String? url,
    bool? active,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
  }) {
    return Instance(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      active: active ?? this.active,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

