import 'package:flutter/material.dart';
import '../models/fault_report_model.dart';
import '../models/fault_status_model.dart';
import '../services/fault_tracking_service.dart';

class FaultTrackingScreen extends StatefulWidget {
  final String userId;

  const FaultTrackingScreen({super.key, required this.userId});

  @override
  State<FaultTrackingScreen> createState() => _FaultTrackingScreenState();
}

class _FaultTrackingScreenState extends State<FaultTrackingScreen> {
  List<FaultReportModel> _userReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReports();
  }

  Future<void> _loadUserReports() async {
    try {
      final allReports = await FaultTrackingService.getFaultReportsList();
      setState(() {
        _userReports = allReports.where((report) => report.userId == widget.userId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arıza Takibi'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadUserReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userReports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Henüz arıza bildiriminiz bulunmuyor',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userReports.length,
                    itemBuilder: (context, index) {
                      final report = _userReports[index];
                      return _buildReportCard(report);
                    },
                  ),
                ),
    );
  }

  Widget _buildReportCard(FaultReportModel report) {
    final currentStatus = FaultStatus.fromValue(report.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Takip Numarası
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.trackingNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Durum İlerlemesi
            _buildStatusProgress(report),
            const SizedBox(height: 12),
            
            // Mevcut Durum
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(currentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(currentStatus).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(currentStatus),
                    size: 16,
                    color: _getStatusColor(currentStatus),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentStatus.title,
                    style: TextStyle(
                      color: _getStatusColor(currentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Açıklama
            Text(
              currentStatus.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Kategori ve Konum
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(report.category, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tarih ve Öncelik
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(report.createdAt),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.priority_high, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(report.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.priority,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriorityColor(report.priority),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Detay Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTrackingDetails(report),
                icon: const Icon(Icons.timeline),
                label: const Text('Durum Geçmişini Görüntüle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgress(FaultReportModel report) {
    final currentStatus = FaultStatus.fromValue(report.status);
    final allStatuses = FaultStatus.values;
    final currentIndex = allStatuses.indexOf(currentStatus);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'İlerleme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              '${((currentIndex + 1) / allStatuses.length * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667eea),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (currentIndex + 1) / allStatuses.length,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Text(
          '${currentIndex + 1} / ${allStatuses.length} aşama tamamlandı',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'düşük':
        return Colors.green;
      case 'orta':
        return Colors.orange;
      case 'yüksek':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTrackingDetails(FaultReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildTrackingDetails(
          report,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildTrackingDetails(FaultReportModel report, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Başlık
          Text(
            'Arıza Takip Detayları',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.trackingNumber,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          // Durum Geçmişi
          Expanded(
            child: FutureBuilder<FaultTrackingModel?>(
              future: FaultTrackingService.getFaultTracking(report.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final tracking = snapshot.data;
                if (tracking == null) {
                  return const Center(
                    child: Text('Henüz durum geçmişi bulunmuyor'),
                  );
                }
                
                return ListView.builder(
                  controller: scrollController,
                  itemCount: tracking.statusHistory.length,
                  itemBuilder: (context, index) {
                    final update = tracking.statusHistory[index];
                    final isLast = index == tracking.statusHistory.length - 1;
                    
                    return _buildTimelineItem(update, isLast);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(FaultStatusUpdate update, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getStatusColor(update.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(update.status).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _getStatusIcon(update.status),
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.status.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  update.status.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      update.updatedByName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(update.updatedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (update.note != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      update.note!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
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

  IconData _getStatusIcon(FaultStatus status) {
    switch (status) {
      case FaultStatus.pending:
        return Icons.hourglass_empty;
      case FaultStatus.reviewing:
        return Icons.search;
      case FaultStatus.teamAssigned:
        return Icons.group;
      case FaultStatus.onTheWay:
        return Icons.directions_car;
      case FaultStatus.onSite:
        return Icons.location_on;
      case FaultStatus.inProgress:
        return Icons.build;
      case FaultStatus.testing:
        return Icons.science;
      case FaultStatus.resolved:
        return Icons.check_circle;
      case FaultStatus.completed:
        return Icons.check_circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
