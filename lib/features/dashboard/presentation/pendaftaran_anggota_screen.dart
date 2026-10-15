import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class PendaftaranAnggotaScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const PendaftaranAnggotaScreen({Key? key, this.initialData}) : super(key: key);

  @override
  State<PendaftaranAnggotaScreen> createState() => _PendaftaranAnggotaScreenState();
}

class _PendaftaranAnggotaScreenState extends State<PendaftaranAnggotaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers Step 1: Data Kontak & Izin Klinik
  final _namaKlinikController = TextEditingController();
  final _namaKontakController = TextEditingController();
  final _emailController = TextEditingController();
  final _tlfController = TextEditingController();
  String _statusPendaftar = 'Pemilik';
  final _noIjinController = TextEditingController();
  final _tglIjinController = TextEditingController();
  final _tglAkhirIjinController = TextEditingController();

  // Controllers Step 2: Alamat & Fasilitas Faskes
  final _namaPemilikController = TextEditingController();
  String _jenisKlinik = 'Pratama'; // Pratama / Utama
  String _statusKepemilikan = 'Perorangan'; // Perorangan / Badan Usaha / Badan Hukum
  String _bentukBadanHukum = 'PT';
  final _namaBadanUsahaController = TextEditingController();
  final _alamatKlinikController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _kodePosController = TextEditingController();
  final _tlfKlinikController = TextEditingController();

  // Master Wilayah
  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];
  String? _selectedProvinsiCode;
  String? _selectedKotaCode;

  // Step 3: Input SDM Dokter Penanggung Jawab
  final _namaDokterPjController = TextEditingController();
  final _npaIdiPjController = TextEditingController();
  final _noStrPjController = TextEditingController();
  final _noSipPjController = TextEditingController();
  final _tglAkhirSipPjController = TextEditingController();
  final _tlfDokterPjController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
    _populateInitialData();
  }

  void _populateInitialData() {
    final d = widget.initialData;
    if (d != null) {
      _namaKlinikController.text = d['nama_klinik'] ?? '';
      _namaKontakController.text = d['nama_kontak'] ?? '';
      _emailController.text = d['email'] ?? '';
      _tlfController.text = d['tlf'] ?? '';
      _noIjinController.text = d['no_ijin'] ?? '';
      _tglIjinController.text = d['tgl_ijin'] ?? '';
      _tglAkhirIjinController.text = d['tgl_akhir_ijin'] ?? '';
      _namaPemilikController.text = d['nama_pemilik_klinik'] ?? '';
      _alamatKlinikController.text = d['alamat_klinik'] ?? '';
      _selectedProvinsiCode = d['id_provinsi'];
      _selectedKotaCode = d['id_kota'];
      if (_selectedProvinsiCode != null) {
        _fetchCities(_selectedProvinsiCode!);
      }
    }
  }

  Future<void> _fetchProvinces() async {
    try {
      final res = await _apiClient.dio.get('/wilayah/provinsi');
      setState(() => _provinces = res.data['data'] ?? []);
    } catch (_) {}
  }

  Future<void> _fetchCities(String provCode) async {
    try {
      final res = await _apiClient.dio.get('/wilayah/kota', queryParameters: {'provinsi_code': provCode});
      setState(() {
        _cities = res.data['data'] ?? [];
        if (!_cities.any((c) => c['code'] == _selectedKotaCode)) {
          _selectedKotaCode = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _submitStep1And2() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvinsiCode == null || _selectedKotaCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Provinsi dan Kabupaten/Kota.'), backgroundColor: AppColors.primaryRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        '/anggota/pendaftaran',
        data: {
          'nama_klinik': _namaKlinikController.text.trim(),
          'nama_kontak': _namaKontakController.text.trim(),
          'email': _emailController.text.trim(),
          'tlf': _tlfController.text.trim(),
          'id_provinsi': _selectedProvinsiCode,
          'id_kota': _selectedKotaCode,
          'alamat_klinik': _alamatKlinikController.text.trim(),
          'rt': _rtController.text.trim(),
          'rw': _rwController.text.trim(),
          'kode_pos': _kodePosController.text.trim(),
          'tlf_klinik': _tlfKlinikController.text.trim(),
          'jenis_klinik': _jenisKlinik,
          'status_pendaftar': _statusPendaftar,
          'status_kepemilikan': _statusKepemilikan,
          'nama_pemilik_klinik': _namaPemilikController.text.trim(),
          'bentuk_badan_hukum': _bentukBadanHukum,
          'nama_badan_usaha': _namaBadanUsahaController.text.trim(),
          'no_ijin': _noIjinController.text.trim(),
          'tgl_ijin': _tglIjinController.text.trim(),
          'tgl_akhir_ijin': _tglAkhirIjinController.text.trim(),
        },
      );

      if (res.data['success'] == true) {
        setState(() {
          _isLoading = false;
          _currentStep = 1; // Pindah ke Step SDM Dokter
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan pendaftaran faskes.'), backgroundColor: AppColors.primaryRed),
      );
    }
  }

  Future<void> _submitStep3Sdm() async {
    final namaDokter = _namaDokterPjController.text.trim();
    if (namaDokter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Dokter Penanggung Jawab wajib diisi.'), backgroundColor: AppColors.primaryRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        '/anggota/sdm',
        data: {
          'nama_dokter': namaDokter,
          'id_kategori_sdm': 1, // 1 = Penanggung Jawab
          'npa_idi': _npaIdiPjController.text.trim(),
          'no_str': _noStrPjController.text.trim(),
          'no_sip': _noSipPjController.text.trim(),
          'tgl_akhir_sip': _tglAkhirSipPjController.text.trim(),
          'no_tlf': _tlfDokterPjController.text.trim(),
        },
      );

      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran faskes dan SDM dokter berhasil dikirim ke Pengurus Cabang!'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data SDM Dokter.'), backgroundColor: AppColors.primaryRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Formulir Pendaftaran Anggota ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                elevation: 0,
                onStepTapped: (step) => setState(() => _currentStep = step),
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Data Klinik'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: _buildStepKlinik(),
                  ),
                  Step(
                    title: const Text('Input SDM'),
                    isActive: _currentStep >= 1,
                    state: _currentStep == 1 ? StepState.indexed : StepState.disabled,
                    content: _buildStepSdm(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepKlinik() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Data Kontak & Legalitas Izin Klinik',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRed),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _namaKlinikController,
          decoration: const InputDecoration(labelText: 'Nama Klinik *'),
          validator: (val) => val == null || val.isEmpty ? 'Nama klinik wajib diisi' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _namaKontakController,
          decoration: const InputDecoration(labelText: 'Nama Kontak Person (Penanggung Jawab) *'),
          validator: (val) => val == null || val.isEmpty ? 'Kontak person wajib diisi' : null,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Resmi *'),
                validator: (val) => val == null || val.isEmpty ? 'Email wajib diisi' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _tlfController,
                decoration: const InputDecoration(labelText: 'No. Telepon / WA *'),
                validator: (val) => val == null || val.isEmpty ? 'Nomor telepon wajib diisi' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _statusPendaftar,
          decoration: const InputDecoration(labelText: 'Status Pendaftar'),
          items: const [
            DropdownMenuItem(value: 'Pemilik', child: Text('Pemilik')),
            DropdownMenuItem(value: 'Penanggungjawab', child: Text('Penanggungjawab')),
            DropdownMenuItem(value: 'Pengelola', child: Text('Pengelola')),
            DropdownMenuItem(value: 'Pemilik dan Penanggungjawab', child: Text('Pemilik & Penanggungjawab')),
          ],
          onChanged: (val) => setState(() => _statusPendaftar = val!),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _noIjinController,
                decoration: const InputDecoration(labelText: 'No. Ijin Klinik (SIO)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _tglAkhirIjinController,
                decoration: const InputDecoration(labelText: 'Masa Berlaku (YYYY-MM-DD)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          '2. Alamat & Karakteristik Faskes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRed),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _jenisKlinik,
                decoration: const InputDecoration(labelText: 'Jenis Klinik'),
                items: const [
                  DropdownMenuItem(value: 'Pratama', child: Text('Pratama')),
                  DropdownMenuItem(value: 'Utama', child: Text('Utama')),
                ],
                onChanged: (val) => setState(() => _jenisKlinik = val!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusKepemilikan,
                decoration: const InputDecoration(labelText: 'Status Kepemilikan'),
                items: const [
                  DropdownMenuItem(value: 'Perorangan', child: Text('Perorangan')),
                  DropdownMenuItem(value: 'Badan Usaha', child: Text('Badan Usaha')),
                  DropdownMenuItem(value: 'Badan Hukum', child: Text('Badan Hukum')),
                ],
                onChanged: (val) => setState(() => _statusKepemilikan = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _namaPemilikController,
          decoration: const InputDecoration(labelText: 'Nama Pemilik / Badan Usaha'),
        ),
        const SizedBox(height: 12),

        // Dropdown Provinsi
        DropdownButtonFormField<String>(
          value: _selectedProvinsiCode,
          decoration: const InputDecoration(labelText: 'Provinsi *'),
          items: _provinces.map<DropdownMenuItem<String>>((p) {
            return DropdownMenuItem<String>(value: p['code'], child: Text(p['name']));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedProvinsiCode = val;
              _selectedKotaCode = null;
            });
            if (val != null) _fetchCities(val);
          },
        ),
        const SizedBox(height: 12),

        // Dropdown Kota
        DropdownButtonFormField<String>(
          value: _selectedKotaCode,
          decoration: const InputDecoration(labelText: 'Kabupaten / Kota *'),
          items: _cities.map<DropdownMenuItem<String>>((c) {
            return DropdownMenuItem<String>(value: c['code'], child: Text(c['name']));
          }).toList(),
          onChanged: (val) => setState(() => _selectedKotaCode = val),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _alamatKlinikController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Alamat Lengkap Klinik *'),
          validator: (val) => val == null || val.isEmpty ? 'Alamat klinik wajib diisi' : null,
        ),
        const SizedBox(height: 24),

        AsklinPrimaryButton(
          text: 'LANJUT KE INPUT SDM DOKTER',
          icon: Icons.arrow_forward,
          onPressed: _submitStep1And2,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepSdm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Input SDM Dokter Penanggung Jawab',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRed),
        ),
        const SizedBox(height: 6),
        const Text(
          'Wajib mendaftarkan minimal 1 Dokter Penanggung Jawab Klinik sesuai syarat regulasi ASKLIN.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _namaDokterPjController,
          decoration: const InputDecoration(labelText: 'Nama Lengkap Dokter Penanggung Jawab *'),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _npaIdiPjController,
                decoration: const InputDecoration(labelText: 'NPA IDI / PDGI'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _noStrPjController,
                decoration: const InputDecoration(labelText: 'Nomor STR Dokter'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _noSipPjController,
                decoration: const InputDecoration(labelText: 'Nomor SIP Dokter'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _tglAkhirSipPjController,
                decoration: const InputDecoration(labelText: 'Masa Berlaku SIP (YYYY-MM-DD)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _tlfDokterPjController,
          decoration: const InputDecoration(labelText: 'No. Telepon / WhatsApp Dokter'),
        ),
        const SizedBox(height: 28),

        AsklinPrimaryButton(
          text: 'SELESAIKAN PENDAFTARAN & KIRIM',
          icon: Icons.check_circle,
          onPressed: _submitStep3Sdm,
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text('Kembali ke Data Klinik', style: TextStyle(color: AppColors.primaryRed)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

