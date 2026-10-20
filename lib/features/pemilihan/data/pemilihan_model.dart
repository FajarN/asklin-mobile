class PemilihanItemModel {
  final int id;
  final String judul;
  final String tingkat;
  final String wilayah;
  final String periode;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String status;
  final bool isBerlangsung;
  final bool isEligible;
  final String statusKlinik;
  final String eligibilityMessage;
  final bool hasVoted;
  final DateTime? waktuVote;
  final int totalKandidat;

  PemilihanItemModel({
    required this.id,
    required this.judul,
    required this.tingkat,
    required this.wilayah,
    required this.periode,
    this.tanggalMulai,
    this.tanggalSelesai,
    required this.status,
    required this.isBerlangsung,
    required this.isEligible,
    required this.statusKlinik,
    required this.eligibilityMessage,
    required this.hasVoted,
    this.waktuVote,
    required this.totalKandidat,
  });

  factory PemilihanItemModel.fromJson(Map<String, dynamic> json) {
    final hakSuara = (json['hak_suara'] as Map<String, dynamic>?) ?? {};
    return PemilihanItemModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      tingkat: json['tingkat'] ?? '',
      wilayah: json['wilayah'] ?? '',
      periode: json['periode'] ?? '',
      tanggalMulai: json['tanggal_mulai'] != null ? DateTime.tryParse(json['tanggal_mulai']) : null,
      tanggalSelesai: json['tanggal_selesai'] != null ? DateTime.tryParse(json['tanggal_selesai']) : null,
      status: json['status'] ?? 'draft',
      isBerlangsung: json['is_berlangsung'] ?? false,
      isEligible: hakSuara['is_eligible'] ?? false,
      statusKlinik: hakSuara['status_klinik'] ?? '',
      eligibilityMessage: hakSuara['eligibility_message'] ?? '',
      hasVoted: hakSuara['has_voted'] ?? false,
      waktuVote: hakSuara['waktu_vote'] != null ? DateTime.tryParse(hakSuara['waktu_vote']) : null,
      totalKandidat: json['total_kandidat'] ?? 0,
    );
  }
}

class KandidatModel {
  final int id;
  final int nomorUrut;
  final String namaCalon;
  final String? gelar;
  final String namaLengkap;
  final String? asalKlinik;
  final String? fotoUrl;
  final String? visi;
  final String? misi;
  final String? programKerja;
  final int totalSuara;
  final num persentase;

  KandidatModel({
    required this.id,
    required this.nomorUrut,
    required this.namaCalon,
    this.gelar,
    required this.namaLengkap,
    this.asalKlinik,
    this.fotoUrl,
    this.visi,
    this.misi,
    this.programKerja,
    this.totalSuara = 0,
    this.persentase = 0,
  });

  factory KandidatModel.fromJson(Map<String, dynamic> json) {
    return KandidatModel(
      id: json['id'] ?? 0,
      nomorUrut: json['nomor_urut'] ?? 0,
      namaCalon: json['nama_calon'] ?? '',
      gelar: json['gelar'],
      namaLengkap: json['nama_lengkap'] ?? json['nama_calon'] ?? '',
      asalKlinik: json['asal_klinik'],
      fotoUrl: json['foto_url'],
      visi: json['visi'],
      misi: json['misi'],
      programKerja: json['program_kerja'],
      totalSuara: json['total_suara'] ?? 0,
      persentase: json['persentase'] ?? 0,
    );
  }
}

class PemilihanDetailModel {
  final int id;
  final String judul;
  final String tingkat;
  final String wilayah;
  final String periode;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String status;
  final bool isBerlangsung;
  final String? deskripsi;
  final bool isEligible;
  final String statusKlinik;
  final String eligibilityMessage;
  final bool hasVoted;
  final DateTime? waktuVote;
  final List<KandidatModel> kandidat;

  PemilihanDetailModel({
    required this.id,
    required this.judul,
    required this.tingkat,
    required this.wilayah,
    required this.periode,
    this.tanggalMulai,
    this.tanggalSelesai,
    required this.status,
    required this.isBerlangsung,
    this.deskripsi,
    required this.isEligible,
    required this.statusKlinik,
    required this.eligibilityMessage,
    required this.hasVoted,
    this.waktuVote,
    required this.kandidat,
  });

  factory PemilihanDetailModel.fromJson(Map<String, dynamic> json) {
    final hakSuara = (json['hak_suara'] as Map<String, dynamic>?) ?? {};
    final rawKandidat = (json['kandidat'] as List<dynamic>?) ?? [];
    return PemilihanDetailModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      tingkat: json['tingkat'] ?? '',
      wilayah: json['wilayah'] ?? '',
      periode: json['periode'] ?? '',
      tanggalMulai: json['tanggal_mulai'] != null ? DateTime.tryParse(json['tanggal_mulai']) : null,
      tanggalSelesai: json['tanggal_selesai'] != null ? DateTime.tryParse(json['tanggal_selesai']) : null,
      status: json['status'] ?? 'draft',
      isBerlangsung: json['is_berlangsung'] ?? false,
      deskripsi: json['deskripsi'],
      isEligible: hakSuara['is_eligible'] ?? false,
      statusKlinik: hakSuara['status_klinik'] ?? '',
      eligibilityMessage: hakSuara['eligibility_message'] ?? '',
      hasVoted: hakSuara['has_voted'] ?? false,
      waktuVote: hakSuara['waktu_vote'] != null ? DateTime.tryParse(hakSuara['waktu_vote']) : null,
      kandidat: rawKandidat.map((k) => KandidatModel.fromJson(k as Map<String, dynamic>)).toList(),
    );
  }
}

