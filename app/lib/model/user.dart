/// 用户模型
///
/// 表示应用中的用户数据
class User {
  final int id;
  final String username;
  final String? email;
  final String? phone;
  final bool isVip;
  final DateTime? vipExpiresAt;
  final int downloadCount;
  final int dailyDownloadCount;
  final DateTime? lastDailyReset;
  final int vipDailyLimit;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime? lastLogin;

  // 新会员系统数据
  final MembershipInfo? membership;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.isVip = false,
    this.vipExpiresAt,
    this.downloadCount = 0,
    this.dailyDownloadCount = 0,
    this.lastDailyReset,
    this.vipDailyLimit = 30,
    this.inviteCode,
    required this.createdAt,
    this.lastLogin,
    this.membership,
  });

  /// 从 JSON 创建用户
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['userId'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      phone: json['phone'],
      isVip: json['isVip'] ?? json['is_vip'] ?? false,
      vipExpiresAt: json['vipExpiresAt'] != null
          ? DateTime.tryParse(json['vipExpiresAt'])
          : json['vip_expires_at'] != null
          ? DateTime.tryParse(json['vip_expires_at'])
          : null,
      downloadCount: json['downloadCount'] ?? json['download_count'] ?? 0,
      dailyDownloadCount: json['dailyDownloadCount'] ?? json['daily_download_count'] ?? 0,
      lastDailyReset: json['lastDailyReset'] != null
          ? DateTime.tryParse(json['lastDailyReset'])
          : json['last_daily_reset'] != null
          ? DateTime.tryParse(json['last_daily_reset'])
          : null,
      vipDailyLimit: json['vipDailyLimit'] ?? json['vip_daily_limit'] ?? 30,
      inviteCode: json['inviteCode'] ?? json['invite_code'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'])
          : json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'])
          : null,
      membership: json['membership'] != null ? MembershipInfo.fromJson(json['membership']) : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'isVip': isVip,
      'vipExpiresAt': vipExpiresAt?.toIso8601String(),
      'downloadCount': downloadCount,
      'dailyDownloadCount': dailyDownloadCount,
      'lastDailyReset': lastDailyReset?.toIso8601String(),
      'vipDailyLimit': vipDailyLimit,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'membership': membership != null
          ? {
              'has_svip': membership!.hasSvip,
              'svip_end_date': membership!.svipEndDate?.toIso8601String(),
              'svip_card_type': membership!.svipCardType,
              'has_vip': membership!.hasVip,
              'project_memberships': membership!.projectMemberships
                  .map(
                    (m) => {
                      'project_id': m.projectId,
                      'project_code': m.projectCode,
                      'project_name': m.projectName,
                      'vip_end_date': m.vipEndDate?.toIso8601String(),
                      'vip_card_type': m.vipCardType,
                    },
                  )
                  .toList(),
            }
          : null,
    };
  }

  /// 复制并修改
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    bool? isVip,
    DateTime? vipExpiresAt,
    int? downloadCount,
    int? dailyDownloadCount,
    DateTime? lastDailyReset,
    int? vipDailyLimit,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? lastLogin,
    MembershipInfo? membership,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVip: isVip ?? this.isVip,
      vipExpiresAt: vipExpiresAt ?? this.vipExpiresAt,
      downloadCount: downloadCount ?? this.downloadCount,
      dailyDownloadCount: dailyDownloadCount ?? this.dailyDownloadCount,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      vipDailyLimit: vipDailyLimit ?? this.vipDailyLimit,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      membership: membership ?? this.membership,
    );
  }

  /// VIP 是否有效（优先使用新会员系统）
  bool get isVipActive {
    // 优先判断大会员（SVIP）
    if (membership?.hasSvip == true) return true;
    // 检查是否有项目会员（VIP）
    if (membership?.hasVip == true) return true;
    // 兼容旧字段
    if (!isVip) return false;
    if (vipExpiresAt == null) return true; // 永久会员
    return vipExpiresAt!.isAfter(DateTime.now());
  }

  /// SVIP（大会员）是否有效
  bool get isSvipActive {
    return membership?.hasSvip == true;
  }

  /// 获取会员类型显示名称
  String get membershipTypeName {
    if (isSvipActive) return 'SVIP';
    if (isVipActive) return 'VIP';
    return '普通用户';
  }

  /// VIP 剩余天数，-1 表示永久会员
  int get vipRemainingDays {
    // 优先使用大会员
    if (membership?.hasSvip == true) {
      final svipCardType = membership?.svipCardType;
      if (svipCardType == 'permanent') return -1;
      final svipEnd = membership?.svipEndDate;
      if (svipEnd != null && svipEnd.isAfter(DateTime.now())) {
        return svipEnd.difference(DateTime.now()).inDays;
      }
    }
    // 检查项目会员
    if (membership?.hasVip == true && membership?.projectMemberships.isNotEmpty == true) {
      // 检查是否有永久会员
      final permanentMembership = membership!.projectMemberships.where((m) => m.isPermanent).toList();
      if (permanentMembership.isNotEmpty) {
        return -1; // 永久
      }
      // 取最近的一个项目会员到期时间
      final validMemberships = membership!.projectMemberships.where((m) => m.vipEndDate != null && m.vipEndDate!.isAfter(DateTime.now())).toList();
      if (validMemberships.isNotEmpty) {
        final maxEnd = validMemberships.map((m) => m.vipEndDate!).reduce((a, b) => a.isAfter(b) ? a : b);
        return maxEnd.difference(DateTime.now()).inDays;
      }
    }
    // 兼容旧字段
    if (!isVip) return 0;
    if (vipExpiresAt == null) return -1; // 永久会员
    final remaining = vipExpiresAt!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}

