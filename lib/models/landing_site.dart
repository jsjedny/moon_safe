import 'dart:convert';

class LandingCoordinates {
  final double latitude;
  final double longitude;
  final double elevationMeters;

  LandingCoordinates({
    required this.latitude,
    required this.longitude,
    required this.elevationMeters,
  });

  factory LandingCoordinates.fromJson(Map<String, dynamic> json) {
    return LandingCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevationMeters: (json['elevation_meters'] as num).toDouble(),
    );
  }
}

class SurfaceTemperature {
  final int maxSunlit;
  final int minShadow;

  SurfaceTemperature({required this.maxSunlit, required this.minShadow});

  factory SurfaceTemperature.fromJson(Map<String, dynamic> json) {
    return SurfaceTemperature(
      maxSunlit: (json['max_sunlit'] as num).toInt(),
      minShadow: (json['min_shadow'] as num).toInt(),
    );
  }
}

class SiteMetrics {
  final double slopeDegrees;
  final double sunlightAvailabilityPercent;
  final double hydrogenPpmWaterIce;
  final String earthVisibility;

  SiteMetrics({
    required this.slopeDegrees,
    required this.sunlightAvailabilityPercent,
    required this.hydrogenPpmWaterIce,
    required this.earthVisibility,
  });

  factory SiteMetrics.fromJson(Map<String, dynamic> json) {
    return SiteMetrics(
      slopeDegrees: (json['slope_degrees'] as num).toDouble(),
      sunlightAvailabilityPercent:
          (json['sunlight_availability_percent'] as num).toDouble(),
      hydrogenPpmWaterIce: (json['hydrogen_ppm_water_ice'] as num).toDouble(),
      earthVisibility: json['earth_visibility'] as String,
    );
  }
}

class LandingSite {
  final String siteId;
  final String name;
  final String description;
  final LandingCoordinates coordinates;
  final SiteMetrics metrics;
  final SurfaceTemperature surfaceTemperature;
  final double? craterDiameterKm;
  final double? psrAreaKm2;
  final String terrainRiskFactor;
  final String scientificValue;
  final List<String> dataInstruments;

  LandingSite({
    required this.siteId,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.metrics,
    required this.surfaceTemperature,
    this.craterDiameterKm,
    this.psrAreaKm2,
    required this.terrainRiskFactor,
    required this.scientificValue,
    required this.dataInstruments,
  });

  factory LandingSite.fromJson(Map<String, dynamic> json) {
    return LandingSite(
      siteId: json['site_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coordinates: LandingCoordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      metrics: SiteMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      surfaceTemperature: SurfaceTemperature.fromJson(
        json['surface_temperature_K'] as Map<String, dynamic>,
      ),
      craterDiameterKm: json['crater_diameter_km'] != null
          ? (json['crater_diameter_km'] as num).toDouble()
          : null,
      psrAreaKm2: json['psr_area_km2'] != null
          ? (json['psr_area_km2'] as num).toDouble()
          : null,
      terrainRiskFactor: json['terrain_risk_factor'] as String,
      scientificValue: json['scientific_value'] as String,
      dataInstruments: (json['data_instruments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  // --------------- Scoring Engine ---------------

  /// Computes the normalized suitability index (0–100) given user weights.
  ///
  /// Sub-scores (each 0–1):
  ///   Safety  = 1 - clamp(slope / 15, 0, 1)          (flatter is safer)
  ///   Sun     = sunlight_percent / 100
  ///   Water   = clamp(hydrogen_ppm / 250, 0, 1)      (250 ppm cap)
  ///
  /// Suitability = (Ws*Safety + Wl*Sun + Ww*Water) / (Ws+Wl+Ww) * 100
  double computeScore({
    required double wSafety,
    required double wSunlight,
    required double wWater,
  }) {
    final safetyScore = 1.0 - (metrics.slopeDegrees / 15.0).clamp(0.0, 1.0);
    final sunScore =
        (metrics.sunlightAvailabilityPercent / 100.0).clamp(0.0, 1.0);
    final waterScore = (metrics.hydrogenPpmWaterIce / 250.0).clamp(0.0, 1.0);

    final totalWeight = wSafety + wSunlight + wWater;
    if (totalWeight == 0) return 0;

    final raw =
        (wSafety * safetyScore + wSunlight * sunScore + wWater * waterScore) /
            totalWeight;
    return (raw * 100.0).clamp(0.0, 100.0);
  }

  /// Individual sub-scores exposed for the explainability sheet.
  Map<String, double> subScores() {
    return {
      'safety': (1.0 - (metrics.slopeDegrees / 15.0).clamp(0.0, 1.0)) * 100,
      'sunlight':
          (metrics.sunlightAvailabilityPercent / 100.0).clamp(0.0, 1.0) * 100,
      'water': (metrics.hydrogenPpmWaterIce / 250.0).clamp(0.0, 1.0) * 100,
    };
  }
}

class LunarDataset {
  final String project;
  final String dataSource;
  final String targetRegion;
  final List<String> dataReferences;
  final String coordinateDatum;
  final List<LandingSite> landingSites;

  LunarDataset({
    required this.project,
    required this.dataSource,
    required this.targetRegion,
    required this.dataReferences,
    required this.coordinateDatum,
    required this.landingSites,
  });

  factory LunarDataset.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return LunarDataset(
      project: json['project'] as String,
      dataSource: json['data_source'] as String,
      targetRegion: json['target_region'] as String,
      dataReferences: (json['data_references'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      coordinateDatum: json['coordinate_datum'] as String,
      landingSites: (json['landing_sites'] as List<dynamic>)
          .map((e) => LandingSite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
