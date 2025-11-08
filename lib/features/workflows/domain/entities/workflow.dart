class Workflow {
  final String id;
  final String name;
  final bool active;
  final String? description;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  
  const Workflow({
    required this.id,
    required this.name,
    required this.active,
    this.description,
    this.updatedAt,
    this.createdAt,
  });
  
  Workflow copyWith({
    String? id,
    String? name,
    bool? active,
    String? description,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Workflow(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