/// 会员信息
class MembershipInfo {
  final bool hasSvip;
  final DateTime? svipEndDate;
  final String? svipCardType;
  final bool hasVip;
  final List<ProjectMembership> projectMemberships;

  const MembershipInfo({
    this.hasSvip = false,
    this.svipEndDate,
    this.svipCardType,
    this.hasVip = false,
    this.projectMemberships = const [],
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      hasSvip: json['has_svip'] ?? false,
      svipEndDate: json['svip_end_date'] != null ? DateTime.tryParse(json['svip_end_date']) : null,
      svipCardType: json['svip_card_type'],
      hasVip: json['has_vip'] ?? false,
      projectMemberships: json['project_memberships'] != null
          ? (json['project_memberships'] as List).map((m) => ProjectMembership.fromJson(m)).toList()
          : [],
    );
  }

  /// 获取指定项目的会员信息
  ProjectMembership? getProjectMembership(int projectId) {
    try {
      return projectMemberships.firstWhere((m) => m.projectId == projectId);
    } catch (_) {
      return null;
    }
  }

  /// 是否有指定项目的会员权限（含大会员）
  bool hasProjectAccess(int projectId) {
    if (hasSvip) return true;
    final pm = getProjectMembership(projectId);
    return pm?.isValid ?? false;
  }
}

/// 项目会员
class ProjectMembership {
  final int projectId;
  final String? projectCode;
  final String? projectName;
  final DateTime? vipEndDate;
  final String? vipCardType;

  const ProjectMembership({
    required this.projectId,
    this.projectCode,
    this.projectName,
    this.vipEndDate,
    this.vipCardType,
  });

  factory ProjectMembership.fromJson(Map<String, dynamic> json) {
    return ProjectMembership(
      projectId: json['project_id'] ?? 0,
      projectCode: json['project_code'],
      projectName: json['project_name'],
      vipEndDate: json['vip_end_date'] != null ? DateTime.tryParse(json['vip_end_date']) : null,
      vipCardType: json['vip_card_type'],
    );
  }

  /// 是否有效（未过期）
  bool get isValid {
    if (isPermanent) return true; // 永久
    if (vipEndDate == null) return false;
    return vipEndDate!.isAfter(DateTime.now());
  }

  /// 是否为永久会员
  bool get isPermanent {
    return vipCardType == 'permanent';
  }

  /// 剩余天数，-1 表示永久会员
  int get remainingDays {
    if (isPermanent) return -1;
    if (vipEndDate == null) return 0;
    final remaining = vipEndDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}
