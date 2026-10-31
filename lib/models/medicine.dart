class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.times,
    required this.remaining,
    required this.totalQuantity,
    this.notes = '',
  });

  final String id;
  final String name;
  final String dose;
  final List<String> times;
  final int remaining;
  final int totalQuantity;
  final String notes;

  Medicine copyWith({
    String? name,
    String? dose,
    List<String>? times,
    int? remaining,
    int? totalQuantity,
    String? notes,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      times: times ?? this.times,
      remaining: remaining ?? this.remaining,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'times': times,
        'remaining': remaining,
        'totalQuantity': totalQuantity,
        'notes': notes,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id'] as String,
        name: json['name'] as String,
        dose: json['dose'] as String,
        times: (json['times'] as List<dynamic>).cast<String>(),
        remaining: json['remaining'] as int,
        totalQuantity: json['totalQuantity'] as int,
        notes: json['notes'] as String? ?? '',
      );
}
