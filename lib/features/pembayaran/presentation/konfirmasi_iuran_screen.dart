import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class KonfirmasiIuranScreen extends StatefulWidget {
  const KonfirmasiIuranScreen({Key? key}) : super(key: key);

  @override
  State<KonfirmasiIuranScreen> createState() => _KonfirmasiIuranScreenState();
}

class _KonfirmasiIuranScreenState extends State<KonfirmasiIuranScreen> with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _statusData;
  List<dynamic> _riwayatList = [];

  // Form Fields
  int _selectedKategoriId = 1;
  final _totalController = TextEditingController(text: '1200000');
  final _tanggalController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _keteranganController = TextEditingController();
  File? _selectedProofFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalController.dispose();
    _tanggalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statusRes = await _apiClient.dio.get(ApiConstants.pembayaranStatus);
      if (statusRes.data['success'] == true) {
        _statusData = statusRes.data;
      }

      final riwayatRes = await _apiClient.dio.get(ApiConstants.pembayaranRiwayat);
      if (riwayatRes.data['success'] == true) {
        _riwayatList = riwayatRes.data['data'] as List<dynamic>;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat status pembayaran: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() {
          _selectedProofFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file bukti transfer: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Bukti Transfer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryRed),
                title: const Text('Buka Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryRed),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitKonfirmasi() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap sertakan foto bukti transfer pembayaran.'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formData = FormData.fromMap({
        'id_kategori': _selectedKategoriId,
        'total': _totalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'tanggal_bayar': _tanggalController.text,
        'keterangan': _keteranganController.text.trim(),
        'bukti': await MultipartFile.fromFile(
          _selectedProofFile!.path,
          filename: _selectedProofFile!.path.split(Platform.pathSeparator).last,
        ),
      });

      final res = await _apiClient.dio.post(
        ApiConstants.pembayaranKonfirmasi,
        data: formData,
      );

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi berhasil dikirim! Menunggu validasi bendahara.'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
        setState(() {
          _selectedProofFile = null;
          _keteranganController.clear();
        });
        await _loadData();
        _tabController.animateTo(1); // Pindah ke tab riwayat
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim konfirmasi: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : Column(
              children: [
                _buildHeader(),
                // TabBar dengan kontras tinggi & navigasi jelas
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryRed,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryRed,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.upload_file, size: 20),
                        text: 'Konfirmasi Bayar',
                      ),
                      Tab(
                        icon: Icon(Icons.history, size: 20),
                        text: 'Riwayat Pembayaran',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildKonfirmasiTab(),
                      _buildRiwayatTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final klinik = _statusData?['klinik'] ?? {};
    final isLunas = klinik['is_lunas'] == true;
    final canPop = Navigator.canPop(context);

    return Container(
      color: AppColors.primaryRed,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (canPop) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Iuran & Keuangan Anggota',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      klinik['nama_klinik'] ?? 'Klinik Anggota ASKLIN',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLunas ? Colors.green.shade600 : Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLunas ? 'LUNAS' : 'PENDING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKonfirmasiTab() {
    final rekening = _statusData?['rekening'] ?? {};
    final latestPayment = _statusData?['latest_payment'];
    final klinik = _statusData?['klinik'] ?? {};
    final isLunas = klinik['is_lunas'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status Terkini
          if (isLunas)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Iuran Keanggotaan Terverifikasi',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Klinik Anda berstatus Lunas. Anda dapat mengunduh e-Sertifikat dan SK Anggota resmi dari dasbor.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (latestPayment != null && latestPayment['status'] == '0')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pembayaran Sedang Diverifikasi',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bukti transfer ${latestPayment['total_rupiah'] ?? ''} diunggah pada ${latestPayment['created_at'] ?? '-'}. Bendahara ASKLIN sedang memvalidasi mutasi rekening.',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (latestPayment != null && latestPayment['status'] == '2')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pembayaran Ditolak Verifikator',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catatan: ${latestPayment['keterangan'] ?? 'Bukti transfer tidak valid atau nominal tidak sesuai.'}',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Silakan lakukan transfer ulang atau kirimkan konfirmasi bukti transfer yang sesuai di bawah.',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Rekening Resmi ASKLIN Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.softRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance, color: AppColors.primaryRed, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rekening['bank'] ?? 'BANK SYARIAH INDONESIA',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              rekening['cabang'] ?? 'BSI Kantor Cabang',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nomor Rekening Resmi', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            rekening['no_rekening'] ?? '4000300027',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.primaryRed,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('SALIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          side: const BorderSide(color: AppColors.primaryRed),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: rekening['no_rekening'] ?? '4000300027'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor rekening ASKLIN berhasil disalin ke clipboard!'),
                              backgroundColor: AppColors.primaryRed,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Atas Nama: ${rekening['atas_nama'] ?? 'ASOSIASI KLINIK INDONESIA'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rekening['petunjuk'] ?? 'Cantumkan Nama Klinik & No Anggota pada berita transfer.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Formulir Konfirmasi Transfer
          const Text(
            'Formulir Konfirmasi Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilihan Kategori
                    const Text('Jenis Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedKategoriId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Uang Iuran Tahunan (Rp 1.200.000)')),
                        DropdownMenuItem(value: 2, child: Text('Uang Pangkal Registrasi (Rp 500.000)')),
                        DropdownMenuItem(value: 3, child: Text('Uang Pangkal & Iuran (Rp 1.700.000)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedKategoriId = val;
                            if (val == 1) _totalController.text = '1200000';
                            if (val == 2) _totalController.text = '500000';
                            if (val == 3) _totalController.text = '1700000';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Jumlah Bayar
                    const Text('Jumlah Bayar (Rp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Harap masukkan nominal';
                        final numVal = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (numVal == null || numVal < 1000) return 'Nominal tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Tanggal Bayar
                    const Text('Tanggal Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setState(() {
                            _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Keterangan / Berita
                    const Text('Keterangan / Berita Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Iuran Tahunan Klinik Putra Medika 2026',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Bukti Transfer Box
                    const Text('Bukti Transfer (Struk ATM / Screenshot M-Banking)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    if (_selectedProofFile != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                _selectedProofFile!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedProofFile!.path.split(Platform.pathSeparator).last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Bukti siap diunggah', style: TextStyle(color: Colors.green, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppColors.primaryRed),
                              tooltip: 'Ganti Gambar',
                              onPressed: _showImageSourceDialog,
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: _showImageSourceDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primaryRed),
                              SizedBox(height: 8),
                              Text('Sentuh untuk Upload Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 4),
                              Text('Mendukung Kamera / Galeri (JPG, PNG)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          _isSubmitting ? 'MENGIRIM BUKTI...' : 'KIRIM KONFIRMASI PEMBAYARAN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSubmitting ? null : _submitKonfirmasi,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRiwayatTab() {
    if (_riwayatList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada riwayat pembayaran yang tercatat.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayatList.length,
      itemBuilder: (context, index) {
        final item = _riwayatList[index];
        final badge = item['status_badge'] ?? {};
        final statusLabel = item['status_label'] ?? 'Menunggu';
        final status = item['status'].toString();

        Color badgeBg = Colors.amber.shade100;
        Color badgeFg = Colors.amber.shade900;
        if (status == '1') {
          badgeBg = Colors.green.shade100;
          badgeFg = Colors.green.shade800;
        } else if (status == '2') {
          badgeBg = Colors.red.shade100;
          badgeFg = Colors.red.shade800;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['kategori_nama'] ?? 'Uang Iuran',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: badgeFg, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['total_rupiah'] ?? 'Rp 0',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Tgl: ${item['tanggal_bayar'] ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    if (item['bukti_url'] != null)
                      TextButton.icon(
                        icon: const Icon(Icons.image, size: 14),
                        label: const Text('Lihat Bukti', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                        ),
                        onPressed: () => _showReceiptModal(item['bukti_url']),
                      ),
                  ],
                ),
                if (item['keterangan'] != null && item['keterangan'].toString().isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(
                    'Catatan: ${item['keterangan']}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReceiptModal(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              child: Image.network(
                imageUrl,
                height: 350,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Gambar bukti tidak dapat ditampilkan.'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
