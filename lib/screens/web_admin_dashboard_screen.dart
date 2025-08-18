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
  void _loadPersonnelList() async {
    final personnelList = await AdminSessionService.getPersonnelList();
    setState(() {
      _personnelList = personnelList;
    });
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
                            Switch(
                              value: personnel.active,
                              onChanged: (value) {
                                _updatePersonnelStatus(personnel.uid, value);
                              },
                            ),
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
                value: 'all',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tümü')),
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
                                Text('Durum: ${report.status}'),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
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
              Text('Durum: ${report.status}'),
              Text('Oluşturan: ${report.contactName}'),
              Text('Tarih: ${_formatDate(report.createdAt)}'),
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

                  // Local olarak personel oluştur
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

                  // Local listeye ekle - ana widget'ın state'ini güncelle
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

  void _updatePersonnelStatus(String uid, bool active) async {
    try {
      // Local listede personeli bul ve güncelle
      final index = _personnelList.indexWhere((p) => p.uid == uid);
      if (index != -1) {
        setState(() {
          _personnelList[index] = _personnelList[index].copyWith(active: active);
        });
        // Session'a kaydet
        await AdminSessionService.savePersonnelList(_personnelList);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
}
