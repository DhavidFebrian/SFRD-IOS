class EditFotoTask {
  final String no;
  final String idListing;
  final String namaMe;
  final bool postingIg;
  final String jadwalPosting;
  final String editNotes;
  final bool done;
  final String judul;
  final String source;
  final String sheetName;
  final bool synced;

  EditFotoTask({
    dynamic no = '',
    required this.idListing,
    required this.namaMe,
    this.postingIg = false,
    this.jadwalPosting = '',
    this.editNotes = '',
    this.done = false,
    this.judul = '',
    this.source = '',
    this.sheetName = '',
    this.synced = true,
  }) : no = (no == null || no == 0) ? '' : no.toString().trim();

  String get cleanId {
    final raw = idListing.trim();
    final m = RegExp(r'\d+').firstMatch(raw);
    return m != null ? m.group(0)! : raw;
  }

  String get websiteUrl => cleanId.isNotEmpty
      ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
      : '';

  bool get isEditVideo {
    final n = editNotes.toLowerCase();
    final j = judul.toLowerCase();
    final s = source.toLowerCase();
    return n.contains('video') ||
        j.contains('video') ||
        s.contains('video') ||
        n.contains('reels');
  }

  bool get isGarisTanah {
    final n = editNotes.toLowerCase();
    final j = judul.toLowerCase();
    final s = source.toLowerCase();
    return n.contains('drone') ||
        n.contains('garis') ||
        n.contains('tanah') ||
        j.contains('drone') ||
        s.contains('drone');
  }

  bool get isUpFoto => !isEditVideo && !isGarisTanah;

  factory EditFotoTask.fromJson(
    Map<String, dynamic> json, [
    String defaultSheet = '',
  ]) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val == null) return false;
      final s = val.toString().toLowerCase().trim();
      return s == 'true' ||
          s == '1' ||
          s == 'yes' ||
          s == 'ya' ||
          s == 'done' ||
          s == '✔';
    }

    return EditFotoTask(
      no: (json['no'] ?? '').toString().trim(),
      idListing: (json['idListing'] ?? '').toString().trim(),
      namaMe: (json['namaMe'] ?? '').toString().trim(),
      postingIg: parseBool(json['postingIg']),
      jadwalPosting: (json['jadwalPosting'] ?? '').toString().trim(),
      editNotes: (json['editNotes'] ?? '').toString().trim(),
      done: parseBool(json['done']),
      judul: (json['judul'] ?? '').toString().trim(),
      source: (json['source'] ?? '').toString().trim(),
      sheetName: (json['sheetName'] != null &&
              json['sheetName'].toString().isNotEmpty)
          ? json['sheetName'].toString().trim()
          : defaultSheet,
      synced: true,
    );
  }

  Map<String, dynamic> toJson({String? sheetNameOverride}) => {
        'action': 'edit_foto',
        'no': no,
        'idListing': idListing,
        'namaMe': namaMe,
        'postingIg': postingIg,
        'jadwalPosting': jadwalPosting,
        'editNotes': editNotes,
        'done': done,
        'judul': judul,
        'source': source,
        'sheetName': sheetNameOverride ?? sheetName,
      };

  EditFotoTask copyWith({
    dynamic no,
    String? idListing,
    String? namaMe,
    bool? postingIg,
    String? jadwalPosting,
    String? editNotes,
    bool? done,
    String? judul,
    String? source,
    String? sheetName,
    bool? synced,
  }) {
    return EditFotoTask(
      no: no ?? this.no,
      idListing: idListing ?? this.idListing,
      namaMe: namaMe ?? this.namaMe,
      postingIg: postingIg ?? this.postingIg,
      jadwalPosting: jadwalPosting ?? this.jadwalPosting,
      editNotes: editNotes ?? this.editNotes,
      done: done ?? this.done,
      judul: judul ?? this.judul,
      source: source ?? this.source,
      sheetName: sheetName ?? this.sheetName,
      synced: synced ?? this.synced,
    );
  }
}
