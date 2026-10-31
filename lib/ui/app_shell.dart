import 'package:flutter/material.dart';

import '../app/reaya_theme.dart';
import '../models/health_service.dart';
import '../state/reaya_cubit.dart';
import 'screens/assistant_screen.dart';
import 'screens/directory_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/medicines_screen.dart';
import 'screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final ReayaCubit controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  ServiceType? _directoryType;

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) _directoryType = null;
    });
  }

  void _openCategory(ServiceType type) {
    setState(() {
      _directoryType = type;
      _selectedIndex = 1;
    });
  }

  void _openAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('مساعد رعاية')),
          body: AssistantScreen(
            onOpenDirectory: () {
              Navigator.of(context).pop();
              _navigateTo(1);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (context) {
          final pages = [
            HomeScreen(
              controller: widget.controller,
              onNavigate: _navigateTo,
              onOpenDirectory: _openCategory,
              onOpenAssistant: _openAssistant,
              onOpenFavorites: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FavoritesScreen(controller: widget.controller),
                ),
              ),
            ),
            DirectoryScreen(
              key: ValueKey<ServiceType?>(_directoryType),
              controller: widget.controller,
              initialType: _directoryType,
            ),
            MedicinesScreen(controller: widget.controller),
            ProfileScreen(
              onOpenFavorites: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FavoritesScreen(controller: widget.controller),
                ),
              ),
            ),
          ];

          return Scaffold(
            body: IndexedStack(index: _selectedIndex, children: pages),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'reaya-assistant-fab',
              tooltip: 'فتح مساعد رعاية',
              onPressed: _openAssistant,
              backgroundColor: ReayaColors.plum,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('مساعدك الصحي'),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _navigateTo,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  label: 'الدليل',
                ),
                NavigationDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication_rounded),
                  label: 'أدويتي',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_suggest_outlined),
                  selectedIcon: Icon(Icons.settings_suggest_rounded),
                  label: 'الإعدادات',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
