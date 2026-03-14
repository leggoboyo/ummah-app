import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:subscriptions/subscriptions.dart';

import '../bootstrap/app_controller.dart';

class PlansAndUnlocksScreen extends StatelessWidget {
  const PlansAndUnlocksScreen({
    super.key,
    required this.controller,
    this.focusEntitlement,
  });

  final AppController controller;
  final AppEntitlement? focusEntitlement;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final SubscriptionProduct? recommendedProduct = focusEntitlement == null
            ? null
            : controller.recommendedProductFor(focusEntitlement!);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Plans & Unlocks'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (focusEntitlement != null)
                _FocusedModuleCard(
                  entitlement: focusEntitlement!,
                  recommendedProduct: recommendedProduct,
                  controller: controller,
                ),
              if (controller.startupSelection.deferredPackIds.isNotEmpty)
                _DeferredPackCard(controller: controller),
              const _CoreFreeCard(),
              const SizedBox(height: 12),
              _BillingStateCard(controller: controller),
              const SizedBox(height: 12),
              _ProductActionsCard(controller: controller),
              const SizedBox(height: 12),
              ...controller.subscriptionCatalog.map(
                (SubscriptionProduct product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductCard(
                    controller: controller,
                    product: product,
                    highlighted: recommendedProduct != null &&
                        recommendedProduct.id == product.id,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoreFreeCard extends StatelessWidget {
  const _CoreFreeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'Core Free',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Prayer times, local adhan notifications, qibla, Hijri date, Quran Arabic, one recommended Quran translation, and one recommended Sunni Hadith pack stay free and ad-free.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DeferredPackCard extends StatelessWidget {
  const _DeferredPackCard({
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Saved for later',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'These packs were selected during setup but deferred until a paid unlock becomes available.',
              ),
              const SizedBox(height: 12),
              for (final String packId
                  in controller.startupSelection.deferredPackIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${_packTitleForId(packId)}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedModuleCard extends StatelessWidget {
  const _FocusedModuleCard({
    required this.entitlement,
    required this.recommendedProduct,
    required this.controller,
  });

  final AppEntitlement entitlement;
  final SubscriptionProduct? recommendedProduct;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = controller.hasAccess(entitlement);
    final String recommendationText = recommendedProduct == null
        ? 'Choose a plan below to unlock this module.'
        : 'Recommended path: ${recommendedProduct!.title}.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: unlocked
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: ListTile(
          title: Text(
            unlocked
                ? '${entitlement.title} is unlocked'
                : '${entitlement.title} is locked',
          ),
          subtitle: Text(
            unlocked
                ? 'You already have access to this module on this device.'
                : recommendationText,
          ),
        ),
      ),
    );
  }
}

class _BillingStateCard extends StatelessWidget {
  const _BillingStateCard({
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final DateTime? syncTime = controller.entitlementSyncTime;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Billing status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(controller.billingProviderKind.label)),
                Chip(label: Text(controller.billingAvailability.label)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.subscriptionStatusMessage ??
                  'Entitlement status has not been loaded yet.',
            ),
            if (syncTime != null) ...<Widget>[
              const SizedBox(height: 8),
              Text('Last sync: ${_formatDateTime(syncTime)}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductActionsCard extends StatelessWidget {
  const _ProductActionsCard({
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonal(
              onPressed: controller.isWorking
                  ? null
                  : () => controller.refreshEntitlements(),
              child: const Text('Refresh entitlements'),
            ),
            FilledButton.tonal(
              onPressed: controller.isWorking
                  ? null
                  : () => controller.restorePurchases(),
              child: const Text('Restore purchases'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.controller,
    required this.product,
    required this.highlighted,
  });

  final AppController controller;
  final SubscriptionProduct product;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = controller.hasAccess(product.primaryEntitlement);
    final bool canPurchase =
        controller.billingAvailability != BillingAvailability.unavailable;

    return Card(
      color:
          highlighted ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(product.tagline),
                    ],
                  ),
                ),
                if (product.isFeatured) const Chip(label: Text('Featured')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(product.kind.label)),
                ...product.includesEntitlements.map(
                  (AppEntitlement entitlement) =>
                      Chip(label: Text(entitlement.title)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(product.description),
            const SizedBox(height: 8),
            Text(
              _moduleUnlockSummary(product),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    unlocked
                        ? 'Already unlocked on this device.'
                        : product.storePriceLabel ??
                            'Store pricing will appear after App Store and Play products are connected.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: unlocked || controller.isWorking || !canPurchase
                      ? null
                      : () => _handlePurchase(context),
                  child: Text(unlocked ? 'Included' : 'Unlock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    final PurchaseResult result = await controller.purchaseProduct(product.id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }
}

String _moduleUnlockSummary(SubscriptionProduct product) {
  switch (product.primaryEntitlement) {
    case AppEntitlement.quranPlus:
      return 'Unlocks optional Quran audio packs and future premium Quran study content.';
    case AppEntitlement.hadithPlus:
      return 'Unlocks extra Sunni Hadith language packs and future advanced Hadith study tools.';
    case AppEntitlement.aiQuran:
      return 'Unlocks Ask Quran AI. Base Quran reading stays free.';
    case AppEntitlement.aiHadith:
      return 'Unlocks Ask Hadith AI and includes Hadith Plus.';
    case AppEntitlement.scholarFeed:
      return 'Unlocks the scholar/article feed and its local cache controls.';
    case AppEntitlement.megaBundle:
      return 'Unlocks every paid pack and module in one subscription.';
    case AppEntitlement.coreFree:
      return 'Prayer, Quran Arabic, recommended reading packs, and setup tools stay free.';
  }
}

String _packTitleForId(String packId) {
  switch (packId) {
    case 'quran_audio:starter':
      return 'Audio starter pack';
    case 'quran_translation:default':
      return 'Phone-language Quran translation';
    case 'hadith_pack:default':
      return 'Recommended Sunni Hadith pack';
    default:
      return packId;
  }
}

String _formatDateTime(DateTime value) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final String month = months[value.month - 1];
  final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final String minute = value.minute.toString().padLeft(2, '0');
  final String suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$month ${value.day}, ${value.year} at $hour:$minute $suffix';
}
