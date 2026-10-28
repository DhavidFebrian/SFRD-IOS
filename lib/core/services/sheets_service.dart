import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/media/models/schedule.dart';
import '../../features/tasks/models/edit_foto_task.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';
import '../../features/publish/models/publish_item.dart';
import '../models/absensi_models.dart';
import '../models/chat_message.dart';

class SheetsDataResponse {
  final List<Schedule> schedules;
  final List<EditFotoTask> editFotoTasks;

  SheetsDataResponse({
    required this.schedules,
    required this.editFotoTasks,
  });
}

class YearlyIgHistoryItem {
  final String idListing;
  final String sheetName;
  final String date;
  final String source;
  final String namaMe;
  final String keterangan;

  const YearlyIgHistoryItem({
    required this.idListing,
    this.sheetName = '',
    this.date = '',
    this.source = '',
    this.namaMe = '',
    this.keterangan = '',
  });

  factory YearlyIgHistoryItem.fromJson(Map<String, dynamic> json) {
    return YearlyIgHistoryItem(
      idListing: (json['idListing'] ?? json['id_listing'] ?? '').toString(),
      sheetName: (json['sheetName'] ?? json['month'] ?? '').toString(),
      date: (json['date'] ?? json['jadwalPosting'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      namaMe: (json['namaMe'] ?? '').toString(),
      keterangan: (json['keterangan'] ?? '').toString(),
    );
  }
}

class SheetsService {
  static const String defaultAppsScriptUrl =
      'https://script.google.com/macros/s/AKfycbxigpXtPgjTlAKhTDLeTm_UlVrVtXs3864ybMElNbNA2Yz8sMBXhjPAtZ_NxVQn8qQQ/exec';
  static const String defaultSpreadsheetId =
      '1L0ajG9dAmhisDQ7ADil5KKNRkzgXp_jdCi41-6mPkIw';
  static const String reelsGvizUrl =
      'https://docs.google.com/spreadsheets/d/1ydmss-ADSeJpw7KJyQzT44RUNaqu5wJ0UJrIxn_8EmY/gviz/tq?tqx=out:json&gid=506914265&range=B4:H1000';

  static const Set<String> oldDeprecatedUrls = {
    'https://script.google.com/macros/s/AKfycbxRn3d7uC-mHT5yW0W9p-5N7s0oR-V1L1f-H9n-eG_C/exec',
    'https://script.google.com/macros/s/AKfycbyoG2K5b8U0w0-3_p8c-R7_j3b-G4X2p2-l_H0/exec',
    'https://script.google.com/macros/s/AKfycbzXp2p6-k6d8J0L3m8_p8c-R7_j3b-G4X2p2-l_H0/exec',
    'https://script.google.com/macros/s/AKfycbz-rG-m4V5L5n6P0W9p-5N7s0oR-V1L1f-H9n-eG_C/exec',
    'https://script.google.com/macros/s/AKfycbytrM7-rYQ_EjK9pzHJn4GvFL8j9ypajc6-BzzAqbCCbawXoXf9Gi9E0ECPNmjVsXIH/exec',
    'https://script.google.com/macros/s/AKfycbwfG4qR33aC4uG4wQvEwB9r02bF8tF5K8q1k-k3/exec',
    'https://script.google.com/macros/s/AKfycbyqQvEwB9r02bF8tF5K8q1k-k3/exec',
    'https://script.google.com/macros/s/AKfycbwQvEwB9r02bF8tF5K8q1k-k3/exec',
    'https://script.google.com/macros/s/AKfycbw7aP1L-k9m2N0W9p-5N7s0oR-V1L1f-H9n-eG_C/exec',
    'https://script.google.com/macros/s/AKfycbz9nL2m3K4p5Q6r7S8t9U0v1W2x3Y4z5A6B7C8D9E0F/exec',
  };

  static const String keyApiUrl = 'custom_apps_script_url';
  static const String keyChatApiUrl = 'custom_chat_apps_script_url';
  static const String keyCaptionApiUrl = 'custom_caption_apps_script_url';
  static const String keySpreadsheetId = 'custom_spreadsheet_id';

  static final SheetsService _instance = SheetsService._internal();
  factory SheetsService() => _instance;
  SheetsService._internal();

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(keyApiUrl)?.trim();
    if (url != null && url.isNotEmpty) {
      if (oldDeprecatedUrls.contains(url)) {
        await prefs.setString(keyApiUrl, defaultAppsScriptUrl);
        return defaultAppsScriptUrl;
      }
      return url;
    }
    return defaultAppsScriptUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      keyApiUrl,
      url.trim().isEmpty ? defaultAppsScriptUrl : url.trim(),
    );
  }

