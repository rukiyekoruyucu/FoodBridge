class PrivateFridge {
  final String id;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? address;

  PrivateFridge({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory PrivateFridge.fromJson(Map<String, dynamic> json) {
    return PrivateFridge(
      id: json['id'].toString(), // ✅ int gelse bile stringe çevir
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      latitude: _numToDouble(json['latitude']),
      longitude: _numToDouble(json['longitude']),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  static double? _numToDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
