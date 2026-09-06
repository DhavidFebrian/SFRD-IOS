class MeetingListing {
  final int no;
  final int row;
  final int colIndex;
  final String date;
  final String idListing;
  final String namaMe;
  final String judul;
  final String lokasi;
  final String keterangan;
  final bool postingIg;
  final String jadwalPosting;
  final String catatan;
  final String sheetName;

  MeetingListing({
    this.no = 0,
    this.row = 0,
    this.colIndex = 0,
    this.date = '',
    required this.idListing,
    required this.namaMe,
    this.judul = '',
    this.lokasi = '',
    this.keterangan = '',
    this.postingIg = false,
    this.jadwalPosting = '',
    this.catatan = '',
    this.sheetName = '',
  });

  String get cleanId => idListing.trim();

  String get websiteUrl => cleanId.isNotEmpty 
      ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
      : '';

  String get mapsQueryUrl => lokasi.trim().isNotEmpty
      ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(lokasi.trim())}'
      : '';

  bool get isHot => keterangan.toLowerCase().contains('hot');
  bool get isFotoUlang => keterangan.toLowerCase().contains('foto ulang') || keterangan.toLowerCase().contains('ulang');
  bool get isIgTarget => keterangan.toLowerCase().contains('ig') || keterangan.toLowerCase().contains('instagram');

  factory MeetingListing.fromJson(Map<String, dynamic> json, [String defaultSheet = '']) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val == null) return false;
      final s = val.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }

    return MeetingListing(
      no: json['no'] is int ? json['no'] : (int.tryParse(json['no']?.toString() ?? '0') ?? 0),
      row: json['row'] is int ? json['row'] : (int.tryParse(json['row']?.toString() ?? '0') ?? 0),
      colIndex: json['colIndex'] is int ? json['colIndex'] : (int.tryParse(json['colIndex']?.toString() ?? '0') ?? 0),
      date: (json['date'] ?? '').toString().trim(),
      idListing: (json['idListing'] ?? json['id'] ?? '').toString().trim(),
      namaMe: (json['namaMe'] ?? '').toString().trim(),
      judul: (json['judul'] ?? json['keterangan'] ?? '').toString().trim(),
      lokasi: (json['lokasi'] ?? '').toString().trim(),
      keterangan: (json['keterangan'] ?? '').toString().trim(),
      postingIg: parseBool(json['postingIg']),
      jadwalPosting: (json['jadwalPosting'] ?? '').toString().trim(),
      catatan: (json['catatan'] ?? '').toString().trim(),
      sheetName: (json['sheetName'] != null && json['sheetName'].toString().isNotEmpty)
          ? json['sheetName'].toString().trim()
          : defaultSheet,
    );
  }

  Map<String, dynamic> toJson() => {
    'no': no,
    'row': row,
    'colIndex': colIndex,
    'date': date,
    'idListing': idListing,
    'namaMe': namaMe,
    'judul': judul,
    'lokasi': lokasi,
    'keterangan': keterangan,
    'postingIg': postingIg,
    'jadwalPosting': jadwalPosting,
    'catatan': catatan,
    'sheetName': sheetName,
  };

  MeetingListing copyWith({
    int? no,
    int? row,
    int? colIndex,
    String? date,
    String? idListing,
    String? namaMe,
    String? judul,
    String? lokasi,
    String? keterangan,
    bool? postingIg,
    String? jadwalPosting,
    String? catatan,
    String? sheetName,
  }) {
    return MeetingListing(
      no: no ?? this.no,
      row: row ?? this.row,
      colIndex: colIndex ?? this.colIndex,
      date: date ?? this.date,
      idListing: idListing ?? this.idListing,
      namaMe: namaMe ?? this.namaMe,
      judul: judul ?? this.judul,
      lokasi: lokasi ?? this.lokasi,
      keterangan: keterangan ?? this.keterangan,
      postingIg: postingIg ?? this.postingIg,
      jadwalPosting: jadwalPosting ?? this.jadwalPosting,
      catatan: catatan ?? this.catatan,
      sheetName: sheetName ?? this.sheetName,
    );
  }
}
