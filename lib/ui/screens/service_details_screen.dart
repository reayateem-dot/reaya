import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/reaya_theme.dart';
import '../../models/health_service.dart';
import '../../state/reaya_cubit.dart';
import '../widgets/reaya_widgets.dart';

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({
    required this.service,
    required this.controller,
    super.key,
  });

  final HealthService service;
  final ReayaCubit controller;

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showAppMessage(context, 'تعذر فتح التطبيق المطلوب على هذا الجهاز.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapQuery = Uri.encodeComponent(
      '${service.name}, ${service.address}, ${service.city}',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخدمة'),
        actions: [
          BlocSelector<ReayaCubit, ReayaState, bool>(
            selector: (state) => state.favoriteIds.contains(service.id),
            builder: (context, favorite) => IconButton(
              tooltip: favorite ? 'إزالة من المفضلة' : 'أضف للمفضلة',
              onPressed: () async {
                try {
                  await controller.toggleFavorite(service.id);
                } on Exception catch (error) {
                  if (context.mounted) {
                    showAppMessage(context, 'تعذر تحديث المفضلة: $error');
                  }
                }
              },
              icon: Icon(
                favorite ? Icons.favorite_rounded : Icons.favorite_border,
                color: favorite ? Colors.red.shade400 : ReayaColors.plum,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            height: 156,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ReayaColors.plum, Color(0xFF493244)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(service.type.icon, color: Colors.white, size: 43),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            service.type.singularLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(service.name, style: Theme.of(context).textTheme.headlineSmall),
          if (service.specialty != null) ...[
            const SizedBox(height: 7),
            Text(
              service.specialty!,
              style: const TextStyle(
                color: ReayaColors.plum,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.location_on_outlined,
                text: service.locationLabel,
              ),
              if (service.rating != null)
                _InfoPill(
                  icon: Icons.star_rounded,
                  text: '${service.rating!.toStringAsFixed(1)} تقييم تجريبي',
                ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeading(title: 'عن الخدمة'),
          const SizedBox(height: 7),
          Text(
            service.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          const SectionHeading(title: 'معلومات التواصل والزيارة'),
          const SizedBox(height: 8),
          _DetailLine(
            icon: Icons.location_on_outlined,
            title: 'العنوان',
            value: service.address,
          ),
          _DetailLine(
            icon: Icons.schedule_outlined,
            title: 'مواعيد العمل',
            value: service.hours,
          ),
          if (service.price != null)
            _DetailLine(
              icon: Icons.payments_outlined,
              title: 'السعر',
              value: service.price!,
            ),
          _DetailLine(
            icon: Icons.phone_outlined,
            title: 'رقم التواصل',
            value: service.phone,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openLink(
                    context,
                    Uri(scheme: 'tel', path: service.phone),
                  ),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('اتصل'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openLink(
                    context,
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$mapQuery',
                    ),
                  ),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('الموقع'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ReayaColors.plum,
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: ReayaColors.plum),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'البيانات المعروضة تجريبية. يرجى التحقق من رقم الهاتف والعنوان ومواعيد العمل قبل الزيارة.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ReayaColors.amber),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: ReayaColors.plum),
          const SizedBox(width: 10),
          SizedBox(
            width: 91,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
