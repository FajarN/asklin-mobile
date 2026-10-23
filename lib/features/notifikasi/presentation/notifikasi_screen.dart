import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../pengurus/presentation/verifikasi_klinik_detail_screen.dart';
import '../data/notifikasi_model.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  late TabController _tabController;

  bool _isLoading = true;
  int _unreadCount = 0;
  List<NotifikasiModel> _allNotifications = [];
  String _userRole = 'Anggota Klinik';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRoleAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initRoleAndData() async {
    final role = await SecureStorageService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role ?? 'Anggota Klinik';
      });
    }
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(ApiConstants.notifikasi);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final items = (data['items'] as List<dynamic>? ?? [])
            .map((e) => NotifikasiModel.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _allNotifications = items;
          _unreadCount = data['unread_count'] is int ? data['unread_count'] : 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotifikasiModel item) async {
    if (item.isRead) return;

    try {
      await _apiClient.dio.post(ApiConstants.notifikasiRead(item.id));
      setState(() {
        final index = _allNotifications.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    try {
      await _apiClient.dio.post(ApiConstants.notifikasiReadAll);
      setState(() {
        _allNotifications = _allNotifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca.'),
            backgroundColor: AppColors.statusGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _onNotificationTap(NotifikasiModel item) async {
    await _markAsRead(item);

    // Navigasi ke detail verifikasi jika ada referensi ID klinik dan user adalah pengurus
    final anggotaId = item.data?['anggota_id'] != null
        ? int.tryParse(item.data!['anggota_id'].toString())
        : item.referenceId;

    final isPengurus = _userRole.toLowerCase().contains('cabang') ||
        _userRole.toLowerCase().contains('sekjen') ||
        _userRole.toLowerCase().contains('ketua') ||
        _userRole.toLowerCase().contains('superadmin') ||
        _userRole.toLowerCase().contains('pusat');

    if (!mounted) return;

    if (anggotaId != null && anggotaId > 0 && isPengurus) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifikasiKlinikDetailScreen(
            anggotaId: anggotaId,
            userRole: _userRole,
          ),
        ),
      );
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount Baru',
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, size: 22),
              tooltip: 'Tandai Semua Dibaca',
              onPressed: _markAllAsRead,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Semua (${_allNotifications.length})'),
            Tab(text: 'Belum Dibaca ($_unreadCount)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_allNotifications),
          _buildNotificationList(_allNotifications.where((n) => !n.isRead).toList()),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotifikasiModel> list) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
    }

    if (list.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: _loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.softRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, size: 54, color: AppColors.primaryRed),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Notifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Semua pemberitahuan pendaftaran dan verifikasi akan tampil di sini.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildNotificationCard(item);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotifikasiModel item) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (item.type) {
      case 'anggota_baru':
        iconColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        icon = Icons.person_add_alt_1;
        break;
      case 'request_verifikasi_cabang':
        iconColor = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        icon = Icons.assignment_late;
        break;
      case 'verifikasi_cabang':
        iconColor = Colors.purple.shade700;
        bgColor = Colors.purple.shade50;
        icon = Icons.verified;
        break;
      case 'request_verifikasi_pusat':
        iconColor = Colors.deepPurple.shade700;
        bgColor = Colors.deepPurple.shade50;
        icon = Icons.forward_to_inbox;
        break;
      case 'approved':
      case 'approved_pusat':
        iconColor = AppColors.statusGreen;
        bgColor = Colors.green.shade50;
        icon = Icons.check_circle;
        break;
      case 'perlu_perbaikan':
        iconColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        iconColor = AppColors.primaryRed;
        bgColor = AppColors.softRed;
        icon = Icons.notifications_active;
    }

    return InkWell(
      onTap: () => _onNotificationTap(item),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFFFF9F9),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: item.isRead ? AppColors.borderSubtle : AppColors.primaryRed.withOpacity(0.35),
            width: item.isRead ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Tipe Notifikasi
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Konten Notifikasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: item.isRead ? AppColors.textPrimary : AppColors.primaryRed,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isRead ? AppColors.textSecondary : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.timeAgo.isNotEmpty ? item.timeAgo : (item.createdAt ?? ''),
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                      if (item.referenceId != null)
                        const Row(
                          children: [
                            Text(
                              'Lihat Detail',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right, size: 14, color: AppColors.primaryRed),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
