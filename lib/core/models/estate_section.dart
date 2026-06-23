class EstateSection {
  final String sectionId;
  final String estateId;
  final String name;

  const EstateSection({
    required this.sectionId,
    required this.estateId,
    required this.name,
  });

  factory EstateSection.fromJson(Map<String, dynamic> json) => EstateSection(
        sectionId: json['sectionId'] as String,
        estateId: json['estateId'] as String,
        name: json['name'] as String,
      );
}
