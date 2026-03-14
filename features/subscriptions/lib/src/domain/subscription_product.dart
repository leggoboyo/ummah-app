import 'package:core/core.dart';

enum SubscriptionProductKind {
  lifetimeAddOn,
  subscription;

  String get label {
    switch (this) {
      case SubscriptionProductKind.lifetimeAddOn:
        return 'One-time add-on';
      case SubscriptionProductKind.subscription:
        return 'Subscription';
    }
  }
}

class SubscriptionProduct {
  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.kind,
    required this.primaryEntitlement,
    required this.includesEntitlements,
    required this.isFeatured,
    this.storePriceLabel,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;
  final SubscriptionProductKind kind;
  final AppEntitlement primaryEntitlement;
  final Set<AppEntitlement> includesEntitlements;
  final bool isFeatured;
  final String? storePriceLabel;

  bool unlocks(AppEntitlement entitlement) {
    return includesEntitlements.contains(entitlement);
  }

  SubscriptionProduct copyWith({
    String? id,
    String? title,
    String? tagline,
    String? description,
    SubscriptionProductKind? kind,
    AppEntitlement? primaryEntitlement,
    Set<AppEntitlement>? includesEntitlements,
    bool? isFeatured,
    String? storePriceLabel,
  }) {
    return SubscriptionProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      primaryEntitlement: primaryEntitlement ?? this.primaryEntitlement,
      includesEntitlements: includesEntitlements ?? this.includesEntitlements,
      isFeatured: isFeatured ?? this.isFeatured,
      storePriceLabel: storePriceLabel ?? this.storePriceLabel,
    );
  }
}
