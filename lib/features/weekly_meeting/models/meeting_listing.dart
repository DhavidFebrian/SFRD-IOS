class MeetingListing {
  final String id;
  final String idListing;
  final String namaMe;
  final String judul;
  final String harga;
  final String imageUrl;
  final String catatan;
  final String status;
  final DateTime createdAt;

  MeetingListing({
    required this.id,
    required this.idListing,
    required this.namaMe,
    required this.judul,
    required this.harga,
    this.imageUrl = '',
    this.catatan = '',
    this.status = 'Review',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'idListing': idListing,
    'namaMe': namaMe,
    'judul': judul,
    'harga': harga,
    'imageUrl': imageUrl,
    'catatan': catatan,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MeetingListing.fromJson(Map<String, dynamic> json) => MeetingListing(
    id: json['id'] ?? '',
    idListing: json['idListing'] ?? '',
    namaMe: json['namaMe'] ?? '',
    judul: json['judul'] ?? '',
    harga: json['harga'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    catatan: json['catatan'] ?? '',
    status: json['status'] ?? 'Review',
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );
}
