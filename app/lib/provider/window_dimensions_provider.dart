import 'dart:math' as math;
import 'dart:ui';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:linkdrop_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class WindowDimensions {
  final Offset position;
  final Size size;

  WindowDimensions({
    required this.position,
    required this.size,
  });
}

final windowDimensionProvider = Provider<WindowDimensionsController>((ref) {
  return WindowDimensionsController(ref.read(persistenceProvider));
});

// 旧值(400x500)在 Windows 上非常容易触发布局溢出；这里提高下限，
// 同时在 bitsdojo_window 上设置 minSize，确保“拖到很小还能继续拖”的问题被彻底解决。
// 最小尺寸策略：
// - 宽度允许更小，以便触发移动端/窄屏布局（例如侧边栏下沉）。
// - 高度提高，避免桌面端在极矮窗口下出现大量垂直溢出。
const Size _minimalSize = Size(560, 800);
const Size _defaultSize = Size(900, 800);

class WindowDimensionsController {
  final PersistenceService _service;

  WindowDimensionsController(this._service);

  /// Sets window position & size according to saved settings.
  Future<void> initDimensionsConfiguration() async {
    await WindowManager.instance.setMinimumSize(_minimalSize);

    // 隐藏窗口标题栏按钮（最小化、最大化、关闭）
    await WindowManager.instance.setTitleBarStyle(TitleBarStyle.hidden);

    // 在部分桌面平台/窗口实现下，仅设置 window_manager 的最小尺寸并不足以限制用户继续缩小窗口。
    // bitsdojo_window 的 minSize 需要在 window ready 之后设置。
    doWhenWindowReady(() {
      appWindow.minSize = _minimalSize;
    });

    // load saved Window placement and preferences
    final useSavedPlacement = _service.getSaveWindowPlacement();
    final persistedDimensions = _service.getWindowLastDimensions();

    if (useSavedPlacement && persistedDimensions != null && await isInScreenBounds(persistedDimensions.position, persistedDimensions.size)) {
      final safeSize = Size(
        math.max(_minimalSize.width, persistedDimensions.size.width),
        math.max(_minimalSize.height, persistedDimensions.size.height),
      );
      await WindowManager.instance.setSize(safeSize);
      await WindowManager.instance.setPosition(persistedDimensions.position);
    } else {
      final primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();
      final hasEnoughWidthForDefaultSize = primaryDisplay.digestedSize.width >= 1200;
      await WindowManager.instance.setSize(hasEnoughWidthForDefaultSize ? _defaultSize : _minimalSize);
      await WindowManager.instance.center();
    }
  }

  Future<bool> isInScreenBounds(Offset windowPosition, [Size? windowSize]) async {
    final displays = await ScreenRetriever.instance.getAllDisplays();
    final sumWidth = displays.fold(0.0, (previousValue, element) => previousValue + element.digestedSize.width);
    final maxHeight = displays.fold(
      0.0,
      (previousValue, element) => previousValue > element.digestedSize.height ? previousValue : element.digestedSize.height,
    );
    final minX = displays.fold(0.0, (previousValue, element) {
      final currX = element.visiblePosition?.dx ?? 0;
      return currX < previousValue ? currX : previousValue;
    });
    final minY = displays.fold(0.0, (previousValue, element) {
      final currY = element.visiblePosition?.dy ?? 0;
      return currY < previousValue ? currY : previousValue;
    });
    final checkX = windowPosition.dx >= minX && windowPosition.dx + (windowSize?.width ?? 0) <= sumWidth;
    final checkY = windowPosition.dy >= minY && windowPosition.dy + (windowSize?.height ?? 0) <= maxHeight;

    return checkX && checkY;
  }

  Future<void> storeDimensions({
    required Offset windowOffset,
    required Size windowSize,
  }) async {
    if (await isInScreenBounds(windowOffset)) {
      await _service.setWindowOffsetX(windowOffset.dx);
      await _service.setWindowOffsetY(windowOffset.dy);
      await _service.setWindowHeight(windowSize.height);
      await _service.setWindowWidth(windowSize.width);
    }
  }

  Future<void> storePosition({required Offset windowOffset}) async {
    if (await isInScreenBounds(windowOffset)) {
      await _service.setWindowOffsetX(windowOffset.dx);
      await _service.setWindowOffsetY(windowOffset.dy);
    }
  }

  Future<void> storeSize({required Size windowSize}) async {
    await _service.setWindowHeight(windowSize.height);
    await _service.setWindowWidth(windowSize.width);
  }
}

extension on Display {
  Size get digestedSize => visibleSize ?? size;
}
