import 'package:flutter/material.dart';

import '../../app/reaya_theme.dart';
import '../../models/health_service.dart';
import '../../state/reaya_cubit.dart';
import '../widgets/reaya_widgets.dart';
import 'service_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.controller,
    required this.onNavigate,
    required this.onOpenFavorites,
    required this.onOpenDirectory,
    required this.onOpenAssistant,
    super.key,
  });

  final ReayaCubit controller;
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenFavorites;
  final ValueChanged<ServiceType> onOpenDirectory;
  final VoidCallback onOpenAssistant;

  @override
  Widget build(BuildContext context) {
    final featured = controller.services.take(3).toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/Pink Heart and Caring Hand Emblem.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رعاية',
                          style: TextStyle(
                            fontSize: 20,
                            color: ReayaColors.plum,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'معلومات صحية أقرب إليك',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'المفضلة',
                      onPressed: onOpenFavorites,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: ReayaColors.plum,
                      ),
                      icon: const Icon(Icons.favorite_border_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('أهلًا بيك 👋', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'خلّي الوصول للخدمات الصحية أسهل.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => onNavigate(1),
                  borderRadius: BorderRadius.circular(17),
                  child: IgnorePointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن طبيب أو خدمة صحية',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: ReayaColors.plum,
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: ReayaColors.plum,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _AssistantBanner(onTap: onOpenAssistant),
                const SizedBox(height: 26),
                const SectionHeading(title: 'تصفّح الخدمات'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 106,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ServiceType.values
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 10),
                            child: ServiceCategoryTile(
                              type: type,
                              onTap: () => onOpenDirectory(type),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeading(
                  title: 'خدمات صحية مميزة',
                  actionLabel: 'عرض الكل',
                  onAction: () => onNavigate(1),
                ),
                const SizedBox(height: 10),
                for (final service in featured) ...[
                  ServiceCard(
                    service: service,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ServiceDetailsScreen(
                          service: service,
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                const _DemoNotice(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantBanner extends StatelessWidget {
  const _AssistantBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReayaColors.plum,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مش عارف تبدأ منين؟',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'مساعد إرشادي يساعدك تختار تخصصًا للاستفسار عنه',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: ReayaColors.amber),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'بيانات الخدمات المعروضة تجريبية للتوضيح، ويجب التحقق من تفاصيلها قبل الاعتماد عليها.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
