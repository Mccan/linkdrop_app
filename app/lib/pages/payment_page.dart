import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linkdrop_app/model/payment_order.dart' show PaymentOrder, PaymentStatus;
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/services/api_service.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/widget/qr_code_display.dart';
import 'package:provider/provider.dart' as provider;

/// 支付页面
///
/// 提供会员套餐选择和支付宝扫码支付功能
enum _PaymentOverlayKind {
  qr,
  success,
  status,
  recommendSvip,
}

class PaymentPage extends StatefulWidget {
  final PaymentApi apiService;

  PaymentPage({super.key, PaymentApi? apiService}) : apiService = apiService ?? ApiService();

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<RechargeItem> _globalItems = []; // 大会员套餐
  List<RechargeItem> _projectItems = []; // 子会员套餐
  RechargeItem? _selectedItem;
  PaymentOrder? _currentOrder;
  bool _isLoading = true;
  bool _isPaying = false;
  _PaymentOverlayKind? _overlayKind;
  String? _overlayTitle;
  String? _overlayMessage;
  Timer? _pollTimer;
  int _pollRetryCount = 0;
  static const int _maxPollRetries = 72; // 72次 * 3秒 = 216秒 = 3.6分钟超时

  // LinkDrop 项目ID
  static const int _linkdropProjectId = 1;

  // 会员状态（用于升级建议）
  MembershipStatusResponse? _membershipStatus;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  PaymentApi get _apiService => widget.apiService;

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      // 并行获取会员价格和会员状态
      final results = await Future.wait<dynamic>([
        _apiService.getMembershipPrices(projectCode: 'linkdrop'),
        _apiService.getMembershipStatus(projectId: _linkdropProjectId),
      ]);

      final priceResponse = results[0] as MembershipPriceResponse?;
      final membershipStatus = results[1] as MembershipStatusResponse?;

      if (priceResponse != null && mounted) {
        setState(() {
          _globalItems = priceResponse.globalItems;
          _projectItems = priceResponse.projectItems;
          _membershipStatus = membershipStatus;
          _isLoading = false;
          // 默认选中第一个套餐（优先大会员）
          if (_globalItems.isNotEmpty) {
            _selectedItem = _globalItems.first;
          } else if (_projectItems.isNotEmpty) {
            _selectedItem = _projectItems.first;
          }
        });
      } else {
        // 如果统一接口失败，回退到原来的方式
        final fallbackResults = await Future.wait([
          _apiService.getRechargeItems(membershipType: 'global'),
          _apiService.getRechargeItems(membershipType: 'project', projectId: _linkdropProjectId),
        ]);

        final globalItems = fallbackResults[0] as List<RechargeItem>;
        final projectItems = fallbackResults[1] as List<RechargeItem>;

        if (mounted) {
          setState(() {
            _globalItems = globalItems;
            _projectItems = projectItems;
            _membershipStatus = membershipStatus;
            _isLoading = false;
            if (globalItems.isNotEmpty) {
              _selectedItem = globalItems.first;
            } else if (projectItems.isNotEmpty) {
              _selectedItem = projectItems.first;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载商品失败: $e');
      }
    }
  }

  Future<void> _startPayment() async {
    if (_selectedItem == null) return;

    // 如果选择的是子会员套餐，检查是否已有其他项目会员，建议升级大会员
    if (_selectedItem!.isProject && _membershipStatus?.recommendSvip == true) {
      setState(() {
        _overlayKind = _PaymentOverlayKind.recommendSvip;
      });
      return;
    }

    await _doPayment();
  }

  /// 执行支付
  Future<void> _doPayment() async {
    if (_selectedItem == null) return;

    setState(() => _isPaying = true);

    try {
      // 1. 创建订单
      final order = await _apiService.createRechargeOrder(_selectedItem!.id);
      if (order == null) {
        _showError('创建订单失败');
        setState(() => _isPaying = false);
        return;
      }

      // 2. 创建支付（获取二维码）
      final paymentOrder = await _apiService.createPayment(int.parse(order.orderId));
      if (paymentOrder == null || paymentOrder.qrCode == null) {
        _showError('创建支付失败');
        setState(() => _isPaying = false);
        return;
      }

      setState(() {
        _currentOrder = paymentOrder;
        _overlayKind = _PaymentOverlayKind.qr;
        _overlayTitle = null;
        _overlayMessage = null;
        _isPaying = false;
      });

      // 4. 开始轮询支付状态
      _startPolling(paymentOrder.orderNo);
    } catch (e) {
      _showError('支付失败: $e');
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  void _closeOverlay() {
    if (!mounted || _overlayKind == null) {
      return;
    }

    setState(() {
      _overlayKind = null;
      _overlayTitle = null;
      _overlayMessage = null;
    });
  }

  void _showStatusOverlay(String title, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _overlayKind = _PaymentOverlayKind.status;
      _overlayTitle = title;
      _overlayMessage = message;
    });
  }

  void _showSuccessOverlay() {
    if (!mounted) {
      return;
    }

    setState(() {
      _overlayKind = _PaymentOverlayKind.success;
      _overlayTitle = null;
      _overlayMessage = null;
    });
  }

  void _startPolling(String orderNo) {
    _pollTimer?.cancel();
    _pollRetryCount = 0;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollRetryCount++;

      final order = await _apiService.queryPaymentStatus(orderNo);

      if (order == null) {
        // 订单不存在，停止轮询
        timer.cancel();
        _onPaymentTimeout(orderNo, isNotFound: true);
        return;
      }

      // 检查支付状态
      if (order.isPaid) {
        timer.cancel();
        _onPaymentSuccess();
        return;
      }

      // 检查订单是否已过期/关闭
      if (order.status == PaymentStatus.expired || order.status == PaymentStatus.closed || order.status == PaymentStatus.cancelled) {
        timer.cancel();
        _onPaymentExpired(order);
        return;
      }

      // 检查是否超过最大重试次数
      if (_pollRetryCount >= _maxPollRetries) {
        timer.cancel();
        _onPaymentTimeout(orderNo);
        return;
      }
    });
  }

