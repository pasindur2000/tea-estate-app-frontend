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
        entryId: (json['teaEntryId'] ?? json['entryId'] ?? json['entry_id'] ?? json['id'] ?? '') as String,
        estateId: (json['estateId'] ?? json['estate_id'] ?? '') as String,
        workerId: (json['workerId'] ?? json['worker_id'] ?? '') as String,
        workerName: (json['workerName'] ?? json['worker_name'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        kg: ((json['kg'] ?? 0) as num).toDouble(),
        ratePerKg: ((json['ratePerKg'] ?? json['rate_per_kg'] ?? 0) as num).toDouble(),
        totalAmount: ((json['totalAmount'] ?? json['total_amount'] ?? 0) as num).toDouble(),
      );
}
