import 'package:flutter/material.dart';
import 'package:reaya/app/firebase_bootstrap.dart';
import 'package:reaya/app/reaya_app.dart';
import 'package:reaya/data/firestore_reaya_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(ReayaApp(repository: FirestoreReayaRepository()));
}
