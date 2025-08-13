import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';
import '../models/fault_report_model.dart';
import 'web_personnel_login_screen.dart';

class WebPersonnelDashboardScreen extends StatefulWidget {
  final AdminModel personnel;

  const WebPersonnelDashboardScreen({super.key, required this.personnel});

  @override
  State<WebPersonnelDashboardScreen> createState() => _WebPersonnelDashboardScreenState();
}

class _WebPersonnelDashboardScreenState extends State<WebPersonnelDashboardScreen> {
  int _selectedIndex = 0;
  String _selectedStatusFilter = 'all';
  String _selectedCategoryFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personel Paneli',
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
                        widget.personnel.name,
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
        return _buildFaultTracking();
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
                  title: 'İşlemde',
                  value: '0',
                  icon: Icons.engineering,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  title: 'Tamamlanan',
                  value: '0',
                  icon: Icons.check_circle,
                  color: Colors.green,
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
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDate(report.createdAt),
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
                                color: _getStatusColor(report.status),
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

  Widget _buildFaultTracking() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arıza Takibi',
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
                value: _selectedStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tüm Durumlar')),
                  DropdownMenuItem(value: 'pending', child: Text('Bekleyen')),
                  DropdownMenuItem(value: 'in_progress', child: Text('İşlemde')),
                  DropdownMenuItem(value: 'completed', child: Text('Tamamlanan')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatusFilter = value!;
                  });
                },
              ),
              const SizedBox(width: 20),
              DropdownButton<String>(
                value: _selectedCategoryFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tüm Kategoriler')),
                  DropdownMenuItem(value: 'Su Kesintisi', child: Text('Su Kesintisi')),
                  DropdownMenuItem(value: 'Kaçak', child: Text('Kaçak')),
                  DropdownMenuItem(value: 'Kötü Koku', child: Text('Kötü Koku')),
                  DropdownMenuItem(value: 'Sayaç', child: Text('Sayaç')),
                  DropdownMenuItem(value: 'Vana', child: Text('Vana')),
                  DropdownMenuItem(value: 'Kanalizasyon', child: Text('Kanalizasyon')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryFilter = value!;
                  });
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

                // Filtreleme
                final filteredReports = reports.where((doc) {
                  final report = FaultReportModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                  );
                  
                  bool statusMatch = _selectedStatusFilter == 'all' || 
                                   report.status == _selectedStatusFilter;
                  bool categoryMatch = _selectedCategoryFilter == 'all' || 
                                     report.category == _selectedCategoryFilter;
                  
                  return statusMatch && categoryMatch;
                }).toList();

                if (filteredReports.isEmpty) {
                  return const Center(
                    child: Text(
                      'Seçilen filtrelere uygun arıza bulunamadı',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = FaultReportModel.fromMap(
                      filteredReports[index].data() as Map<String, dynamic>,
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
                        subtitle: Text(
                          '${report.category} • ${report.location} • ${_formatDate(report.createdAt)}',
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
                                Text('Durum: ${_getStatusText(report.status)}'),
                                const SizedBox(height: 10),
                                Text('Oluşturan: ${report.contactName}'),
                                const SizedBox(height: 10),
                                Text('Telefon: ${report.contactPhone}'),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    if (report.status == 'pending')
                                      ElevatedButton(
                                        onPressed: () {
                                          _updateReportStatus(report.id, 'in_progress');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('İşleme Al'),
                                      ),
                                    if (report.status == 'in_progress') ...[
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: () {
                                          _updateReportStatus(report.id, 'completed');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Tamamla'),
                                      ),
                                    ],
                                    if (report.status == 'pending')
                                      const SizedBox(width: 10),
                                    if (report.status == 'pending')
                                      ElevatedButton(
                                        onPressed: () {
                                          _showAddNoteDialog(report.id);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Not Ekle'),
                                      ),
                                  ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'in_progress':
        return 'İşlemde';
      case 'completed':
        return 'Tamamlandı';
      default:
        return 'Bilinmiyor';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
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
              Text('Durum: ${_getStatusText(report.status)}'),
              Text('Oluşturan: ${report.contactName}'),
              Text('Telefon: ${report.contactPhone}'),
              Text('Tarih: ${_formatDate(report.createdAt)}'),
              if (report.photos.isNotEmpty)
                Text('Fotoğraf Sayısı: ${report.photos.length}'),
              if (report.videoUrl != null)
                const Text('Video: Var'),
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

  void _updateReportStatus(String reportId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': status});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arıza durumu güncellendi'),
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

  void _showAddNoteDialog(String reportId) {
    final _noteController = TextEditingController();
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Arıza ile ilgili notunuzu yazın:'),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Notunuzu buraya yazın...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          StatefulBuilder(
            builder: (context, setState) => ElevatedButton(
              onPressed: _isAdding ? null : () async {
                if (_noteController.text.trim().isEmpty) return;

                setState(() {
                  _isAdding = true;
                });

                try {
                  await FirebaseFirestore.instance
                      .collection('reports')
                      .doc(reportId)
                      .collection('notes')
                      .add({
                    'note': _noteController.text.trim(),
                    'addedBy': widget.personnel.name,
                    'addedAt': DateTime.now().toIso8601String(),
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Not başarıyla eklendi'),
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
                      _isAdding = false;
                    });
                  }
                }
              },
              child: _isAdding
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
}
