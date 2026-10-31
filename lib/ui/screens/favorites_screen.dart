import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../state/reaya_cubit.dart';
import '../widgets/reaya_widgets.dart';
import 'service_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({required this.controller, super.key});

  final ReayaCubit controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخدمات المفضلة')),
      body: BlocSelector<ReayaCubit, ReayaState, Set<String>>(
        selector: (state) => state.favoriteIds,
        builder: (context, favoriteIds) {
          final favorites = controller.services
              .where((service) => favoriteIds.contains(service.id))
              .toList();
          return favorites.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: const EmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: 'لسه مفيش خدمات مفضلة',
                        message:
                            'اضغط على علامة القلب بجانب أي خدمة لحفظها هنا.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final service = favorites[index];
                    return ServiceCard(
                      service: service,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ServiceDetailsScreen(
                            service: service,
                            controller: controller,
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
