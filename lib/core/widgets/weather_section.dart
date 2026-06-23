import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/weather_data.dart';
import '../providers/auth_providers.dart';

class WeatherSection extends ConsumerWidget {
  final String location;

  const WeatherSection({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider(location));

    return weatherAsync.when(
      loading: () => _LoadingCard(location: location),
      error: (_, __) => _UnavailableCard(location: location),
      data: (data) {
        if (data == null) return _UnavailableCard(location: location);
        return _WeatherCard(
          data: data,
          location: location,
          onRefresh: () => ref.invalidate(weatherProvider(location)),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Main weather card
// ---------------------------------------------------------------------------

class _WeatherCard extends StatelessWidget {
  final WeatherData data;
  final String location;
  final VoidCallback onRefresh;

  const _WeatherCard({
    required this.data,
    required this.location,
    required this.onRefresh,
  });

  List<Color> get _gradientColors {
    if (data.isThunderstorm) {
      return const [Color(0xFF1A237E), Color(0xFF283593)];
    }
    if (data.isRaining) {
      return const [Color(0xFF0D47A1), Color(0xFF1976D2)];
    }
    if (data.isFoggy) {
      return const [Color(0xFF37474F), Color(0xFF607D8B)];
    }
    if (data.isCloudy) {
      return const [Color(0xFF455A64), Color(0xFF78909C)];
    }
    // Clear / mainly clear — warm sky
    return const [Color(0xFF0277BD), Color(0xFF0288D1)];
  }

  IconData get _conditionIcon {
    if (data.isThunderstorm) return Icons.electric_bolt_rounded;
    if (data.isRaining) return Icons.grain_rounded;
    if (data.isFoggy) return Icons.cloud_outlined;
    if (data.isCloudy) return Icons.cloud_rounded;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: condition + location + refresh
          Row(
            children: [
              Icon(_conditionIcon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.conditionLabel,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    location,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onRefresh,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Temperature
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.temperature.round()}°C',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'Feels ${data.apparentTemperature.round()}°C',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rain & Wind tiles
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Rain',
                  value: '${data.rain.toStringAsFixed(1)} mm',
                  isAlert: data.rain > 5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: '${data.windSpeed.round()} km/h',
                  isAlert: data.windSpeed > 40,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.cloud_rounded,
                  label: 'Cloud',
                  value: '${data.cloudCover}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric tile (rain / wind / cloud)
// ---------------------------------------------------------------------------

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAlert;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: isAlert
            ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: Colors.white.withValues(alpha: 0.85), size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _LoadingCard extends StatelessWidget {
  final String location;
  const _LoadingCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fetching weather for $location…',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unavailable state
// ---------------------------------------------------------------------------

class _UnavailableCard extends StatelessWidget {
  final String location;
  const _UnavailableCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: AppColors.textHint, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather unavailable',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Could not fetch weather for $location',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
