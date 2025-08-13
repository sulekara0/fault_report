import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAqltNdKMSTVHs5IIV0rtcgFhMv-5BSUU',
      appId: '1:884446641689:web:9c75b4851dffd27415b488',
      messagingSenderId: '884446641689',
      projectId: 'fault-8506366',
      authDomain: 'fault-8506366.firebaseapp.com',
      storageBucket: 'fault-8506366.appspot.com',
      measurementId: 'G-56NB38CEZW',
    ),
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Admin Web Panel Hazır 🖥️'))),
    );
  }
}
