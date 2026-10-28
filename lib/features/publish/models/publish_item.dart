import 'package:intl/intl.dart';
import '../../../core/models/agent_contact.dart';
import '../../tasks/models/edit_foto_task.dart';
import '../../weekly_meeting/models/meeting_listing.dart';

const List<String> kIndonesianMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> kIndonesianWeekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> kSortedLocations = [
  'Kebayoran Baru',
  'Kebayoran Lama',
  'Pondok Indah',
  'Cipete Utara',
  'Cipete Selatan',
  'Cipete',
  'Cilandak Barat',
  'Cilandak Timur',
  'Cilandak',
  'Kemang',
  'Bangka',
  'Pela Mampang',
  'Mampang Prapatan',
  'Senopati',
  'Senayan',
  'Dharmawangsa',
  'Wijaya',
  'Prapanca',
  'Brawijaya',
  'Panglima Polim',
  'Melawai',
  'Gandaria',
  'Radio Dalam',
  'Pondok Pinang',
  'Lebak Bulus',
  'Fatmawati',
  'Simprug',
  'Permata Hijau',
  'Pakubuwono',
  'Hang Lekir',
  'Hang Tuah',
  'Pattimura',
  'Sriwijaya',
  'Gunawarman',
  'Wolter Monginsidi',
  'Tendean',
  'Kuningan',
  'Setiabudi',
  'Menteng',
  'Tebet',
  'Pancoran',
  'Kalibata',
  'Pejaten Barat',
  'Pejaten Timur',
  'Pejaten',
  'Pasar Minggu',
  'Ampera',
  'Jeruk Purut',
  'Ragunan',
  'Jagakarsa',
  'Ciganjur',
  'Lenteng Agung',
  'Tanjung Barat',
  'Bintaro',
  'Pesanggrahan',
  'Petukangan',
  'Ulujami',
  'Rempoa',
  'Cirendeu',
  'Cinere',
  'BSD',
  'Alam Sutera',
  'Gading Serpong',
  'Tangerang Selatan',
  'Depok',
  'Bogor',
  'Bekasi',
  'Jakarta Selatan',
  'Jakarta Pusat',
  'Jakarta Barat',
  'Jakarta Timur',
  'Jakarta Utara',
];

const List<String> kJakselAreaKeywords = [
  'cipete',
  'cilandak',
  'kebayoran',
  'pondok indah',
  'kemang',
  'bangka',
  'dharmawangsa',
  'wijaya',
  'senopati',
  'gunawarman',
  'senayan',
  'pakubuwono',
  'permata hijau',
  'simprug',
  'gandaria',
  'radio dalam',
  'pondok pinang',
  'lebak bulus',
  'fatmawati',
  'ampera',
  'jeruk purut',
  'pejaten',
  'pasar minggu',
  'jagakarsa',
  'ciganjur',
  'tebet',
  'pancoran',
  'mampang',
  'kalibata',
  'prapanca',
  'brawijaya',
  'melawai',
  'panglima polim',
  'hang lekir',
  'hang tuah',
  'pattimura',
  'sriwijaya',
  'bintaro',
  'pesanggrahan',
  'jakarta selatan',
  'jaksel',
];

bool parseSheetBool(Object? value) {
  if (value is bool) return value;
  if (value == null) return false;
  return {'true', '1', 'yes', 'ya', 'done', '✔'}
      .contains(value.toString().trim().toLowerCase());
}

DateTime? parseIndonesianDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);

  final google = RegExp(r'Date\((\d+),(\d+),(\d+)').firstMatch(text);
  if (google != null) {
    return DateTime(
      int.parse(google[1]!),
      int.parse(google[2]!) + 1,
      int.parse(google[3]!),
    );
  }

  final numeric =
      RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
  if (numeric != null) {
    return DateTime(
      int.parse(numeric[3]!),
      int.parse(numeric[2]!),
      int.parse(numeric[1]!),
    );
  }

  for (var i = 0; i < kIndonesianMonths.length; i++) {
    final match = RegExp(
      '(\\d{1,2})[\\s\\-]+${kIndonesianMonths[i]}[\\s\\-]+(\\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      return DateTime(int.parse(match[2]!), i + 1, int.parse(match[1]!));
    }
  }
  return null;
}

