import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'agenda_detail_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({Key? key}) : super(key: key);

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiClient = ApiClient();

  List<dynamic> _agendaList = [];
  bool _isLoading = true;
  String _currentTab = 'upcoming'; // 'upcoming' vs 'past'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index == 0 ? 'upcoming' : 'past';
        });
        _fetchAgenda();
      }
    });
    _fetchAgenda();
  }

  Future<void> _fetchAgenda() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        ApiConstants.agenda,
        queryParameters: {'tab': _currentTab},
      );
      setState(() {
        _agendaList = res.data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Agenda & Kongres ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Kegiatan Mendatang'),
            Tab(text: 'Riwayat Kegiatan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _agendaList.isEmpty
              ? Center(
                  child: Text(
                    _currentTab == 'upcoming'
                        ? 'Tidak ada agenda kegiatan mendatang saat ini.'
                        : 'Belum ada arsip kegiatan lampau.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: _fetchAgenda,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _agendaList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = _agendaList[index];
                      return _AgendaCard(item: item);
                    },
                  ),
                ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _AgendaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusPill = item['status_pill'] ?? 'Pendaftaran Buka';
    final isUpcoming = statusPill == 'Pendaftaran Buka' || statusPill == 'Sedang Berlangsung';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUpcoming ? AppColors.statusGreenBg : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusPill,
                    style: TextStyle(
                      color: isUpcoming ? AppColors.statusGreen : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  item['lokasi'] ?? 'ASKLIN Pusat',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['judul'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['excerpt'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Text(
                  item['tanggal_formatted'] ?? 'Tanggal Pelaksanaan',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AgendaDetailScreen(item: item),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Detail', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

