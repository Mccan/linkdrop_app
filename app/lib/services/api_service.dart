import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkdrop_app/model/payment_order.dart';
import 'package:linkdrop_app/model/user.dart';
import 'package:linkdrop_app/util/crypto_helper.dart';

/// 缓存条目
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}

abstract class PaymentApi {
  Future<List<RechargeItem>> getRechargeItems({String? membershipType, int? projectId});

  Future<MembershipPriceResponse?> getMembershipPrices({String? projectCode});

  Future<MembershipStatusResponse?> getMembershipStatus({int? projectId});

  Future<PaymentOrder?> createRechargeOrder(int itemId);

  Future<PaymentOrder?> createPayment(int orderId);

  Future<PaymentOrder?> queryPaymentStatus(String orderNo);
}

/// API 服务
///
/// 封装所有与后端 API 的通信
class ApiService implements PaymentApi {
  // 开发环境使用局域网 IP，方便真机调试
  // static const String _devBaseUrl = 'http://localhost:3000/api';
  static const String _devBaseUrl = 'http://192.168.0.101:3000/api';
  static const String _prodBaseUrl = 'https://toolapi.dearlinkcn.top/api';

  static String get _baseUrl {
    if (kDebugMode) {
      return _devBaseUrl;
    } else {
      return _prodBaseUrl;
    }
  }

  static const String _accessTokenKey = 'linkdrop_access_token';
  static const String _refreshTokenKey = 'linkdrop_refresh_token';
  static const String _savedUsernameKey = 'linkdrop_saved_username';
  static const String _savedPasswordKey = 'linkdrop_saved_password';
  static const String _cachedUserKey = 'linkdrop_cached_user';

  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // 防止刷新 token 时无限递归
  bool _isRefreshing = false;

  // ==================== 内存缓存 ====================
  static const Duration _cacheDuration = Duration(minutes: 5);
  final Map<String, _CacheEntry> _cache = {};

