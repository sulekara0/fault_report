import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';
import '../models/announcement_model.dart';
import '../models/fault_report_model.dart';
import '../services/admin_session_service.dart';
import 'web_admin_login_screen.dart';

class WebAdminDashboardScreen extends StatefulWidget {
  final AdminModel admin;

  const WebAdminDashboardScreen({super.key, required this.admin});

  @override
  State<WebAdminDashboardScreen> createState() => _WebAdminDashboardScreenState();
}

class _WebAdminDashboardScreenState extends State<WebAdminDashboardScreen> {
  int _selectedIndex = 0;
  
  // Local personel listesi (Firebase yerine)
  List<AdminModel> _personnelList = [];

  @override
  void initState() {
    super.initState();
    _loadPersonnelList();
  }

  // Personel listesini session'dan yükle
  Future<void> _loadPersonnelList() async {
    try {
      print('Personel listesi yükleniyor...');
      // Önce Firebase'den personelleri çek
      final firebasePersonnel = await FirebaseFirestore.instance
          .collection('personnel')
          .get();
      
      print('Firebase\'den ${firebasePersonnel.docs.length} personel bulundu');
      
      List<AdminModel> personnelList = [];
      
      for (var doc in firebasePersonnel.docs) {
        try {
          final data = doc.data();
          print('Personel verisi: $data');
          final personnel = AdminModel.fromMap(data);
          personnelList.add(personnel);
          print('Personel eklendi: ${personnel.display} (${personnel.uid})');
        } catch (e) {
          print('Personel verisi okuma hatası: $e');
        }
      }
      
      print('Toplam ${personnelList.length} personel yüklendi');
      
      // Local storage'a kaydet
      await AdminSessionService.savePersonnelList(personnelList);
      
      setState(() {
        _personnelList = personnelList;
      });
      
      print('Personel listesi state\'e kaydedildi: ${_personnelList.length} personel');
    } catch (e) {
      print('Personel listesi yükleme hatası: $e');
      // Firebase hatası durumunda local'den yükle
      final personnelList = await AdminSessionService.getPersonnelList();
      setState(() {
        _personnelList = personnelList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Paneli',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                // Admin bilgileri
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
                          Icons.admin_panel_settings,
                          size: 30,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.admin.display,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.admin.role == 'admin' ? 'Yönetici' : 'Personel',
                        style: const TextStyle(
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
                      if (widget.admin.role == 'admin') ...[
                        _buildMenuItem(
                          icon: Icons.people,
                          title: 'Personel Yönetimi',
                          index: 1,
                        ),
                        _buildMenuItem(
                          icon: Icons.announcement,
                          title: 'Duyuru Yönetimi',
                          index: 2,
                        ),
                      ],
                      _buildMenuItem(
                        icon: Icons.report_problem,
                        title: 'Arıza Takibi',
                        index: 3,
                      ),
                      _buildMenuItem(
                        icon: Icons.analytics,
                        title: 'Personel Performansı',
                        index: 4,
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
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF667eea) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF667eea) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF667eea).withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return widget.admin.role == 'admin' 
            ? _buildPersonnelManagement() 
            : _buildAccessDenied();
      case 2:
        return widget.admin.role == 'admin' 
            ? _buildAnnouncementManagement() 
            : _buildAccessDenied();
      case 3:
        return _buildFaultTracking();
      case 4:
        return _buildPersonnelPerformance();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Test personeli ekleme butonu
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addTestPersonnel,
                icon: const Icon(Icons.person_add),
                label: const Text('Test Personeli Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _loadPersonnelList,
                icon: const Icon(Icons.refresh),
                label: const Text('Personel Listesini Yenile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // İstatistik kartları
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Toplam Arıza',
                  value: '0',
                  icon: Icons.report_problem,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  title: 'Bekleyen Arıza',
                  value: '0',
                  icon: Icons.pending,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  title: 'Çözülen Arıza',
                  value: '0',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  title: 'Aktif Duyuru',
                  value: '0',
                  icon: Icons.announcement,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Son arızalar
          const Text(
            'Son Arızalar',
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
                  .limit(10)
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

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = FaultReportModel.fromMap(
                      reports[index].data() as Map<String, dynamic>,
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
                        trailing: Text(
                          _formatDate(report.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelManagement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personel Yönetimi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddPersonnelDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Personel Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: _personnelList.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz personel bulunmuyor',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                  itemCount: _personnelList.length,
                  itemBuilder: (context, index) {
                    final personnel = _personnelList[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF667eea),
                          child: Text(
                            personnel.display[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(personnel.display),
                        subtitle: Text(personnel.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Aktif/Pasif durumu göstergesi (sadece görüntüleme)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: personnel.active ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                personnel.active ? 'Aktif' : 'Pasif',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditPersonnelDialog(personnel);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deletePersonnel(personnel);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementManagement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duyuru Yönetimi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddAnnouncementDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Duyuru Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final announcements = snapshot.data?.docs ?? [];

                if (announcements.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz duyuru bulunmuyor',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = AnnouncementModel.fromMap(
                      announcements[index].data() as Map<String, dynamic>,
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getPriorityColor(announcement.priority),
                          child: Icon(
                            Icons.announcement,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(announcement.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(announcement.content),
                            const SizedBox(height: 5),
                            Text(
                              'Oluşturan: ${announcement.createdBy} • ${_formatDate(announcement.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: announcement.isActive,
                              onChanged: (value) {
                                _updateAnnouncementStatus(announcement.id, value);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteAnnouncement(announcement);
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
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

  Widget _buildFaultTracking() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arıza Takibi ve Atama',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Filtreler
          Row(
            children: [
              DropdownButton<String>(
                value: 'all',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tümü')),
                  DropdownMenuItem(value: 'unassigned', child: Text('Atanmamış')),
                  DropdownMenuItem(value: 'assigned', child: Text('Atanmış')),
                  DropdownMenuItem(value: 'pending', child: Text('Bekleyen')),
                  DropdownMenuItem(value: 'in_progress', child: Text('İşlemde')),
                  DropdownMenuItem(value: 'completed', child: Text('Tamamlanan')),
                ],
                onChanged: (value) {
                  // TODO: Filtre implementasyonu
                },
              ),
              const SizedBox(width: 20),
              DropdownButton<String>(
                value: 'all',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tüm Kategoriler')),
                  DropdownMenuItem(value: 'Su Kesintisi', child: Text('Su Kesintisi')),
                  DropdownMenuItem(value: 'Kaçak', child: Text('Kaçak')),
                  DropdownMenuItem(value: 'Kötü Koku', child: Text('Kötü Koku')),
                ],
                onChanged: (value) {
                  // TODO: Kategori filtresi
                },
              ),
            ],
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

                                 return ListView.builder(
                   itemCount: reports.length,
                   itemBuilder: (context, index) {
                     final report = FaultReportModel.fromMap(
                       reports[index].data() as Map<String, dynamic>,
                     );
                     
                     return Card(
                       margin: const EdgeInsets.only(bottom: 10),
                       child: ExpansionTile(
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
                         subtitle: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               '${report.category} • ${report.location} • ${_formatDate(report.createdAt)}',
                             ),
                             if (report.assignedTo != null)
                               Text(
                                 'Atanan: ${report.assignedByName}',
                                 style: TextStyle(
                                   color: Colors.green[600],
                                   fontWeight: FontWeight.bold,
                                 ),
                               )
                             else
                               Text(
                                 'Atanmamış',
                                 style: TextStyle(
                                   color: Colors.orange[600],
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                           ],
                         ),
                         children: [
                           Padding(
                             padding: const EdgeInsets.all(16),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('Açıklama: ${report.description}'),
                                 const SizedBox(height: 10),
                                 Text('Takip No: ${report.trackingNumber}'),
                                 const SizedBox(height: 10),
                                 Row(
                                   children: [
                                     Container(
                                       padding: const EdgeInsets.symmetric(
                                         horizontal: 12,
                                         vertical: 6,
                                       ),
                                       decoration: BoxDecoration(
                                         color: _getStatusColor(report.status),
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: Text(
                                         'Durum: ${_getStatusText(report.status)}',
                                         style: const TextStyle(
                                           color: Colors.white,
                                           fontWeight: FontWeight.bold,
                                           fontSize: 12,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 10),
                                 
                                 // Atama durumu
                                 if (report.assignedTo != null) ...[
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                                       color: Colors.green.withOpacity(0.1),
                                       borderRadius: BorderRadius.circular(8),
                                       border: Border.all(
                                         color: Colors.green.withOpacity(0.3),
                                       ),
                                     ),
                                     child: Row(
                                       children: [
                                         Icon(
                                           Icons.person,
                                           color: Colors.green[600],
                                           size: 16,
                                         ),
                                         const SizedBox(width: 8),
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Text(
                                                 'Atanan Personel: ${report.assignedByName}',
                                                 style: TextStyle(
                                                   color: Colors.green[600],
                                                   fontWeight: FontWeight.bold,
                                                 ),
                                               ),
                                               if (report.assignedAt != null)
                                                 Text(
                                                   'Atama Tarihi: ${_formatDate(report.assignedAt!)}',
                                                   style: TextStyle(
                                                     color: Colors.green[600],
                                                     fontSize: 12,
                                                   ),
                                                 ),
                                             ],
                                           ),
                                         ),
                                         IconButton(
                                           icon: const Icon(Icons.edit, color: Colors.blue),
                                           onPressed: () => _showAssignFaultDialog(report),
                                           tooltip: 'Personel Değiştir',
                                         ),
                                       ],
                                     ),
                                   ),
                                 ] else ...[
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                                       color: Colors.orange.withOpacity(0.1),
                                       borderRadius: BorderRadius.circular(8),
                                       border: Border.all(
                                         color: Colors.orange.withOpacity(0.3),
                                       ),
                                     ),
                                     child: Row(
                                       children: [
                                         Icon(
                                           Icons.warning,
                                           color: Colors.orange[600],
                                           size: 16,
                                         ),
                                         const SizedBox(width: 8),
                                         Expanded(
                                           child: Text(
                                             'Bu arıza henüz bir personel atanmamış',
                                             style: TextStyle(
                                               color: Colors.orange[600],
                                               fontWeight: FontWeight.bold,
                                             ),
                                           ),
                                         ),
                                         ElevatedButton.icon(
                                           onPressed: () => _showAssignFaultDialog(report),
                                           icon: const Icon(Icons.person_add),
                                           label: const Text('Personel Ata'),
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: Colors.orange,
                                             foregroundColor: Colors.white,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ],
                                 
                                 const SizedBox(height: 10),
                                 Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: Colors.blue.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(
                                       color: Colors.blue.withOpacity(0.3),
                                     ),
                                   ),
                                   child: Row(
                                     children: [
                                       Icon(
                                         Icons.info_outline,
                                         color: Colors.blue[600],
                                         size: 16,
                                       ),
                                       const SizedBox(width: 8),
                                       Expanded(
                                         child: Text(
                                           'Arıza durumu güncellemeleri personel tarafından yapılır',
                                           style: TextStyle(
                                             color: Colors.blue[600],
                                             fontSize: 12,
                                           ),
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
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

  Widget _buildAccessDenied() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'Erişim Reddedildi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Bu sayfaya erişim yetkiniz bulunmuyor.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'yüksek':
      case 'urgent':
        return Colors.red;
      case 'orta':
      case 'important':
        return Colors.orange;
      case 'düşük':
      case 'normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _logout() async {
    // Admin session'ını temizle
    await AdminSessionService.clearAdminSession();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WebAdminLoginScreen(),
        ),
      );
    }
  }

  void _showReportDetails(FaultReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kategori: ${report.category}'),
              Text('Öncelik: ${report.priority}'),
              Text('Konum: ${report.location}'),
              Text('Açıklama: ${report.description}'),
              Text('Takip No: ${report.trackingNumber}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Durum: '),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(report.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Oluşturan: ${report.contactName}'),
              Text('Tarih: ${_formatDate(report.createdAt)}'),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arıza durumu güncellemeleri personel panelinden yapılır',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showAddPersonnelDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _phoneController = TextEditingController();
    bool _isCreating = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personel Ekle'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon (Opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre gerekli';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          StatefulBuilder(
            builder: (context, setState) => ElevatedButton(
              onPressed: _isCreating ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() {
                  _isCreating = true;
                });

                try {
                  // E-posta kontrolü - aynı e-posta ile personel var mı kontrol et
                  final emailExists = _personnelList.any((p) => p.email == _emailController.text.trim());
                  if (emailExists) {
                    throw Exception('Bu e-posta adresi ile zaten bir personel kayıtlı');
                  }

                  // Firebase'de de kontrol et
                  final firebaseQuery = await FirebaseFirestore.instance
                      .collection('personnel')
                      .where('email', isEqualTo: _emailController.text.trim())
                      .get();
                  
                  if (firebaseQuery.docs.isNotEmpty) {
                    throw Exception('Bu e-posta adresi ile zaten bir personel kayıtlı');
                  }

                  // Personel oluştur
                  final personnel = AdminModel(
                    uid: 'personnel_${DateTime.now().millisecondsSinceEpoch}',
                    email: _emailController.text.trim(),
                    display: _nameController.text.trim(),
                    role: 'personel',
                    createdAt: DateTime.now(),
                    active: true,
                    phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                    createdBy: widget.admin.uid,
                  );

                  // Firebase'e kaydet
                  await FirebaseFirestore.instance
                      .collection('personnel')
                      .doc(personnel.uid)
                      .set({
                    ...personnel.toMap(),
                    'password': _passwordController.text.trim(), // Şifreyi de kaydet
                  });

                  // Local listeye ekle
                  _personnelList.add(personnel);
                  
                  // Session'a kaydet
                  await AdminSessionService.savePersonnelList(_personnelList);

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Personel başarıyla eklendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Ana widget'ı yenile
                    this.setState(() {});
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isCreating = false;
                    });
                  }
                }
              },
              child: _isCreating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ekle'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAnnouncementDialog() {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _contentController = TextEditingController();
    final _locationController = TextEditingController();
    String _selectedPriority = 'normal';
    bool _isCreating = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyuru Ekle'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Başlık gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'İçerik gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Bölge (Opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Öncelik',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'important', child: Text('Önemli')),
                    DropdownMenuItem(value: 'urgent', child: Text('Acil')),
                  ],
                  onChanged: (value) {
                    _selectedPriority = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          StatefulBuilder(
            builder: (context, setState) => ElevatedButton(
              onPressed: _isCreating ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() {
                  _isCreating = true;
                });

                try {
                  final announcement = AnnouncementModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text.trim(),
                    content: _contentController.text.trim(),
                    createdBy: widget.admin.display,
                    createdAt: DateTime.now(),
                    location: _locationController.text.trim().isEmpty 
                        ? null 
                        : _locationController.text.trim(),
                    priority: _selectedPriority,
                    isActive: true,
                  );

                  await FirebaseFirestore.instance
                      .collection('announcements')
                      .doc(announcement.id)
                      .set(announcement.toMap());

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Duyuru başarıyla eklendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isCreating = false;
                    });
                  }
                }
              },
              child: _isCreating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ekle'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPersonnelDialog(AdminModel personnel) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: personnel.display);
    final _emailController = TextEditingController(text: personnel.email);
    final _phoneController = TextEditingController(text: personnel.phone ?? '');
    final _passwordController = TextEditingController();
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personel Düzenle'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  // Aynı e-posta kontrolü (kendisi hariç)
                  final emailExists = _personnelList.any((p) => 
                      p.email == value.trim() && p.uid != personnel.uid);
                  if (emailExists) {
                    return 'Bu e-posta adresi zaten kullanılıyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon (Opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Opsiyonel)',
                  border: OutlineInputBorder(),
                  hintText: 'Boş bırakılırsa değiştirilmez',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          StatefulBuilder(
            builder: (context, setState) => ElevatedButton(
              onPressed: _isUpdating ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() {
                  _isUpdating = true;
                });

                try {
                  // Firebase'de güncelle
                  Map<String, dynamic> updateData = {
                    'display': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                    'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                  };
                  
                  // Şifre değiştirilecekse ekle
                  if (_passwordController.text.trim().isNotEmpty) {
                    updateData['password'] = _passwordController.text.trim();
                  }
                  
                  await FirebaseFirestore.instance
                      .collection('personnel')
                      .doc(personnel.uid)
                      .update(updateData);

                  // Personeli güncelle
                  final updatedPersonnel = personnel.copyWith(
                    display: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                  );

                  // Local listede güncelle
                  final index = _personnelList.indexWhere((p) => p.uid == personnel.uid);
                  if (index != -1) {
                    _personnelList[index] = updatedPersonnel;
                    
                    // Session'a kaydet
                    await AdminSessionService.savePersonnelList(_personnelList);

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Personel başarıyla güncellendi!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Ana widget'ı yenile
                      this.setState(() {});
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isUpdating = false;
                    });
                  }
                }
              },
              child: _isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Güncelle'),
            ),
          ),
        ],
      ),
    );
  }



  void _deletePersonnel(AdminModel personnel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Sil'),
        content: Text('${personnel.display} adlı personeli silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Firebase'den personeli sil
        await FirebaseFirestore.instance
            .collection('personnel')
            .doc(personnel.uid)
            .delete();
        
        // Local listeden personeli sil
        setState(() {
          _personnelList.removeWhere((p) => p.uid == personnel.uid);
        });
        
        // Session'a kaydet
        await AdminSessionService.savePersonnelList(_personnelList);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personel silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateAnnouncementStatus(String id, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(id)
          .update({'isActive': isActive});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteAnnouncement(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyuruyu Sil'),
        content: Text('${announcement.title} adlı duyuruyu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(announcement.id)
            .delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duyuru silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Admin panelinde durum renkleri
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Admin panelinde durum metinleri
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Bekliyor';
      case 'in_progress':
        return 'İşlemde';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  // Personel performans sekmesi
  Widget _buildPersonnelPerformance() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personel Performans Analizi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Veri yüklenirken hata oluştu'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data?.docs ?? [];
              
              // Personel performans verilerini hesapla
              Map<String, PersonnelPerformanceData> personnelStats = {};
              
              for (var doc in reports) {
                final data = doc.data() as Map<String, dynamic>;
                final report = FaultReportModel.fromMap(data);
                
                // Sadece tamamlanmış arızaları analiz et
                if (report.status == 'completed') {
                  final personnelId = data['updatedBy'] as String? ?? 'unknown';
                  
                  if (!personnelStats.containsKey(personnelId)) {
                    personnelStats[personnelId] = PersonnelPerformanceData(
                      personnelId: personnelId,
                      personnelName: data['updatedByName'] as String? ?? 'Bilinmeyen Personel',
                      totalCompleted: 0,
                      totalResolutionTime: 0,
                      averageResolutionTime: 0,
                    );
                  }
                  
                  // Çözüm süresini hesapla
                  DateTime? createdAt;
                  DateTime? completedAt;
                  
                  // createdAt alanını parse et
                  if (data['createdAt'] is Timestamp) {
                    createdAt = (data['createdAt'] as Timestamp).toDate();
                  } else if (data['createdAt'] is String) {
                    try {
                      createdAt = DateTime.parse(data['createdAt']);
                    } catch (e) {
                      continue; // Geçersiz tarih formatı, bu raporu atla
                    }
                  }
                  
                  // lastUpdated alanını parse et
                  if (data['lastUpdated'] is Timestamp) {
                    completedAt = (data['lastUpdated'] as Timestamp).toDate();
                  } else if (data['lastUpdated'] is String) {
                    try {
                      completedAt = DateTime.parse(data['lastUpdated']);
                    } catch (e) {
                      continue; // Geçersiz tarih formatı, bu raporu atla
                    }
                  }
                  
                  if (createdAt != null && completedAt != null) {
                    final resolutionTime = completedAt.difference(createdAt).inDays;
                    personnelStats[personnelId]!.totalCompleted++;
                    personnelStats[personnelId]!.totalResolutionTime += resolutionTime;
                  }
                }
              }
              
              // Ortalama çözüm sürelerini hesapla
              for (var stat in personnelStats.values) {
                if (stat.totalCompleted > 0) {
                  stat.averageResolutionTime = stat.totalResolutionTime / stat.totalCompleted;
                }
              }
              
              // Performans verilerini sırala (ortalama çözüm süresine göre)
              final sortedStats = personnelStats.values.toList()
                ..sort((a, b) => a.averageResolutionTime.compareTo(b.averageResolutionTime));
              
              return Column(
                children: [
                  // Genel istatistikler
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceMetric(
                          title: 'Toplam Personel',
                          value: personnelStats.length.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPerformanceMetric(
                          title: 'Toplam Tamamlanan',
                          value: personnelStats.values
                              .fold(0, (sum, stat) => sum + stat.totalCompleted)
                              .toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPerformanceMetric(
                          title: 'Ortalama Çözüm Süresi',
                          value: personnelStats.isNotEmpty
                              ? '${(personnelStats.values
                                      .fold(0.0, (sum, stat) => sum + stat.averageResolutionTime) /
                                  personnelStats.length)
                                  .toStringAsFixed(1)} gün'
                              : '0 gün',
                          icon: Icons.timeline,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Personel listesi
                  const Text(
                    'Personel Performans Detayları',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (sortedStats.isEmpty)
                    const Center(
                      child: Text(
                        'Henüz tamamlanmış arıza bulunmuyor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ...sortedStats.map((stat) => _buildPersonnelPerformanceCard(stat)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonnelPerformanceCard(PersonnelPerformanceData stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getPerformanceColor(stat.averageResolutionTime),
                child: Text(
                  stat.personnelName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.personnelName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${stat.personnelId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPerformanceColor(stat.averageResolutionTime).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stat.averageResolutionTime.toStringAsFixed(1)} gün',
                  style: TextStyle(
                    color: _getPerformanceColor(stat.averageResolutionTime),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Performans detayları
          Row(
            children: [
              Expanded(
                child: _buildPerformanceDetail(
                  title: 'Tamamlanan',
                  value: stat.totalCompleted.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceDetail(
                  title: 'Toplam Süre',
                  value: '${stat.totalResolutionTime} gün',
                  icon: Icons.timeline,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceDetail(
                  title: 'Ortalama',
                  value: '${stat.averageResolutionTime.toStringAsFixed(1)} gün',
                  icon: Icons.analytics,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDetail({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
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
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double averageDays) {
    if (averageDays <= 1) return Colors.green;
    if (averageDays <= 3) return Colors.orange;
    return Colors.red;
  }

  // Test personeli ekleme fonksiyonu
  void _addTestPersonnel() async {
    try {
      print('Test personeli ekleniyor...');
      
      // Test personeli verisi
      final testPersonnel = AdminModel(
        uid: 'test_personnel_${DateTime.now().millisecondsSinceEpoch}',
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        display: 'Test Personeli ${DateTime.now().millisecondsSinceEpoch}',
        role: 'personel',
        createdAt: DateTime.now(),
        active: true,
      );
      
      // Firebase'e kaydet
      await FirebaseFirestore.instance
          .collection('personnel')
          .doc(testPersonnel.uid)
          .set(testPersonnel.toMap());
      
      print('Test personeli Firebase\'e kaydedildi: ${testPersonnel.display}');
      
      // Personel listesini yenile
      await _loadPersonnelList();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test personeli eklendi: ${testPersonnel.display}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Test personeli ekleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Arıza atama dialog'u
  void _showAssignFaultDialog(FaultReportModel report) {
    String? selectedPersonnelId;
    bool isAssigning = false;

    print('Atama dialog\'u açılıyor...');
    print('Mevcut personel listesi: ${_personnelList.length} personel');
    for (var personnel in _personnelList) {
      print('- ${personnel.display} (${personnel.uid})');
    }

    // Personel listesi boşsa uyarı göster
    if (_personnelList.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('Personel Bulunamadı'),
          content: const Text(
            'Henüz personel bulunmuyor. Önce Dashboard\'dan "Test Personeli Ekle" butonuna basarak personel ekleyin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Arıza Ata: ${report.title}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori: ${report.category}'),
                        Text('Öncelik: ${report.priority}'),
                        Text('Konum: ${report.location}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Personel Seçin:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _personnelList.length,
                      itemBuilder: (context, index) {
                        final personnel = _personnelList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: RadioListTile<String>(
                            title: Text(personnel.display),
                            subtitle: Text(personnel.email),
                            value: personnel.uid,
                            groupValue: selectedPersonnelId,
                            onChanged: (value) {
                              print('Personel seçildi: $value');
                              setState(() {
                                selectedPersonnelId = value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Dialog iptal edildi');
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            if (report.assignedTo != null)
              TextButton(
                onPressed: isAssigning ? null : () async {
                  // Atamayı kaldır
                  setState(() {
                    isAssigning = true;
                  });
                  
                  try {
                    await FirebaseFirestore.instance
                        .collection('reports')
                        .doc(report.id)
                        .update({
                      'assignedTo': null,
                      'assignedByName': null,
                      'assignedAt': null,
                    });
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Arıza ataması kaldırıldı'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isAssigning = false;
                      });
                    }
                  }
                },
                child: const Text('Atamayı Kaldır'),
              ),
            ElevatedButton(
              onPressed: (selectedPersonnelId == null || isAssigning) ? null : () async {
                print('Atama işlemi başlatılıyor...');
                print('Seçilen personel ID: $selectedPersonnelId');
                
                setState(() {
                  isAssigning = true;
                });
                
                try {
                  final selectedPersonnel = _personnelList.firstWhere(
                    (p) => p.uid == selectedPersonnelId,
                  );
                  
                  print('Seçilen personel: ${selectedPersonnel.display} (${selectedPersonnel.uid})');
                  print('Arıza ID: ${report.id}');
                  
                  await FirebaseFirestore.instance
                      .collection('reports')
                      .doc(report.id)
                      .update({
                    'assignedTo': selectedPersonnel.uid,
                    'assignedByName': selectedPersonnel.display,
                    'assignedAt': DateTime.now().toIso8601String(),
                  });
                  
                  print('Firebase güncelleme başarılı');
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Arıza ${selectedPersonnel.display} adlı personel atandı'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Atama hatası: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      isAssigning = false;
                    });
                  }
                }
              },
              child: isAssigning
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ata'),
            ),
          ],
        ),
      ),
    );
  }
}

// Personel performans veri sınıfı
class PersonnelPerformanceData {
  final String personnelId;
  final String personnelName;
  int totalCompleted;
  int totalResolutionTime;
  double averageResolutionTime;

  PersonnelPerformanceData({
    required this.personnelId,
    required this.personnelName,
    required this.totalCompleted,
    required this.totalResolutionTime,
    required this.averageResolutionTime,
  });
}
