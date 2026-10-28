import 'package:url_launcher/url_launcher.dart';
import '../../features/media/models/schedule.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';
import '../../features/publish/models/publish_item.dart';
import '../models/agent_contact.dart';
import '../services/rwc_scraper_service.dart';

class WhatsAppFormatter {
  static const String defaultFormatDone = '''Halo {honorific_name}.
Foto listing {id_listing} sudah kita update ya {greeting_short}.

Berikut info lengkap jadwal kegiatan untuk properti Anda:
📌 *ID Listing*: {id_listing}
🎬 *Tipe*: {type}
📅 *Jadwal*: {tanggal} pada {jam}
📍 *Lokasi*: {lokasi}
🏃 *Staff*: {staff}
⚡ *Status*: {status}

Detail lengkap properti website Ray White Cipete:
🔗 {link}

Terima kasih.''';

  static const String defaultFormatNotDone = '''{greeting} {honorific_name}.

Listing {honorific_long} {me_name} berikut kira-kira bisa kita ambil foto ulang kapan? agar kita dapat input ke dalam jadwal.

🔗 {link}

Terima kasih.''';

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
    if (clean.startsWith('bu ') ||
        clean.startsWith('bu/') ||
        clean.startsWith('ibu ')) {
      return 'Bu';
    }

    const maleNames = [
      'donny',
      'agung',
      'bayu',
      'ilham',
      'iskandar',
      'remmy',
      'sam',
      'santiaji',
      'vincent',
      'yayan',
      'haryadi',
      'rony',
      'dasep',
      'dedie',
      'dhenis',
      'zulkifli',
      'muljadi',
      'andika',
      'briand',
      'utomo',
    ];
    const femaleNames = [
      'dian',
      'dini',
      'dutta',
      'ifa',
      'ike',
      'imelda',
      'resmi',
      'indah',
      'ruby',
      'aii dyana',
      'ayu',
      'mari',
      'amelia',
      'hilda',
      'desy',
      'rika',
      'meisi',
      'yuma',
    ];

    for (final m in maleNames) {
      if (clean.contains(m)) return 'Pak';
    }
    for (final f in femaleNames) {
      if (clean.contains(f)) return 'Bu';
    }