  /// 获取缓存数据
  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheDuration) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// 设置缓存数据
  void _setCache<T>(String key, T data) {
    _cache[key] = _CacheEntry(data: data, timestamp: DateTime.now());
  }

  /// 清除所有缓存
  void clearCache() {
    _cache.clear();
  }

  /// 清除指定缓存
  void clearCacheKey(String key) {
    _cache.remove(key);
  }

  ApiService._internal() {
    _storage = const FlutterSecureStorage();
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
        validateStatus: (statusCode) => true,
      ),
    );

    // 添加日志拦截器（仅在调试模式）
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 自动添加 token（刷新请求不需要）
          if (!(_isRefreshing && options.path == '/auth/refresh')) {
            final token = await getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Token 过期时尝试刷新（排除刷新请求本身）
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            final refreshToken = await getRefreshToken();
            if (refreshToken != null) {
              try {
                // 直接用 Dio 实例发送请求，跳过拦截器
                final response = await _dio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                  options: Options(
                    headers: {'Content-Type': 'application/json'},
                  ),
                );
                if (response.data['success'] == true) {
                  final newAccessToken = response.data['data']['accessToken'];
                  final newRefreshToken = response.data['data']['refreshToken'];
                  await setTokens(newAccessToken, newRefreshToken);
                  // 重试原请求
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  _isRefreshing = false;
                  return handler.resolve(await _dio.fetch(error.requestOptions));
                } else {
                  // 刷新返回失败，清除 token
                  await clearTokens();
                  await clearCachedUser();
                }
              } on DioException catch (e) {
                // 刷新失败，清除 token
                debugPrint('Token 刷新失败: ${e.message}');
                await clearTokens();
                await clearCachedUser();
              } catch (e) {
                debugPrint('Token 刷新异常: $e');
                await clearTokens();
                await clearCachedUser();
              } finally {
                _isRefreshing = false;
              }
            } else {
              // 没有 refresh token，清除状态
              await clearTokens();
              await clearCachedUser();
            }
          }
          _isRefreshing = false;
          return handler.next(error);
        },
      ),
    );
  }

  /// 设置基础 URL
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  // ==================== Token 管理 ====================

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('读取 access token 失败: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('读取 refresh token 失败: $e');
      return null;
    }
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      debugPrint('保存 token 失败: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('清除 token 失败: $e');
    }
  }

  // ==================== 用户信息缓存 ====================

  /// 获取缓存的用户信息
  Future<User?> getCachedUser() async {
    try {
      final userJson = await _storage.read(key: _cachedUserKey);
      if (userJson == null || userJson.isEmpty) {
        return null;
      }
      return User.fromJson(
        Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            const JsonDecoder().convert(userJson),
          ),
        ),
      );
    } catch (e) {
      debugPrint('读取缓存的用户信息失败: $e');
      return null;
    }
  }

  /// 缓存用户信息
  Future<void> setCachedUser(User user) async {
    try {
      await _storage.write(key: _cachedUserKey, value: const JsonEncoder().convert(user.toJson()));
    } catch (e) {
      debugPrint('缓存用户信息失败: $e');
    }
  }

  /// 清除缓存的用户信息
  Future<void> clearCachedUser() async {
    try {
      await _storage.delete(key: _cachedUserKey);
    } catch (e) {
      debugPrint('清除缓存的用户信息失败: $e');
    }
  }

  // ==================== 保存的用户名 ====================

  Future<String?> getSavedUsername() async {
    try {
      return await _storage.read(key: _savedUsernameKey);
    } catch (e) {
      debugPrint('读取保存的用户名失败: $e');
      return null;
    }
  }

  Future<void> setSavedUsername(String username) async {
    try {
      await _storage.write(key: _savedUsernameKey, value: username);
    } catch (e) {
      debugPrint('保存用户名失败: $e');
    }
  }

  Future<void> clearSavedUsername() async {
    try {
      await _storage.delete(key: _savedUsernameKey);
    } catch (e) {
      debugPrint('清除保存的用户名失败: $e');
    }
  }

  // ==================== 保存的密码（加密存储）====================

  /// 获取保存的加密密码并解密
  Future<String?> getSavedPassword() async {
    try {
      final encryptedPassword = await _storage.read(key: _savedPasswordKey);
      if (encryptedPassword == null || encryptedPassword.isEmpty) {
        return null;
      }
      // 解密密码
      final cryptoHelper = CryptoHelper();
      return await cryptoHelper.decryptText(encryptedPassword);
    } catch (e) {
      debugPrint('读取保存的密码失败: $e');
      return null;
    }
  }

  /// 保存密码（自动加密）
  Future<void> setSavedPassword(String password) async {
    try {
      final cryptoHelper = CryptoHelper();
      final encryptedPassword = await cryptoHelper.encryptText(password);
      if (encryptedPassword != null) {
        await _storage.write(key: _savedPasswordKey, value: encryptedPassword);
      }
    } catch (e) {
      debugPrint('保存密码失败: $e');
    }
  }

  /// 清除保存的密码
  Future<void> clearSavedPassword() async {
    try {
      await _storage.delete(key: _savedPasswordKey);
    } catch (e) {
      debugPrint('清除保存的密码失败: $e');
    }
  }

  // ==================== 用户认证 ====================

  /// 用户登录
  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await setTokens(data['accessToken'], data['refreshToken']);
        // 保存用户名以便下次自动填充
        await setSavedUsername(username);
        // 保存加密后的密码
        await setSavedPassword(password);
        return LoginResult(
          success: true,
          user: User.fromJson(data),
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      } else {
        return LoginResult(
          success: false,
          message: response.data['message'] ?? '登录失败',
        );
      }
    } on DioException catch (e) {
      return LoginResult(
        success: false,
        message: e.response?.data['message'] ?? '网络错误，请稍后重试',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: '登录失败: $e',
      );
    }
  }

  /// 用户注册
  Future<LoginResult> register(String username, String password, {String? inviteCode}) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'confirmPassword': password,
          'securityQuestion': '默认问题',
          'securityAnswer': 'default',
          if (inviteCode != null) 'invite_code': inviteCode,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await setTokens(data['accessToken'], data['refreshToken']);
        return LoginResult(
          success: true,
          user: User.fromJson(data),
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      } else {
        return LoginResult(
          success: false,
          message: response.data['message'] ?? '注册失败',
        );
      }
    } on DioException catch (e) {
      return LoginResult(
        success: false,
        message: e.response?.data['message'] ?? '网络错误，请稍后重试',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: '注册失败: $e',
      );
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      debugPrint('退出登录请求失败: $e');
    } finally {
      await clearTokens();
    }
  }

  /// 获取当前用户信息
  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return null;
    }
  }

  // ==================== 充值商品 ====================

  /// 获取充值商品列表
  /// 获取充值商品列表
  ///
  /// [membershipType] 会员类型：'global' 大会员, 'project' 子会员
  /// [projectId] 项目ID，null 表示获取大会员套餐，有值表示获取对应项目的子会员套餐
  /// [forceRefresh] 是否强制刷新缓存
  Future<List<RechargeItem>> getRechargeItems({String? membershipType, int? projectId, bool forceRefresh = false}) async {
    final cacheKey = 'recharge_items_${membershipType ?? "all"}_${projectId ?? "all"}';

    // 检查缓存
    if (!forceRefresh) {
      final cached = _getFromCache<List<RechargeItem>>(cacheKey);
      if (cached != null) {
        debugPrint('[Cache] 使用缓存的充值商品列表');
        return cached;
      }
    }

    try {
      final queryParams = <String, dynamic>{};
      if (membershipType != null) {
        queryParams['membership_type'] = membershipType;
      }
      if (projectId != null) {
        queryParams['project_id'] = projectId;
      }

      final response = await _dio.get(
        '/recharge/items',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.data['success'] == true) {
        final items = response.data['data'] as List;
        final result = items.map((item) => RechargeItem.fromJson(item)).toList();
        _setCache(cacheKey, result);
        return result;
      }
      return [];
    } catch (e) {
      debugPrint('获取充值商品失败: $e');
      return [];
    }
  }

  /// 获取会员价格信息（统一接口）
  ///
  /// [projectCode] 项目代码，如 'linkdrop'
  /// [forceRefresh] 是否强制刷新缓存
  Future<MembershipPriceResponse?> getMembershipPrices({String? projectCode, bool forceRefresh = false}) async {
    final cacheKey = 'membership_prices_${projectCode ?? "all"}';

    // 检查缓存
    if (!forceRefresh) {
      final cached = _getFromCache<MembershipPriceResponse>(cacheKey);
      if (cached != null) {
        debugPrint('[Cache] 使用缓存的会员价格');
        return cached;
      }
    }

    try {
      final queryParams = <String, dynamic>{};
      if (projectCode != null) {
        queryParams['project_code'] = projectCode;
      }

      final response = await _dio.get(
        '/membership/prices',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.data['success'] == true) {
        final result = MembershipPriceResponse.fromJson(response.data['data']);
        _setCache(cacheKey, result);
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('获取会员价格失败: $e');
      return null;
    }
  }

  // ==================== 支付订单 ====================

  /// 创建充值订单
  Future<PaymentOrder?> createRechargeOrder(int itemId) async {
    try {
      final response = await _dio.post(
        '/recharge/orders',
        data: {
          'item_id': itemId,
        },
      );

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('创建订单失败: $e');
      return null;
    }
  }

  /// 创建支付（获取二维码）
  Future<PaymentOrder?> createPayment(int orderId) async {
    try {
      final response = await _dio.post(
        '/payment/alipay/facetoface/create',
        data: {
          'order_id': orderId,
        },
      );

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('创建支付失败: $e');
      return null;
    }
  }

  /// 查询支付状态
  Future<PaymentOrder?> queryPaymentStatus(String orderNo) async {
    try {
      final response = await _dio.get('/payment/queryOrderStatus/$orderNo');

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('查询支付状态失败: $e');
      return null;
    }
  }

  /// 获取用户订单列表
  Future<List<PaymentOrder>> getUserOrders() async {
    try {
      final response = await _dio.get('/auth/orders');
      if (response.data['success'] == true) {
        final orders = response.data['data'] as List;
        return orders.map((order) => PaymentOrder.fromJson(order)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('获取订单列表失败: $e');
      return [];
    }
  }

  /// 重新激活过期订单
  Future<PaymentOrder?> reactivateOrder(int orderId) async {
    try {
      final response = await _dio.post('/payment/orders/reactivate/$orderId');

      if (response.data['success'] == true) {
        return PaymentOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('重新激活订单失败: $e');
      return null;
    }
  }

  // ==================== 会员状态 ====================

  /// 获取用户会员状态
  /// [projectId] 项目ID，可选
  /// [forceRefresh] 是否强制刷新缓存
  Future<MembershipStatusResponse?> getMembershipStatus({int? projectId, bool forceRefresh = false}) async {
    final cacheKey = 'membership_status_${projectId ?? "all"}';

    // 检查缓存
    if (!forceRefresh) {
      final cached = _getFromCache<MembershipStatusResponse>(cacheKey);
      if (cached != null) {
        debugPrint('[Cache] 使用缓存的会员状态');
        return cached;
      }
    }

    try {
      final queryParams = projectId != null ? {'project_id': projectId} : null;
      final response = await _dio.get(
        '/membership/user/membership',
        queryParameters: queryParams,
      );
      if (response.data['success'] == true) {
        final result = MembershipStatusResponse.fromJson(response.data['data']);
        _setCache(cacheKey, result);
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('获取会员状态失败: $e');
      return null;
    }
  }

  // ==================== 联系我们 ====================

  /// 提交联系消息
  Future<Map<String, dynamic>> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/contact/send',
        data: {
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('提交联系消息失败: $e');
      return {
        'success': false,
        'message': '提交失败，请稍后重试',
      };
    }
  }

  // ==================== 用户信息 ====================

  /// 更新用户基本信息
  Future<Map<String, dynamic>> updateProfile(String username) async {
    try {
      final response = await _dio.put(
        '/auth/profile',
        data: {'username': username},
      );
      return {
        'success': response.data['success'] == true,
        'message': response.data['message'],
        'data': response.data['data'],
      };
    } catch (e) {
      debugPrint('更新用户信息失败: $e');
      return {
        'success': false,
        'message': '更新失败，请稍后重试',
      };
    }
  }

  /// 修改密码
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return {
        'success': response.data['success'] == true,
        'message': response.data['message'],
      };
    } catch (e) {
      debugPrint('修改密码失败: $e');
      return {
        'success': false,
        'message': '修改失败，请稍后重试',
      };
    }
  }

  // ==================== 兑换码 ====================

  /// 兑换码兑换
  /// [code] 兑换码
  /// [projectCode] 项目代码，默认 'linkdrop'
  Future<RedeemResult> redeemCoupon(String code, {String projectCode = 'linkdrop'}) async {
    try {
      final response = await _dio.post(
        '/coupons/redeem',
        data: {
          'code': code,
          'project_code': projectCode,
        },
      );

      if (response.data['success'] == true) {
        return RedeemResult(
          success: true,
          type: response.data['data']?['type'] ?? 'vip',
          projectName: response.data['data']?['project_name'],
        );
      } else {
        return RedeemResult(
          success: false,
          message: response.data['message'] ?? response.data['msg'] ?? '兑换失败',
        );
      }
    } catch (e) {
      debugPrint('兑换码兑换失败: $e');
      return RedeemResult(
        success: false,
        message: '兑换失败，请稍后重试',
      );
    }
  }
}

/// 兑换结果
class RedeemResult {
  final bool success;
  final String? message;
  final String? type; // 'svip' 或 'vip'
  final String? projectName;

  const RedeemResult({
    required this.success,
    this.message,
    this.type,
    this.projectName,
  });
}

/// 登录结果
class LoginResult {
  final bool success;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  const LoginResult({
    required this.success,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.message,
  });
}

/// 会员价格响应
class MembershipPriceResponse {
  final GlobalMembershipInfo? global;
  final List<RechargeItem> globalItems;
  final ProjectMembershipInfo? project;
  final List<RechargeItem> projectItems;

  MembershipPriceResponse({
    this.global,
    this.globalItems = const [],
    this.project,
    this.projectItems = const [],
  });

  factory MembershipPriceResponse.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MembershipPriceResponse(
      global: json['global'] != null ? GlobalMembershipInfo.fromJson(json['global']) : null,
      globalItems: json['global_items'] != null ? (json['global_items'] as List).map((item) => RechargeItem.fromJson(item)).toList() : [],
      project: json['project'] != null ? ProjectMembershipInfo.fromJson(json['project']) : null,
      projectItems: json['project_items'] != null ? (json['project_items'] as List).map((item) => RechargeItem.fromJson(item)).toList() : [],
    );
  }
}

