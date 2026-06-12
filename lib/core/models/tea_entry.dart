class TeaEntry {
  final String entryId;
  final String estateId;
  final String workerId;
  final String workerName;
  final String date;
  final double kg;
  final double ratePerKg;
  final double totalAmount;

  const TeaEntry({
    required this.entryId,
    required this.estateId,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.kg,
    required this.ratePerKg,
    required this.totalAmount,
  });

  factory TeaEntry.fromJson(Map<String, dynamic> json) => TeaEntry(
        entryId: json['entryId'] as String,
        estateId: json['estateId'] as String,
        workerId: json['workerId'] as String,
        workerName: json['workerName'] as String,
        date: json['date'] as String,
        kg: (json['kg'] as num).toDouble(),
        ratePerKg: (json['ratePerKg'] as num).toDouble(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
      );
}
