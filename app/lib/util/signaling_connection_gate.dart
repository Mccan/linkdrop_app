bool shouldStartSignalingConnection({
  required bool alreadyConnected,
  required bool currentlyConnecting,
}) {
  return !alreadyConnected && !currentlyConnecting;
}