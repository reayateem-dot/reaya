import 'package:flutter/material.dart';

import '../../models/health_service.dart';
import '../../state/reaya_cubit.dart';
import '../widgets/reaya_widgets.dart';
import 'service_details_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({
    required this.controller,
    this.initialType,
    super.key,
  });

  final ReayaCubit controller;
  final ServiceType? initialType;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  late final TextEditingController _searchController;
  late ServiceType? _selectedType;
  String _selectedCity = 'كل المدن';

  static const _cities = [
    'كل المدن',
    'أشمون',
    'شبين الكوم',
    'طنطا',
    'مدينة السادات',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedType = widget.initialType;
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final results = widget.controller.services.where((service) {
      final matchesType = _selectedType == null || service.type == _selectedType;
      final matchesCity =
          _selectedCity == 'كل المدن' || service.city == _selectedCity;
      final searchable =
          '${service.name} ${service.specialty ?? ''} ${service.city} ${service.area}'
              .toLowerCase();
      return matchesType && matchesCity && searchable.contains(query);
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('دليل الخدمات', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text(
                  'ابحث واختر الخدمة المناسبة في مدينتك.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'اسم الطبيب، التخصص، أو الخدمة',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _TypeFilter(
                        label: 'الكل',
                        selected: _selectedType == null,
                        onTap: () => setState(() => _selectedType = null),
                      ),
                      for (final type in ServiceType.values)
                        _TypeFilter(
                          label: type.label,
                          selected: _selectedType == type,
                          onTap: () => setState(() => _selectedType = type),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city_outlined),
                    labelText: 'المدينة',
                  ),
                  items: _cities
                      .map(
                        (city) => DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        ),
                      )
                      .toList(),
                  onChanged: (city) {
                    if (city != null) setState(() => _selectedCity = city);
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  '${results.length} خدمة متاحة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 10),
                if (results.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'مفيش نتائج مطابقة',
                    message: 'جرّب تغيير كلمة البحث أو اختيار مدينة أخرى.',
                  ),
                for (final service in results) ...[
                  ServiceCard(
                    service: service,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ServiceDetailsScreen(
                          service: service,
                          controller: widget.controller,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          fontSize: 12,
        ),
      ),
    );
  }
}