/// 大会员信息
class GlobalMembershipInfo {
  final int itemId;
  final double price;
  final double originalPrice;
  final String name;
  final List<String> benefits;

  GlobalMembershipInfo({
    required this.itemId,
    required this.price,
    required this.originalPrice,
    required this.name,
    required this.benefits,
  });

  factory GlobalMembershipInfo.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return GlobalMembershipInfo(
      itemId: json['item_id'] ?? 0,
      price: parsePrice(json['price']),
      originalPrice: parsePrice(json['original_price']),
      name: json['name'] ?? '大会员',
      benefits: (json['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// 项目会员信息
class ProjectMembershipInfo {
  final int projectId;
  final String projectCode;
  final String projectName;
  final double price;
  final double originalPrice;

  ProjectMembershipInfo({
    required this.projectId,
    required this.projectCode,
    required this.projectName,
    required this.price,
    required this.originalPrice,
  });

  factory ProjectMembershipInfo.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ProjectMembershipInfo(
      projectId: json['project_id'] ?? 0,
      projectCode: json['project_code'] ?? '',
      projectName: json['project_name'] ?? '',
      price: parsePrice(json['price']),
      originalPrice: parsePrice(json['original_price']),
    );
  }
}

/// 充值商品
class RechargeItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final int? days;
  final int downloadCount;
  final int dailyLimit;
  final int type; // 0: 会员套餐, 1: 下载包
  final String membershipType; // 'global': 大会员, 'project': 子会员
  final int? projectId; // NULL表示大会员，有值表示子会员

  const RechargeItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.days,
    this.downloadCount = 0,
    this.dailyLimit = 30,
    this.type = 0,
    this.membershipType = 'project',
    this.projectId,
  });

