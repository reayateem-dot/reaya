import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app/firebase_bootstrap.dart';
import '../models/health_service.dart';
import '../models/medicine.dart';
import 'reaya_repository.dart';

class ReayaRepositoryException implements Exception {
  const ReayaRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirestoreReayaRepository implements ReayaRepository {
  FirestoreReayaRepository();

  static const _batchSize = 400;

  FirebaseFirestore? _firestore;
  Future<String>? _userId;

  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCollection(
    String userId,
    String name,
  ) => _db.collection('users').doc(userId).collection(name);

  Future<String> _ensureUser() async {
    if (!await initializeFirebase()) {
      throw const ReayaRepositoryException(
        'تعذر تهيئة Firebase. تأكد من إضافة ملف google-services.json المطابق لمعرّف التطبيق.',
      );
    }

    try {
      return await (_userId ??= _signIn());
    } on Object {
      _userId = null;
      rethrow;
    }
  }

  Future<String> _signIn() async {
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      try {
        user = (await auth.signInAnonymously()).user;
      } on FirebaseAuthException catch (error) {
        throw ReayaRepositoryException(_authErrorMessage(error));
      }
    }
    if (user == null) {
      throw const ReayaRepositoryException(
        'تعذر إنشاء جلسة مستخدم Firebase مجهولة. تأكد من تفعيل Anonymous Authentication.',
      );
    }
    return user.uid;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    final details = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (details.contains('configuration_not_found') ||
        details.contains('configuration-not-found')) {
      return 'خدمة تسجيل الدخول لم تُجهّز في Firebase لهذا المشروع. من Firebase Console افتح Authentication ثم Get started، وفعّل Anonymous من Sign-in method، وتأكد أن المشروع هو reaya-7f077. بعدها اضغط «إعادة المحاولة».';
    }
    if (error.code == 'operation-not-allowed') {
      return 'فعّل Anonymous من Firebase Console: Authentication ثم Sign-in method، وبعدها اضغط «إعادة المحاولة».';
    }
    if (error.code == 'admin-restricted-operation') {
      return 'Firebase رفض إنشاء حساب الضيف. من المشروع reaya-7f077 افتح Authentication ثم Sign-in method، وفعّل Anonymous تحديدًا (تفعيل Authentication وحده لا يكفي)، ثم اضغط «إعادة المحاولة».';
    }
    if (error.code == 'invalid-api-key') {
      return 'مفتاح Firebase غير صالح. نزّل google-services.json من تطبيق Android المسجّل بالحزمة com.company.reaya واستبدل الملف داخل android/app.';
    }
    if (error.code == 'network-request-failed') {
      return 'تعذر الاتصال بخدمة تسجيل الدخول. تحقق من الإنترنت ثم اضغط «إعادة المحاولة».';
    }
    return 'تعذر تسجيل الدخول إلى Firebase (${error.code}). تأكد من تفعيل Anonymous وصحة إعدادات المشروع، ثم اضغط «إعادة المحاولة».';
  }

  Future<T> _withFirestoreGuidance<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ReayaRepositoryException(
          'تم تسجيل الدخول، لكن قواعد Firestore لم تسمح بقراءة البيانات. انشر القواعد من مجلد المشروع بالأمر: firebase deploy --only firestore:rules --project reaya-7f077',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<HealthService>> getServices() => _withFirestoreGuidance(() async {
    await _ensureUser();
    final snapshot = await _db.collection('services').get();
    final services = snapshot.docs
        .map((document) => HealthService.fromJson(document.data()))
        .toList();
    services.sort((a, b) => a.name.compareTo(b.name));
    return services;
  });

  @override
  Future<Set<String>> getFavoriteIds() => _withFirestoreGuidance(() async {
    final userId = await _ensureUser();
    final snapshot = await _userCollection(userId, 'favorites').get();
    return snapshot.docs.map((document) => document.id).toSet();
  });

  @override
  Future<void> saveFavoriteIds(Set<String> ids) => _withFirestoreGuidance(
    () async {
      final userId = await _ensureUser();
      final collection = _userCollection(userId, 'favorites');
      final current = await collection.get();
      final writes = <void Function(WriteBatch)>[];

      for (final document in current.docs) {
        if (!ids.contains(document.id)) {
          writes.add((batch) => batch.delete(document.reference));
        }
      }
      for (final id in ids) {
        writes.add((batch) => batch.set(collection.doc(id), {'serviceId': id}));
      }
      await _commitWrites(writes);
    },
  );

  @override
  Future<List<Medicine>> getMedicines() => _withFirestoreGuidance(() async {
    final userId = await _ensureUser();
    final snapshot = await _userCollection(userId, 'medicines').get();
    return snapshot.docs
        .map((document) => Medicine.fromJson(document.data()))
        .toList();
  });

  @override
  Future<void> saveMedicines(List<Medicine> medicines) =>
      _withFirestoreGuidance(() async {
        final userId = await _ensureUser();
        final collection = _userCollection(userId, 'medicines');
        final current = await collection.get();
        final updatedIds = medicines.map((medicine) => medicine.id).toSet();
        final writes = <void Function(WriteBatch)>[];

        for (final document in current.docs) {
          if (!updatedIds.contains(document.id)) {
            writes.add((batch) => batch.delete(document.reference));
          }
        }
        for (final medicine in medicines) {
          writes.add(
            (batch) =>
                batch.set(collection.doc(medicine.id), medicine.toJson()),
          );
        }
        await _commitWrites(writes);
      });

  Future<void> _commitWrites(List<void Function(WriteBatch)> writes) async {
    for (var start = 0; start < writes.length; start += _batchSize) {
      final batch = _db.batch();
      final end = (start + _batchSize).clamp(0, writes.length);
      for (final write in writes.sublist(start, end)) {
        write(batch);
      }
      await batch.commit();
    }
  }
}
