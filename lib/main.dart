import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'models/admin_model.dart';
import 'services/admin_session_service.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/web_home_screen.dart';
import 'screens/web_admin_login_screen.dart';
import 'screens/web_admin_dashboard_screen.dart';
import 'screens/web_personnel_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase başarıyla başlatıldı');
  } catch (e) {
    print('Firebase başlatma hatası: $e');
    // Eğer options ile başlatma başarısız olursa, options olmadan dene
    try {
      await Firebase.initializeApp();
      print('Firebase options olmadan başlatıldı');
    } catch (e2) {
      print('Firebase başlatma tamamen başarısız: $e2');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arıza Bildirim Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Web için admin session kontrolü
    if (kIsWeb) {
      return FutureBuilder<AdminModel?>(
        future: AdminSessionService.getAdminSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            // Role'e göre dashboard'a git
            if (user.role == 'admin') {
              return WebAdminDashboardScreen(admin: user);
            } else if (user.role == 'personel') {
              return WebPersonnelDashboardScreen(personnel: user);
            }
          }
          
          // Session yoksa ana sayfayı göster
          return const WebHomeScreen();
        },
      );
    }

    // Mobil için auth kontrolü
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Önce admin kontrolü yap
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('usersweb')
                .where('email', isEqualTo: snapshot.data!.email)
                .get(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (adminSnapshot.hasData && adminSnapshot.data!.docs.isNotEmpty) {
                // Admin kullanıcı
                final adminData = AdminModel.fromMap(adminSnapshot.data!.docs.first.data() as Map<String, dynamic>);
                return WebAdminDashboardScreen(admin: adminData);
              }
              
              // Normal kullanıcı kontrolü
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = UserModel.fromMap(userSnapshot.data!.data() as Map<String, dynamic>);
                    return WelcomeScreen(user: userData);
                  }
                  
                  // Kullanıcı verisi bulunamadı, giriş sayfasına yönlendir
                  return const LoginScreen();
                },
              );
            },
          );
        }
        
        // Kullanıcı giriş yapmamış, giriş sayfasına yönlendir
        return const LoginScreen();
      },
    );
  }
}
