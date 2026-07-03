class ServiceOrderItem {
  const ServiceOrderItem({
    required this.filePath,
    required this.title,
  });

  final String filePath;
  final String title;

  factory ServiceOrderItem.fromJson(Map<String, dynamic> json) {
    return ServiceOrderItem(
      filePath: json['filePath'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'title': title,
      };
}

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.name,
    required this.items,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<ServiceOrderItem> items;
  final String updatedAt;

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => ServiceOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt,
      };

  ServiceOrder copyWith({
    String? name,
    List<ServiceOrderItem>? items,
    String? updatedAt,
  }) {
    return ServiceOrder(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