  factory RechargeItem.fromJson(Map<String, dynamic> json) {
    // 辅助函数：将各种类型转换为 double
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RechargeItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: parsePrice(json['price']),
      originalPrice: json['original_price'] != null ? parsePrice(json['original_price']) : null,
      days: json['days'],
      downloadCount: json['download_count'] ?? 0,
      dailyLimit: json['daily_limit'] ?? 30,
      type: json['type'] ?? 0,
      membershipType: json['membership_type'] ?? 'project',
      projectId: json['project_id'],
    );
  }

  /// 是否为会员套餐
  bool get isMembership => type == 0;

  /// 是否为永久会员
  bool get isPermanent => days == null;

  /// 是否为大会员
  bool get isGlobal => membershipType == 'global';

  /// 是否为子会员
  bool get isProject => membershipType == 'project';
}

/// 会员状态响应
class MembershipStatusResponse {
  final bool hasSvip;
  final DateTime? svipEndDate;
  final bool hasVip;
  final DateTime? vipEndDate;
  final String? vipType;
  final List<OtherVipProject> otherVipProjects;
  final List<MembershipProjectInfo>? projectMemberships;

  const MembershipStatusResponse({
    this.hasSvip = false,
    this.svipEndDate,
    this.hasVip = false,
    this.vipEndDate,
    this.vipType,
    this.otherVipProjects = const [],
    this.projectMemberships,
  });

