import 'package:flutter/foundation.dart';
import 'package:linkdrop_app/model/user.dart';
import 'package:linkdrop_app/services/api_service.dart';

/// 认证状态
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? (user != null),
    );
  }
}

/// 认证状态管理
///
/// 使用 ChangeNotifier 管理用户认证状态
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthState _state = const AuthState();
  AuthState get state => _state;

  User? get user => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  /// 初始化认证状态（应用启动时调用）
  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        // 先尝试加载缓存的用户信息
        final cachedUser = await _apiService.getCachedUser();
        if (cachedUser != null) {
          // 使用缓存用户信息先设置状态
          _state = AuthState(
            user: cachedUser,
            isLoading: false,
            isAuthenticated: true,
          );
          notifyListeners();
        }

        // 有 token，尝试从 API 获取最新用户信息（包含会员信息）
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          // 更新状态并缓存
          _state = AuthState(
            user: user,
            isLoading: false,
            isAuthenticated: true,
          );
          // 缓存用户信息（包含会员信息）
          await _apiService.setCachedUser(user);
        } else if (cachedUser == null) {
          // token 无效且无缓存
          await _apiService.clearTokens();
          _state = const AuthState(isLoading: false);
        }
        // 如果 API 获取失败但有缓存，保持缓存的状态
      } else {
        _state = const AuthState(isLoading: false);
      }
    } catch (e) {
      debugPrint('初始化认证状态失败: $e');
      // 如果有缓存用户，保持缓存状态
      final cachedUser = await _apiService.getCachedUser();
      if (cachedUser != null) {
        _state = AuthState(
          user: cachedUser,
          isLoading: false,
          isAuthenticated: true,
        );
      } else {
        _state = AuthState(
          isLoading: false,
          error: '初始化失败: $e',
        );
      }
    }

    notifyListeners();
  }

  /// 用户登录
  Future<bool> login(String username, String password) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);

      if (result.success && result.user != null) {
        // 登录 API 已经返回 membership 信息，直接使用
        _state = AuthState(
          user: result.user,
          isLoading: false,
          isAuthenticated: true,
        );
        // 缓存用户信息（包含会员信息）
        await _apiService.setCachedUser(result.user!);
        notifyListeners();
        return true;
      } else {
        _state = AuthState(
          isLoading: false,
          error: result.message ?? '登录失败',
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState(
        isLoading: false,
        error: '登录失败: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(String username, String password, {String? inviteCode}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final result = await _apiService.register(username, password, inviteCode: inviteCode);

      if (result.success && result.user != null) {
        _state = AuthState(
          user: result.user,
          isLoading: false,
          isAuthenticated: true,
        );
        // 缓存用户信息
        await _apiService.setCachedUser(result.user!);
        notifyListeners();
        return true;
      } else {
        _state = AuthState(
          isLoading: false,
          error: result.message ?? '注册失败',
        );
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState(
        isLoading: false,
        error: '注册失败: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    await _apiService.logout();
    // 清除缓存的用户信息
    await _apiService.clearCachedUser();

    _state = const AuthState();
    notifyListeners();
  }

  /// 获取保存的用户名
  Future<String?> getSavedUsername() async {
    return await _apiService.getSavedUsername();
  }

  /// 获取保存的密码（已解密）
  Future<String?> getSavedPassword() async {
    return await _apiService.getSavedPassword();
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    if (!_state.isAuthenticated) return;

    try {
      final user = await _apiService.getCurrentUser();
      if (user != null) {
        _state = _state.copyWith(user: user);
        // 更新缓存的用户信息
        await _apiService.setCachedUser(user);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
  }

  /// 清除错误
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  /// 保存登录凭据（用户名和密码）
  Future<void> saveCredentials(String username, String password) async {
    await _apiService.setSavedUsername(username);
    await _apiService.setSavedPassword(password);
  }

  /// 清除保存的登录凭据
  Future<void> clearCredentials() async {
    await _apiService.clearSavedUsername();
    await _apiService.clearSavedPassword();
  }
}