class UserModel {
  final int id;
  final String email;
  final String name;
  final String plan;
  final int totalPlansGenerated;
  final int plansGeneratedToday;
  final String? createdAt;
  final bool isPaid;
  final int dailyLimit;
  final int maxDurationMinutes;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.plan,
    required this.totalPlansGenerated,
    required this.plansGeneratedToday,
    this.createdAt,
    required this.isPaid,
    required this.dailyLimit,
    required this.maxDurationMinutes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? 0,
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        plan: json['plan'] ?? 'free',
        totalPlansGenerated: json['total_plans_generated'] ?? 0,
        plansGeneratedToday: json['plans_generated_today'] ?? 0,
        createdAt: json['created_at'],
        isPaid: json['is_paid'] ?? false,
        dailyLimit: json['daily_limit'] ?? 3,
        maxDurationMinutes: json['max_duration_minutes'] ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'plan': plan,
        'total_plans_generated': totalPlansGenerated,
        'plans_generated_today': plansGeneratedToday,
        'created_at': createdAt,
        'is_paid': isPaid,
        'daily_limit': dailyLimit,
        'max_duration_minutes': maxDurationMinutes,
      };

  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? plan,
    int? totalPlansGenerated,
    int? plansGeneratedToday,
    String? createdAt,
    bool? isPaid,
    int? dailyLimit,
    int? maxDurationMinutes,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        plan: plan ?? this.plan,
        totalPlansGenerated: totalPlansGenerated ?? this.totalPlansGenerated,
        plansGeneratedToday: plansGeneratedToday ?? this.plansGeneratedToday,
        createdAt: createdAt ?? this.createdAt,
        isPaid: isPaid ?? this.isPaid,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        maxDurationMinutes: maxDurationMinutes ?? this.maxDurationMinutes,
      );

  bool get isFree => plan == 'free';
  bool get isCreator => plan == 'creator';
  bool get isStudio => plan == 'studio';
  int get plansRemaining => dailyLimit == -1 ? -1 : (dailyLimit - plansGeneratedToday).clamp(0, dailyLimit);
}