int parseIndonesianDateToComparable(String raw) {
  final dt = parseIndonesianDate(raw);
  if (dt == null) return 0;
  return dt.year * 10000 + dt.month * 100 + dt.day;
}

String formatIndonesianDateHeader(String raw) {
  final dt = parseIndonesianDate(raw);
  if (dt == null) return raw.trim().isEmpty ? 'Belum Dijadwalkan' : raw;
  final dayName = kIndonesianWeekdays[dt.weekday - 1];
  final monthName = kIndonesianMonths[dt.month - 1];
  return '$dayName, ${dt.day.toString().padLeft(2, '0')} $monthName ${dt.year}';
}

String formatIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String resolveLocationFromText(String text, {String fallback = ''}) {
  final lower = text.toLowerCase();
  for (final loc in kSortedLocations) {
    if (lower.contains(loc.toLowerCase())) {
      return loc;
    }
  }
  return fallback;
}

bool isJakselLocation(String text) {
  final lower = text.toLowerCase();
  for (final kw in kJakselAreaKeywords) {
    if (lower.contains(kw)) return true;
  }
  return false;
}

class ReelItem {
  final String no;
  final int row;
  final String idListing;
  final String driveLink;
  final String lokasi;
  final String spesifikasi;
  final String marketing;
  final bool isPosted;
  final String jadwalPosting;
  final String caption;

  ReelItem({
    dynamic no = '',
    this.row = 0,
    required this.idListing,
    this.driveLink = '',
    this.lokasi = '',
    String? spesifikasi,
    String? catatan,
    String? marketing,
    String? namaMe,
    bool? isPosted,
    bool? statusUpload,
    this.jadwalPosting = '',
    this.caption = '',
  })  : no = (no == null || no == 0) ? '' : no.toString().trim(),
        spesifikasi = spesifikasi ?? catatan ?? '',
        marketing = marketing ?? namaMe ?? '',
        isPosted = isPosted ?? statusUpload ?? false;

  String get namaMe => marketing;
  String get catatan => spesifikasi;
  bool get statusUpload => isPosted;
  bool get isPublished => isPosted;

  String get cleanId {
    final m = RegExp(r'\d+').firstMatch(idListing.trim());
    return m != null ? m.group(0)! : idListing.trim();
  }

  String? get driveFileId {
    if (driveLink.trim().isEmpty) return null;
    final dMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(driveLink);
    if (dMatch != null) return dMatch.group(1);
    final uri = Uri.tryParse(driveLink);
    return uri?.queryParameters['id'];
  }

  String get drivePreviewUrl => driveFileId != null
      ? 'https://drive.google.com/file/d/$driveFileId/preview'
      : driveLink;
  String get previewUrl => drivePreviewUrl;

  String get driveDownloadUrl => driveFileId != null
      ? 'https://drive.google.com/uc?export=download&id=$driveFileId'
      : driveLink;
  String get downloadUrl => driveDownloadUrl;

  String get driveThumbnailUrl => driveFileId != null
      ? 'https://drive.google.com/thumbnail?id=$driveFileId&sz=w800'
      : '';
  String get thumbnailUrl => driveThumbnailUrl;

  String get formattedSchedule => formatIndonesianDateHeader(jadwalPosting);

  ReelItem copyWith({
    dynamic no,
    int? row,
    String? idListing,
    String? driveLink,
    String? lokasi,
    String? spesifikasi,
    String? catatan,
    String? marketing,
    String? namaMe,
    bool? isPosted,
    bool? statusUpload,
    String? jadwalPosting,
    String? caption,
  }) =>
      ReelItem(
        no: no ?? this.no,
        row: row ?? this.row,
        idListing: idListing ?? this.idListing,
        driveLink: driveLink ?? this.driveLink,
        lokasi: lokasi ?? this.lokasi,
        spesifikasi: spesifikasi ?? catatan ?? this.spesifikasi,
        marketing: marketing ?? namaMe ?? this.marketing,
        isPosted: isPosted ?? statusUpload ?? this.isPosted,
        jadwalPosting: jadwalPosting ?? this.jadwalPosting,
        caption: caption ?? this.caption,
      );
}

