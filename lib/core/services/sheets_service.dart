import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/media/models/schedule.dart';
import '../../features/tasks/models/edit_foto_task.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';

class SheetsDataResponse {
  final List<Schedule> schedules;
  final List<EditFotoTask> editFotoTasks;

  SheetsDataResponse({
    required this.schedules,
    required this.editFotoTasks,
  });
}

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

  /// Fetches schedules and edit foto tasks for a given sheet (month, e.g. "Juni 2026", "Foto Ulang")
  Future<SheetsDataResponse> fetchMonthData(String sheetName) async {
    final baseUrl = await getBaseUrl();
    final separator = baseUrl.contains('?') ? '&' : '?';
    final url = Uri.parse('$baseUrl${separator}sheetName=${Uri.encodeComponent(sheetName)}');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final bodyStr = response.body.trim();
        if (bodyStr.startsWith('{')) {
          final data = json.decode(bodyStr);
          final schedList = <Schedule>[];
          final taskList = <EditFotoTask>[];

          if (data is Map) {
            if (data['schedules'] is List) {
              for (var item in data['schedules']) {
                if (item is Map<String, dynamic>) {
                  schedList.add(Schedule.fromJson(item, sheetName));
                }
              }
            }
            if (data['editFotoTasks'] is List) {
              for (var item in data['editFotoTasks']) {
                if (item is Map<String, dynamic>) {
                  taskList.add(EditFotoTask.fromJson(item, sheetName));
                }
              }
            }
          }
          return SheetsDataResponse(schedules: schedList, editFotoTasks: taskList);
        } else if (bodyStr.startsWith('[')) {
          final list = json.decode(bodyStr) as List;
          final schedList = list
              .whereType<Map<String, dynamic>>()
              .map((item) => Schedule.fromJson(item, sheetName))
              .toList();
          return SheetsDataResponse(schedules: schedList, editFotoTasks: []);
        }
      }
    } catch (e) {
      // Return empty response on error or timeout
    }
    return SheetsDataResponse(schedules: [], editFotoTasks: []);
  }

  /// Fetches weekly meeting listings
  Future<List<MeetingListing>> fetchWeeklyMeetingListings(String sheetName, [String? date]) async {
    final baseUrl = await getBaseUrl();
    final separator = baseUrl.contains('?') ? '&' : '?';
    var query = 'action=get_all_weekly_meeting_listings&sheetName=${Uri.encodeComponent(sheetName)}';
    if (date != null && date.trim().isNotEmpty) {
      query += '&date=${Uri.encodeComponent(date.trim())}';
    }
    final url = Uri.parse('$baseUrl$separator$query');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && (data['status'] == 'success' || data['listings'] != null)) {
          final list = (data['listings'] as List? ?? []);
          return list
              .whereType<Map<String, dynamic>>()
              .map((item) => MeetingListing.fromJson(item, sheetName))
              .toList();
        }
      }
    } catch (e) {
      // Handled
    }
    return [];
  }

  /// Updates an Edit Foto Task (checkbox Done, Posting IG, Notes)
  Future<bool> updateEditFotoTask(EditFotoTask task, String sheetName) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'edit_foto',
      'no': task.no,
      'idListing': task.idListing,
      'namaMe': task.namaMe,
      'postingIg': task.postingIg,
      'jadwalPosting': task.jadwalPosting,
      'editNotes': task.editNotes,
      'done': task.done,
      'judul': task.judul,
      'source': task.source,
      'sheetName': sheetName,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map && (data['status'] == 'success' || data['status'] == 'ok');
      }
    } catch (e) {
      // Error
    }
    return false;
  }

  /// Adds a new schedule to Google Sheets
  Future<bool> addSchedule(Schedule schedule) async {
    final baseUrl = await getBaseUrl();
    final payload = schedule.toJson();

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map && (data['status'] == 'success' || data['status'] == 'ok');
      }
    } catch (e) {
      // Error
    }
    return false;
  }

  /// Adds a new weekly meeting listing to Google Sheets
  Future<bool> addWeeklyMeetingListing({
    required String idListing,
    required String namaMe,
    required String keterangan,
    required String catatan,
    String lokasi = '',
    required String sheetName,
    required String date,
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'add_weekly_meeting_listing',
      'sheetName': sheetName,
      'date': date,
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
        return data is Map && (data['status'] == 'success' || data['status'] == 'ok');
      }
    } catch (e) {
      // Error
    }
    return false;
  }

  /// Updates Weekly Meeting posting IG status
  Future<bool> updateMeetingPostingIg({
    required String sheetName,
    required String date,
    required int row,
    required int colIndex,
    required bool postingIg,
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'update_weekly_meeting_posting_ig',
      'sheetName': sheetName,
      'date': date,
      'row': row,
      'colIndex': colIndex,
      'postingIg': postingIg,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map && (data['status'] == 'success' || data['status'] == 'ok');
      }
    } catch (e) {
      // Error
    }
    return false;
  }

  /// Deletes a Weekly Meeting listing
  Future<bool> deleteMeetingListing({
    required String sheetName,
    required String date,
    required int row,
    required int colIndex,
    required String idListing,
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'delete_weekly_meeting_listing',
      'sheetName': sheetName,
      'date': date,
      'row': row,
      'colIndex': colIndex,
      'idListing': idListing,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map && (data['status'] == 'success' || data['status'] == 'ok');
      }
    } catch (e) {
      // Error
    }
    return false;
  }
}
