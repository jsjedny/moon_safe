import 'package:flutter/material.dart';
import '../models/landing_site.dart';

/// A single ranked landing-site card with mini score bars for clarity.
class SiteCard extends StatelessWidget {
  final LandingSite site;
  final double score;
  final int rank;
  final bool isSelected;
  final VoidCallback onTap;

  const SiteCard({
    super.key,
    required this.site,
    required this.score,
    required this.rank,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subs = site.subScores();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A2332) : const Color(0xFF151B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F2FE).withValues(alpha: 0.5)
                : const Color(0xFF1E2530),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            // ── Top row: rank + name + score ──
            Row(
              children: [
                // Rank badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _scoreColor(score),
                        _scoreColor(score).withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _scoreColor(score).withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _chip(Icons.landscape_outlined,
                              '${site.coordinates.elevationMeters.toInt()} m'),
                          const SizedBox(width: 10),
                          _riskChip(site.terrainRiskFactor),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score circle
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 3.5,
                          backgroundColor:
                              const Color(0xFF1E2530),
                          valueColor: AlwaysStoppedAnimation(
                              _scoreColor(score)),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: TextStyle(
                              color: _scoreColor(score),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '%',
                            style: TextStyle(
                              color:
                                  _scoreColor(score).withValues(alpha: 0.6),
                              fontSize: 9,
                              height: 0.9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Mini score bars ──
            Row(
              children: [
                _miniBar('Safety', subs['safety']!, const Color(0xFF00F2FE)),
                const SizedBox(width: 8),
                _miniBar('Sun', subs['sunlight']!, const Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                _miniBar('Water', subs['water']!, const Color(0xFF818CF8)),
              ],
            ),

            // ── Tap hint ──
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined,
                    color: Colors.white24, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Tap for detailed breakdown',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBar(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 9)),
              Text('${value.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 3,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _riskChip(String risk) {
    Color c;
    switch (risk) {
      case 'Low':
        c = const Color(0xFF4ADE80);
        break;
      case 'Medium':
        c = const Color(0xFFFBBF24);
        break;
      default:
        c = const Color(0xFFEF4444);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        risk,
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600),
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
