import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkdrop_app/model/payment_order.dart';
import 'package:linkdrop_app/pages/payment_page.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/services/api_service.dart';
import 'package:provider/provider.dart';

class FakePaymentApi implements PaymentApi {
  final RechargeItem _item = const RechargeItem(
    id: 1,
    name: 'LinkDrop会员-月卡',
    price: 9.9,
    days: 30,
    membershipType: 'project',
    projectId: 1,
  );

  int createRechargeOrderCalls = 0;
  int createPaymentCalls = 0;

  @override
  Future<PaymentOrder?> createPayment(int orderId) async {
    createPaymentCalls++;
    return PaymentOrder(
      orderId: orderId.toString(),
      orderNo: 'RC17738187434623SN9ZH',
      amount: 9.9,
      qrCode: 'https://example.com/pay/RC17738187434623SN9ZH',
      itemName: _item.name,
      createdAt: DateTime(2026, 3, 18),
    );
  }

  @override
  Future<PaymentOrder?> createRechargeOrder(int itemId) async {
    createRechargeOrderCalls++;
    return PaymentOrder(
      orderId: itemId.toString(),
      orderNo: 'RC17738187434623SN9ZH',
      amount: 9.9,
      itemName: _item.name,
      createdAt: DateTime(2026, 3, 18),
    );
  }

  @override
  Future<MembershipPriceResponse?> getMembershipPrices({String? projectCode}) async {
    return MembershipPriceResponse(
      projectItems: [_item],
    );
  }

  @override
  Future<List<RechargeItem>> getRechargeItems({String? membershipType, int? projectId}) async {
    return [_item];
  }

  @override
  Future<PaymentOrder?> queryPaymentStatus(String orderNo) async {
    return PaymentOrder(
      orderId: '1',
      orderNo: orderNo,
      amount: 9.9,
      itemName: _item.name,
      createdAt: DateTime(2026, 3, 18),
      status: PaymentStatus.pending,
    );
  }
}

void main() {
  testWidgets('desktop mouse click shows payment QR dialog', (tester) async {
    final api = FakePaymentApi();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: PaymentPage(apiService: api),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final payButtonLabel = find.text('立即支付 ¥9.90');
    expect(payButtonLabel, findsOneWidget);

    final payButton = find.widgetWithText(ElevatedButton, '立即支付 ¥9.90');
    await tester.ensureVisible(payButton);
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(payButton).onPressed, isNotNull);

    await tester.tap(payButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(api.createRechargeOrderCalls, 1);
    expect(api.createPaymentCalls, 1);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('payment-qr-overlay')), findsOneWidget);
    expect(find.text('支付金额：¥9.90'), findsOneWidget);
  });
}