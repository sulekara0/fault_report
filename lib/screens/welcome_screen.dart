import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'fault_report_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final UserModel user;

  const WelcomeScreen({super.key, required this.user});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                                 // Üst kısım - Profil butonu
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     IconButton(
                       onPressed: () {
                         Navigator.of(context).push(
                           MaterialPageRoute(
                             builder: (context) => ProfileScreen(user: user),
                           ),
                         );
                       },
                       icon: const Icon(
                         Icons.person,
                         color: Colors.white,
                         size: 28,
                       ),
                     ),
                   ],
                 ),
                
                const Spacer(),
                
                                 // Karşılama bölümü
                 Column(
                   children: [
                     // Hoşgeldin başlığı
                     Text(
                       'Hoş geldin, ${user.firstName}!',
                       style: const TextStyle(
                         fontSize: 32,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                         shadows: [
                           Shadow(
                             offset: Offset(0, 2),
                             blurRadius: 4,
                             color: Colors.black26,
                           ),
                         ],
                       ),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 12),
                     
                     // Alt metin
                     Text(
                       'Bulunduğun konumu paylaşarak arızayı 1 dakikada bildirebilirsin.',
                       style: TextStyle(
                         fontSize: 16,
                         color: Colors.white.withOpacity(0.9),
                         height: 1.4,
                         shadows: [
                           Shadow(
                             offset: const Offset(0, 1),
                             blurRadius: 2,
                             color: Colors.black26,
                           ),
                         ],
                       ),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 40),
                     
                     // Duyuru bandı
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(
                           colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         borderRadius: BorderRadius.circular(20),
                         boxShadow: [
                           BoxShadow(
                             color: const Color(0xFFFF6B6B).withOpacity(0.3),
                             blurRadius: 15,
                             offset: const Offset(0, 5),
                           ),
                         ],
                       ),
                       child: Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(10),
                             ),
                             child: const Icon(
                               Icons.announcement,
                               color: Colors.white,
                               size: 24,
                             ),
                           ),
                           const SizedBox(width: 15),
                           Expanded(
                             child: Text(
                               'Duyuru: 13.08 10:00–12:00 Nilüfer\'de planlı su kesintisi.',
                               style: const TextStyle(
                                 fontSize: 14,
                                 color: Colors.white,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 
                 const SizedBox(height: 30),
                 
                 // Ana menü butonları
                 Column(
                   children: [
                                             _buildMenuButton(
                          context,
                          'Arıza Bildir',
                          Icons.report_problem,
                          const Color(0xFF667eea),
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FaultReportScreen(user: user),
                              ),
                            );
                          },
                        ),
                     const SizedBox(height: 20),
                     _buildMenuButton(
                       context,
                       'Geçmiş Arızalar',
                       Icons.history,
                       const Color(0xFF764ba2),
                       () {
                         // Geçmiş arızalar sayfasına git
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Geçmiş arızalar özelliği yakında eklenecek!'),
                             backgroundColor: Color(0xFF764ba2),
                           ),
                         );
                       },
                     ),
                     const SizedBox(height: 20),
                     _buildMenuButton(
                       context,
                       'Bildirimlerim',
                       Icons.notifications,
                       Colors.orange,
                       () {
                         // Bildirimler sayfasına git
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Bildirimler özelliği yakında eklenecek!'),
                             backgroundColor: Colors.orange,
                           ),
                         );
                       },
                     ),
                   ],
                 ),
                
                const Spacer(),
                
                // Alt bilgi
                Text(
                  'Arıza Bildirim Sistemi v1.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}