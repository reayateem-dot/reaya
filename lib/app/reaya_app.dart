import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/firestore_reaya_repository.dart';
import '../data/reaya_repository.dart';
import '../state/reaya_cubit.dart';
import '../state/theme_cubit.dart';
import '../ui/screens/splash_screen.dart';
import 'reaya_theme.dart';

class ReayaApp extends StatelessWidget {
  ReayaApp({super.key, ReayaRepository? repository})
    : repository = repository ?? FirestoreReayaRepository();

  final ReayaRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ReayaCubit(repository)..load()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          title: 'رعاية | Reaya',
          debugShowCheckedModeBanner: false,
          theme: ReayaTheme.light,
          darkTheme: ReayaTheme.dark,
          themeMode: themeMode,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _AppStartup(),
        ),
      ),
    );
  }
}

class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReayaCubit, ReayaState>(
      builder: (context, state) {
        if (state.status == LoadStatus.error) {
          return _StartupError(
            error: state.loadError,
            onRetry: context.read<ReayaCubit>().load,
          );
        }
        if (state.status == LoadStatus.loaded) {
          return const SplashScreen();
        }
        return const SplashScreen();
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 16),
              const Text('تعذر تحميل بيانات التطبيق'),
              const SizedBox(height: 8),
              Text(error?.toString() ?? 'حدث خطأ غير متوقع.'),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
