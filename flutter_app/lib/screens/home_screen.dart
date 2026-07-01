import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
          child: StreamBuilder<Map<String, dynamic>>(
            stream: SupabaseService.watchState(),
            builder: (context, snapshot) {
              final state = snapshot.data ?? {};

              final pumpOn = state['pump_on'] ?? false;
              final valve1On = state['valve1_on'] ?? false;
              final valve2On = state['valve2_on'] ?? false;
              final autoMode = state['auto_mode'] ?? false;
              final lowWater = state['low_water'] ?? false;
              final soilPct = (state['soil_pct'] ?? 0) as int;
              final connected = snapshot.hasData;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    floating: true,
                    elevation: 0,
                    title: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tưới Cây',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      _ConnectionDot(connected: connected),
                      const SizedBox(width: 16),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          if (lowWater) ...[
                            const _AlertBanner(),
                            const SizedBox(height: 12),
                          ],

                          _SoilCard(
                            soilPct: soilPct,
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _ModeCard(
                                  autoMode: autoMode,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _WaterCard(
                                  lowWater: lowWater,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          _DeviceCard(
                            icon: Icons.water_drop_rounded,
                            label: 'Bơm chính',
                            isOn: pumpOn,
                            color: AppTheme.primary,
                          ),

                          const SizedBox(height: 8),

                          _DeviceCard(
                            icon: Icons.opacity_rounded,
                            label: 'Van 1',
                            isOn: valve1On,
                            color: AppTheme.secondary,
                          ),

                          const SizedBox(height: 8),

                          _DeviceCard(
                            icon: Icons.opacity_rounded,
                            label: 'Van 2',
                            isOn: valve2On,
                            color: const Color(0xFF7B61FF),
                          ),

                          const SizedBox(height: 16),

                          _LastUpdated(
                            updatedAt: state['updated_at'],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  final bool connected;

  const _ConnectionDot({
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: connected
                ? AppTheme.primary
                : AppTheme.danger,
            shape: BoxShape.circle,
            boxShadow: connected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          connected ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            color: connected
                ? AppTheme.primary
                : AppTheme.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.danger.withOpacity(0.5),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.danger,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'CẠN NƯỚC — Hệ thống đã tự dừng',
              style: TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SoilCard extends StatelessWidget {
  final int soilPct;

  const _SoilCard({
    required this.soilPct,
  });

  Color get _color {
    if (soilPct < 25) return AppTheme.danger;
    if (soilPct < 50) return AppTheme.warning;
    if (soilPct < 75) return AppTheme.primary;
    return AppTheme.secondary;
  }

  String get _label {
    if (soilPct < 25) return 'Đất khô - Cần tưới';
    if (soilPct < 50) return 'Hơi khô';
    if (soilPct < 75) return 'Độ ẩm tốt';
    return 'Rất ẩm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.bgBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grass_rounded,
                color: _color,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Độ ẩm đất',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 12,
                  color: _color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$soilPct',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: _color,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: soilPct / 100,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: AppTheme.bgBorder,
                  valueColor: AlwaysStoppedAnimation(_color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _ModeCard extends StatelessWidget {
  final bool autoMode;

  const _ModeCard({
    required this.autoMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: autoMode
            ? AppTheme.secondary.withOpacity(0.12)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: autoMode
              ? AppTheme.secondary.withOpacity(0.4)
              : AppTheme.bgBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            autoMode
                ? Icons.auto_mode_rounded
                : Icons.pan_tool_alt_rounded,
            color: autoMode
                ? AppTheme.secondary
                : AppTheme.textSecondary,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            autoMode ? 'AUTO' : 'MANUAL',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: autoMode
                  ? AppTheme.secondary
                  : AppTheme.textPrimary,
            ),
          ),
          const Text(
            'Chế độ',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final bool lowWater;

  const _WaterCard({
    required this.lowWater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lowWater
            ? AppTheme.danger.withOpacity(0.12)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lowWater
              ? AppTheme.danger.withOpacity(0.4)
              : AppTheme.bgBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            lowWater
                ? Icons.water_drop_outlined
                : Icons.water_drop_rounded,
            color: lowWater
                ? AppTheme.danger
                : AppTheme.secondary,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            lowWater ? 'CẠN' : 'ĐỦ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: lowWater
                  ? AppTheme.danger
                  : AppTheme.primary,
            ),
          ),
          const Text(
            'Nguồn nước',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
class _DeviceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final Color color;

  const _DeviceCard({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isOn
            ? color.withOpacity(0.10)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn
              ? color.withOpacity(0.5)
              : AppTheme.bgBorder,
          width: isOn ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOn
                  ? color.withOpacity(0.20)
                  : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isOn
                  ? color
                  : AppTheme.textDisabled,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isOn
                  ? color.withOpacity(0.15)
                  : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOn ? "● BẬT" : "○ TẮT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isOn
                    ? color
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  final dynamic updatedAt;

  const _LastUpdated({
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    String text = "Chưa cập nhật";

    if (updatedAt != null) {
      try {
        final dt = DateTime.parse(updatedAt.toString()).toLocal();

        text =
            "Cập nhật ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textDisabled,
          ),
        ),
      ),
    );
  }
}