import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

import '../../core/utils/formatters.dart';

import '../../data/models/dashboard_model.dart';



/// Graphique barres — Dépôts vs Retraits du jour + transferts 30j

class ActiviteChart extends StatelessWidget {

  final DashboardModel dashboard;



  const ActiviteChart({super.key, required this.dashboard});



  @override

  Widget build(BuildContext context) {

    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'Activité du jour',

              style:

                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700),

            ),

            const SizedBox(height: 4),

            const Text(

              'Dépôts, retraits et transferts (30j)',

              style:

                  TextStyle(fontSize: 12, color: AppTheme.textSecondary),

            ),

            const SizedBox(height: 20),

            SizedBox(

              height: 160,

              child: BarChart(

                BarChartData(

                  alignment: BarChartAlignment.spaceAround,

                  maxY: _maxY,

                  barTouchData: BarTouchData(

                    touchTooltipData: BarTouchTooltipData(

                      getTooltipItem: (group, groupIndex, rod, rodIndex) {

                        final labels = ['Dépôts', 'Retraits', 'Transferts'];

                        return BarTooltipItem(

                          '${labels[groupIndex]}\n${Formatters.currency(rod.toY)}',

                          const TextStyle(

                              color: Colors.white, fontSize: 12),

                        );

                      },

                    ),

                  ),

                  titlesData: FlTitlesData(

                    show: true,

                    bottomTitles: AxisTitles(

                      sideTitles: SideTitles(

                        showTitles: true,

                        getTitlesWidget: (value, meta) {

                          const titles = ['Dépôts', 'Retraits', 'Transf.'];

                          return Padding(

                            padding: const EdgeInsets.only(top: 6),

                            child: Text(

                              titles[value.toInt()],

                              style: const TextStyle(

                                  fontSize: 11,

                                  color: AppTheme.textSecondary),

                            ),

                          );

                        },

                      ),

                    ),

                    leftTitles: const AxisTitles(

                      sideTitles: SideTitles(showTitles: false),

                    ),

                    topTitles: const AxisTitles(

                      sideTitles: SideTitles(showTitles: false),

                    ),

                    rightTitles: const AxisTitles(

                      sideTitles: SideTitles(showTitles: false),

                    ),

                  ),

                  gridData: FlGridData(

                    show: true,

                    drawVerticalLine: false,

                    getDrawingHorizontalLine: (_) => const FlLine(

                      color: AppTheme.border,

                      strokeWidth: 1,

                    ),

                  ),

                  borderData: FlBorderData(show: false),

                  barGroups: [

                    _bar(0, dashboard.totalDepotsJour, AppTheme.success),

                    _bar(1, dashboard.totalRetraitsJour, AppTheme.error),

                    _bar(2, dashboard.totalTransferts30j, AppTheme.primary),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 12),

            // Légende

            Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                _Legend(color: AppTheme.success, label: 'Dépôts'),

                const SizedBox(width: 16),

                _Legend(color: AppTheme.error, label: 'Retraits'),

                const SizedBox(width: 16),

                _Legend(color: AppTheme.primary, label: 'Transferts 30j'),

              ],

            ),

          ],

        ),

      ),

    );

  }



  double get _maxY {

    final values = [

      dashboard.totalDepotsJour,

      dashboard.totalRetraitsJour,

      dashboard.totalTransferts30j,

    ];

    final max = values.reduce((a, b) => a > b ? a : b);

    return max == 0 ? 1000 : max * 1.2;

  }



  BarChartGroupData _bar(int x, double value, Color color) {

    return BarChartGroupData(

      x: x,

      barRods: [

        BarChartRodData(

          toY: value,

          color: color,

          width: 36,

          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),

        ),

      ],

    );

  }

}



class _Legend extends StatelessWidget {

  final Color color;

  final String label;



  const _Legend({required this.color, required this.label});



  @override

  Widget build(BuildContext context) {

    return Row(

      mainAxisSize: MainAxisSize.min,

      children: [

        Container(

          width: 10,

          height: 10,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),

        ),

        const SizedBox(width: 4),

        Text(label,

            style: const TextStyle(

                fontSize: 11, color: AppTheme.textSecondary)),

      ],

    );

  }

}



/// Graphique donut — répartition des soldes (Épargne vs DAT vs Crédits)

class RepartitionChart extends StatelessWidget {

  final DashboardModel dashboard;



  const RepartitionChart({super.key, required this.dashboard});



  @override

  Widget build(BuildContext context) {

    final total = dashboard.totalEpargne +

        dashboard.totalDat +

        dashboard.totalEncours;



    if (total == 0) return const SizedBox();



    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'Répartition des fonds',

              style:

                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700),

            ),

            const SizedBox(height: 16),

            Row(

              children: [

                SizedBox(

                  height: 130,

                  width: 130,

                  child: PieChart(

                    PieChartData(

                      sectionsSpace: 2,

                      centerSpaceRadius: 36,

                      sections: [

                        _section(

                          dashboard.totalEpargne / total,

                          AppTheme.primary,

                        ),

                        _section(

                          dashboard.totalDat / total,

                          const Color(0xFF8B5CF6),

                        ),

                        _section(

                          dashboard.totalEncours / total,

                          AppTheme.error,

                        ),

                      ],

                    ),

                  ),

                ),

                const SizedBox(width: 16),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      _LegendRow(

                        color: AppTheme.primary,

                        label: 'Épargne',

                        value: Formatters.currency(dashboard.totalEpargne),

                        pct: total > 0

                            ? (dashboard.totalEpargne / total * 100)

                                .toStringAsFixed(1)

                            : '0',

                      ),

                      const SizedBox(height: 8),

                      _LegendRow(

                        color: const Color(0xFF8B5CF6),

                        label: 'DAT',

                        value: Formatters.currency(dashboard.totalDat),

                        pct: total > 0

                            ? (dashboard.totalDat / total * 100)

                                .toStringAsFixed(1)

                            : '0',

                      ),

                      const SizedBox(height: 8),

                      _LegendRow(

                        color: AppTheme.error,

                        label: 'Crédits',

                        value: Formatters.currency(dashboard.totalEncours),

                        pct: total > 0

                            ? (dashboard.totalEncours / total * 100)

                                .toStringAsFixed(1)

                            : '0',

                      ),

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



  PieChartSectionData _section(double pct, Color color) {

    return PieChartSectionData(

      value: pct * 100,

      color: color,

      radius: 28,

      showTitle: false,

    );

  }

}



class _LegendRow extends StatelessWidget {

  final Color color;

  final String label;

  final String value;

  final String pct;



  const _LegendRow({

    required this.color,

    required this.label,

    required this.value,

    required this.pct,

  });



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        Container(

          width: 10,

          height: 10,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),

        ),

        const SizedBox(width: 6),

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(label,

                  style: const TextStyle(

                      fontSize: 11, color: AppTheme.textSecondary)),

              Text(value,

                  style: const TextStyle(

                      fontSize: 12, fontWeight: FontWeight.w600)),

            ],

          ),

        ),

        Text(

          '$pct%',

          style: TextStyle(

              fontSize: 12, fontWeight: FontWeight.w600, color: color),

        ),

      ],

    );

  }

}

