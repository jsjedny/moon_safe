import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/landing_site.dart';

/// Bottom sheet showing explainable breakdown of a site's score.
class SiteExplainSheet extends StatelessWidget {
  final LandingSite site;
  final double overallScore;
  final double wSafety;
  final double wSunlight;
  final double wWater;

  const SiteExplainSheet({
    super.key,
    required this.site,
    required this.overallScore,
    required this.wSafety,
    required this.wSunlight,
    required this.wWater,
  });

  @override
  Widget build(BuildContext context) {
    final subs = site.subScores();
    final totalW = wSafety + wSunlight + wWater;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A2030), Color(0xFF0F1319)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _scoreColor(overallScore),
                        _scoreColor(overallScore).withValues(alpha: 0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _scoreColor(overallScore).withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${overallScore.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Suitability Index: ${overallScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _scoreColor(overallScore)
                              .withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Description ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                site.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── "How is this score calculated?" ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF00F2FE), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'How is this score calculated?',
                        style: TextStyle(
                          color: Color(0xFF00F2FE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each site is evaluated on 3 axes — Safety (terrain slope), '
                    'Sunlight (illumination %), and Water-Ice (hydrogen ppm). '
                    'Your slider weights determine how much each axis contributes '
                    'to the final Suitability Index.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Radar chart ──
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SCORE PROFILE',
                style: TextStyle(
                  color: Color(0xFF00F2FE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  radarBorderData: const BorderSide(
                      color: Color(0xFF00F2FE), width: 0.5),
                  gridBorderData: const BorderSide(
                      color: Color(0xFF1E2530), width: 0.5),
                  tickBorderData:
                      const BorderSide(color: Colors.transparent),
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(fontSize: 0),
                  titlePositionPercentageOffset: 0.2,
                  getTitle: (index, _) {
                    const labels = ['Safety', 'Sunlight', 'Water-Ice'];
                    return RadarChartTitle(
                        text: labels[index], angle: 0);
                  },
                  titleTextStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  dataSets: [
                    RadarDataSet(
                      dataEntries: [
                        RadarEntry(value: subs['safety']!),
                        RadarEntry(value: subs['sunlight']!),
                        RadarEntry(value: subs['water']!),
                      ],
                      fillColor: const Color(0xFF00F2FE)
                          .withValues(alpha: 0.12),
                      borderColor: const Color(0xFF00F2FE),
                      borderWidth: 2,
                      entryRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Score breakdown ──
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SCORE BREAKDOWN',
                style: TextStyle(
                  color: Color(0xFF00F2FE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _explainRow(
              'Safety',
              subs['safety']!,
              wSafety,
              totalW,
              'Slope: ${site.metrics.slopeDegrees}° — lower slope = safer landing',
              Icons.shield_outlined,
              const Color(0xFF00F2FE),
            ),
            _explainRow(
              'Sunlight',
              subs['sunlight']!,
              wSunlight,
              totalW,
              'Illumination: ${site.metrics.sunlightAvailabilityPercent}% — powers solar panels',
              Icons.wb_sunny_outlined,
              const Color(0xFFFBBF24),
            ),
            _explainRow(
              'Water-Ice',
              subs['water']!,
              wWater,
              totalW,
              'Hydrogen: ${site.metrics.hydrogenPpmWaterIce} ppm — indicates subsurface ice',
              Icons.water_drop_outlined,
              const Color(0xFF818CF8),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF1E2530)),

            // ── Physical data ──
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PHYSICAL DATA (NASA LRO)',
                style: TextStyle(
                  color: Color(0xFF00F2FE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _metaRow('Coordinates',
                '${site.coordinates.latitude}°S, ${site.coordinates.longitude}°E'),
            _metaRow('Elevation',
                '${site.coordinates.elevationMeters.toInt()} m (from 1737.4 km datum)'),
            _metaRow('Surface Temp',
                '${site.surfaceTemperature.minShadow} K – ${site.surfaceTemperature.maxSunlit} K'),
            if (site.craterDiameterKm != null)
              _metaRow('Crater Diameter',
                  '${site.craterDiameterKm!.toStringAsFixed(1)} km'),
            if (site.psrAreaKm2 != null)
              _metaRow('PSR Area',
                  '${site.psrAreaKm2!.toStringAsFixed(0)} km²'),
            _metaRow('Earth Visibility', site.metrics.earthVisibility),
            _metaRow('Terrain Risk', site.terrainRiskFactor),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E2530)),
            const SizedBox(height: 8),

            // ── Scientific value ──
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SCIENTIFIC VALUE',
                style: TextStyle(
                  color: Color(0xFF00F2FE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.12)),
              ),
              child: Text(
                site.scientificValue,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Data instruments ──
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const Text('Data from: ',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 10)),
                  ...site.dataInstruments.map((inst) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2FE)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF00F2FE)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          inst,
                          style: const TextStyle(
                            color: Color(0xFF00F2FE),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _explainRow(
    String label,
    double baseScore,
    double weight,
    double totalW,
    String detail,
    IconData icon,
    Color color,
  ) {
    final contribution =
        totalW > 0 ? (weight / totalW * baseScore) : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label  ×  weight ${weight.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${contribution.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: baseScore / 100,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 75) return const Color(0xFF00F2FE);
    if (score >= 50) return const Color(0xFF4ADE80);
    if (score >= 30) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }
}
