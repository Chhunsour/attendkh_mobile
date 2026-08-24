class TopEmployee {
  final int id;
  final String name;
  final String? avatar;
  final int amount;
  final double hours;

  TopEmployee({
    required this.id,
    required this.name,
    this.avatar,
    required this.amount,
    required this.hours,
  });

  factory TopEmployee.fromJson(Map<String, dynamic> json) {
    return TopEmployee(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toInt() : (int.tryParse(json['amount']?.toString() ?? '') ?? 0),
      hours: (json['hours'] is num) ? (json['hours'] as num).toDouble() : (double.tryParse(json['hours']?.toString() ?? '') ?? 0.0),
    );
  }
}
