import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/reaya_theme.dart';
import '../../models/medicine.dart';
import '../../state/reaya_cubit.dart';
import '../widgets/reaya_widgets.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({required this.controller, super.key});

  final ReayaCubit controller;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ReayaCubit, ReayaState, List<Medicine>>(
      selector: (state) => state.medicines,
      builder: (context, medicines) => SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'أدويتي',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (medicines.isNotEmpty)
                      IconButton.filledTonal(
                        tooltip: 'نسخ قائمة الأدوية',
                        onPressed: () => _copyMedicineList(context, medicines),
                        icon: const Icon(Icons.ios_share_rounded),
                      ),
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      onPressed: () => _openMedicineForm(context),
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('إضافة'),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'نظّم مواعيدك وكميتك المتبقية في مكان واحد.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                _MedicineNotice(count: medicines.length),
                const SizedBox(height: 16),
                if (medicines.isEmpty)
                  const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'قائمة أدويتك فاضية',
                    message: 'أضف دواءً لتسجيل الجرعة ومواعيد الاستخدام والكمية.',
                  ),
                for (final medicine in medicines) ...[
                  _MedicineCard(
                    medicine: medicine,
                    onEdit: () => _openMedicineForm(context, medicine: medicine),
                    onDelete: () => _confirmDelete(context, medicine),
                    onTaken: () => _markTaken(context, medicine),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Text(
                  'تسجيل الاستهلاك يخصم وحدة واحدة في كل مرة. لا تغيّر جرعة دوائك أو مواعيده؛ اتبع وصف الطبيب أو الصيدلي.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _openMedicineForm(
    BuildContext context, {
    Medicine? medicine,
  }) async {
    final result = await showDialog<Medicine>(
      context: context,
      builder: (_) => _MedicineForm(medicine: medicine),
    );
    if (result == null) return;
    try {
      await controller.saveMedicine(result);
      if (context.mounted) showAppMessage(context, 'تم حفظ بيانات الدواء.');
    } on Exception catch (error) {
      if (context.mounted) showAppMessage(context, 'تعذر حفظ الدواء: $error');
    }
  }

  Future<void> _markTaken(BuildContext context, Medicine medicine) async {
    if (medicine.remaining == 0) return;
    try {
      await controller.updateMedicine(
        medicine.copyWith(remaining: medicine.remaining - 1),
      );
      if (context.mounted) showAppMessage(context, 'تم تحديث الكمية المتبقية.');
    } on Exception catch (error) {
      if (context.mounted) showAppMessage(context, 'تعذر تحديث الكمية: $error');
    }
  }

  Future<void> _confirmDelete(BuildContext context, Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدواء؟'),
        content: Text('سيتم حذف «${medicine.name}» من قائمتك على هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.deleteMedicine(medicine.id);
      if (context.mounted) showAppMessage(context, 'تم حذف الدواء.');
    } on Exception catch (error) {
      if (context.mounted) showAppMessage(context, 'تعذر حذف الدواء: $error');
    }
  }

  Future<void> _copyMedicineList(
    BuildContext context,
    List<Medicine> medicines,
  ) async {
    final summary = [
      'قائمة الأدوية - رعاية',
      for (final medicine in medicines)
        '• ${medicine.name}: ${medicine.dose} | المواعيد: ${medicine.times.join('، ')} | المتبقي: ${medicine.remaining}',
      '',
      'هذه القائمة أدخلها المستخدم ولا تغني عن مراجعة الطبيب أو الصيدلي.',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) {
      showAppMessage(context, 'تم نسخ القائمة. يمكنك لصقها لمشاركتها مع الطبيب.');
    }
  }
}

class _MedicineNotice extends StatelessWidget {
  const _MedicineNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_outlined, color: ReayaColors.green),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              count == 0
                  ? 'سجّل مواعيد الجرعات لمتابعتها بسهولة.'
                  : 'لديك $count ${count == 1 ? 'دواء مسجل' : 'أدوية مسجلة'} في القائمة.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
    required this.onTaken,
  });

  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    final isLow = medicine.remaining <= 3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: ReayaColors.plum,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        medicine.dose,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'خيارات الدواء',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: medicine.times
                  .map(
                    (time) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: ReayaColors.plum,
                      ),
                      label: Text(time),
                    ),
                  )
                  .toList(),
            ),
            if (medicine.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                medicine.notes,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: isLow ? ReayaColors.amber : ReayaColors.green,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'المتبقي: ${medicine.remaining} من ${medicine.totalQuantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isLow
                          ? ReayaColors.amber
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: medicine.remaining == 0 ? null : onTaken,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('خصم وحدة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineForm extends StatefulWidget {
  const _MedicineForm({this.medicine});

  final Medicine? medicine;

  @override
  State<_MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends State<_MedicineForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _timesController;
  late final TextEditingController _remainingController;
  late final TextEditingController _totalController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    _nameController = TextEditingController(text: medicine?.name ?? '');
    _doseController = TextEditingController(text: medicine?.dose ?? '');
    _timesController =
        TextEditingController(text: medicine?.times.join('، ') ?? '');
    _remainingController =
        TextEditingController(text: medicine?.remaining.toString() ?? '');
    _totalController =
        TextEditingController(text: medicine?.totalQuantity.toString() ?? '');
    _notesController = TextEditingController(text: medicine?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _timesController.dispose();
    _remainingController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medicine == null ? 'إضافة دواء' : 'تعديل الدواء'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_nameController, 'اسم الدواء'),
                _field(_doseController, 'الجرعة (كما وصفها الطبيب)'),
                _field(
                  _timesController,
                  'المواعيد (مثال: 08:00، 20:00)',
                  validator: _validateTimes,
                  keyboardType: TextInputType.datetime,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _remainingController,
                        'الكمية المتبقية',
                        keyboardType: TextInputType.number,
                        validator: _validateQuantity,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _totalController,
                        'الكمية الكلية',
                        keyboardType: TextInputType.number,
                        validator: _validateQuantity,
                      ),
                    ),
                  ],
                ),
                _field(_notesController, 'ملاحظات (اختياري)', required: false),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(labelText: label),
        validator: validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                    ? 'هذا الحقل مطلوب'
                    : null
                : null),
      ),
    );
  }

  String? _validateQuantity(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) return 'أدخل رقمًا صحيحًا';
    return null;
  }

  String? _validateTimes(String? value) {
    final times = (value ?? '')
        .split(RegExp('[،,]'))
        .map((time) => time.trim())
        .where((time) => time.isNotEmpty);
    if (times.isEmpty) return 'أدخل موعدًا واحدًا على الأقل';
    for (final time in times) {
      final match = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(time);
      if (!match) return 'استخدم صيغة 24 ساعة، مثل 08:00';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final remaining = int.parse(_remainingController.text.trim());
    final total = int.parse(_totalController.text.trim());
    if (remaining > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية المتبقية لا يمكن أن تتجاوز الكلية.')),
      );
      return;
    }
    final times = _timesController.text
        .split(RegExp('[،,]'))
        .map((time) => time.trim())
        .where((time) => time.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final medicine = Medicine(
      id: widget.medicine?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dose: _doseController.text.trim(),
      times: times,
      remaining: remaining,
      totalQuantity: total,
      notes: _notesController.text.trim(),
    );
    Navigator.pop(context, medicine);
  }
}