  Future<String> getChatUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(keyChatApiUrl)?.trim();
    if (url != null && url.isNotEmpty && !oldDeprecatedUrls.contains(url)) {
      return url;
    }
    return getBaseUrl();
  }

  Future<void> setChatUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyChatApiUrl, url.trim());
  }

  Future<String> getCaptionUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(keyCaptionApiUrl)?.trim();
    if (url != null && url.isNotEmpty && !oldDeprecatedUrls.contains(url)) {
      return url;
    }
    return getBaseUrl();
  }

  Future<void> setCaptionUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCaptionApiUrl, url.trim());
  }

  Future<String> getSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(keySpreadsheetId)?.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return defaultSpreadsheetId;
  }

  Future<void> setSpreadsheetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      keySpreadsheetId,
      id.trim().isEmpty ? defaultSpreadsheetId : id.trim(),
    );
  }

  /// Sends POST JSON to Google Apps Script, handling 302/303 redirects seamlessly
  Future<Map<String, dynamic>?> _postJson(
    String targetUrl,
    Map<String, dynamic> payload,
  ) async {
    try {
      final client = http.Client();
      try {
        final request = http.Request('POST', Uri.parse(targetUrl))
          ..followRedirects = false
          ..headers['Content-Type'] = 'application/json'
          ..body = json.encode(payload);

        final streamedResponse =
            await client.send(request).timeout(const Duration(seconds: 20));
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 302 ||
            response.statusCode == 303 ||
            response.statusCode == 301 ||
            response.statusCode == 307) {
          final location = response.headers['location'];
          if (location != null && location.isNotEmpty) {
            response = await client
                .get(Uri.parse(location))
                .timeout(const Duration(seconds: 20));
          } else {
            return {'status': 'success'};
          }
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = response.body.trim();
          if (body.startsWith('{')) {
            return json.decode(body) as Map<String, dynamic>;
          }
          return {'status': 'success', 'raw': body};
        }
      } finally {
        client.close();
      }
    } catch (_) {}
    return null;
  }

  bool _isSuccessResponse(Map<String, dynamic>? data) {
    if (data == null) return false;
    final status = (data['status'] ?? '').toString().toLowerCase();
    return status == 'success' ||
        status == 'ok' ||
        data['success'] == true ||
        status.isEmpty;
  }

  /// Fetches schedules and edit foto tasks for a given sheet (month, e.g. "Juni 2026", "Foto Ulang")
  Future<SheetsDataResponse> fetchMonthData(String sheetName) async {
    final baseUrl = await getBaseUrl();
    final separator = baseUrl.contains('?') ? '&' : '?';
    final url = Uri.parse(
        '$baseUrl${separator}sheetName=${Uri.encodeComponent(sheetName)}');

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
          return SheetsDataResponse(
              schedules: schedList, editFotoTasks: taskList);
        } else if (bodyStr.startsWith('[')) {
          final list = json.decode(bodyStr) as List;
          final schedList = list
              .whereType<Map<String, dynamic>>()
              .map((item) => Schedule.fromJson(item, sheetName))
              .toList();
          return SheetsDataResponse(schedules: schedList, editFotoTasks: []);
        }
      }
    } catch (_) {}
    return SheetsDataResponse(schedules: [], editFotoTasks: []);
  }

  /// Fetches schedules & tasks across multiple months in parallel
  Future<Map<String, SheetsDataResponse>> fetchMultiMonthData(
      List<String> months) async {
    final entries = await Future.wait(
      months.map((m) async => MapEntry(m, await fetchMonthData(m))),
    );
    return Map.fromEntries(entries);
  }

  /// Fetches weekly meeting listings
  Future<List<MeetingListing>> fetchWeeklyMeetingListings(String sheetName,
      [String? date]) async {
    final baseUrl = await getBaseUrl();
    final separator = baseUrl.contains('?') ? '&' : '?';
    var query =
        'action=get_all_weekly_meeting_listings&sheetName=${Uri.encodeComponent(sheetName)}';
    if (date != null && date.trim().isNotEmpty) {
      query += '&date=${Uri.encodeComponent(date.trim())}';
    }
    final url = Uri.parse('$baseUrl$separator$query');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map &&
            (data['status'] == 'success' || data['listings'] != null)) {
          final list = (data['listings'] as List? ?? []);
          return list
              .whereType<Map<String, dynamic>>()
              .map((item) => MeetingListing.fromJson(item, sheetName))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Saves a schedule (`add`, `edit`, or `delete`)
  Future<bool> saveSchedule(Schedule schedule, {String action = 'add'}) async {
    final baseUrl = await getBaseUrl();
    final payload = schedule.toJson(action: action);
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
  }

  /// Backwards-compatible helper for adding a schedule
  Future<bool> addSchedule(Schedule schedule) =>
      saveSchedule(schedule, action: 'add');

  /// Updates an Edit Foto Task (checkbox Done, Posting IG, Jadwal Posting, Notes)
  Future<bool> updateEditFotoTask(EditFotoTask task, String sheetName) async {
    final baseUrl = await getBaseUrl();
    final payload = task.toJson(sheetNameOverride: sheetName);
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
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
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
  }

  /// Updates Weekly Meeting details (Edit mode)
  Future<bool> updateWeeklyMeetingDetails({
    required String sheetName,
    required String date,
    required int row,
    required int colIndex,
    required String idListing,
    required String namaMe,
    required String keterangan,
    required String catatan,
    String lokasi = '',
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'update_weekly_meeting_details',
      'sheetName': sheetName,
      'date': date,
      'row': row,
      'colIndex': colIndex,
      'idListing': idListing,
      'namaMe': namaMe,
      'keterangan': keterangan,
      'catatan': catatan,
      'lokasi': lokasi,
    };
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
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
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
  }

  /// Updates Weekly Meeting ME Highlight (`Sudah Edit` / `Tandai ME`)
  Future<bool> updateMeetingMeHighlight({
    required String sheetName,
    required String date,
    required int row,
    required int colIndex,
    required String idListing,
    required bool highlight,
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'update_weekly_meeting_me_highlight',
      'sheetName': sheetName,
      'date': date,
      'row': row,
      'colIndex': colIndex,
      'idListing': idListing,
      'highlight': highlight,
    };
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
  }

  /// Updates Weekly Meeting Jadwal Posting (`Scheduling`)
  Future<bool> updateMeetingSchedule({
    required String sheetName,
    required String date,
    required int row,
    required int colIndex,
    required String idListing,
    required String jadwalPosting,
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'update_weekly_meeting_schedule',
      'sheetName': sheetName,
      'date': date,
      'row': row,
      'colIndex': colIndex,
      'idListing': idListing,
      'jadwalPosting': jadwalPosting,
    };
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
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
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
  }

  /// Fetches Absensi Meeting data for a given sheet/month
  Future<AbsensiResponse> fetchAbsensiMeeting(String sheetName) async {
    final baseUrl = await getBaseUrl();
    final separator = baseUrl.contains('?') ? '&' : '?';
    final url = Uri.parse(
      '$baseUrl${separator}action=get_absensi_meeting&sheetName=${Uri.encodeComponent(sheetName)}',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return AbsensiResponse.fromJson(data);
        }
      }
    } catch (_) {}
    return const AbsensiResponse();
  }

  /// Updates Absensi Meeting attendance cell
  Future<bool> updateAbsensiMeeting({
    required String sheetName,
    required int row,
    required int col,
    required bool present,
  }) async {
    final baseUrl = await getBaseUrl();
    final payload = {
      'action': 'update_absensi_meeting',
      'sheetName': sheetName,
      'row': row,
      'col': col,
      'present': present,
    };
    final res = await _postJson(baseUrl, payload);
    return _isSuccessResponse(res);
  }

  /// Fetches 2026 Yearly IG Posting History across all months
  Future<List<YearlyIgHistoryItem>> fetchYearlyIgPostingHistory() async {
    final baseUrl = await getBaseUrl();
    final separator = baseUrl.contains('?') ? '&' : '?';
    final url = Uri.parse(
        '$baseUrl${separator}action=get_yearly_ig_posting_history');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          final rawList = data['history'] ?? data['items'] ?? data['data'];
          if (rawList is List) {
            return rawList
                .whereType<Map<String, dynamic>>()
                .map(YearlyIgHistoryItem.fromJson)
                .toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetches Reels from Google Sheets GViz endpoint (`gid=506914265`, `range=B4:H1000`)
  Future<List<ReelItem>> fetchReels() async {
    try {
      final response = await http
          .get(Uri.parse(reelsGvizUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final body = response.body;
        final startIdx = body.indexOf('{');
        final endIdx = body.lastIndexOf('}');
        if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
          final jsonStr = body.substring(startIdx, endIdx + 1);
          final data = json.decode(jsonStr);
          final rows = data['table']?['rows'] as List? ?? [];
          final items = <ReelItem>[];

          for (var i = 0; i < rows.length; i++) {
            final rowObj = rows[i];
            if (rowObj is! Map) continue;
            final cells = rowObj['c'] as List? ?? [];
            String cellVal(int idx) {
              if (idx >= cells.length || cells[idx] == null) return '';
              final cell = cells[idx];
              if (cell is Map) {
                return (cell['f'] ?? cell['v'] ?? '').toString().trim();
              }
              return '';
            }

            final no = cellVal(0);
            final driveLink = cellVal(1);
            final idListing = cellVal(2);
            final lokasi = cellVal(3);
            final specs = cellVal(4);
            final me = cellVal(5);
            final postedRaw = cellVal(6).toLowerCase();

            if (driveLink.isEmpty && idListing.isEmpty && lokasi.isEmpty) {
              continue;
            }

            final isPosted = postedRaw == 'true' ||
                postedRaw == 'sudah' ||
                postedRaw == 'done' ||
                postedRaw == '1' ||
                postedRaw == 'yes' ||
                postedRaw.contains('posted');

            items.add(
              ReelItem(
                no: no.isNotEmpty ? no : '${i + 1}',
                driveLink: driveLink,
                idListing: idListing,
                lokasi: lokasi,
                spesifikasi: specs,
                marketing: me,
                isPosted: isPosted,
              ),
            );
          }
          return items;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetches saved custom Instagram captions
  Future<Map<String, String>> fetchSavedCaptions() async {
    final urlStr = await getCaptionUrl();
    final separator = urlStr.contains('?') ? '&' : '?';
    final url = Uri.parse('$urlStr${separator}action=get_captions');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final map = <String, String>{};
        if (data is Map) {
          final captions = data['captions'] ?? data['data'];
          if (captions is Map) {
            captions.forEach((k, v) {
              if (v != null && v.toString().trim().isNotEmpty) {
                map[k.toString().trim()] = v.toString();
              }
            });
          } else if (captions is List) {
            for (final item in captions) {
              if (item is Map) {
                final id = (item['idListing'] ?? item['id'] ?? '').toString().trim();
                final cap = (item['caption'] ?? '').toString();
                if (id.isNotEmpty && cap.isNotEmpty) {
                  map[id] = cap;
                }
              }
            }
          }
        }
        return map;
      }
    } catch (_) {}
    return {};
  }

  /// Saves a custom Instagram caption for a listing ID
  Future<bool> saveCaption(String idListing, String caption) async {
    final urlStr = await getCaptionUrl();
    final payload = {
      'action': 'save_caption',
      'idListing': idListing.trim(),
      'caption': caption,
    };
    final res = await _postJson(urlStr, payload);
    return _isSuccessResponse(res);
  }

  /// Fetches real-time team chat messages
  Future<List<ChatMessage>> fetchChatMessages() async {
    final urlStr = await getChatUrl();
    final separator = urlStr.contains('?') ? '&' : '?';
    final url = Uri.parse('$urlStr${separator}action=get_chats');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          final list = data['chats'] ?? data['messages'] ?? data['data'];
          if (list is List) {
            return list
                .whereType<Map<String, dynamic>>()
                .map(ChatMessage.fromJson)
                .toList();
          }
        } else if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Sends a team chat message
  Future<bool> sendChatMessage({
    required String sender,
    required String message,
  }) async {
    final urlStr = await getChatUrl();
    final payload = {
      'action': 'chat_send',
      'sender': sender,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final res = await _postJson(urlStr, payload);
    return _isSuccessResponse(res);
  }

  /// Edits an existing chat message
  Future<bool> editChatMessage({
    required String id,
    required String newMessage,
  }) async {
    final urlStr = await getChatUrl();
    final payload = {
      'action': 'chat_edit',
      'id': id,
      'rowIndex': int.tryParse(id) ?? 0,
      'message': newMessage,
    };
    final res = await _postJson(urlStr, payload);
    return _isSuccessResponse(res);
  }

  /// Deletes a chat message
  Future<bool> deleteChatMessage(String id) async {
    final urlStr = await getChatUrl();
    final payload = {
      'action': 'chat_delete',
      'id': id,
      'rowIndex': int.tryParse(id) ?? 0,
    };
    final res = await _postJson(urlStr, payload);
    return _isSuccessResponse(res);
  }
}
