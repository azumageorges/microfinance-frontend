import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/credit_model.dart';
import '../../../data/models/echeance_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';

// ─── Provider dédié ────────────────────────────────────────────────────────────
final _creditByReferenceProvider =
    FutureProvider.family<CreditModel, String>((ref, reference) async {
  return ref.watch(creditRepositoryProvider).getCreditByReference(reference);
});

class CreditDetailScreen extends ConsumerStatefulWidget {
  final String reference;
  const CreditDetailScreen({super.key, required this.reference});

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vérifier les retards dès l'ouverture de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifierRetards());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rafraîchir automatiquement quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _verifierRetards();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _verifierRetards() async {
    try {
      await ref.read(creditRepositoryProvider).verifierRetards();
    } catch (_) {}
    if (mounted) {
      ref.invalidate(_creditByReferenceProvider(widget.reference));
    }
  }
