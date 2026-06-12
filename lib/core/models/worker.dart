class Worker {
  final String workerId;
  final String name;
  final String nic;
  final String phone;
  final String estateId;
  final String joinedDate;
  final String status;

  const Worker({
    required this.workerId,
    required this.name,
    required this.nic,
    required this.phone,
    required this.estateId,
    required this.joinedDate,
    required this.status,
  });

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        workerId: json['workerId'] as String,
        name: json['name'] as String,
        nic: json['nic'] as String,
        phone: json['phone'] as String,
        estateId: json['estateId'] as String,
        joinedDate: json['joinedDate'] as String,
        status: json['status'] as String,
      );

  bool get isActive => status == 'active';
}
