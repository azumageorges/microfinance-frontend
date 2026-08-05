import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_app_bar.dart';

class RapportsScreen extends ConsumerStatefulWidget {
  const RapportsScreen({super.key});

  @override
  ConsumerState<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends ConsumerState<RapportsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Rapports',
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _buildTab('Global', 0),
          _buildTab('Comptes', 1),
          _buildTab('Crédits', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _RapportGlobalWidget();
      case 1:
        return _RapportComptesWidget();
      case 2:
        return _RapportCreditsWidget();
      default:
        return const SizedBox();
    }
  }
}

class _RapportGlobalWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.read(reportRepositoryProvider).getRapportGlobal();

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingOverlay();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        return _buildRapportGlobal(snapshot.data!.data);
      },
    );
  }

  Widget _buildRapportGlobal(Map<String, dynamic> data) {
    final comptes = data['comptes'] as Map<String, dynamic>;
    final transactions = data['transactions'] as Map<String, dynamic>;
    final credits = data['credits'] as Map<String, dynamic>;
    final clients = data['clients'] as Map<String, dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Comptes',
          icon: Icons.account_balance_wallet,
          children: [
            _StatRow(label: 'Total', value: comptes['total'].toString()),
            _StatRow(label: 'Actifs', value: comptes['actifs'].toString()),
            _StatRow(label: 'Bloqués', value: comptes['bloques'].toString()),
            _StatRow(label: 'Clôturés', value: comptes['clotures'].toString()),
            _StatRow(label: 'Solde total', value: Formatters.currency(comptes['totalSolde'])),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Transactions',
          icon: Icons.receipt_long,
          children: [
            _StatRow(label: 'Total', value: transactions['total'].toString()),
            _StatRow(label: 'Dépôts', value: transactions['depots'].toString()),
            _StatRow(label: 'Retraits', value: transactions['retraits'].toString()),
            _StatRow(label: 'Transferts', value: transactions['transferts'].toString()),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Crédits',
          icon: Icons.credit_card,
          children: [
            _StatRow(label: 'Total', value: credits['total'].toString()),
            _StatRow(label: 'En cours', value: credits['enCours'].toString()),
            _StatRow(label: 'En attente', value: credits['enAttente'].toString()),
            _StatRow(label: 'Validés', value: credits['valides'].toString()),
            _StatRow(label: 'Remboursés', value: credits['rembourses'].toString()),
            _StatRow(label: 'Montant accordé', value: Formatters.currency(credits['totalMontantAccorde'])),
            _StatRow(label: 'Encours', value: Formatters.currency(credits['encours'])),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Clients',
          icon: Icons.people,
          children: [
            _StatRow(label: 'Total', value: clients['total'].toString()),
          ],
        ),
      ],
    );
  }
}

class _RapportComptesWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.read(reportRepositoryProvider).getRapportComptes();

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingOverlay();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        return _buildRapportComptes(snapshot.data!.data);
      },
    );
  }

  Widget _buildRapportComptes(Map<String, dynamic> data) {
    final parStatut = data['parStatut'] as Map<String, dynamic>;
    final parType = data['parType'] as Map<String, dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Par statut',
          icon: Icons.pie_chart,
          children: [
            _StatRow(label: 'Actifs', value: parStatut['ACTIF'].toString()),
            _StatRow(label: 'Bloqués', value: parStatut['BLOQUE'].toString()),
            _StatRow(label: 'Clôturés', value: parStatut['CLOTURE'].toString()),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Par type',
          icon: Icons.category,
          children: [
            _StatRow(label: 'Épargne', value: parType['EPARGNE'].toString()),
            _StatRow(label: 'DAT', value: parType['DAT'].toString()),
            _StatRow(label: 'Crédit', value: parType['CREDIT'].toString()),
            _StatRow(label: 'Enfant', value: parType['ENFANT'].toString()),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Solde total',
          icon: Icons.account_balance,
          children: [
            _StatRow(label: 'Montant', value: Formatters.currency(data['totalSolde'])),
          ],
        ),
      ],
    );
  }
}

class _RapportCreditsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.read(reportRepositoryProvider).getRapportCredits();

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingOverlay();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        return _buildRapportCredits(snapshot.data!.data);
      },
    );
  }

  Widget _buildRapportCredits(Map<String, dynamic> data) {
    final parStatut = data['parStatut'] as Map<String, dynamic>;
    final montants = data['montants'] as Map<String, dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Par statut',
          icon: Icons.pie_chart,
          children: [
            _StatRow(label: 'En attente', value: parStatut['EN_ATTENTE'].toString()),
            _StatRow(label: 'Validés', value: parStatut['VALIDE'].toString()),
            _StatRow(label: 'Déblocage en attente', value: parStatut['DEBLOCAGE_EN_ATTENTE'].toString()),
            _StatRow(label: 'En cours', value: parStatut['EN_COURS'].toString()),
            _StatRow(label: 'Remboursés', value: parStatut['REMBOURSE'].toString()),
            _StatRow(label: 'Rejetés', value: parStatut['REJETE'].toString()),
            _StatRow(label: 'En retard', value: parStatut['EN_RETARD'].toString()),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Montants',
          icon: Icons.monetization_on,
          children: [
            _StatRow(label: 'Total accordé', value: Formatters.currency(montants['totalAccorde'])),
            _StatRow(label: 'Total remboursé', value: Formatters.currency(montants['totalRembourse'])),
            _StatRow(label: 'Reste à rembourser', value: Formatters.currency(montants['totalReste'])),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
