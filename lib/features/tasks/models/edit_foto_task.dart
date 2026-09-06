class EditFotoTask {
  final int no;
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
    this.no = 0,
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
  });

  String get cleanId => idListing.trim();

  String get websiteUrl => cleanId.isNotEmpty 
      ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
      : '';

  factory EditFotoTask.fromJson(Map<String, dynamic> json, [String defaultSheet = '']) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val == null) return false;
      final s = val.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }

    return EditFotoTask(
      no: json['no'] is int ? json['no'] : (int.tryParse(json['no']?.toString() ?? '0') ?? 0),
      idListing: (json['idListing'] ?? '').toString().trim(),
      namaMe: (json['namaMe'] ?? '').toString().trim(),
      postingIg: parseBool(json['postingIg']),
      jadwalPosting: (json['jadwalPosting'] ?? '').toString().trim(),
      editNotes: (json['editNotes'] ?? '').toString().trim(),
      done: parseBool(json['done']),
      judul: (json['judul'] ?? '').toString().trim(),
      source: (json['source'] ?? '').toString().trim(),
      sheetName: (json['sheetName'] != null && json['sheetName'].toString().isNotEmpty)
          ? json['sheetName'].toString().trim()
          : defaultSheet,
      synced: true,
    );
  }

  Map<String, dynamic> toJson() => {
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
    'sheetName': sheetName,
  };

  EditFotoTask copyWith({
    int? no,
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
