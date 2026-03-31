import 'package:linkdrop_app/util/signaling_connection_gate.dart';
import 'package:test/test.dart';

void main() {
  test('Should block start when already connected', () {
    final allowed = shouldStartSignalingConnection(
      alreadyConnected: true,
      currentlyConnecting: false,
    );

    expect(allowed, isFalse);
  });

  test('Should block start when currently connecting', () {
    final allowed = shouldStartSignalingConnection(
      alreadyConnected: false,
      currentlyConnecting: true,
    );

    expect(allowed, isFalse);
  });

  test('Should allow start when not connected and not connecting', () {
    final allowed = shouldStartSignalingConnection(
      alreadyConnected: false,
      currentlyConnecting: false,
    );

    expect(allowed, isTrue);
  });
}