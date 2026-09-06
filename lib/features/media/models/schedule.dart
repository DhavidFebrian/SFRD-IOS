class Schedule {
  final int no;
  final String idListing;
  final String namaMe;
  final String lokasi;
  final String tanggal;
  final String jam;
  final String staff;
  final String type;
  final String status;
  final String sheetName;
  final bool synced;

  Schedule({
    this.no = 0,
    required this.idListing,
    required this.namaMe,
    this.lokasi = '',
    this.tanggal = '',
    this.jam = '',
    this.staff = '',
    this.type = 'Foto',
    this.status = 'Pending',
    this.sheetName = '',
    this.synced = true,
  });

  bool get isDone {
    final s = status.toLowerCase().trim();
    final t = type.toLowerCase().trim();
    return s == 'done' || s == 'selesai' || t.startsWith('done');
  }

  bool get isFotoUlang {
    final t = type.toLowerCase();
    final s = sheetName.toLowerCase();
    return t.contains('foto ulang') || t.contains('ulang') || s.contains('foto ulang');
  }

  String get cleanId => idListing.trim();

  String get websiteUrl => cleanId.isNotEmpty 
      ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
      : '';

  String get mapsQueryUrl => lokasi.trim().isNotEmpty
      ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(lokasi.trim())}'
      : '';

  factory Schedule.fromJson(Map<String, dynamic> json, [String defaultSheet = '']) {
    return Schedule(
      no: json['no'] is int ? json['no'] : (int.tryParse(json['no']?.toString() ?? '0') ?? 0),
      idListing: (json['idListing'] ?? '').toString().trim(),
      namaMe: (json['namaMe'] ?? '').toString().trim(),
      lokasi: (json['lokasi'] ?? '').toString().trim(),
      tanggal: (json['tanggal'] ?? '').toString().trim(),
      jam: (json['jam'] ?? '').toString().trim(),
      staff: (json['staff'] ?? '').toString().trim(),
      type: (json['type'] ?? 'Foto').toString().trim(),
      status: (json['status'] ?? 'Pending').toString().trim(),
      sheetName: (json['sheetName'] != null && json['sheetName'].toString().isNotEmpty)
          ? json['sheetName'].toString().trim()
          : defaultSheet,
      synced: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'action': 'add',
    'no': no,
    'idListing': idListing,
    'namaMe': namaMe,
    'lokasi': lokasi,
    'tanggal': tanggal,
    'jam': jam,
    'staff': staff,
    'type': type,
    'status': status,
    'sheetName': sheetName,
  };

  Schedule copyWith({
    int? no,
    String? idListing,
    String? namaMe,
    String? lokasi,
    String? tanggal,
    String? jam,
    String? staff,
    String? type,
    String? status,
    String? sheetName,
    bool? synced,
  }) {
    return Schedule(
      no: no ?? this.no,
      idListing: idListing ?? this.idListing,
      namaMe: namaMe ?? this.namaMe,
      lokasi: lokasi ?? this.lokasi,
      tanggal: tanggal ?? this.tanggal,
      jam: jam ?? this.jam,
      staff: staff ?? this.staff,
      type: type ?? this.type,
      status: status ?? this.status,
      sheetName: sheetName ?? this.sheetName,
      synced: synced ?? this.synced,
    );
  }
}
