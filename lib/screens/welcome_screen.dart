import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/fault_report_model.dart';
import '../services/fault_tracking_service.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import 'fault_report_screen.dart';
import 'fault_tracking_screen.dart';
import 'notifications_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final UserModel user;

  const WelcomeScreen({super.key, required this.user});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<FaultReportModel> _userReports = [];
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTestData();
  }

  Future<void> _loadData() async {
    try {
      // Kullanıcının arıza raporlarını yükle
      final reports = await FaultTrackingService.getFaultReportsList();
      final userReports = reports.where((report) => report.userId == widget.user.uid).toList();
      
      // Okunmamış bildirim sayısını yükle
      final unreadCount = await NotificationService.getUnreadCount();

      if (mounted) {
        setState(() {
          _userReports = userReports;
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
    }
  }

  Future<void> _loadTestData() async {
    // Test verilerini yükle (sadece ilk kez)
    await FaultTrackingService.createTestData();
  }

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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Üst kısım - Profil ve bildirim butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bildirimler butonu
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => NotificationsScreen(user: widget.user),
                                ),
                              );
                              // Sayfa döndüğünde bildirim sayısını güncelle
                              _loadData();
                            },
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _unreadNotifications > 99 ? '99+' : _unreadNotifications.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Profil butonu
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(user: widget.user),
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
                  
                  const SizedBox(height: 40),
                  
                  // Karşılama bölümü
                  Column(
                    children: [
                      // Hoşgeldin başlığı
                      Text(
                        'Hoş geldin, ${widget.user.firstName}!',
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
                  
                  const SizedBox(height: 40),
                  
                  // Ana menü butonları
                  Column(
                    children: [
                      _buildMenuButton(
                        context,
                        'Arıza Bildir',
                        Icons.report_problem,
                        const Color(0xFF667eea),
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FaultReportScreen(user: widget.user),
                            ),
                          );
                          // Sayfa döndüğünde verileri güncelle
                          _loadData();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildMenuButton(
                        context,
                        'Arıza Takibi',
                        Icons.timeline,
                        const Color(0xFF764ba2),
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FaultTrackingScreen(userId: widget.user.uid),
                            ),
                          );
                          // Sayfa döndüğünde verileri güncelle
                          _loadData();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildMenuButton(
                        context,
                        'Bildirimlerim',
                        Icons.notifications,
                        Colors.orange,
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(user: widget.user),
                            ),
                          );
                          // Sayfa döndüğünde bildirim sayısını güncelle
                          _loadData();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Son arıza raporları özeti
                  if (_userReports.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Son Arıza Bildirimlerin',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_userReports.take(2).map((report) => _buildReportSummary(report))),
                          if (_userReports.length > 2)
                            TextButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FaultTrackingScreen(userId: widget.user.uid),
                                  ),
                                );
                                _loadData();
                              },
                              child: const Text(
                                'Tümünü Gör',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // Alt bilgi
                  Text(
                    'Arıza Bildirim Sistemi v1.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportSummary(FaultReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  report.trackingNumber,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(report.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(report.status),
              style: TextStyle(
                color: _getStatusColor(report.status),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'teamassigned':
        return Colors.purple;
      case 'ontheway':
        return Colors.indigo;
      case 'onsite':
        return Colors.teal;
      case 'inprogress':
        return Colors.amber;
      case 'testing':
        return Colors.cyan;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Bekliyor';
      case 'reviewing':
        return 'İnceleniyor';
      case 'teamassigned':
        return 'Ekip Atandı';
      case 'ontheway':
        return 'Yolda';
      case 'onsite':
        return 'Sahada';
      case 'inprogress':
        return 'İşlemde';
      case 'testing':
        return 'Test Ediliyor';
      case 'resolved':
        return 'Çözüldü';
      case 'closed':
        return 'Kapatıldı';
      default:
        return status;
    }
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