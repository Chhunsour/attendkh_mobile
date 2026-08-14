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
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      amount: json['amount'] ?? 0,
      hours: (json['hours'] ?? 0).toDouble(),
    );
  }
}
