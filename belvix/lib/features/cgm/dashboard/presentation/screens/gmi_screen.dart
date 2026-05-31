import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Glucose Management Indicator (GMI) detail screen.
///
/// A pixel-faithful build of the "Hub · Data · GMI" reference design:
/// hero GMI value, 6-month trend chart, supporting stat cards, an AI
/// advisor block and the educational sections (What is GMI / Why it
/// matters / What it means / How to improve / Sources).
///
/// Content is currently static to match the reference; swap the
/// constants below for live values when wiring real data.
class GmiScreen extends StatelessWidget {
  const GmiScreen({super.key});

  // --- Palette (sampled from the reference) ---
  static const _bg = Color(0xFFF5F6F8);
  static const _surface = Colors.white;
  static const _green = Color(0xFF16A34A);
  static const _greenDark = Color(0xFF15803D);
  static const _greenBg = Color(0xFFE7F6EC);
  static const _blue = Color(0xFF2F80ED);
  static const _blueBg = Color(0xFFE9F2FD);
  static const _orange = Color(0xFFE89240);
  static const _red = Color(0xFFE5484D);
  static const _purple = Color(0xFF6366F1);
  static const _ink = Color(0xFF101418);
  static const _sub = Color(0xFF6B7280);
  static const _muted = Color(0xFF9AA1AB);
  static const _line = Color(0xFFECEEF1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _ink, size: 28),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Glucose Management Indicator',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      body: const GmiContent(),
    );
  }

  static const _whyBullets = <_Bullet>[
    _Bullet(
      'Early warning system',
      ' — GMI can detect deteriorating glucose control weeks before '
          'conventional HbA1c testing would flag it.',
    ),
    _Bullet(
      'Real-time accountability',
      ' — because GMI updates continuously from CGM data, it gives '
          'immediate feedback on whether dietary, exercise, or sleep '
          'interventions are working at the biological level.',
    ),
    _Bullet(
      'Protein glycation proxy',
      ' — a lower GMI means less haemoglobin glycation, less collagen '
          'cross-linking, and slower accumulation of AGEs that drive tissue '
          'aging.',
    ),
    _Bullet(
      'Cardiovascular risk',
      ' — each 1% increase in HbA1c (and by extension GMI) is associated '
          'with a 21% increase in risk of diabetes-related deaths and '
          'complications (UKPDS 35).',
    ),
    _Bullet(
      'Lab HbA1c discordance',
      ' — GMI and lab HbA1c diverge in 10–15% of people. When they do, '
          'CGM-based GMI often better reflects actual tissue glucose '
          'exposure.',
    ),
  ];

  static const _improveBullets = <_Bullet>[
    _Bullet(
      'Reduce overall carbohydrate load',
      ' — limiting daily carbohydrate to 100–150g is the single most '
          'impactful lever for lowering mean glucose and improving GMI.',
    ),
    _Bullet(
      'Increase walking volume',
      ' — 8,000–10,000 daily steps distributed throughout the day lowers '
          'mean glucose by 5–10 mg/dL — roughly 0.12–0.24% GMI improvement.',
    ),
    _Bullet(
      'Zone 2 cardio',
      ' — 150 min/week of low-intensity aerobic exercise is the strongest '
          'lifestyle intervention for improving insulin sensitivity and '
          'lowering glucose.',
    ),
    _Bullet(
      'Build muscle mass',
      ' — each kilogram of added skeletal muscle increases whole-body '
          'glucose disposal capacity, lowering average glucose sustainably.',
    ),
    _Bullet(
      'Eliminate liquid calories',
      ' — juice, sweetened beverages, and alcohol elevate mean glucose '
          'without the buffering effect of fibre, directly driving GMI up.',
    ),
  ];
}

