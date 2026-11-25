import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/eq_panel.dart';
import '../widgets/equalizer_icon.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    const _Header(),
                    const SizedBox(height: 28),
                    const _Intro(),
                    const SizedBox(height: 28),
                    const EqPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Text(
            'Equalizer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.18,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back to player',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left_rounded, size: 30),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final accent = context.appAccent;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: EqualizerIcon(size: 32, color: accent.soft),
        ),
        const SizedBox(height: 16),
        const Text(
          'Shape your sound',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.44,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 260),
          child: Text(
            'Fine-tune each frequency band for the perfect balance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: Color(0xFF9993A3),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom card that returns to the player.
