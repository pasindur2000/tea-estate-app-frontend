class Estate {
  final String estateId;
  final String name;
  final String location;
  final String status;

  const Estate({
    required this.estateId,
    required this.name,
    required this.location,
    required this.status,
  });

  factory Estate.fromJson(Map<String, dynamic> json) => Estate(
        estateId: json['estateId'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        status: json['status'] as String,
      );

  bool get isActive => status == 'active';
}