  factory MembershipStatusResponse.fromJson(Map<String, dynamic> json) {
    return MembershipStatusResponse(
      hasSvip: json['has_svip'] ?? false,
      svipEndDate: json['svip_end_date'] != null ? DateTime.tryParse(json['svip_end_date']) : null,
      hasVip: json['has_vip'] ?? false,
      vipEndDate: json['vip_end_date'] != null ? DateTime.tryParse(json['vip_end_date']) : null,
      vipType: json['vip_type'],
      otherVipProjects: json['other_vip_projects'] != null
          ? (json['other_vip_projects'] as List).map((m) => OtherVipProject.fromJson(m)).toList()
          : [],
      projectMemberships: json['project_memberships'] != null
          ? (json['project_memberships'] as List).map((m) => MembershipProjectInfo.fromJson(m)).toList()
          : null,
    );
  }

  /// 是否建议升级大会员
  bool get recommendSvip => !hasSvip && otherVipProjects.isNotEmpty;

  /// 升级建议文案
  String get recommendReason {
    if (!recommendSvip) return '';
    final names = otherVipProjects.map((p) => p.projectName ?? '其他应用').join('、');
    return '您已在$names开通了VIP，升级大会员可享全部应用权限';
  }
}

/// 其他已开通VIP的项目
class OtherVipProject {
  final int projectId;
  final String? projectCode;
  final String? projectName;
  final DateTime? vipEndDate;

  const OtherVipProject({
    required this.projectId,
    this.projectCode,
    this.projectName,
    this.vipEndDate,
  });

  factory OtherVipProject.fromJson(Map<String, dynamic> json) {
    return OtherVipProject(
      projectId: json['project_id'] ?? 0,
      projectCode: json['project_code'],
      projectName: json['project_name'],
      vipEndDate: json['vip_end_date'] != null ? DateTime.tryParse(json['vip_end_date']) : null,
    );
  }
}

/// 会员项目信息
class MembershipProjectInfo {
  final int projectId;
  final String? projectCode;
  final String? projectName;
  final DateTime? vipEndDate;
  final String? vipCardType;

  const MembershipProjectInfo({
    required this.projectId,
    this.projectCode,
    this.projectName,
    this.vipEndDate,
    this.vipCardType,
  });

  factory MembershipProjectInfo.fromJson(Map<String, dynamic> json) {
    return MembershipProjectInfo(
      projectId: json['project_id'] ?? 0,
      projectCode: json['project_code'],
      projectName: json['project_name'],
      vipEndDate: json['vip_end_date'] != null ? DateTime.tryParse(json['vip_end_date']) : null,
      vipCardType: json['vip_card_type'],
    );
  }
}