  void _onPaymentSuccess() {
    // 刷新用户信息
    provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();

    if (mounted) {
      _showSuccessOverlay();
    }
  }

  /// 订单过期处理
  void _onPaymentExpired(PaymentOrder order) {
    if (mounted) {
      _showStatusOverlay('订单已过期', '订单 ${order.orderNo} 已${order.status.label}，请重新创建订单');
    }
  }

  /// 支付超时处理
  void _onPaymentTimeout(String orderNo, {bool isNotFound = false}) {
    if (mounted) {
      final title = isNotFound ? '订单不存在' : '支付查询超时';
      final content = isNotFound ? '订单可能已过期或被取消，请重新创建订单' : '订单号：$orderNo\n\n请打开支付宝检查是否已支付，若已支付请联系客服';

      _showStatusOverlay(title, content);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 构建套餐列表
  Widget _buildItemList(List<RechargeItem> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: items.map((item) {
          final isSelected = _selectedItem == item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedItem = item),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? LinkDropColors.zinc800 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? LinkDropColors.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: LinkDropColors.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                ),
                              ),
                              if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '¥${item.originalPrice!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.withValues(alpha: 0.7),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.isMembership ? '会员特权 · ${item.isPermanent ? '永久有效' : '${item.days}天有效期'}' : '下载包 · ${item.downloadCount}次下载',
                            style: TextStyle(
                              fontSize: 12,
                              color: LinkDropColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '¥${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LinkDropColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverlay(bool isDark) {
    final overlayKind = _overlayKind;
    if (overlayKind == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: constraints.maxHeight - 48,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc900 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: switch (overlayKind) {
                      _PaymentOverlayKind.qr => _buildQrOverlayContent(),
                      _PaymentOverlayKind.success => _buildSuccessOverlayContent(),
                      _PaymentOverlayKind.status => _buildStatusOverlayContent(),
                      _PaymentOverlayKind.recommendSvip => _buildRecommendSvipOverlayContent(),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrOverlayContent() {
    final paymentOrder = _currentOrder;
    if (paymentOrder == null) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('payment-qr-overlay'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '扫码支付',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '请使用支付宝扫描下方二维码完成支付',
          style: TextStyle(color: LinkDropColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: QRCodeDisplay(
            qrCode: paymentOrder.qrCode!,
            size: 200,
            isPolling: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '支付金额：¥${paymentOrder.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: LinkDropColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('等待支付中...'),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            _pollTimer?.cancel();
            _closeOverlay();
          },
          child: const Text('取消支付'),
        ),
      ],
    );
  }

  Widget _buildSuccessOverlayContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          '支付成功',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('您的会员权益已生效'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            _closeOverlay();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: LinkDropColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('完成'),
        ),
      ],
    );
  }

  Widget _buildStatusOverlayContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _overlayTitle ?? '提示',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _overlayMessage ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LinkDropColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _closeOverlay,
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// 升级大会员建议弹窗
  Widget _buildRecommendSvipOverlayContent() {
    final status = _membershipStatus;
    if (status == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinkDropColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          '升级大会员',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          status.recommendReason,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LinkDropColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                _closeOverlay();
                _doPayment();
              },
              child: Text(
                '继续开通子会员',
                style: TextStyle(color: LinkDropColors.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                _closeOverlay();
                // 切换到大会员套餐
                if (_globalItems.isNotEmpty) {
                  setState(() => _selectedItem = _globalItems.first);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LinkDropColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('升级大会员'),
            ),
          ],
        ),
      ],
    );
  }

  /// 兑换码兑换区域
  Widget _buildRedeemSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '兑换码兑换',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RedeemCodeInput(isDark: isDark),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = provider.Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
            ),
            child: CustomScrollView(
              slivers: [
                // 顶部标题栏
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '开通会员',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : LinkDropColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 用户当前状态
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Card(
                      color: isDark ? LinkDropColors.zinc800 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: user?.membership?.hasSvip == true
                                    ? LinkDropColors.primaryGradient
                                    : user?.membership?.hasVip == true
                                    ? LinkDropColors.primaryGradient
                                    : null,
                                color: user?.isVipActive == true ? null : LinkDropColors.textSecondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                user?.membership?.hasSvip == true
                                    ? Icons.diamond
                                    : user?.membership?.hasVip == true
                                    ? Icons.workspace_premium
                                    : Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.username ?? '用户',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.membership?.hasSvip == true
                                        ? (user?.vipRemainingDays == -1 ? 'SVIP大会员 · 永久' : 'SVIP大会员 · 剩余${user?.vipRemainingDays ?? 0}天')
                                        : user?.membership?.hasVip == true
                                        ? (user?.vipRemainingDays == -1 ? 'VIP会员 · 永久' : 'VIP会员 · 剩余${user?.vipRemainingDays ?? 0}天')
                                        : '普通用户',
                                    style: TextStyle(
                                      color: user?.isVipActive == true ? LinkDropColors.primary : LinkDropColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 套餐选择标题
                // 大会员套餐标题
                if (_globalItems.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '大会员套餐',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '解锁全部子项目会员功能',
                        style: TextStyle(
                          fontSize: 12,
                          color: LinkDropColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: _buildItemList(_globalItems, isDark),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],

                // 子会员套餐标题
                if (_projectItems.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          Icon(Icons.send, color: LinkDropColors.primary, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'LinkDrop 会员套餐',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '仅解锁 LinkDrop 会员功能',
                        style: TextStyle(
                          fontSize: 12,
                          color: LinkDropColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: _buildItemList(_projectItems, isDark),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],

                // 加载中或无数据
                if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_globalItems.isEmpty && _projectItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: LinkDropColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无可用套餐',
                            style: TextStyle(
                              fontSize: 16,
                              color: LinkDropColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadItems,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重新加载'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LinkDropColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 兑换码兑换区域
                SliverToBoxAdapter(
                  child: _buildRedeemSection(isDark),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 底部支付按钮
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isPaying || _selectedItem == null ? null : _startPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LinkDropColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isPaying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                '立即支付 ¥${_selectedItem?.price.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_overlayKind != null) _buildOverlay(isDark),
        ],
      ),
    );
  }
}

/// 兑换码输入组件
class _RedeemCodeInput extends StatefulWidget {
  final bool isDark;

  const _RedeemCodeInput({required this.isDark});

  @override
  State<_RedeemCodeInput> createState() => _RedeemCodeInputState();
}

class _RedeemCodeInputState extends State<_RedeemCodeInput> {
  final _codeController = TextEditingController();
  final _apiService = ApiService();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showSnackBar('请输入兑换码', isError: true);
      return;
    }

    setState(() => _isRedeeming = true);

    try {
      final result = await _apiService.redeemCoupon(code);

      if (result.success) {
        final message = result.type == 'svip' ? 'SVIP 已激活' : '${result.projectName ?? "VIP"} 已激活';

        // 刷新用户信息
        provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();

        if (mounted) {
          _showSnackBar(message, isError: false);
          _codeController.clear();
        }
      } else {
        if (mounted) {
          _showSnackBar(result.message ?? '兑换失败', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('兑换失败，请稍后重试', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (!isError) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: '输入兑换码',
              filled: true,
              fillColor: widget.isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintStyle: TextStyle(
                color: LinkDropColors.textSecondary,
              ),
            ),
            style: TextStyle(
              color: widget.isDark ? Colors.white : LinkDropColors.textPrimary,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isRedeeming ? null : _handleRedeem,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: _isRedeeming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '兑换',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
