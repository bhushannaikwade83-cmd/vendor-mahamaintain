class ServiceCategory {
  final int id;
  final String name;
  final String? imageUrl;

  const ServiceCategory({required this.id, required this.name, this.imageUrl});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}