    const standardFemaleKeywords = [
      'sri',
      'siti',
      'dewi',
      'putri',
      'fitri',
      'maria',
      'rani',
      'lia',
      'eka',
      'linda',
      'kartika',
      'nur',
      'sarah',
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

  /// Generates follow-up WhatsApp message with support for custom templates
  static String generateScheduleFollowUpMessage(
    Schedule schedule, {
    String? targetMeOverride,
    String? customTemplateDone,
    String? customTemplateNotDone,
  }) {
    final cleanId = schedule.cleanId;
    final targetMe = (targetMeOverride ?? schedule.namaMe).trim();
    final honorific = getHonorificForMe(targetMe);
    final honorificLong = getHonorificLongForMe(targetMe);
    final displayMeName = targetMe.isNotEmpty ? targetMe : 'ME Ray White';
    final greeting = getIndonesianTimeGreeting();

    final honorificName = targetMe.isNotEmpty
        ? (targetMe.toLowerCase().startsWith('pak') ||
                targetMe.toLowerCase().startsWith('bu')
            ? targetMe
            : (honorific != 'Pak/Bu'
                ? '$honorific $targetMe'
                : 'Pak/Bu $targetMe'))
        : 'ME Ray White';

    final websiteLink = cleanId.isNotEmpty
        ? 'https://raywhitecipete.net/ListingView/Detail/$cleanId'
        : 'https://raywhitecipete.net';

    final template = schedule.isDone
        ? (customTemplateDone != null && customTemplateDone.trim().isNotEmpty
            ? customTemplateDone
            : defaultFormatDone)
        : (customTemplateNotDone != null &&
                customTemplateNotDone.trim().isNotEmpty
            ? customTemplateNotDone
            : defaultFormatNotDone);

    return template
        .replaceAll('{greeting}', greeting)
        .replaceAll('{greeting_short}', honorific)
        .replaceAll('{honorific_name}', honorificName)
        .replaceAll('{honorific_long}', honorificLong)
        .replaceAll('{me_name}', displayMeName)
        .replaceAll(
            '{id_listing}', cleanId.isNotEmpty ? cleanId : '(Manual Input)')
        .replaceAll(
            '{lokasi}', schedule.lokasi.isNotEmpty ? schedule.lokasi : '-')
        .replaceAll('{tanggal}', schedule.tanggal)
        .replaceAll('{jam}', schedule.jam)
        .replaceAll('{staff}', schedule.staff)
        .replaceAll('{type}', schedule.type)
        .replaceAll('{status}', schedule.status)
        .replaceAll('{link}', websiteLink)
        .trim();
  }

  /// Builds Instagram Feed Caption matching Android's InstagramPostMockupScreen.kt
  static String buildInstagramCaption({
    required String idListing,
    required String namaMe,
    String customHeadline = '',
    String lokasi = '',
    ScrapedListingDetail? detail,
    List<AgentContact> customAgents = const [],
  }) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    final meLower = namaMe.toLowerCase();

    // Ilham Rule: If ME contains "Ilham" and no custom headline is set, use first line of web description
    String headline = customHeadline.trim();
    if (headline.isEmpty && meLower.contains('ilham') && detail != null) {
      final firstLine = detail.description
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => '');
      if (firstLine.isNotEmpty) {
        headline = firstLine;
      }
    }
    if (headline.isEmpty) {
      headline = (detail != null &&
              detail.title.isNotEmpty &&
              !detail.title.toLowerCase().contains('tidak ditemukan'))
          ? detail.title
          : (lokasi.isNotEmpty
              ? 'Properti Eksklusif di $lokasi'
              : 'Properti Pilihan Ray White Cipete');
    }

    final buf = StringBuffer();
    buf.writeln(headline.toUpperCase());
    buf.writeln();

    if (detail != null && detail.description.trim().isNotEmpty) {
      buf.writeln(detail.description.trim());
      buf.writeln();
    }

    // Canonical Spec Ordering: LT -> LB -> Dimensi -> KT -> KM -> Garasi -> Carport -> Sertifikat -> Menghadap
    final specs = <String>[];
    if (detail != null) {
      if (detail.lt.isNotEmpty) specs.add('• Luas Tanah: ${detail.lt} m²');
      if (detail.lb.isNotEmpty) specs.add('• Luas Bangunan: ${detail.lb} m²');
      if (detail.dimensi.isNotEmpty) specs.add('• Dimensi: ${detail.dimensi}');
      if (detail.kt.isNotEmpty) specs.add('• Kamar Tidur: ${detail.kt}');
      if (detail.km.isNotEmpty) specs.add('• Kamar Mandi: ${detail.km}');
      if (detail.garasi.isNotEmpty) specs.add('• Garasi: ${detail.garasi}');
      if (detail.carport.isNotEmpty) specs.add('• Carport: ${detail.carport}');
      if (detail.sertifikat.isNotEmpty) {
        specs.add('• Sertifikat: ${detail.sertifikat}');
      }
      if (detail.hadap.isNotEmpty) specs.add('• Menghadap: ${detail.hadap}');
    }

    if (specs.isNotEmpty) {
      buf.writeln('Spesifikasi:');
      for (final s in specs) {
        buf.writeln(s);
      }
      buf.writeln();
    }

    // Price Block: [FOR SALE] / [FOR RENT]
    if (detail != null) {
      if (detail.isForSale &&
          detail.hargaJual.isNotEmpty &&
          !detail.hargaJual.contains('Rp. 0')) {
        buf.writeln('[FOR SALE] ${detail.hargaJual}');
      } else if (detail.isForRent &&
          detail.hargaSewa.isNotEmpty &&
          !detail.hargaSewa.contains('Rp. 0')) {
        buf.writeln('[FOR RENT] ${detail.hargaSewa}');
      } else if (detail.price.isNotEmpty) {
        final tag = detail.isForRent ? '[FOR RENT]' : '[FOR SALE]';
        buf.writeln('$tag ${detail.price}');
      }
      buf.writeln();
    }

