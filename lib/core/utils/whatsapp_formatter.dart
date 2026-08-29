import 'package:url_launcher/url_launcher.dart';

class WhatsAppFormatter {
  /// Membuka aplikasi WhatsApp dengan pesan yang sudah diformat
  static Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    // Normalisasi nomor telepon ke format internasional (misal 0812 -> 62812)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Membuat format teks broadcast Weekly Meeting listing properti
  static String formatWeeklyMeetingBroadcast({
    required String idListing,
    required String namaMe,
    required String judul,
    required String harga,
    required String catatan,
    required String status,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *WEEKLY MEETING UPDATE*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🆔 *ID Listing:* $idListing');
    if (namaMe.isNotEmpty) buffer.writeln('👤 *ME:* $namaMe');
    if (judul.isNotEmpty) buffer.writeln('🏡 *Judul:* $judul');
    if (harga.isNotEmpty) buffer.writeln('💰 *Harga:* $harga');
    if (status.isNotEmpty) buffer.writeln('🏷️ *Status:* $status');
    if (catatan.isNotEmpty) {
      buffer.writeln('📝 *Catatan:* $catatan');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✨ _Generated via SFRD iOS_');
    return buffer.toString();
  }
}
