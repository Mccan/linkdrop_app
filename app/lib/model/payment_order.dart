/// 支付状态枚举
enum PaymentStatus {
  pending('待支付'),
  paid('已支付'),
  expired('已过期'),
  cancelled('已取消'),
  closed('已关闭');

  const PaymentStatus(this.label);
  final String label;
}

/// 支付订单模型
///
/// 表示用户创建的支付订单
class PaymentOrder {
  final String orderId;
  final String orderNo;
  final double amount;
  final String? qrCode;
  final String? payUrl;
  final String itemName;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;

  const PaymentOrder({
    required this.orderId,
    required this.orderNo,
    required this.amount,
    this.qrCode,
    this.payUrl,
    required this.itemName,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.paidAt,
  });

  /// 从 JSON 创建订单
  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    // 辅助函数：解析价格为 double
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return PaymentOrder(
      orderId: json['order_id']?.toString() ?? json['id']?.toString() ?? '',
      orderNo: json['order_no'] ?? '',
      amount: parsePrice(json['amount'] ?? json['price']),
      qrCode: json['qr_code'] ?? json['qrCode'],
      payUrl: json['pay_url'] ?? json['payUrl'],
      itemName: json['item_name'] ?? json['itemName'] ?? '',
      status: _parseStatus(json['status'] ?? json['payment_status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'])
          : json['paidAt'] != null
              ? DateTime.tryParse(json['paidAt'])
              : json['payment_time'] != null
                  ? DateTime.tryParse(json['payment_time'])
                  : null,
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status) {
      case 'paid':
      case 'TRADE_SUCCESS':
      case 'TRADE_FINISHED':
        return PaymentStatus.paid;
      case 'expired':
        return PaymentStatus.expired;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'closed':
      case 'TRADE_CLOSED':
        return PaymentStatus.closed;
      default:
        return PaymentStatus.pending;
    }
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_no': orderNo,
      'amount': amount,
      'qr_code': qrCode,
      'pay_url': payUrl,
      'item_name': itemName,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  /// 复制并修改
  PaymentOrder copyWith({
    String? orderId,
    String? orderNo,
    double? amount,
    String? qrCode,
    String? payUrl,
    String? itemName,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? paidAt,
  }) {
    return PaymentOrder(
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      amount: amount ?? this.amount,
      qrCode: qrCode ?? this.qrCode,
      payUrl: payUrl ?? this.payUrl,
      itemName: itemName ?? this.itemName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  /// 是否可以支付
  bool get canPay => status == PaymentStatus.pending;

  /// 是否已支付
  bool get isPaid => status == PaymentStatus.paid;
}
