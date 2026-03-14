import 'subscription_state.dart';

enum PurchaseStatus {
  success,
  unavailable,
  cancelled,
  failed;
}

class PurchaseResult {
  const PurchaseResult({
    required this.status,
    required this.state,
    required this.message,
  });

  final PurchaseStatus status;
  final SubscriptionState state;
  final String message;
}
