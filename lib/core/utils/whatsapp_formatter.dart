import 'package:url_launcher/url_launcher.dart';
import '../../features/media/models/schedule.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';

class WhatsAppFormatter {
  static String getIndonesianTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour <= 10) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour <= 14) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour <= 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  static String getHonorificForMe(String name) {
    final clean = name.toLowerCase().trim();
    if (clean.startsWith('pak ') || clean.startsWith('pak/')) return 'Pak';
    if (clean.startsWith('bu ') || clean.startsWith('bu/') || clean.startsWith('ibu ')) return 'Bu';

    const maleNames = [
      'donny', 'agung', 'bayu', 'ilham', 'iskandar', 'remmy', 'sam', 'santiaji',
      'vincent', 'yayan', 'haryadi', 'rony', 'dasep', 'dedie', 'dhenis',
      'zulkifli', 'muljadi', 'andika', 'briand'
    ];
    const femaleNames = [
      'dian', 'dini', 'dutta', 'ifa', 'ike', 'imelda', 'resmi', 'indah',
      'ruby', 'aii dyana', 'ayu', 'mari', 'amelia', 'hilda', 'desy',
      'rika', 'meisi', 'yuma'
    ];

    for (final m in maleNames) {
      if (clean.contains(m)) return 'Pak';
    }
    for (final f in femaleNames) {
      if (clean.contains(f)) return 'Bu';
    }

    const standardFemaleKeywords = [
      'sri', 'siti', 'dewi', 'putri', 'fitri', 'maria', 'rani', 'lia',
      'eka', 'linda', 'kartika', 'nur', 'sarah'
    ];
    if (standardFemaleKeywords.any((k) => clean.contains(k))) {
      return 'Bu';
    }

    return 'Pak/Bu';
  }

  static String getHonorificLongForMe(String name) {
    final honorific = getHonorificForMe(name);
    return honorific == 'Bu' ? 'Ibu' : 'Pak';
  }

  /// Generates follow-up WhatsApp message matching Android ScheduleRepository & WhatsAppFormatter
  static String generateScheduleFollowUpMessage(Schedule schedule) {
    final cleanId = schedule.cleanId;
    final targetMe = schedule.namaMe.trim();
    final honorific = getHonorificForMe(targetMe);
    final honorificLong = getHonorificLongForMe(targetMe);
    final displayMeName = targetMe.isNotEmpty ? targetMe : 'ME Ray White';

    final greetingName = targetMe.isNotEmpty
        ? (targetMe.toLowerCase().startsWith('pak') || targetMe.toLowerCase().startsWith('bu')
            ? targetMe
            : (honorific != 'Pak/Bu' ? '$honorific $targetMe' : 'Pak/Bu $targetMe'))
        : 'ME Ray White';

    final websiteLink = cleanId.isNotEmpty
        ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
        : 'https://raywhitecipete.net';

    if (schedule.isDone) {
      return '''
Halo $greetingName.
Foto listing ${cleanId.isNotEmpty ? cleanId : "(Manual Input)"} sudah kita update ya $honorific.

Berikut info lengkap jadwal kegiatan untuk properti Anda:
📌 *ID Listing*: ${cleanId.isNotEmpty ? cleanId : "(Manual Input)"}
🎬 *Tipe*: ${schedule.type}
📅 *Jadwal*: ${schedule.tanggal} pada ${schedule.jam}
📍 *Lokasi*: ${schedule.lokasi.isNotEmpty ? schedule.lokasi : "-"}
🏃 *Staff*: ${schedule.staff}
⚡ *Status*: ${schedule.status}

Detail lengkap properti website Ray White Cipete:
🔗 $websiteLink

Terima kasih.
'''.trim();
    } else {
      final greeting = getIndonesianTimeGreeting();
      return '''
$greeting $honorific $displayMeName.

Listing $honorificLong $displayMeName berikut kira-kira bisa kita ambil foto ulang kapan? agar kita dapat input ke dalam jadwal.

🔗 $websiteLink

Terima kasih.
'''.trim();
    }
  }

  /// Generates Weekly Meeting broadcast message matching Android format
  static String generateWeeklyMeetingBroadcast(MeetingListing listing) {
    final cleanId = listing.cleanId;
    final websiteLink = cleanId.isNotEmpty
        ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
        : '';

    final buffer = StringBuffer();
    buffer.writeln('📋 *WEEKLY MEETING UPDATE*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🆔 *ID Listing:* ${listing.idListing}');
    if (listing.namaMe.isNotEmpty) buffer.writeln('👤 *ME:* ${listing.namaMe}');
    if (listing.judul.isNotEmpty) buffer.writeln('🏡 *Judul/Ket:* ${listing.judul}');
    if (listing.lokasi.isNotEmpty) buffer.writeln('📍 *Lokasi:* ${listing.lokasi}');
    buffer.writeln('📱 *Posting IG:* ${listing.postingIg ? "✅ Sudah" : "⏳ Belum"}');
    if (listing.catatan.isNotEmpty) buffer.writeln('📝 *Catatan:* ${listing.catatan}');
    if (websiteLink.isNotEmpty) {
      buffer.writeln('🔗 *Detail Website:* $websiteLink');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✨ _RWC Media Production Mobile_');
    return buffer.toString();
  }

  /// Sends text via WhatsApp
  static Future<bool> openWhatsApp({String phoneNumber = '', required String message}) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final urlStr = cleanNumber.isNotEmpty
        ? 'https://wa.me/$cleanNumber?text=$encodedMessage'
        : 'https://api.whatsapp.com/send?text=$encodedMessage';

    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
