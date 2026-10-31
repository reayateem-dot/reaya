import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/reaya_theme.dart';
import '../../state/reaya_cubit.dart';
import '../app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _minimumDurationPassed = false;
  Timer? _minimumDurationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
    _minimumDurationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _minimumDurationPassed = true);
    });
  }

  @override
  void dispose() {
    _minimumDurationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReayaCubit, ReayaState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loaded && _minimumDurationPassed) {
          return AppShell(controller: context.read<ReayaCubit>());
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                PositionedDirectional(
                  top: -105,
                  start: -95,
                  child: _GlowCircle(
                    size: 260,
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.65),
                  ),
                ),
                PositionedDirectional(
                  bottom: -155,
                  end: -90,
                  child: _GlowCircle(
                    size: 300,
                    color: ReayaColors.blush.withValues(alpha: 0.55),
                  ),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ReayaColors.plum.withValues(alpha: .1),
                                  blurRadius: 35,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/Pink Heart and Caring Hand Emblem.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.health_and_safety_outlined,
                                size: 78,
                                color: ReayaColors.plum,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'رعاية',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: ReayaColors.plum,
                                  fontSize: 31,
                                  letterSpacing: 0.2,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'صحتك أقرب.. ورعايتك أسهل',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 42),
                          if (state.status == LoadStatus.error) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'تعذر تحميل بيانات التطبيق. تحقق من التخزين وحاول مرة أخرى.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: context.read<ReayaCubit>().load,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ] else ...[
                            const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: ReayaColors.plum,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.status == LoadStatus.loaded
                                  ? 'لحظات ونبدأ...'
                                  : 'بنجهّزلك تجربة رعاية متكاملة',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 20,
                  start: 0,
                  end: 0,
                  child: Text(
                    'Reaya  •  دليل الخدمات الصحية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