class PublishFeedItem {
  final String uniqueKey;
  final String no;
  final int row;
  final int colIndex;
  final String idListing;
  final String namaMe;
  final String judul;
  final String catatan;
  final String lokasi;
  final String meetingDate;
  final String jadwalPosting;
  final String sheetName;
  final bool postingIg;
  final bool isEdited;
  final bool isFromMeeting;
  final EditFotoTask? sourceTask;
  final MeetingListing? sourceMeeting;

  PublishFeedItem({
    this.uniqueKey = '',
    dynamic no = '',
    this.row = 0,
    this.colIndex = 0,
    required this.idListing,
    this.namaMe = '',
    String? judul,
    this.catatan = '',
    this.lokasi = '',
    this.meetingDate = '',
    this.jadwalPosting = '',
    this.sheetName = '',
    this.postingIg = false,
    bool? isEdited,
    bool? meHighlighted,
    this.isFromMeeting = false,
    this.sourceTask,
    this.sourceMeeting,
  })  : no = (no == null || no == 0) ? '' : no.toString().trim(),
        judul = (judul != null && judul.trim().isNotEmpty)
            ? judul.trim()
            : (extractJudulFromNotes(catatan) ?? ''),
        isEdited = isEdited ?? meHighlighted ?? false;

  bool get meHighlighted => isEdited;

  String get cleanId {
    final m = RegExp(r'\d+').firstMatch(idListing.trim());
    return m != null ? m.group(0)! : idListing.trim();
  }

  bool get isPublished => postingIg;

  bool get isScheduled =>
      jadwalPosting.trim().isNotEmpty &&
      jadwalPosting.trim() != '-' &&
      !jadwalPosting.toLowerCase().contains('belum');

  String? get extractedJudul =>
      judul.isNotEmpty ? judul : extractJudulFromNotes(catatan);

  bool get isTurunHarga =>
      catatan.toLowerCase().contains('turun harga') ||
      judul.toLowerCase().contains('turun harga') ||
      (sourceMeeting?.isTurunHarga ?? false);

  bool get isJaksel => isJakselLocation('$lokasi $judul $catatan');

  PublishFeedItem copyWith({
    String? uniqueKey,
    dynamic no,
    int? row,
    int? colIndex,
    String? idListing,
    String? namaMe,
    String? judul,
    String? catatan,
    String? lokasi,
    String? meetingDate,
    String? jadwalPosting,
    String? sheetName,
    bool? postingIg,
    bool? isEdited,
    bool? meHighlighted,
    bool? isFromMeeting,
    EditFotoTask? sourceTask,
    MeetingListing? sourceMeeting,
  }) =>
      PublishFeedItem(
        uniqueKey: uniqueKey ?? this.uniqueKey,
        no: no ?? this.no,
        row: row ?? this.row,
        colIndex: colIndex ?? this.colIndex,
        idListing: idListing ?? this.idListing,
        namaMe: namaMe ?? this.namaMe,
        judul: judul ?? this.judul,
        catatan: catatan ?? this.catatan,
        lokasi: lokasi ?? this.lokasi,
        meetingDate: meetingDate ?? this.meetingDate,
        jadwalPosting: jadwalPosting ?? this.jadwalPosting,
        sheetName: sheetName ?? this.sheetName,
        postingIg: postingIg ?? this.postingIg,
        isEdited: isEdited ?? meHighlighted ?? this.isEdited,
        isFromMeeting: isFromMeeting ?? this.isFromMeeting,
        sourceTask: sourceTask ?? this.sourceTask,
        sourceMeeting: sourceMeeting ?? this.sourceMeeting,
      );
}
