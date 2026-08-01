import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/utilisateur_model.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_app_bar.dart';
import '../../../core/utils/app_snackbar.dart';

class UtilisateursScreen extends ConsumerWidget {
  const UtilisateursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(utilisateursProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Utilisateurs',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(utilisateursProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel utilisateur'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: usersAsync.when(
        loading: () => const LoadingOverlay(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(utilisateursProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return EmptyView(
              message: 'Aucun utilisateur enregistré',
              icon: Icons.manage_accounts_outlined,
              action: ElevatedButton.icon(
                onPressed: () => _showCreateUserSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Créer un utilisateur'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(utilisateursProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) =>
                  _UserCard(user: users[i], ref: ref),
            ),
          );
        },
      ),
    );
  }

  void _showCreateUserSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateUserSheet(),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UtilisateurModel user;
  final WidgetRef ref;

  const _UserCard({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (user.telephone != null && user.telephone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.telephone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _RoleChip(label: user.roleLabel),
                      const SizedBox(width: 6),
                      StatusBadge(
                        status: user.actif ? 'ACTIF' : 'INACTIF',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'toggle') {
                  try {
                    await ref
                        .read(utilisateurRepositoryProvider)
                        .toggleActif(user.id);
                    ref.invalidate(utilisateursProvider);
                    if (context.mounted) {
                      context.showSuccessSnackBar(user.actif
                                ? 'Utilisateur désactivé'
                                : 'Utilisateur activé',);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorSnackBar(e.toString());
                    }
                  }
                } else if (action == 'modifier') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _EditUserSheet(user: user, ref: ref),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'modifier',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        user.actif
                            ? Icons.person_off_outlined
                            : Icons.person_outline,
                        size: 18,
                        color: user.actif ? AppTheme.error : AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(user.actif ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;

  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'AGENT_TERRAIN';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  static const _roles = {
    'ADMIN': 'Administrateur',
    'AGENT_TERRAIN': 'Agent terrain',
    'GESTIONNAIRE_COMPTE': 'Gestionnaire de compte',
    'CAISSIER': 'Caissier',
  };

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(utilisateurRepositoryProvider).createUtilisateur({
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'motDePasse': _passCtrl.text,
        'role': _role,
        if (_telCtrl.text.isNotEmpty) 'telephone': _telCtrl.text.trim(),
      });
      ref.invalidate(utilisateursProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nouvel utilisateur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomCtrl,
                      decoration: const InputDecoration(labelText: 'Prénom *'),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(labelText: 'Nom *'),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _role,
                decoration: const InputDecoration(labelText: 'Rôle *'),
                items: _roles.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'Minimum 8 caractères';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppTheme.error)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Créer l\'utilisateur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet modification utilisateur ──────────────────────────────────────────

class _EditUserSheet extends ConsumerStatefulWidget {
  final UtilisateurModel user;
  final WidgetRef ref;

  const _EditUserSheet({required this.user, required this.ref});

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _telCtrl;
  late String _role;
  bool _loading = false;
  String? _error;

  static const _roles = {
    'ADMIN':               'Administrateur',
    'AGENT_TERRAIN':       'Agent terrain',
    'GESTIONNAIRE_COMPTE': 'Gestionnaire de compte',
    'CAISSIER':            'Caissier',
  };

  @override
  void initState() {
    super.initState();
    _nomCtrl    = TextEditingController(text: widget.user.nom);
    _prenomCtrl = TextEditingController(text: widget.user.prenom);
    _telCtrl    = TextEditingController(text: widget.user.telephone ?? '');
    _role       = widget.user.role;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(utilisateurRepositoryProvider).updateUtilisateur(
        widget.user.id,
        {
          if (_nomCtrl.text.trim() != widget.user.nom)
            'nom': _nomCtrl.text.trim(),
          if (_prenomCtrl.text.trim() != widget.user.prenom)
            'prenom': _prenomCtrl.text.trim(),
          if (_telCtrl.text.trim() != (widget.user.telephone ?? ''))
            'telephone': _telCtrl.text.trim(),
          if (_role != widget.user.role)
            'role': _role,
        },
      );
      ref.invalidate(utilisateursProvider);
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar('Utilisateur modifié avec succès');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      widget.user.fullName.isNotEmpty
                          ? widget.user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Modifier l\'utilisateur',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(widget.user.email,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prénom + Nom
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomCtrl,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Téléphone
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Rôle
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: _roles.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style:
                                const TextStyle(color: AppTheme.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
