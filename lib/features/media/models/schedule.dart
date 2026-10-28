class Schedule {
  final String no;
  final String idListing;
  final String namaMe;
  final String lokasi;
  final String tanggal;
  final String jam;
  final String staff;
  final String type;
  final String status;
  final String sheetName;
  final String source;
  final bool synced;
  final String originalIdListing;
  final String originalNamaMe;
  final String originalTanggal;
  final String originalJam;

  Schedule({
    dynamic no = '',
    required this.idListing,
    required this.namaMe,
    this.lokasi = '',
    this.tanggal = '',
    this.jam = '',
    this.staff = '',
    this.type = 'Foto',
    this.status = 'Pending',
    this.sheetName = '',
    this.source = '',
    this.synced = true,
    this.originalIdListing = '',
    this.originalNamaMe = '',
    this.originalTanggal = '',
    this.originalJam = '',
  }) : no = (no == null || no == 0) ? '' : no.toString().trim();

  bool get isDone {
    final s = status.toLowerCase().trim();
    final t = type.toLowerCase().trim();
    return s == 'done' || s == 'selesai' || t.startsWith('done');
  }

  bool get isNonActive {
    final s = status.toLowerCase().trim();
    final sh = sheetName.toLowerCase().trim();
    return sh.contains('foto ulang') ||
        s.contains('batal') ||
        s.contains('cancel') ||
        s.contains('tunda') ||
        s.contains('reschedule') ||
        s.contains('pending') ||
        s.contains('non');
  }

  bool get isActive => !isDone && !isNonActive;

  bool get isFotoUlang {
    final t = type.toLowerCase();
    final s = sheetName.toLowerCase();
    return t.contains('foto ulang') ||
        t.contains('ulang') ||
        s.contains('foto ulang');
  }

  String get cleanId {
    final raw = idListing.trim();
    final m = RegExp(r'\d+').firstMatch(raw);
    return m != null ? m.group(0)! : raw;
  }

  String get websiteUrl => cleanId.isNotEmpty
      ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
      : '';

  String get mapsQueryUrl => lokasi.trim().isNotEmpty
      ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(lokasi.trim())}'
      : '';

  String get formattedTime12Hour {
    final raw = jam.trim();
    if (raw.isEmpty) return '-';
    if (raw.toLowerCase().contains('am') || raw.toLowerCase().contains('pm')) {
      return raw;
    }
    final m = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw);
    if (m != null) {
      int h = int.tryParse(m.group(1)!) ?? 0;
      final min = m.group(2)!;
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h == 0) h = 12;
      if (h > 12) h -= 12;
      return '$h:$min $suffix';
    }
    return raw;
  }

  factory Schedule.fromJson(
    Map<String, dynamic> json, [
    String defaultSheet = '',
  ]) {
    final id = (json['idListing'] ?? '').toString().trim();
    final me = (json['namaMe'] ?? '').toString().trim();
    final tgl = (json['tanggal'] ?? '').toString().trim();
    final jm = (json['jam'] ?? '').toString().trim();
    return Schedule(
      no: (json['no'] ?? '').toString().trim(),
      idListing: id,
      namaMe: me,
      lokasi: (json['lokasi'] ?? '').toString().trim(),
      tanggal: tgl,
      jam: jm,
      staff: (json['staff'] ?? '').toString().trim(),
      type: (json['type'] ?? 'Foto').toString().trim(),
      status: (json['status'] ?? 'On Progress').toString().trim(),
      sheetName: (json['sheetName'] != null &&
              json['sheetName'].toString().isNotEmpty)
          ? json['sheetName'].toString().trim()
          : defaultSheet,
      source: (json['source'] ?? '').toString().trim(),
      synced: json['synced'] != false,
      originalIdListing: (json['originalIdListing'] ?? id).toString().trim(),
      originalNamaMe: (json['originalNamaMe'] ?? me).toString().trim(),
      originalTanggal: (json['originalTanggal'] ?? tgl).toString().trim(),
      originalJam: (json['originalJam'] ?? jm).toString().trim(),
    );
  }

  Map<String, dynamic> toJson({String action = 'add'}) => {
        'action': action,
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
        'source': source,
        'originalIdListing':
            originalIdListing.isNotEmpty ? originalIdListing : idListing,
        'originalNamaMe': originalNamaMe.isNotEmpty ? originalNamaMe : namaMe,
        'originalTanggal':
            originalTanggal.isNotEmpty ? originalTanggal : tanggal,
        'originalJam': originalJam.isNotEmpty ? originalJam : jam,
      };

  Schedule copyWith({
    dynamic no,
    String? idListing,
    String? namaMe,
    String? lokasi,
    String? tanggal,
    String? jam,
    String? staff,
    String? type,
    String? status,
    String? sheetName,
    String? source,
    bool? synced,
    String? originalIdListing,
    String? originalNamaMe,
    String? originalTanggal,
    String? originalJam,
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
      source: source ?? this.source,
      synced: synced ?? this.synced,
      originalIdListing: originalIdListing ?? this.originalIdListing,
      originalNamaMe: originalNamaMe ?? this.originalNamaMe,
      originalTanggal: originalTanggal ?? this.originalTanggal,
      originalJam: originalJam ?? this.originalJam,
    );
  }
}
