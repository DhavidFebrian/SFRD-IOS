class MeetingListing {
  final String id;
  final String idListing;
  final String namaMe;
  final String judul;
  final String harga;
  final String lokasi;
  final String keterangan;
  final String postingIg;
  final String jadwalPosting;
  final String imageUrl;
  final String catatan;
  final String status;
  final String date;
  final DateTime createdAt;

  MeetingListing({
    required this.id,
    required this.idListing,
    required this.namaMe,
    this.judul = '',
    this.harga = '',
    this.lokasi = '',
    this.keterangan = '',
    this.postingIg = '',
    this.jadwalPosting = '',
    this.imageUrl = '',
    this.catatan = '',
    this.status = 'Review',
    this.date = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'idListing': idListing,
    'namaMe': namaMe,
    'judul': judul,
    'harga': harga,
    'lokasi': lokasi,
    'keterangan': keterangan,
    'postingIg': postingIg,
    'jadwalPosting': jadwalPosting,
    'imageUrl': imageUrl,
    'catatan': catatan,
    'status': status,
    'date': date,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MeetingListing.fromJson(Map<String, dynamic> json) => MeetingListing(
    id: (json['id'] ?? json['no'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
    idListing: (json['idListing'] ?? json['id'] ?? '').toString(),
    namaMe: (json['namaMe'] ?? '').toString(),
    judul: (json['judul'] ?? json['keterangan'] ?? '').toString(),
    harga: (json['harga'] ?? '').toString(),
    lokasi: (json['lokasi'] ?? '').toString(),
    keterangan: (json['keterangan'] ?? '').toString(),
    postingIg: (json['postingIg'] ?? '').toString(),
    jadwalPosting: (json['jadwalPosting'] ?? '').toString(),
    imageUrl: (json['imageUrl'] ?? '').toString(),
    catatan: (json['catatan'] ?? '').toString(),
    status: (json['status'] ?? (json['postingIg'] == true || json['postingIg'] == 'true' ? 'Disetujui' : 'Review')).toString(),
    date: (json['date'] ?? '').toString(),
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );
}