    // Multi-Agent Contact Block
    final agentSource = namaMe.trim().isNotEmpty
        ? namaMe.trim()
        : (detail?.agentName ?? 'Ray White Cipete');
    final parsedNames = parseMultipleAgentNames(agentSource);

    buf.writeln('More Info:');
    if (parsedNames.isNotEmpty) {
      for (final name in parsedNames) {
        final contact = findAgentContact(name, customAgents: customAgents);
        if (contact != null) {
          buf.writeln(
              '👤 ${contact.displayName} — ${contact.formattedPhoneDisplay}');
        } else {
          buf.writeln('👤 $name');
        }
      }
    } else {
      buf.writeln('👤 Ray White Cipete — 0851-6967-1344');
    }

    buf.writeln('🏢 Ray White Cipete');
    if (cleanId.isNotEmpty) {
      buf.writeln('🆔 ID Listing: #$cleanId');
      buf.writeln('🔗 https://raywhitecipete.net/ListingView/Detail/$cleanId');
    }
    buf.writeln();
    buf.writeln(
      '#RayWhiteCipete #RayWhiteIndonesia #PropertiJakartaSelatan #RumahDijualJakartaSelatan #ListingRWC',
    );

    return buf.toString().trim();
  }

  /// Builds Instagram Reels Caption matching Android's PublishScreen.kt
  static String buildReelCaption(
    ReelItem reel, {
    ScrapedListingDetail? detail,
    List<AgentContact> customAgents = const [],
  }) {
    final buf = StringBuffer();
    final title = detail != null && detail.title.isNotEmpty
        ? detail.title
        : (reel.lokasi.isNotEmpty
            ? 'HUNIAN EKSKLUSIF DI ${reel.lokasi.toUpperCase()}'
            : 'PROPERTI PILIHAN RAY WHITE CIPETE');

    buf.writeln('✨ $title ✨');
    buf.writeln();
    if (reel.lokasi.isNotEmpty) {
      buf.writeln('📍 Lokasi: ${reel.lokasi}');
    }
    if (reel.spesifikasi.isNotEmpty) {
      buf.writeln('🏡 Spesifikasi:');
      buf.writeln(reel.spesifikasi.trim());
      buf.writeln();
    }
    if (detail != null && detail.price.isNotEmpty) {
      buf.writeln('💰 Harga: ${detail.price}');
      buf.writeln();
    }

    final names = parseMultipleAgentNames(reel.marketing);
    buf.writeln('More Info:');
    if (names.isNotEmpty) {
      for (final n in names) {
        final c = findAgentContact(n, customAgents: customAgents);
        if (c != null) {
          buf.writeln('📞 ${c.displayName}: ${c.formattedPhoneDisplay}');
        } else {
          buf.writeln('📞 $n');
        }
      }
    } else {
      buf.writeln('📞 Ray White Cipete: 0851-6967-1344');
    }

    if (reel.cleanId.isNotEmpty) {
      buf.writeln('🆔 ID Listing: #${reel.cleanId}');
    }
    buf.writeln();
    buf.writeln(
      '#ReelsProperti #RayWhiteCipete #RumahJakartaSelatan #LuxuryHomesJakarta #PropertyTour',
    );
    return buf.toString().trim();
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
    if (listing.judul.isNotEmpty) {
      buffer.writeln('🏡 *Judul/Ket:* ${listing.judul}');
    }
    if (listing.lokasi.isNotEmpty) {
      buffer.writeln('📍 *Lokasi:* ${listing.lokasi}');
    }
    buffer.writeln(
        '📱 *Posting IG:* ${listing.postingIg ? "✅ Sudah" : "⏳ Belum"}');
    if (listing.catatan.isNotEmpty) {
      buffer.writeln('📝 *Catatan:* ${listing.catatan}');
    }
    if (websiteLink.isNotEmpty) {
      buffer.writeln('🔗 *Detail Website:* $websiteLink');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✨ _RWC Media Production Mobile_');
    return buffer.toString();
  }

  /// Builds Analytic Weekly Meeting Report for WhatsApp
  static String buildWeeklyReportText({
    required String month,
    required String meetingDate,
    required List<MeetingListing> listings,
  }) {
    final buf = StringBuffer();
    buf.writeln('📊 *LAPORAN WEEKLY MEETING — ${month.toUpperCase()}*');
    if (meetingDate.isNotEmpty) {
      buf.writeln('📅 *Tanggal Meeting:* $meetingDate');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Total Listing Dibahas: *${listings.length} Listing*');

    final igListings =
        listings.where((l) => l.keterangan.toUpperCase().contains('IG')).toList();
    final postedIg = igListings.where((l) => l.postingIg).length;
    buf.writeln('Target Posting IG: *$postedIg / ${igListings.length} Selesai*');
    buf.writeln();

    for (var i = 0; i < listings.length; i++) {
      final l = listings[i];
      final statusIcon = l.postingIg ? '✅' : '⏳';
      buf.writeln(
        '${i + 1}. $statusIcon *#${l.cleanId.isNotEmpty ? l.cleanId : l.idListing}* — ${l.namaMe} (${l.keterangan.isNotEmpty ? l.keterangan : "-"})',
      );
      if (l.lokasi.isNotEmpty) {
        buf.writeln('   📍 ${l.lokasi}');
      }
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('✨ _RWC Media Production_');
    return buf.toString().trim();
  }

  /// Builds Analytic Jadwal Foto Report ("Update Foto Raffa - David Bulan ...")
  static String buildJadwalFotoReportText({
    required String month,
    required List<Schedule> schedules,
  }) {
    final buf = StringBuffer();
    buf.writeln('*Update Foto Raffa - David Bulan $month*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    final doneList = schedules.where((s) => s.isDone).toList();
    final activeList = schedules.where((s) => s.isActive).toList();
    final nonActiveList = schedules.where((s) => s.isNonActive).toList();

    buf.writeln('📸 Total Jadwal: *${schedules.length}*');
    buf.writeln('✅ Selesai (Done): *${doneList.length}*');
    buf.writeln('⏳ Aktif (On Progress): *${activeList.length}*');
    buf.writeln('⚠️ Non-Aktif (Pending): *${nonActiveList.length}*');
    buf.writeln();

    if (doneList.isNotEmpty) {
      buf.writeln('*Daftar Selesai (Done):*');
      for (var i = 0; i < doneList.length; i++) {
        final s = doneList[i];
        buf.writeln(
          '${i + 1}. #${s.cleanId.isNotEmpty ? s.cleanId : "-"} | ${s.namaMe} | ${s.lokasi} (${s.tanggal})',
        );
      }
      buf.writeln();
    }

    if (activeList.isNotEmpty) {
      buf.writeln('*Daftar Jadwal Aktif:*');
      for (var i = 0; i < activeList.length; i++) {
        final s = activeList[i];
        buf.writeln(
          '${i + 1}. #${s.cleanId.isNotEmpty ? s.cleanId : "-"} | ${s.namaMe} | ${s.lokasi} (${s.tanggal} ${s.jam})',
        );
      }
    }

    return buf.toString().trim();
  }

  /// Sends text via WhatsApp or WhatsApp Business
  static Future<bool> openWhatsApp({
    String phoneNumber = '',
    required String message,
    bool preferBusiness = false,
  }) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final encodedMessage = Uri.encodeComponent(message);

    // On iOS, standard wa.me universal link opens WhatsApp or WA Business seamlessly
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
