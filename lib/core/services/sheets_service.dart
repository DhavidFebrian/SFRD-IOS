import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';

class SheetsService {
  static const String defaultAppsScriptUrl =
      'https://script.google.com/macros/s/AKfycbytrM7-rYQ_EjK9pzHJn4GvFL8j9ypajc6-BzzAqbCCbawXoXf9Gi9E0ECPNmjVsXIH/exec';
  static const String keyApiUrl = 'custom_apps_script_url';

  static final SheetsService _instance = SheetsService._internal();
  factory SheetsService() => _instance;
  SheetsService._internal();

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(keyApiUrl);
    if (url != null && url.trim().isNotEmpty) {
      return url.trim();
    }
    return defaultAppsScriptUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyApiUrl, url.trim());
  }

  String getWeeklyMeetingSheetNameForMonth(int monthIndex, int year) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final shortYear = (year % 100).toString().padLeft(2, '0');
    final monthName = (monthIndex >= 0 && monthIndex < 12) ? months[monthIndex] : 'Sep';
    return 'WM $monthName $shortYear';
  }

  Future<List<MeetingListing>> fetchWeeklyMeetingListings({String? sheetName}) async {
    final baseUrl = await getBaseUrl();
    final now = DateTime.now();
    final targetSheet = sheetName ?? getWeeklyMeetingSheetNameForMonth(now.month - 1, now.year);
    
    final separator = baseUrl.contains('?') ? '&' : '?';
    final url = Uri.parse('$baseUrl${separator}action=get_all_weekly_meeting_listings&sheetName=${Uri.encodeComponent(targetSheet)}');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && (data['status'] == 'success' || data['listings'] != null)) {
          final list = (data['listings'] as List? ?? []);
          return list.map((item) => MeetingListing.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      // Fallback or offline error handling
    }
    return [];
  }

  Future<bool> addWeeklyMeetingListing({
    required String idListing,
    required String namaMe,
    required String keterangan,
    required String catatan,
    String lokasi = '',
    String? sheetName,
    String? date,
  }) async {
    final baseUrl = await getBaseUrl();
    final now = DateTime.now();
    final targetSheet = sheetName ?? getWeeklyMeetingSheetNameForMonth(now.month - 1, now.year);
    final targetDate = date ?? '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final payload = {
      'action': 'add_weekly_meeting_listing',
      'sheetName': targetSheet,
      'date': targetDate,
      'idListing': idListing,
      'namaMe': namaMe,
      'keterangan': keterangan,
      'catatan': catatan,
      'lokasi': lokasi,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map && data['status'] == 'success';
      }
    } catch (e) {
      // Return false on failure
    }
    return false;
  }
}
