import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';
import '../models/fault_report_model.dart';
import '../models/fault_status_model.dart';
import '../services/admin_session_service.dart';
import '../services/fault_tracking_service.dart';
import '../services/notification_service.dart';
import 'web_personnel_login_screen.dart';

class WebPersonnelDashboardScreen extends StatefulWidget {
  final AdminModel personnel;

  const WebPersonnelDashboardScreen({super.key, required this.personnel});

  @override
  State<WebPersonnelDashboardScreen> createState() => _WebPersonnelDashboardScreenState();
}

class _WebPersonnelDashboardScreenState extends State<WebPersonnelDashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedStatusFilter = 'all';
  String _selectedCategoryFilter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
             appBar: AppBar(
         title: const Text(
           'Personel Girişi',
           style: TextStyle(
             color: Colors.white,
             fontWeight: FontWeight.bold,
           ),
         ),
         backgroundColor: const Color(0xFF667eea),
         elevation: 0,
       ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // Personel bilgileri
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.people,
                          size: 30,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.personnel.display,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Arıza Takip Personeli',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menü
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                                         children: [
                       _buildMenuItem(
                         icon: Icons.dashboard,
                         title: 'Dashboard',
                         index: 0,
                       ),
                       _buildMenuItem(
                         icon: Icons.report_problem,
                         title: 'Arıza Takibi',
                         index: 1,
                       ),
                       _buildMenuItem(
                         icon: Icons.analytics,
                         title: 'Performans',
                         index: 2,
                       ),
                       const Divider(height: 1, color: Colors.grey),
                       _buildMenuItem(
                         icon: Icons.logout,
                         title: 'Çıkış Yap',
                         index: 3,
                       ),
                     ],
                  ),
                ),
              ],
            ),
          ),
          
          // Ana içerik
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final isLogout = index == 3; // Çıkış yap butonu
    
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : (isSelected ? const Color(0xFF667eea) : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : (isSelected ? const Color(0xFF667eea) : Colors.grey[800]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected && !isLogout,
      selectedTileColor: isLogout ? null : const Color(0xFF667eea).withOpacity(0.1),
      onTap: () {
        if (isLogout) {
          _logout();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildFaultTracking();
      case 2:
        return _buildPerformance();
      default:
        return _buildDashboard();
    }
  }

    Widget _buildDashboard() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih başlığı
          Row(
            children: [
              Icon(Icons.calendar_today, color: const Color(0xFF667eea)),
              const SizedBox(width: 8),
              Text(
                _formatDate(today),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // İstatistik kartları
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .snapshots(),
            builder: (context, snapshot) {
              int todayNewReports = 0;
              int todayCompletedReports = 0;
              int pendingReports = 0;
              int inProgressReports = 0;

              if (snapshot.hasData) {
                final reports = snapshot.data!.docs;
                
                for (var doc in reports) {
                  final report = FaultReportModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                  );
                  
                  final faultStatus = FaultStatus.fromValue(report.status);
                  final reportDate = report.createdAt;
                  final isToday = reportDate.isAfter(todayStart) && reportDate.isBefore(todayEnd);
                  
                  if (faultStatus.category == 'completed') {
                    if (isToday) {
                      todayCompletedReports++;
                    }
                  } else if (faultStatus.category == 'pending') {
                    pendingReports++;
                  } else if (faultStatus.category == 'in_progress') {
                    inProgressReports++;
                  }
                  
                  // Bugün gelen arızaları say
                  if (isToday) {
                    todayNewReports++;
                  }
                }
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Bugün Gelen',
                      value: todayNewReports.toString(),
                      icon: Icons.today,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Bugün Tamamlanan',
                      value: todayCompletedReports.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Bekleyen',
                      value: pendingReports.toString(),
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'İşlemde',
                      value: inProgressReports.toString(),
                      icon: Icons.engineering,
                      color: Colors.purple,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // Günlük arızalar
          const Text(
            'Bugün Gelen Arızalar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data?.docs ?? [];

                if (reports.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz arıza bildirimi bulunmuyor',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Bugün gelen arızaları filtrele
                final todayReports = reports.where((doc) {
                  final report = FaultReportModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                  );
                  final reportDate = report.createdAt;
                  final isToday = reportDate.isAfter(todayStart) && reportDate.isBefore(todayEnd);
                  return isToday;
                }).toList();

                if (todayReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.today, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Bugün henüz arıza bildirimi yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: todayReports.length,
                  itemBuilder: (context, index) {
                    final report = FaultReportModel.fromMap(
                      todayReports[index].data() as Map<String, dynamic>,
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getPriorityColor(report.priority),
                          child: Text(
                            report.priority[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(report.title),
                        subtitle: Text(
                          '${report.category} • ${report.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(report.createdAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColorFromString(report.status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getStatusText(report.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showReportDetails(report);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaultTracking() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arıza Takibi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Geçmiş arızaları temizle butonu
              ElevatedButton.icon(
                onPressed: () => _showClearHistoryDialog(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Geçmiş Arızaları Temizle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF667eea),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(text: 'Bekleyen'),
                Tab(text: 'İşlemde'),
                Tab(text: 'Tamamlandı'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaultList(['pending']), // Bekleyen
                _buildFaultList(['in_progress', 'inprogress']), // İşlemde
                _buildFaultList(['completed']), // Tamamlandı
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaultList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Bir hata oluştu'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data?.docs ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Text(
              'Henüz arıza bildirimi bulunmuyor',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Durum filtreleme - Kategori bazında
        final filteredReports = reports.where((doc) {
          final report = FaultReportModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );
          final faultStatus = FaultStatus.fromValue(report.status);
          return statuses.contains(faultStatus.category);
        }).toList();

        if (filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu kategoride arıza bulunmuyor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Kategorilere göre grupla
        final groupedReports = <String, List<FaultReportModel>>{};
        for (var doc in filteredReports) {
          final report = FaultReportModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );
          if (!groupedReports.containsKey(report.category)) {
            groupedReports[report.category] = [];
          }
          groupedReports[report.category]!.add(report);
        }

        return ListView.builder(
          itemCount: groupedReports.length,
          itemBuilder: (context, index) {
            final category = groupedReports.keys.elementAt(index);
            final categoryReports = groupedReports[category]!;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori başlığı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: const Color(0xFF667eea),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categoryReports.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arıza listesi
                  ...categoryReports.map((report) => 
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPriorityColor(report.priority),
                        child: Text(
                          report.priority[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(report.title),
                      subtitle: Text(
                        '${report.location} • ${_formatDate(report.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColorFromString(report.status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getStatusText(report.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        _showReportDetails(report);
                      },
                    ),
                  ).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Su Kesintisi':
        return Icons.water_drop;
      case 'Kaçak':
        return Icons.water_drop_outlined;
      case 'Kötü Koku':
        return Icons.air;
      case 'Sayaç':
        return Icons.speed;
      case 'Vana':
        return Icons.settings;
      case 'Kanalizasyon':
        return Icons.engineering;
      default:
        return Icons.report_problem;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'yüksek':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'düşük':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }



  String _getStatusText(String status) {
    final faultStatus = FaultStatus.fromValue(status);
    return faultStatus.title;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _logout() async {
    // Session'ı temizle
    await AdminSessionService.clearAdminSession();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WebPersonnelLoginScreen(),
        ),
      );
    }
  }

  void _showReportDetails(FaultReportModel report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.report_problem,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Takip No: ${report.trackingNumber}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modern Status Display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColorFromString(report.status).withOpacity(0.1),
                              _getStatusColorFromString(report.status).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColorFromString(report.status).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColorFromString(report.status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getStatusIcon(report.status),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mevcut Durum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getStatusText(report.status),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColorFromString(report.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Clean Details Section
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernDetailItem(
                              icon: Icons.category,
                              title: 'Kategori',
                              value: report.category,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernDetailItem(
                              icon: Icons.priority_high,
                              title: 'Öncelik',
                              value: report.priority,
                              color: _getPriorityColor(report.priority),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernDetailItem(
                              icon: Icons.location_on,
                              title: 'Konum',
                              value: report.location,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernDetailItem(
                              icon: Icons.calendar_today,
                              title: 'Tarih',
                              value: _formatDate(report.createdAt),
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      // Description
                      if (report.description.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildModernSection(
                          title: 'Açıklama',
                          icon: Icons.description,
                          child: Text(
                            report.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                      
                      // Contact Info
                      const SizedBox(height: 24),
                      _buildModernSection(
                        title: 'İletişim Bilgileri',
                        icon: Icons.contact_phone,
                        child: Column(
                          children: [
                            _buildContactItem(
                              icon: Icons.person,
                              label: 'Oluşturan',
                              value: report.contactName,
                            ),
                            if (report.contactPhone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildContactItem(
                                icon: Icons.phone,
                                label: 'Telefon',
                                value: report.contactPhone,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Status History Timeline
                      const SizedBox(height: 24),
                      FutureBuilder<FaultTrackingModel?>(
                        future: FaultTrackingService.getFaultTracking(report.id),
                        builder: (context, snapshot) {
                          final tracking = snapshot.data;
                          if (tracking == null || tracking.statusHistory.isEmpty) {
                            return const SizedBox();
                          }
                          
                          return _buildModernSection(
                            title: 'Durum Geçmişi',
                            icon: Icons.timeline,
                            child: _buildStatusTimeline(tracking.statusHistory),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Modern Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Kapat',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showUpdateStatusDialog(report);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Durumu Güncelle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF667eea),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(List<FaultStatusUpdate> statusHistory) {
    return Column(
      children: statusHistory.asMap().entries.map((entry) {
        final index = entry.key;
        final update = entry.value;
        final isLast = index == statusHistory.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStatusColor(update.status),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(update.status).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(update.status).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(update.status).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(update.status.value),
                          size: 18,
                          color: _getStatusColor(update.status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          update.status.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(update.status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(update.updatedAt)} • ${update.updatedByName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (update.note != null && update.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          update.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showUpdateStatusDialog(FaultReportModel report) {
    final _noteController = TextEditingController();
    final currentStatus = FaultStatus.fromValue(report.status);
    final currentStatusColor = _getStatusColorFromString(report.status);
    FaultStatus selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arıza Durumunu Güncelle'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basitleştirilmiş mevcut durum göstergesi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: currentStatusColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: currentStatusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mevcut Durum: ${currentStatus.title}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: currentStatusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Basitleştirilmiş hızlı durum seçenekleri
              _buildQuickStatusOptions(currentStatus, (status) {
                selectedStatus = status;
              }),
              const SizedBox(height: 20),
              
              // Basitleştirilmiş dropdown
              const Text(
                'Durum Seçin:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<FaultStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: FaultStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  border: OutlineInputBorder(),
                  hintText: 'Durum hakkında ek bilgi...',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Loading state göster
              final navigator = Navigator.of(context);
              try {
                await _updateReportStatus(
                  report.id,
                  selectedStatus,
                  _noteController.text.trim(),
                );
                navigator.pop();
              } catch (e) {
                // Hata durumunda dialog'u kapatma
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReportStatus(String reportId, FaultStatus status, String note) async {
    // Loading state için indicator göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Arıza bilgilerini al (bildirim için)
      final reportDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .get();
      
      if (!reportDoc.exists) {
        throw Exception('Arıza raporu bulunamadı');
      }
      
      final report = FaultReportModel.fromMap(
        reportDoc.data() as Map<String, dynamic>,
      );
      
                           // Durum güncelleme mantığı
        String finalStatus = status.value;
        if (report.status == 'pending' && status.value == 'pending') {
          finalStatus = 'reviewing'; // İlk güncelleme → İnceleniyor
        }
       
       // Firestore'da arıza durumunu güncelle
       await FirebaseFirestore.instance
           .collection('reports')
           .doc(reportId)
           .update({
         'status': finalStatus,
         'lastUpdated': DateTime.now(),
         'updatedBy': widget.personnel.uid,
         'updatedByName': widget.personnel.display,
       });
      
             // Tracking verilerini de güncelle
       final finalFaultStatus = finalStatus == 'in_progress' ? FaultStatus.inProgress : 
                                finalStatus == 'completed' ? FaultStatus.completed : 
                                FaultStatus.pending;
       
       await FaultTrackingService.updateFaultStatus(
         faultReportId: reportId,
         newStatus: finalFaultStatus,
         updatedBy: widget.personnel.uid,
         updatedByName: widget.personnel.display,
         note: note.isEmpty ? null : note,
       );
      
             // Bildirim oluştur
       await NotificationService.createFaultUpdateNotification(
         faultId: reportId,
         faultTitle: report.title,
         newStatus: finalStatus,
         updatedBy: widget.personnel.display,
       );
      
      // Loading dialog'unu kapat
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
                                   // Arıza durumuna göre hangi tab'da olduğunu belirle
          int targetTabIndex = 0; // Varsayılan olarak Bekleyen
          
          final faultStatus = FaultStatus.fromValue(finalStatus);
          if (faultStatus.category == 'in_progress') {
            targetTabIndex = 1; // İşlemde
          } else if (faultStatus.category == 'completed') {
            targetTabIndex = 2; // Tamamlandı
          }
        
        // Tab'ı değiştir
        _tabController.animateTo(targetTabIndex);
        
                                   final statusTitle = faultStatus.title;
         
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Arıza durumu "$statusTitle" olarak güncellendi'),
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 2),
           ),
         );
      }
    } catch (e) {
      // Loading dialog'unu kapat
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      rethrow; // Hata dialog'da yakalanabilsin
    }
  }

  Color _getStatusColor(FaultStatus status) {
    switch (status) {
      case FaultStatus.pending:
        return Colors.orange;
      case FaultStatus.reviewing:
        return Colors.blue;
      case FaultStatus.teamAssigned:
        return Colors.purple;
      case FaultStatus.onTheWay:
        return Colors.indigo;
      case FaultStatus.onSite:
        return Colors.teal;
      case FaultStatus.inProgress:
        return Colors.amber;
      case FaultStatus.testing:
        return Colors.cyan;
      case FaultStatus.resolved:
        return Colors.green;
      case FaultStatus.completed:
        return Colors.green;
    }
  }

  Color _getStatusColorFromString(String status) {
    final faultStatus = FaultStatus.fromValue(status);
    return _getStatusColor(faultStatus);
  }

  Widget _buildQuickStatusOptions(FaultStatus currentStatus, Function(FaultStatus) onStatusSelected) {
    final nextSteps = _getNextPossibleSteps(currentStatus);
    
    if (nextSteps.isEmpty) {
      return const SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı Durum Seçenekleri:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nextSteps.map((status) => 
            InkWell(
              onTap: () => onStatusSelected(status),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _getStatusColor(status)),
                  borderRadius: BorderRadius.circular(20),
                  color: _getStatusColor(status).withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }



    List<FaultStatus> _getNextPossibleSteps(FaultStatus currentStatus) {
    switch (currentStatus) {
      case FaultStatus.pending:
        return [FaultStatus.reviewing, FaultStatus.teamAssigned, FaultStatus.completed];
      case FaultStatus.reviewing:
        return [FaultStatus.teamAssigned, FaultStatus.onTheWay, FaultStatus.completed];
      case FaultStatus.teamAssigned:
        return [FaultStatus.onTheWay, FaultStatus.onSite, FaultStatus.completed];
      case FaultStatus.onTheWay:
        return [FaultStatus.onSite, FaultStatus.inProgress, FaultStatus.completed];
      case FaultStatus.onSite:
        return [FaultStatus.inProgress, FaultStatus.testing, FaultStatus.completed];
      case FaultStatus.inProgress:
        return [FaultStatus.testing, FaultStatus.resolved, FaultStatus.completed];
      case FaultStatus.testing:
        return [FaultStatus.resolved, FaultStatus.completed];
      case FaultStatus.resolved:
        return [FaultStatus.completed];
      case FaultStatus.completed:
        return [];
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmiş Arızaları Temizle'),
        content: const Text(
          'Tamamlanmış eski arızaları kalıcı olarak silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem geri alınamaz ve tüm geçmiş arıza verilerini silecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearOldCompletedFaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearOldCompletedFaults() async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 30 günden eski tamamlanmış arızaları bul
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Önce tüm tamamlanmış arızaları al
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'completed')
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // Loading'i kapat
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Temizlenecek eski arıza bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Client-side filtreleme ile 30 günden eski olanları bul
      final oldFaults = <QueryDocumentSnapshot>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'];
        
        DateTime faultDate;
        if (createdAt is Timestamp) {
          faultDate = createdAt.toDate();
        } else if (createdAt is DateTime) {
          faultDate = createdAt;
        } else {
          // Eğer createdAt yoksa veya geçersizse, varsayılan olarak eski kabul et
          faultDate = DateTime.now().subtract(const Duration(days: 31));
        }
        
        if (faultDate.isBefore(thirtyDaysAgo)) {
          oldFaults.add(doc);
        }
      }

      if (oldFaults.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // Loading'i kapat
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Temizlenecek eski arıza bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Batch işlemi ile sil
      final batch = FirebaseFirestore.instance.batch();
      final faultIds = <String>[];

      for (var doc in oldFaults) {
        batch.delete(doc.reference);
        faultIds.add(doc.id);
      }

      await batch.commit();

      // Tracking verilerini de sil
      for (final faultId in faultIds) {
        try {
          await FaultTrackingService.deleteFaultTracking(faultId);
        } catch (e) {
          // Tracking silme hatası kritik değil, devam et
          print('Tracking silme hatası: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${faultIds.length} adet eski arıza başarıyla temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Temizleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPerformance() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 32,
                color: const Color(0xFF667eea),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performans Analizi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz performans verisi bulunmuyor',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildPerformanceContent(snapshot.data!.docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceContent(List<QueryDocumentSnapshot> docs) {
    // Performans verilerini hesapla
    final performanceData = _calculatePerformanceData(docs);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Genel İstatistikler
          _buildPerformanceOverview(performanceData),
          const SizedBox(height: 30),
          
          // Detaylı Analiz
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol kolon - Çözüm süreleri
              Expanded(
                flex: 2,
                child: _buildResolutionTimes(performanceData),
              ),
              const SizedBox(width: 20),
              
              // Sağ kolon - Personel performansı
              Expanded(
                flex: 2,
                child: _buildPersonnelPerformance(performanceData),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculatePerformanceData(List<QueryDocumentSnapshot> docs) {
    final completedFaults = <Map<String, dynamic>>[];
    final personnelStats = <String, Map<String, dynamic>>{};
    final resolutionTimes = <int>[];
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final report = FaultReportModel.fromMap(data);
      
      if (report.status == 'completed' && data['updatedBy'] != null) {
        final createdAt = data['createdAt'];
        final lastUpdated = data['lastUpdated'];
        
        if (createdAt != null && lastUpdated != null) {
          DateTime createDate;
          DateTime updateDate;
          
          if (createdAt is Timestamp) {
            createDate = createdAt.toDate();
          } else if (createdAt is DateTime) {
            createDate = createdAt;
          } else if (createdAt is String) {
            try {
              createDate = DateTime.parse(createdAt);
            } catch (e) {
              continue; // Geçersiz tarih formatı, bu arızayı atla
            }
          } else {
            continue; // Geçersiz tarih tipi, bu arızayı atla
          }
          
          if (lastUpdated is Timestamp) {
            updateDate = lastUpdated.toDate();
          } else if (lastUpdated is DateTime) {
            updateDate = lastUpdated;
          } else if (lastUpdated is String) {
            try {
              updateDate = DateTime.parse(lastUpdated);
            } catch (e) {
              continue; // Geçersiz tarih formatı, bu arızayı atla
            }
          } else {
            continue; // Geçersiz tarih tipi, bu arızayı atla
          }
          
          final resolutionHours = updateDate.difference(createDate).inHours;
          resolutionTimes.add(resolutionHours);
          
          final updatedBy = data['updatedBy'] as String;
          final updatedByName = data['updatedByName'] as String? ?? 'Bilinmeyen';
          
          // Personel istatistiklerini güncelle
          personnelStats[updatedBy] ??= {
            'name': updatedByName,
            'completedCount': 0,
            'totalResolutionTime': 0,
            'resolutionTimes': <int>[],
          };
          
          personnelStats[updatedBy]!['completedCount']++;
          personnelStats[updatedBy]!['totalResolutionTime'] += resolutionHours;
          (personnelStats[updatedBy]!['resolutionTimes'] as List<int>).add(resolutionHours);
          
          completedFaults.add({
            'report': report,
            'resolutionTime': resolutionHours,
            'updatedBy': updatedByName,
            'createdAt': createDate,
            'completedAt': updateDate,
          });
        }
      }
    }
    
    // Ortalama çözüm sürelerini hesapla
    for (var stats in personnelStats.values) {
      final times = stats['resolutionTimes'] as List<int>;
      if (times.isNotEmpty) {
        stats['averageResolutionTime'] = times.reduce((a, b) => a + b) / times.length;
        stats['minResolutionTime'] = times.reduce((a, b) => a < b ? a : b);
        stats['maxResolutionTime'] = times.reduce((a, b) => a > b ? a : b);
      }
    }
    
    return {
      'completedFaults': completedFaults,
      'personnelStats': personnelStats,
      'resolutionTimes': resolutionTimes,
      'totalCompleted': completedFaults.length,
      'averageResolutionTime': resolutionTimes.isEmpty ? 0 : resolutionTimes.reduce((a, b) => a + b) / resolutionTimes.length,
    };
  }

  Widget _buildPerformanceOverview(Map<String, dynamic> data) {
    final totalCompleted = data['totalCompleted'] as int;
    final averageTime = data['averageResolutionTime'] as double;
    final personnelCount = (data['personnelStats'] as Map).length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Genel Performans Özeti',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    title: 'Toplam Tamamlanan',
                    value: totalCompleted.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceCard(
                    title: 'Ortalama Çözüm Süresi',
                    value: '${averageTime.toStringAsFixed(1)} saat',
                    icon: Icons.timer,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceCard(
                    title: 'Aktif Personel',
                    value: personnelCount.toString(),
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceCard(
                    title: 'Günlük Ortalama',
                    value: '${(averageTime / 24).toStringAsFixed(1)} gün',
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionTimes(Map<String, dynamic> data) {
    final resolutionTimes = data['resolutionTimes'] as List<int>;
    
    // Çözüm süresi kategorilerini hesapla
    int under24h = 0;
    int under3days = 0;
    int under7days = 0;
    int over7days = 0;
    
    for (var hours in resolutionTimes) {
      if (hours <= 24) {
        under24h++;
      } else if (hours <= 72) {
        under3days++;
      } else if (hours <= 168) {
        under7days++;
      } else {
        over7days++;
      }
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Çözüm Süreleri Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTimeDistributionBar('24 Saat İçinde', under24h, resolutionTimes.length, Colors.green),
            const SizedBox(height: 12),
            _buildTimeDistributionBar('3 Gün İçinde', under3days, resolutionTimes.length, Colors.lightGreen),
            const SizedBox(height: 12),
            _buildTimeDistributionBar('7 Gün İçinde', under7days, resolutionTimes.length, Colors.orange),
            const SizedBox(height: 12),
            _buildTimeDistributionBar('7 Günden Fazla', over7days, resolutionTimes.length, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDistributionBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$count (${percentage.toStringAsFixed(1)}%)', 
                 style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonnelPerformance(Map<String, dynamic> data) {
    final personnelStats = data['personnelStats'] as Map<String, Map<String, dynamic>>;
    
    if (personnelStats.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Personel Performansı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Henüz personel performans verisi bulunmuyor',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    // Personeli ortalama çözüm süresine göre sırala
    final sortedPersonnel = personnelStats.entries.toList()
      ..sort((a, b) => (a.value['averageResolutionTime'] as double)
          .compareTo(b.value['averageResolutionTime'] as double));
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personel Performansı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ...sortedPersonnel.map((entry) {
              final stats = entry.value;
              final name = stats['name'] as String;
              final completedCount = stats['completedCount'] as int;
              final avgTime = stats['averageResolutionTime'] as double;
              final minTime = stats['minResolutionTime'] as int;
              final maxTime = stats['maxResolutionTime'] as int;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF667eea),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$completedCount arıza tamamlandı',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPerformanceColor(avgTime).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${avgTime.toStringAsFixed(1)}h',
                              style: TextStyle(
                                color: _getPerformanceColor(avgTime),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPerformanceMetric(
                              'En Hızlı',
                              '${minTime}h',
                              Icons.flash_on,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildPerformanceMetric(
                              'Ortalama',
                              '${avgTime.toStringAsFixed(1)}h',
                              Icons.timeline,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildPerformanceMetric(
                              'En Yavaş',
                              '${maxTime}h',
                              Icons.schedule,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getPerformanceColor(double avgHours) {
    if (avgHours <= 24) return Colors.green;
    if (avgHours <= 72) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'reviewing':
        return Icons.search;
      case 'teamAssigned':
        return Icons.people;
      case 'onTheWay':
        return Icons.directions_car;
      case 'onSite':
        return Icons.location_on;
      case 'in_progress':
        return Icons.build;
      case 'testing':
        return Icons.science;
      case 'resolved':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }
}