/// The scrollable GMI content (no Scaffold), so it can be hosted either by
/// [GmiScreen] standalone or directly inside the CGM dashboard body.
class GmiContent extends StatelessWidget {
  const GmiContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: const [
        _Hero(),
        SizedBox(height: 20),
        _SegmentTabs(),
        SizedBox(height: 16),
        _TrendChartCard(),
        SizedBox(height: 20),
        _TirBanner(),
        SizedBox(height: 16),
        _StatPairRow(),
        SizedBox(height: 12),
        _FormulaCard(),
        SizedBox(height: 20),
        _KeyInsightCard(),
        SizedBox(height: 24),
        _SectionTitle('Ask AI Health Advisor'),
        SizedBox(height: 14),
        _AdvisorList(),
        SizedBox(height: 26),
        _SectionTitle('What is GMI?'),
        SizedBox(height: 10),
        _Paragraph(
          'The Glucose Management Indicator (GMI) is a CGM-derived '
          'estimate of HbA1c — the standard laboratory marker of average '
          'blood glucose over 2–3 months. GMI is calculated using a '
          'validated regression formula: GMI (%) = 3.31 + (0.02392 × mean '
          'glucose in mg/dL).',
        ),
        SizedBox(height: 24),
        _SectionTitle('Why does GMI matter?'),
        SizedBox(height: 12),
        _BulletList(GmiScreen._whyBullets),
        SizedBox(height: 24),
        _SectionTitle('What does my GMI mean?'),
        SizedBox(height: 14),
        _LevelCards(),
        SizedBox(height: 16),
        _Paragraph(
          'For longevity-focused individuals, Cyborg considers the optimal '
          'GMI target to be below 5.4% — a level associated with minimal '
          'glycation burden, low cardiovascular risk, and preserved '
          'metabolic flexibility. Your current GMI of 5.2% places you in '
          'this elite zone.',
        ),
        SizedBox(height: 24),
        _SectionTitle('How can I further improve my GMI?'),
        SizedBox(height: 12),
        _BulletList(GmiScreen._improveBullets),
        SizedBox(height: 24),
        _SectionTitle('Sources'),
        SizedBox(height: 12),
        _SourceList(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: GmiScreen._green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'OPTIMAL',
              style: TextStyle(
                color: GmiScreen._green,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '5.2',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w800,
                color: GmiScreen._ink,
                height: 1,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: const [
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GmiScreen._muted,
                    ),
                  ),
                  Text(
                    'GMI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: GmiScreen._ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Estimated HbA1c equivalent — derived from 14-day CGM average',
          style: TextStyle(
            fontSize: 15,
            color: GmiScreen._sub,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Segmented tabs
// ---------------------------------------------------------------------------

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs();

  @override
  Widget build(BuildContext context) {
    const labels = ['7d', '14d', '30d', '90d'];
    const selected = 0;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected
                      ? GmiScreen._greenDark
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: i != selected && i != selected + 1 && i != 0
                      ? const Border(left: BorderSide(color: Color(0xFFD7DBE0)))
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: i == selected ? Colors.white : GmiScreen._sub,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend chart
// ---------------------------------------------------------------------------

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard();

  // 7 monthly GMI points.
  static const _values = [5.7, 5.6, 5.5, 5.6, 5.4, 5.3, 5.2];
  static const _preDiabetes = 5.7;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < _values.length; i++) FlSpot(i.toDouble(), _values[i]),
    ];

    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GMI trend — 6-month trajectory (%)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GmiScreen._muted,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_values.length - 1).toDouble(),
                minY: 5.05,
                maxY: 5.95,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: _bottomLabel,
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _preDiabetes,
                      color: GmiScreen._orange,
                      strokeWidth: 1.4,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 2, bottom: 2),
                        style: const TextStyle(
                          color: GmiScreen._orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (_) => 'Pre-diabetes 5.7%',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: GmiScreen._green,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) {
                        final isLast = spot.x == spots.last.x;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 4,
                          color: isLast ? GmiScreen._green : Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: isLast
                              ? GmiScreen._green
                              : const Color(0xFFB8D9C2),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          GmiScreen._green.withValues(alpha: 0.18),
                          GmiScreen._green.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bottomLabel(double value, TitleMeta meta) {
    const labels = {0: 'Jul 25', 2: 'Sep 25', 4: 'Nov 25', 6: 'Jan 26'};
    final text = labels[value.toInt()];
    if (text == null) return const SizedBox.shrink();

    final isLast = value.toInt() == 6;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isLast ? GmiScreen._green : GmiScreen._muted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TIR banner
// ---------------------------------------------------------------------------

class _TirBanner extends StatelessWidget {
  const _TirBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: GmiScreen._blueBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.trending_up_rounded,
            color: GmiScreen._green,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: GmiScreen._blue,
                ),
                children: [
                  TextSpan(text: '7-day average TIR of 83% '),
                  TextSpan(text: '— up 4% from last week'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat cards
// ---------------------------------------------------------------------------

class _StatPairRow extends StatelessWidget {
  const _StatPairRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: 'Latest result',
            value: '82',
            unit: '%',
            footnote: 'Today',
            valueColor: GmiScreen._green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Optimal range',
            value: '≥70',
            unit: '%',
            footnote: 'of day in target',
            valueColor: GmiScreen._ink,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.footnote,
    required this.valueColor,
  });

  final String title;
  final String value;
  final String unit;
  final String footnote;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GmiScreen._ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            footnote,
            style: const TextStyle(
              fontSize: 13,
              color: GmiScreen._sub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest result',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GmiScreen._ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text(
                '101',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: GmiScreen._green,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(width: 3),
              Text(
                'mg/dl',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GmiScreen._muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Formula: GMI = 3.31 + (0.02392 × mean glucose mg/dL)',
            style: TextStyle(
              fontSize: 13,
              color: GmiScreen._sub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Key insight
// ---------------------------------------------------------------------------

class _KeyInsightCard extends StatelessWidget {
  const _KeyInsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GmiScreen._greenBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _Badge(),
              SizedBox(width: 10),
              Text(
                'Key Insight · Metabolic Control',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GmiScreen._greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your glucose is staying in the healthy range for most of the '
            'day. Wednesday showed a mild spike — likely a meal-related '
            'event. Consistent TIR above 70% significantly reduces long-term '
            'glycation and inflammation risk.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF2B3B30),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Text(
                'Share this with your family',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GmiScreen._green,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 16, color: GmiScreen._green),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1F23),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'C',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI advisor
// ---------------------------------------------------------------------------

class _AdvisorList extends StatelessWidget {
  const _AdvisorList();

  static const _questions = [
    'What caused my glucose variability to spike on Wednesday?',
    'How does glucose variability affect my energy, mood and focus?',
    'Which supplements or foods help reduce glucose oscillations?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final q in _questions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const _Badge(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      q,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: GmiScreen._ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: GmiScreen._muted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Level cards
// ---------------------------------------------------------------------------

class _LevelCards extends StatelessWidget {
  const _LevelCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LevelRow(
          label: 'OPTIMAL',
          range: '< 5.7% (Non-diabetic)',
          labelColor: GmiScreen._green,
          isYours: true,
        ),
        SizedBox(height: 12),
        _LevelRow(
          label: 'BODERLINE',
          range: '5.7–6.4%',
          labelColor: GmiScreen._red,
        ),
        SizedBox(height: 12),
        _LevelRow(
          label: 'ELEVATED RISK',
          range: '≥ 6.5%',
          labelColor: GmiScreen._purple,
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.label,
    required this.range,
    required this.labelColor,
    this.isYours = false,
  });

  final String label;
  final String range;
  final Color labelColor;
  final bool isYours;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  range,
                  style: const TextStyle(
                    fontSize: 14,
                    color: GmiScreen._sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isYours)
            Row(
              children: const [
                Text(
                  'Your level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: GmiScreen._green,
                  ),
                ),
                SizedBox(width: 5),
                Icon(Icons.check, size: 16, color: GmiScreen._green),
              ],
            )
          else
            const Text(
              '-',
              style: TextStyle(
                fontSize: 16,
                color: GmiScreen._muted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sources
// ---------------------------------------------------------------------------

class _SourceList extends StatelessWidget {
  const _SourceList();

  static const _sources = [
    '1. Bergenstal RM, et al. Diabetes Care, 2018. GMI — validation and '
        'formula derivation.',
    '2. Christopoulos G, et al. J Diabetes Sci Technol, 2020. Discordance '
        'between GMI and laboratory HbA1c.',
    '3. Stratton IM, et al. BMJ, 2000. HbA1c and macrovascular/microvascular '
        'complications (UKPDS 35).',
    '4. ATTD Consensus 2023. GMI interpretation, clinical targets and '
        'CGM-HbA1c correlation.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in _sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              s,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: GmiScreen._sub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: GmiScreen._surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GmiScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: GmiScreen._ink,
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: GmiScreen._sub,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _Bullet {
  const _Bullet(this.lead, this.rest);
  final String lead;
  final String rest;
}

class _BulletList extends StatelessWidget {
  const _BulletList(this.items);

  final List<_Bullet> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 12, left: 2),
                  child: _Dot(),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: GmiScreen._sub,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: b.lead,
                          style: const TextStyle(
                            color: GmiScreen._ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: b.rest),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: GmiScreen._muted,
        shape: BoxShape.circle,
      ),
    );
  }
}
