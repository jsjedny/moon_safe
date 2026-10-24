import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import '../models/landing_site.dart';
import '../widgets/lunar_surface_painter.dart';
import '../widgets/site_card.dart';
import '../widgets/site_explain_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────
  LunarDataset? _dataset;
  bool _loading = true;

  // ── Weights ───────────────────────────────────────────────────
  double _wSafety = 50;
  double _wSunlight = 50;
  double _wWater = 50;

  // ── Active preset label (for visual indicator) ────────────────
  String _activePreset = 'Balanced';

  // ── Selection ─────────────────────────────────────────────────
  int? _selectedIndex;

  // ── Animation ─────────────────────────────────────────────────
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadData();
  }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('assets/data/lunar_real_data.json');
    setState(() {
      _dataset = LunarDataset.fromJson(raw);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Computed sorted list ──────────────────────────────────────
  List<MapEntry<LandingSite, double>> get _rankedSites {
    if (_dataset == null) return [];
    final scored = _dataset!.landingSites.map((s) {
      final score = s.computeScore(
        wSafety: _wSafety,
        wSunlight: _wSunlight,
        wWater: _wWater,
      );
      return MapEntry(s, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored;
  }

  // ── Preset helpers ────────────────────────────────────────────
  void _applyPreset(String name, double s, double l, double w) {
    setState(() {
      _wSafety = s;
      _wSunlight = l;
      _wWater = w;
      _activePreset = name;
      _selectedIndex = null;
    });
  }

  void _clearPreset() {
    setState(() => _activePreset = '');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E14),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
        ),
      );
    }

    final ranked = _rankedSites;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ═══════════ HEADER ═══════════
            SliverToBoxAdapter(child: _buildHeader()),

            // ═══════════ CONCEPT BOX ═════
            SliverToBoxAdapter(child: _buildConceptBox()),

            // ═══════════ PRESETS ══════════
            SliverToBoxAdapter(child: _buildSectionLabel('MISSION MODE', 'Choose a mission profile or customize below')),
            SliverToBoxAdapter(child: _buildPresets()),

            // ═══════════ SLIDERS ══════════
            SliverToBoxAdapter(child: _buildSectionLabel('PRIORITY WEIGHTS', 'Drag sliders to adjust how much each factor matters')),
            SliverToBoxAdapter(child: _buildSliders()),

            // ═══════════ LUNAR MAP ═══════
            SliverToBoxAdapter(child: _buildSectionLabel('SOUTH POLE MAP', 'Pin color indicates suitability — cyan is best')),
            SliverToBoxAdapter(child: _buildLunarMap(ranked)),

            // ═══════════ MAP LEGEND ══════
            SliverToBoxAdapter(child: _buildLegend()),

            // ═══════════ LIST HEADER ══════
            SliverToBoxAdapter(
              child: _buildSectionLabel(
                'RANKED SITES (${ranked.length})',
                'Tap any site for a detailed AI-explainable breakdown',
              ),
            ),

            // ═══════════ SITE LIST ════════
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = ranked[index];
                  return SiteCard(
                    site: entry.key,
                    score: entry.value,
                    rank: index + 1,
                    isSelected: _selectedIndex == index,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      _showExplainSheet(entry.key, entry.value);
                    },
                  );
                },
                childCount: ranked.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Section label helper ──────────────────────────────────────
  Widget _buildSectionLabel(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00F2FE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Moon icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00F2FE), Color(0xFF0077FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                const Icon(Icons.nightlight_round, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MoonSafe',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Artemis Landing Site Evaluator',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'NASA LRO',
                  style: TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Concept box ───────────────────────────────────────────────
  Widget _buildConceptBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00F2FE).withValues(alpha: 0.06),
              const Color(0xFF0077FF).withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome,
                color: Color(0xFF00F2FE), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evaluate Artemis landing sites in real-time',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjust Safety, Sunlight, and Water-Ice priority weights '
                    'to instantly re-rank 5 NASA-verified South Pole candidate '
                    'sites by a normalized Suitability Index (0–100%).',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mission presets ───────────────────────────────────────────
  Widget _buildPresets() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _presetButton(
            'Artemis Base',
            'Prioritises safe terrain\n& solar power',
            Icons.rocket_launch_outlined,
            80, 70, 30,
          ),
          const SizedBox(width: 10),
          _presetButton(
            'Water-Ice Drill',
            'Maximises subsurface\nice potential',
            Icons.water_drop_outlined,
            40, 30, 100,
          ),
          const SizedBox(width: 10),
          _presetButton(
            'Balanced',
            'Equal weight on\nall three axes',
            Icons.balance_outlined,
            50, 50, 50,
          ),
        ],
      ),
    );
  }

  Widget _presetButton(
      String label, String desc, IconData icon, double s, double l, double w) {
    final isActive = _activePreset == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPreset(label, s, l, w),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00F2FE).withValues(alpha: 0.10)
                : const Color(0xFF151B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00F2FE).withValues(alpha: 0.5)
                  : const Color(0xFF1E2530),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.06),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive
                      ? const Color(0xFF00F2FE)
                      : Colors.white38,
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? const Color(0xFF00F2FE) : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isActive ? 0.4 : 0.25),
                  fontSize: 8,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliders ───────────────────────────────────────────────────
  Widget _buildSliders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF151B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1E2530)),
        ),
        child: Column(
          children: [
            _slider(
              label: 'Safety',
              subtitle: 'Terrain slope flatness',
              icon: Icons.shield_outlined,
              value: _wSafety,
              color: const Color(0xFF00F2FE),
              onChanged: (v) => setState(() {
                _wSafety = v;
                _selectedIndex = null;
                _clearPreset();
              }),
            ),
            _slider(
              label: 'Sunlight',
              subtitle: 'Solar illumination %',
              icon: Icons.wb_sunny_outlined,
              value: _wSunlight,
              color: const Color(0xFFFBBF24),
              onChanged: (v) => setState(() {
                _wSunlight = v;
                _selectedIndex = null;
                _clearPreset();
              }),
            ),
            _slider(
              label: 'Water-Ice',
              subtitle: 'Hydrogen concentration',
              icon: Icons.water_drop_outlined,
              value: _wWater,
              color: const Color(0xFF818CF8),
              onChanged: (v) => setState(() {
                _wWater = v;
                _selectedIndex = null;
                _clearPreset();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required String subtitle,
    required IconData icon,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.12),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.10),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Lunar map ─────────────────────────────────────────────────
  Widget _buildLunarMap(List<MapEntry<LandingSite, double>> ranked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1319),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E2530)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F2FE).withValues(alpha: 0.03),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 320),
                    painter: LunarSurfacePainter(
                      sites: ranked.map((e) => e.key).toList(),
                      scores: ranked.map((e) => e.value).toList(),
                      selectedIndex: _selectedIndex,
                      animationValue: _pulseController.value,
                    ),
                  );
                },
              ),
              // Corner label
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E14).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.satellite_alt,
                          color: Color(0xFF00F2FE), size: 10),
                      SizedBox(width: 4),
                      Text(
                        'POLAR PROJECTION',
                        style: TextStyle(
                          color: Color(0xFF00F2FE),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Legend ─────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(const Color(0xFF00F2FE), '≥75%'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFF4ADE80), '50–74%'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFFFBBF24), '30–49%'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFFEF4444), '<30%'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
      ],
    );
  }

  // ── Explainability sheet ──────────────────────────────────────
  void _showExplainSheet(LandingSite site, double score) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => SiteExplainSheet(
          site: site,
          overallScore: score,
          wSafety: _wSafety,
          wSunlight: _wSunlight,
          wWater: _wWater,
        ),
      ),
    );
  }
}
