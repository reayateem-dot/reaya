import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reaya/app/reaya_app.dart';
import 'package:reaya/data/local_chat_service.dart';
import 'package:reaya/data/reaya_repository.dart';
import 'package:reaya/models/health_service.dart';
import 'package:reaya/models/medicine.dart';
import 'package:reaya/state/reaya_cubit.dart';
import 'package:reaya/ui/screens/assistant_screen.dart';

void main() {
  test('repository stores favorites and medicine records', () async {
    final repository = _MemoryReayaRepository();
    final favorites = await repository.getFavoriteIds();
    expect(favorites, isEmpty);

    await repository.saveFavoriteIds({'doctor-1'});
    expect(await repository.getFavoriteIds(), contains('doctor-1'));

    const medicine = Medicine(
      id: 'medicine-1',
      name: 'دواء تجريبي',
      dose: 'قرص واحد',
      times: ['08:00'],
      remaining: 5,
      totalQuantity: 10,
    );
    await repository.saveMedicines([medicine]);
    final saved = await repository.getMedicines();
    expect(saved.single.name, medicine.name);
    expect(saved.single.remaining, medicine.remaining);
  });

  test('health service serializes to Firestore-compatible fields', () {
    const service = HealthService(
      id: 'service-1',
      name: 'مقدم خدمة',
      type: ServiceType.doctor,
      city: 'أشمون',
      area: 'وسط البلد',
      address: 'شارع تجريبي',
      phone: '01000000000',
      description: 'وصف',
      hours: 'يوميًا',
      rating: 4.5,
    );

    final restored = HealthService.fromJson(service.toJson());
    expect(restored.id, service.id);
    expect(restored.type, service.type);
    expect(restored.rating, service.rating);
  });

  test('Cubit loads services and emits persisted user changes', () async {
    final cubit = ReayaCubit(_MemoryReayaRepository());
    await cubit.load();

    expect(cubit.state.status, LoadStatus.loaded);
    expect(cubit.state.services, isNotEmpty);

    await cubit.toggleFavorite('doctor-1');
    expect(cubit.state.favoriteIds, contains('doctor-1'));

    const medicine = Medicine(
      id: 'cubit-medicine',
      name: 'دواء محفوظ',
      dose: 'حسب وصف الطبيب',
      times: ['09:00'],
      remaining: 3,
      totalQuantity: 7,
    );
    await cubit.saveMedicine(medicine);
    expect(cubit.state.medicines.single.name, 'دواء محفوظ');
    await cubit.close();
  });

  testWidgets('home opens the searchable health directory', (tester) async {
    await tester.pumpWidget(ReayaApp(repository: _MemoryReayaRepository()));
    await tester.pumpAndSettle();

    expect(find.text('أهلًا بيك 👋'), findsOneWidget);
    expect(find.text('رعاية'), findsOneWidget);

    await tester.tap(find.text('الدليل'));
    await tester.pumpAndSettle();

    expect(find.text('دليل الخدمات'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'الشفاء');
    await tester.pumpAndSettle();

    expect(find.text('صيدلية الشفاء'), findsOneWidget);
    expect(find.text('معامل النخبة'), findsNothing);
  });

  testWidgets('splash screen uses Cairo and transitions to the home page', (
    tester,
  ) async {
    await tester.pumpWidget(ReayaApp(repository: _MemoryReayaRepository()));
    final brandText = find.text('رعاية');
    expect(
      DefaultTextStyle.of(tester.element(brandText)).style.fontFamily,
      'Cairo',
    );
    expect(find.text('صحتك أقرب.. ورعايتك أسهل'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('أهلًا بيك 👋'), findsOneWidget);
  });

  testWidgets('assistant opens from the floating action button', (
    tester,
  ) async {
    await tester.pumpWidget(ReayaApp(repository: _MemoryReayaRepository()));
    await tester.pumpAndSettle();

    expect(find.text('مساعدك'), findsNothing);
    expect(
      tester.getCenter(find.byTooltip('فتح مساعد رعاية')).dx,
      lessThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
    await tester.tap(find.byTooltip('فتح مساعد رعاية'));
    await tester.pumpAndSettle();
    expect(find.text('مساعد رعاية'), findsNWidgets(2));
    expect(find.textContaining('إلى Gemini عبر Firebase AI Logic'), findsOneWidget);
    expect(find.textContaining('Ollama'), findsNothing);
  });

  testWidgets('dark mode setting resets when the app is recreated', (
    tester,
  ) async {
    final repository = _MemoryReayaRepository();
    await tester.pumpWidget(ReayaApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الوضع الداكن'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('المظهر الداكن مفعّل'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ReayaApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('استخدم مظهرًا داكنًا'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('medicine can be added and its quantity updated', (tester) async {
    await tester.pumpWidget(ReayaApp(repository: _MemoryReayaRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أدويتي').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'دواء تجريبي');
    await tester.enterText(fields.at(1), 'قرص واحد');
    await tester.enterText(fields.at(2), '08:00، 20:00');
    await tester.enterText(fields.at(3), '8');
    await tester.enterText(fields.at(4), '10');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('دواء تجريبي'), findsOneWidget);
    await tester.tap(find.text('خصم وحدة'));
    await tester.pumpAndSettle();
    expect(find.text('المتبقي: 7 من 10'), findsOneWidget);
  });

  testWidgets('assistant directs urgent symptoms to emergency care', (
    tester,
  ) async {
    await tester.pumpWidget(ReayaApp(repository: _MemoryReayaRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('فتح مساعد رعاية'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ألم شديد في الصدر');
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    expect(find.textContaining('لا تنتظر ردًا من التطبيق'), findsOneWidget);
    expect(find.textContaining('رقم الإسعاف 123'), findsOneWidget);
  });

  testWidgets('assistant displays a local model service error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssistantScreen(
            onOpenDirectory: () {},
            chatService: LocalChatService(
              generateResponse: (_) async =>
                  throw const AssistantServiceException(
                    'شغّل Ollama على اللابتوب ونزّل النموذج المحلي.',
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      'ما التخصص المناسب لمشكلة عامة؟',
    );
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    expect(find.textContaining('شغّل Ollama على اللابتوب'), findsOneWidget);
  });
}

class _MemoryReayaRepository implements ReayaRepository {
  final List<HealthService> services = [
    const HealthService(
      id: 'doctor-1',
      name: 'د. مريم عبد الرحمن',
      type: ServiceType.doctor,
      city: 'أشمون',
      area: 'وسط البلد',
      address: 'شارع سعد زغلول',
      phone: '01012345678',
      specialty: 'أخصائية طب الأطفال',
      rating: 4.8,
      hours: 'يوميًا',
      description: 'بيانات اختبار.',
    ),
    const HealthService(
      id: 'pharmacy-1',
      name: 'صيدلية الشفاء',
      type: ServiceType.pharmacy,
      city: 'أشمون',
      area: 'وسط البلد',
      address: 'شارع سعد زغلول',
      phone: '0483441122',
      hours: 'يوميًا',
      description: 'بيانات اختبار.',
    ),
    const HealthService(
      id: 'lab-1',
      name: 'معامل النخبة',
      type: ServiceType.laboratory,
      city: 'أشمون',
      area: 'وسط البلد',
      address: 'شارع صلاح سالم',
      phone: '0483456677',
      hours: 'يوميًا',
      description: 'بيانات اختبار.',
    ),
  ];
  Set<String> favoriteIds = {};
  List<Medicine> medicines = [];

  @override
  Future<List<HealthService>> getServices() async => services;

  @override
  Future<Set<String>> getFavoriteIds() async => favoriteIds;

  @override
  Future<void> saveFavoriteIds(Set<String> ids) async {
    favoriteIds = Set.of(ids);
  }

  @override
  Future<List<Medicine>> getMedicines() async => medicines;

  @override
  Future<void> saveMedicines(List<Medicine> values) async {
    medicines = List.of(values);
  }
}
