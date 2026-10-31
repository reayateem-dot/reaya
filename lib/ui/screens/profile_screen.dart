import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/reaya_theme.dart';
import '../../state/reaya_cubit.dart';
import '../../state/theme_cubit.dart';
import '../widgets/reaya_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.onOpenFavorites, super.key});

  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text('الإعدادات', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ReayaColors.plum,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                SizedBox(width: 13),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ضيف رعاية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'حساب ضيف · البيانات على Firebase',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          const SectionHeading(title: 'إعداداتك'),
          const SizedBox(height: 8),
          BlocSelector<ThemeCubit, ThemeMode, bool>(
            selector: (mode) => mode == ThemeMode.dark,
            builder: (context, isDarkMode) => SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 7),
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: ReayaColors.plum,
                  size: 21,
                ),
              ),
              title: const Text(
                'الوضع الداكن',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isDarkMode ? 'المظهر الداكن مفعّل' : 'استخدم مظهرًا داكنًا',
                style: const TextStyle(fontSize: 11),
              ),
              value: isDarkMode,
              activeThumbColor: ReayaColors.plum,
              onChanged: (_) => context.read<ThemeCubit>().toggle(),
            ),
          ),
          BlocSelector<ReayaCubit, ReayaState, int>(
            selector: (state) => state.favoriteIds.length,
            builder: (context, count) => _ProfileItem(
              icon: Icons.favorite_border_rounded,
              title: 'الخدمات المفضلة',
              subtitle: '$count خدمة محفوظة',
              onTap: onOpenFavorites,
            ),
          ),
          BlocSelector<ReayaCubit, ReayaState, int>(
            selector: (state) => state.medicines.length,
            builder: (context, count) => _ProfileItem(
              icon: Icons.medication_outlined,
              title: 'قائمة أدويتي',
              subtitle: '$count دواء مسجل',
              onTap: () => showAppMessage(
                context,
                'استخدم تبويب «أدويتي» لإدارة القائمة ومواعيد الجرعات.',
              ),
            ),
          ),
          _ProfileItem(
            icon: Icons.notifications_none_rounded,
            title: 'التذكيرات',
            subtitle: 'قائمة الأدوية محفوظة في حسابك على Firebase',
            onTap: () => showAppMessage(
              context,
              'إشعارات الهاتف ستُفعّل بعد إضافة خدمة الإشعارات المحلية.',
            ),
          ),
          _ProfileItem(
            icon: Icons.privacy_tip_outlined,
            title: 'الخصوصية والبيانات',
            subtitle: 'بياناتك محفوظة في Firebase',
            onTap: () => _showPrivacy(context),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'المفضلة والأدوية محفوظة في حساب الضيف على Firebase، والمساعد يعمل عبر Gemini من Firebase AI Logic. لا تكتب بيانات شخصية؛ بيانات مقدمي الخدمات تجريبية.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'رعاية · Reaya  |  الإصدار التجريبي 1.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخصوصية والبيانات'),
        content: const Text(
          'المفضلة والأدوية تُحفظ في حساب الضيف على Firebase، وتُرسل أسئلة المساعد إلى Gemini عبر Firebase AI Logic. لا تكتب بيانات شخصية. بيانات مقدمي الخدمات الحالية تجريبية ويلزم التحقق منها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: ReayaColors.plum, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
