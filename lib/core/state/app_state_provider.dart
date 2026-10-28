import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/absensi_models.dart';
import '../models/agent_contact.dart';
import '../models/chat_message.dart';
import '../services/sheets_service.dart';
import '../services/rwc_scraper_service.dart';
import '../utils/whatsapp_formatter.dart';
import '../../features/media/models/schedule.dart';
import '../../features/tasks/models/edit_foto_task.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';
import '../../features/publish/models/publish_item.dart';

class AppStateProvider extends ChangeNotifier {
  static const List<String> availableMonths = [
    'Juni 2026',
    'Juli 2026',
    'Agustus 2026',
    'September 2026',
    'Oktober 2026',
    'November 2026',
    'Desember 2026',
    'Foto Ulang',
  ];

  static const List<String> regularMonths = [
    'Juni 2026',
    'Juli 2026',
    'Agustus 2026',
    'September 2026',
    'Oktober 2026',
    'November 2026',
    'Desember 2026',
  ];

  static const String _keySelectedMonth = 'selected_active_month';
  static const String _keyIsDarkTheme = 'pref_is_dark_theme';
  static const String _keyThemeStyle = 'pref_theme_style';
  static const String _keyUiLayoutMode = 'pref_ui_layout_mode';
  static const String _keyNotificationsEnabled = 'pref_notifications_enabled';
  static const String _keyWaTemplateDone = 'pref_wa_template_done';
  static const String _keyWaTemplateNotDone = 'pref_wa_template_not_done';
  static const String _keyCustomAgents = 'pref_custom_agent_contacts';
  static const String _keyChatSender = 'pref_chat_sender_identity';
  static const String _keyLastReadChatCount = 'pref_last_read_chat_count';
  static const String _keyPostedReels = 'pref_posted_reels_set';

  final SheetsService _sheetsService = SheetsService();
  final RwcScraperService _scraperService = RwcScraperService();

  // --- Theme & UI Settings ---
  bool _isDarkTheme = true;
  bool get isDarkTheme => _isDarkTheme;

  AppThemeStyle _selectedThemeStyle = AppThemeStyle.COSMIC_SLATE;
  AppThemeStyle get selectedThemeStyle => _selectedThemeStyle;

  String _uiLayoutMode = 'MODERN_PRO'; // 'MODERN_PRO' or 'CLASSIC'
  String get uiLayoutMode => _uiLayoutMode;

  bool _isNotificationsEnabled = true;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  String _waTemplateDone = WhatsAppFormatter.defaultFormatDone;
  String get waTemplateDone => _waTemplateDone;

  String _waTemplateNotDone = WhatsAppFormatter.defaultFormatNotDone;
  String get waTemplateNotDone => _waTemplateNotDone;

  // --- Navigation & Overlays ---
  // 0: Meeting, 1: Media, 2: Dashboard (Home), 3: Content, 4: Publish
  int _currentTabIndex = 2;
  int get currentTabIndex => _currentTabIndex;

  // Hidden drawer screens: null, 'ANALYTIC', 'TAMBAH', 'SETTING'
  String? _activeDrawerPage;
  String? get activeDrawerPage => _activeDrawerPage;

  Schedule? _selectedScheduleForDetail;
  Schedule? get selectedScheduleForDetail => _selectedScheduleForDetail;

  int _detailInitialPage = 1; // 0: Edit, 1: Detail Home, 2: Follow Up
  int get detailInitialPage => _detailInitialPage;

  bool _isInChatScreen = false;
  bool get isInChatScreen => _isInChatScreen;

  int _selectedTaskSubTab = 0; // 0: Content, 1: Edit Foto Meeting
  int get selectedTaskSubTab => _selectedTaskSubTab;

  int _selectedPublishSubTab = 0; // 0: Feeds, 1: Reels, 2: Scheduling
  int get selectedPublishSubTab => _selectedPublishSubTab;

  String _publishSelectedMonth = 'Semua Bulan';
  String get publishSelectedMonth => _publishSelectedMonth;

  // --- Data State ---
  String _selectedMonth = 'Juni 2026';
  String get selectedMonth => _selectedMonth;

  String? _selectedMeetingDate;
  String? get selectedMeetingDate => _selectedMeetingDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Schedule> _schedules = [];
  List<Schedule> get schedules => _schedules;

  List<EditFotoTask> _editFotoTasks = [];
  List<EditFotoTask> get editFotoTasks => _editFotoTasks;

  List<MeetingListing> _meetingListings = [];
  List<MeetingListing> get meetingListings => _meetingListings;

  // Multi-month cache for Publish & Global Dashboard
  final Map<String, List<Schedule>> _multiMonthSchedules = {};
  final Map<String, List<EditFotoTask>> _multiMonthTasks = {};
  final Map<String, List<MeetingListing>> _multiMonthMeetings = {};

  List<ReelItem> _reelItems = [];
  List<ReelItem> get reelItems => _reelItems;

  Set<String> _localPostedReelIds = {};

  AbsensiResponse _absensiResponse = const AbsensiResponse();
  AbsensiResponse get absensiResponse => _absensiResponse;

  List<YearlyIgHistoryItem> _yearlyIgHistory = [];
  List<YearlyIgHistoryItem> get yearlyIgHistory => _yearlyIgHistory;

  Map<String, String> _savedCaptions = {};
  Map<String, String> get savedCaptions => _savedCaptions;

  // --- Chat State ---
  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;

  String _chatSender = 'Alan'; // 'Alan' or 'David Staff'
  String get chatSender => _chatSender;

  int _lastReadChatCount = 0;
  Timer? _chatTimer;

  int get unreadChatCount {
    if (_isInChatScreen) return 0;
    final diff = _chatMessages.length - _lastReadChatCount;
    return diff > 0 ? diff : 0;
  }

  // --- Filters ---
  String _mediaFilter = 'Semua'; // 'Semua', 'Aktif', 'Non-Aktif', 'Selesai', 'Foto Ulang'
  String get mediaFilter => _mediaFilter;

  String _staffFilter = 'Semua'; // 'Semua', 'David', 'Alan'
  String get staffFilter => _staffFilter;

  DateTime? _filterStartDate;
  DateTime? get filterStartDate => _filterStartDate;

  DateTime? _filterEndDate;
  DateTime? get filterEndDate => _filterEndDate;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // --- Agent Contacts ---
  List<AgentContact> _customAgents = List.from(kDefaultAgentContacts);
  List<AgentContact> get customAgents => _customAgents;

  // --- Scraped Website Cache ---
  final Map<String, ScrapedListingDetail> _scrapedDetails = {};
  Map<String, ScrapedListingDetail> get scrapedDetails => _scrapedDetails;

  final Set<String> _activeScrapes = {};
  Set<String> get activeScrapes => _activeScrapes;

  AppStateProvider() {
    _init();
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMonth = prefs.getString(_keySelectedMonth);
    if (savedMonth != null && availableMonths.contains(savedMonth)) {
      _selectedMonth = savedMonth;
    }

    _isDarkTheme = prefs.getBool(_keyIsDarkTheme) ?? true;
    _selectedThemeStyle =
        AppThemeStyleX.fromKey(prefs.getString(_keyThemeStyle));
    _uiLayoutMode = prefs.getString(_keyUiLayoutMode) ?? 'MODERN_PRO';
    _isNotificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _waTemplateDone =
        prefs.getString(_keyWaTemplateDone) ?? WhatsAppFormatter.defaultFormatDone;
    _waTemplateNotDone = prefs.getString(_keyWaTemplateNotDone) ??
        WhatsAppFormatter.defaultFormatNotDone;
    _chatSender = prefs.getString(_keyChatSender) ?? 'Alan';
    _lastReadChatCount = prefs.getInt(_keyLastReadChatCount) ?? 0;

    final postedList = prefs.getStringList(_keyPostedReels);
    if (postedList != null) {
      _localPostedReelIds = postedList.toSet();
    }

    final savedAgentsJson = prefs.getString(_keyCustomAgents);
    if (savedAgentsJson != null && savedAgentsJson.isNotEmpty) {
      try {
        final decoded = json.decode(savedAgentsJson) as List;
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(AgentContact.fromJson)
            .toList();
        if (loaded.isNotEmpty) {
          // Ensure Utomo is always present (v8.9.10+)
          if (!loaded.any((a) => a.key == 'utomo')) {
            loaded.add(const AgentContact(
              key: 'utomo',
              displayName: 'Pak Utomo',
              phoneNumber: '081219759295',
              honorific: 'Pak',
            ));
          }
          _customAgents = loaded;
        }
      } catch (_) {}
    }

    notifyListeners();
    await refreshData();
    _startChatPolling();
  }

  void _startChatPolling() {
    _chatTimer?.cancel();
    _chatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshChats(silent: true);
    });
  }

  // --- Navigation Actions ---
  void setTabIndex(int index) {
    _currentTabIndex = index;
    _activeDrawerPage = null;
    _selectedScheduleForDetail = null;
    notifyListeners();
  }

  void openDrawerPage(String? page) {
    _activeDrawerPage = page;
    _selectedScheduleForDetail = null;
    notifyListeners();
  }

  void openScheduleDetail(Schedule? schedule, {int initialPage = 1}) {
    _selectedScheduleForDetail = schedule;
    _detailInitialPage = initialPage;
    notifyListeners();
  }

  void closeScheduleDetail() {
    _selectedScheduleForDetail = null;
    notifyListeners();
  }

  Future<void> openChatScreen(bool open) async {
    _isInChatScreen = open;
    if (open) {
      _lastReadChatCount = _chatMessages.length;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastReadChatCount, _lastReadChatCount);
      refreshChats(silent: true);
    }
    notifyListeners();
  }

  void setSelectedTaskSubTab(int subTab) {
    _selectedTaskSubTab = subTab;
    notifyListeners();
  }

  void setSelectedPublishSubTab(int subTab) {
    _selectedPublishSubTab = subTab;
    notifyListeners();
  }

  void setPublishSelectedMonth(String month) {
    _publishSelectedMonth = month;
    notifyListeners();
  }

  // --- Theme & Preferences Actions ---
  Future<void> setDarkTheme(bool isDark) async {
    _isDarkTheme = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkTheme, isDark);
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _selectedThemeStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeStyle, style.name);
  }

  Future<void> setUiLayoutMode(String mode) async {
    _uiLayoutMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUiLayoutMode, mode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _isNotificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<void> saveWaTemplates({
    required String formatDone,
    required String formatNotDone,
  }) async {
    _waTemplateDone = formatDone;
    _waTemplateNotDone = formatNotDone;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWaTemplateDone, formatDone);
    await prefs.setString(_keyWaTemplateNotDone, formatNotDone);
  }

  Future<void> resetWaTemplates() async {
    await saveWaTemplates(
      formatDone: WhatsAppFormatter.defaultFormatDone,
      formatNotDone: WhatsAppFormatter.defaultFormatNotDone,
    );
  }

  Future<void> setChatSender(String sender) async {
    _chatSender = sender;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChatSender, sender);
  }

  Future<void> saveCustomAgents(List<AgentContact> agents) async {
    _customAgents = List.from(agents);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyCustomAgents,
      json.encode(_customAgents.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> upsertAgentContact(AgentContact contact) async {
    final list = List<AgentContact>.from(_customAgents);
    final idx = list.indexWhere((a) => a.key == contact.key);
    if (idx != -1) {
      list[idx] = contact;
    } else {
      list.add(contact);
    }
    await saveCustomAgents(list);
  }

  Future<void> deleteAgentContact(String key) async {
    final list = _customAgents.where((a) => a.key != key).toList();
    await saveCustomAgents(list);
  }

  // --- Filter Setters ---
  void setMediaFilter(String filter) {
    _mediaFilter = filter;
    notifyListeners();
  }

  void setStaffFilter(String staff) {
    _staffFilter = staff;
    notifyListeners();
  }

  void setDateRangeFilter(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedMeetingDate(String? date) {
    _selectedMeetingDate = date;
    notifyListeners();
  }

  Future<void> setSelectedMonth(String month) async {
    if (_selectedMonth == month) return;
    _selectedMonth = month;
    _selectedMeetingDate = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedMonth, month);

    await refreshData();
  }

  /// Chronological descending sort for EditFotoTasks (v8.9.9)
  List<EditFotoTask> _sortTasksDescending(List<EditFotoTask> list) {
    final copy = List<EditFotoTask>.from(list);
    copy.sort((a, b) {
      final cmpDate = parseIndonesianDateToComparable(b.jadwalPosting)
          .compareTo(parseIndonesianDateToComparable(a.jadwalPosting));
      if (cmpDate != 0) return cmpDate;
      final noA = int.tryParse(a.no) ?? 0;
      final noB = int.tryParse(b.no) ?? 0;
      return noB.compareTo(noA);
    });
    return copy;
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _sheetsService.fetchMonthData(_selectedMonth),
        _sheetsService.fetchWeeklyMeetingListings(_selectedMonth),
        _sheetsService.fetchAbsensiMeeting(_selectedMonth),
        _sheetsService.fetchReels(),
        _sheetsService.fetchSavedCaptions(),
        _sheetsService.fetchChatMessages(),
        _sheetsService.fetchYearlyIgPostingHistory(),
      ]);

      final monthData = results[0] as SheetsDataResponse;
      final listings = results[1] as List<MeetingListing>;
      final absensi = results[2] as AbsensiResponse;
      final reels = results[3] as List<ReelItem>;
      final captions = results[4] as Map<String, String>;
      final chats = results[5] as List<ChatMessage>;
      final igHistory = results[6] as List<YearlyIgHistoryItem>;

      _schedules = monthData.schedules;
      _editFotoTasks = _sortTasksDescending(monthData.editFotoTasks);
      _meetingListings = listings;
      _absensiResponse = absensi;
      _savedCaptions = captions;
      _chatMessages = chats;
      _yearlyIgHistory = igHistory;

      _multiMonthSchedules[_selectedMonth] = _schedules;
      _multiMonthTasks[_selectedMonth] = _editFotoTasks;
      _multiMonthMeetings[_selectedMonth] = _meetingListings;

      // Apply local posted overrides to reels
      _reelItems = reels.map((r) {
        if (_localPostedReelIds.contains(r.cleanId) ||
            _localPostedReelIds.contains(r.no)) {
          return r.copyWith(isPosted: true);
        }
        return r;
      }).toList();

      if (_selectedMeetingDate == null && listings.isNotEmpty) {
        final dates = listings
            .map((l) => l.date)
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList();
        if (dates.isNotEmpty) {
          _selectedMeetingDate = dates.last;
        }
      }

      _autoScrapeListings();
      _syncOtherMonthsInBackground();
    } catch (e) {
      _errorMessage = 'Gagal memuat data dari Google Sheets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Syncs other months in the background for "Semua Bulan" Publish & Global Search
  void _syncOtherMonthsInBackground() {
    Future.microtask(() async {
      for (final m in regularMonths) {
        if (m == _selectedMonth) continue;
        if (_multiMonthTasks.containsKey(m) &&
            _multiMonthMeetings.containsKey(m)) {
          continue;
        }
        try {
          final mData = await _sheetsService.fetchMonthData(m);
          final mMeetings = await _sheetsService.fetchWeeklyMeetingListings(m);
          _multiMonthSchedules[m] = mData.schedules;
          _multiMonthTasks[m] = _sortTasksDescending(mData.editFotoTasks);
          _multiMonthMeetings[m] = mMeetings;
          notifyListeners();
        } catch (_) {}
      }
    });
  }

  Future<void> refreshChats({bool silent = false}) async {
    try {
      final chats = await _sheetsService.fetchChatMessages();
      if (chats.isNotEmpty || _chatMessages.isEmpty) {
        _chatMessages = chats;
        if (_isInChatScreen) {
          _lastReadChatCount = _chatMessages.length;
        }
        if (!silent) notifyListeners();
      }
    } catch (_) {}
  }

  void _autoScrapeListings() {
    final idsToScrape = <String, String>{};

    for (final s in _schedules) {
      if (s.idListing.isNotEmpty) idsToScrape[s.idListing] = s.namaMe;
    }
    for (final m in _meetingListings) {
      if (m.idListing.isNotEmpty) idsToScrape[m.idListing] = m.namaMe;
    }
    for (final t in _editFotoTasks) {
      if (t.idListing.isNotEmpty) idsToScrape[t.idListing] = t.namaMe;
    }
    for (final r in _reelItems) {
      if (r.idListing.isNotEmpty) idsToScrape[r.idListing] = r.marketing;
    }

    Future.microtask(() async {
      for (final entry in idsToScrape.entries) {
        await fetchListingDetails(entry.key, defaultMeName: entry.value);
      }
    });
  }

  Future<ScrapedListingDetail?> fetchListingDetails(
    String idListing, {
    String defaultMeName = '',
    bool force = false,
  }) async {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    if (cleanId.isEmpty) return null;

    if (!force && _scrapedDetails.containsKey(cleanId)) {
      return _scrapedDetails[cleanId];
    }

    if (_activeScrapes.contains(cleanId)) return null;
    _activeScrapes.add(cleanId);

    try {
      final detail = await _scraperService.scrapeListing(
        idListing,
        defaultMeName: defaultMeName,
        forceRefresh: force,
      );

      if (detail != null) {
        _scrapedDetails[cleanId] = detail;
        notifyListeners();
        return detail;
      }
    } finally {
      _activeScrapes.remove(cleanId);
    }
    return null;
  }

  ScrapedListingDetail? getListingDetail(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    return _scrapedDetails[cleanId];
  }

  String? getListingImage(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    return _scrapedDetails[cleanId]?.primaryImageUrl;
  }

  List<String> getListingGallery(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    return _scrapedDetails[cleanId]?.galleryImages ?? [];
  }

  String? getListingTitle(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    return _scrapedDetails[cleanId]?.title;
  }

  String? getListingPrice(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    return _scrapedDetails[cleanId]?.price;
  }

  /// Returns 2026 IG Post history for a specific listing ID
  List<YearlyIgHistoryItem> getIgHistoryForListing(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    if (cleanId.isEmpty) return [];
    final results = <YearlyIgHistoryItem>[];

    for (final h in _yearlyIgHistory) {
      if (RwcScraperService.extractCleanId(h.idListing) == cleanId) {
        results.add(h);
      }
    }

    // Also cross-check local multi-month tasks & meetings that have postingIg == true
    _multiMonthTasks.forEach((month, tasks) {
      for (final t in tasks) {
        if (t.postingIg && t.cleanId == cleanId) {
          final exists = results.any((r) => r.sheetName == month);
          if (!exists) {
            results.add(YearlyIgHistoryItem(
              idListing: cleanId,
              sheetName: month,
              date: t.jadwalPosting,
              source: 'Content',
              namaMe: t.namaMe,
              keterangan: t.judul,
            ));
          }
        }
      }
    });

    _multiMonthMeetings.forEach((month, meetings) {
      for (final m in meetings) {
        if (m.postingIg && m.cleanId == cleanId) {
          final exists = results.any((r) => r.sheetName == month);
          if (!exists) {
            results.add(YearlyIgHistoryItem(
              idListing: cleanId,
              sheetName: month,
              date: m.jadwalPosting.isNotEmpty ? m.jadwalPosting : m.date,
              source: 'Weekly Meeting',
              namaMe: m.namaMe,
              keterangan: m.keterangan,
            ));
          }
        }
      }
    });

    return results;
  }

  // --- CRUD Operations for Schedules (Media) ---
  Future<bool> addSchedule(Schedule schedule) async {
    final targetSheet =
        schedule.sheetName.isNotEmpty ? schedule.sheetName : _selectedMonth;
    final scheduleWithSheet = schedule.copyWith(
      sheetName: targetSheet,
      originalIdListing: schedule.idListing,
      originalNamaMe: schedule.namaMe,
      originalTanggal: schedule.tanggal,
      originalJam: schedule.jam,
    );
    final success =
        await _sheetsService.saveSchedule(scheduleWithSheet, action: 'add');
    if (success) {
      if (targetSheet == _selectedMonth) {
        _schedules.insert(0, scheduleWithSheet);
      }
      _multiMonthSchedules[targetSheet] = [
        scheduleWithSheet,
        ...?_multiMonthSchedules[targetSheet],
      ];
      notifyListeners();
      fetchListingDetails(schedule.idListing, defaultMeName: schedule.namaMe);
    }
    return success;
  }

  Future<bool> updateSchedule(Schedule updated) async {
    final targetSheet =
        updated.sheetName.isNotEmpty ? updated.sheetName : _selectedMonth;
    final idx = _schedules.indexWhere((s) =>
        (s.no.isNotEmpty && s.no == updated.no) ||
        (s.idListing == updated.originalIdListing &&
            s.tanggal == updated.originalTanggal));
    Schedule? old;
    if (idx != -1) {
      old = _schedules[idx];
      _schedules[idx] = updated;
      if (_selectedScheduleForDetail != null &&
          _selectedScheduleForDetail!.idListing == old.idListing) {
        _selectedScheduleForDetail = updated;
      }
      notifyListeners();
    }

    final success =
        await _sheetsService.saveSchedule(updated, action: 'edit');
    if (!success && idx != -1 && old != null) {
      _schedules[idx] = old;
      notifyListeners();
    }
    return success;
  }

  /// Deletes a Schedule (including Non-Active / Foto Ulang schedules per v8.9.13)
  Future<bool> deleteSchedule(Schedule schedule) async {
    final targetSheet = schedule.isFotoUlang
        ? 'Foto Ulang'
        : (schedule.sheetName.isNotEmpty ? schedule.sheetName : _selectedMonth);
    final toDelete = schedule.copyWith(sheetName: targetSheet);

    _schedules.removeWhere(
        (s) => s.no == schedule.no && s.idListing == schedule.idListing);
    if (_selectedScheduleForDetail?.idListing == schedule.idListing &&
        _selectedScheduleForDetail?.no == schedule.no) {
      _selectedScheduleForDetail = null;
    }
    notifyListeners();

    final success =
        await _sheetsService.saveSchedule(toDelete, action: 'delete');
    if (!success && schedule.sheetName != targetSheet) {
      // Fallback: also try deleting from currently selected month sheet
      await _sheetsService.saveSchedule(
        schedule.copyWith(sheetName: _selectedMonth),
        action: 'delete',
      );
    }
    return true;
  }

  // --- CRUD Operations for EditFotoTask (Content) ---
  Future<void> toggleEditFotoDone(EditFotoTask task) async {
    final newDone = !task.done;
    final updatedTask = task.copyWith(done: newDone);
    await _applyEditFotoUpdate(task, updatedTask);
  }

  Future<void> toggleEditFotoPostingIg(EditFotoTask task) async {
    final newPostingIg = !task.postingIg;
    final updatedTask = task.copyWith(postingIg: newPostingIg);
    await _applyEditFotoUpdate(task, updatedTask);
  }

  Future<void> updateEditNotes(EditFotoTask task, String notes) async {
    final updatedTask = task.copyWith(editNotes: notes);
    await _applyEditFotoUpdate(task, updatedTask);
  }

  Future<void> updateEditFotoScheduleDate(
      EditFotoTask task, String jadwalPosting) async {
    final updatedTask = task.copyWith(jadwalPosting: jadwalPosting);
    await _applyEditFotoUpdate(task, updatedTask);
  }

  Future<void> _applyEditFotoUpdate(
      EditFotoTask oldTask, EditFotoTask updatedTask) async {
    final targetSheet =
        updatedTask.sheetName.isNotEmpty ? updatedTask.sheetName : _selectedMonth;

    final index = _editFotoTasks.indexWhere(
        (t) => t.no == oldTask.no && t.idListing == oldTask.idListing);
    if (index != -1) {
      _editFotoTasks[index] = updatedTask;
    }
    final mList = _multiMonthTasks[targetSheet];
    if (mList != null) {
      final mIdx = mList.indexWhere(
          (t) => t.no == oldTask.no && t.idListing == oldTask.idListing);
      if (mIdx != -1) mList[mIdx] = updatedTask;
    }
    notifyListeners();

    final success =
        await _sheetsService.updateEditFotoTask(updatedTask, targetSheet);
    if (!success && index != -1) {
      _editFotoTasks[index] = oldTask;
      notifyListeners();
    }
  }

  // --- CRUD Operations for Weekly Meeting Listings ---
  Future<bool> addMeetingListing({
    required String idListing,
    required String namaMe,
    required String keterangan,
    required String catatan,
    String lokasi = '',
    required String date,
  }) async {
    final success = await _sheetsService.addWeeklyMeetingListing(
      idListing: idListing,
      namaMe: namaMe,
      keterangan: keterangan,
      catatan: catatan,
      lokasi: lokasi,
      sheetName: _selectedMonth,
      date: date,
    );

    if (success) {
      final newListing = MeetingListing(
        no: '${_meetingListings.length + 1}',
        idListing: idListing,
        namaMe: namaMe,
        keterangan: keterangan,
        catatan: catatan,
        lokasi: lokasi,
        date: date,
        sheetName: _selectedMonth,
      );
      _meetingListings.insert(0, newListing);
      _multiMonthMeetings[_selectedMonth] = _meetingListings;
      notifyListeners();
      fetchListingDetails(idListing, defaultMeName: namaMe);
    }
    return success;
  }

  Future<bool> updateMeetingListingDetails({
    required MeetingListing original,
    required String idListing,
    required String namaMe,
    required String keterangan,
    required String catatan,
    String lokasi = '',
  }) async {
    final targetSheet =
        original.sheetName.isNotEmpty ? original.sheetName : _selectedMonth;
    final updated = original.copyWith(
      idListing: idListing,
      namaMe: namaMe,
      keterangan: keterangan,
      catatan: catatan,
      lokasi: lokasi,
    );

    final idx = _meetingListings.indexWhere(
        (l) => l.row == original.row && l.idListing == original.idListing);
    if (idx != -1) {
      _meetingListings[idx] = updated;
      notifyListeners();
    }

    final success = await _sheetsService.updateWeeklyMeetingDetails(
      sheetName: targetSheet,
      date: original.date,
      row: original.row,
      colIndex: original.colIndex,
      idListing: idListing,
      namaMe: namaMe,
      keterangan: keterangan,
      catatan: catatan,
      lokasi: lokasi,
    );

    if (!success && idx != -1) {
      _meetingListings[idx] = original;
      notifyListeners();
    }
    return success;
  }

  Future<void> toggleMeetingListingPostingIg(MeetingListing listing) async {
    final targetSheet =
        listing.sheetName.isNotEmpty ? listing.sheetName : _selectedMonth;
    final newPostingIg = !listing.postingIg;
    final updatedListing = listing.copyWith(postingIg: newPostingIg);

    final index = _meetingListings.indexWhere(
        (l) => l.no == listing.no && l.idListing == listing.idListing);
    if (index != -1) {
      _meetingListings[index] = updatedListing;
    }
    final mList = _multiMonthMeetings[targetSheet];
    if (mList != null) {
      final mIdx = mList.indexWhere(
          (l) => l.no == listing.no && l.idListing == listing.idListing);
      if (mIdx != -1) mList[mIdx] = updatedListing;
    }
    notifyListeners();

    final success = await _sheetsService.updateMeetingPostingIg(
      sheetName: targetSheet,
      date: listing.date,
      row: listing.row,
      colIndex: listing.colIndex,
      postingIg: newPostingIg,
    );

    if (!success && index != -1) {
      _meetingListings[index] = listing;
      notifyListeners();
    }
  }

  Future<void> toggleMeetingMeHighlight(MeetingListing listing) async {
    final targetSheet =
        listing.sheetName.isNotEmpty ? listing.sheetName : _selectedMonth;
    final newHighlight = !listing.meHighlighted;
    final updatedListing = listing.copyWith(meHighlighted: newHighlight);

    final index = _meetingListings.indexWhere(
        (l) => l.no == listing.no && l.idListing == listing.idListing);
    if (index != -1) {
      _meetingListings[index] = updatedListing;
    }
    final mList = _multiMonthMeetings[targetSheet];
    if (mList != null) {
      final mIdx = mList.indexWhere(
          (l) => l.no == listing.no && l.idListing == listing.idListing);
      if (mIdx != -1) mList[mIdx] = updatedListing;
    }
    notifyListeners();

    final success = await _sheetsService.updateMeetingMeHighlight(
      sheetName: targetSheet,
      date: listing.date,
      row: listing.row,
      colIndex: listing.colIndex,
      idListing: listing.idListing,
      highlight: newHighlight,
    );

    if (!success && index != -1) {
      _meetingListings[index] = listing;
      notifyListeners();
    }
  }

  Future<void> updateMeetingScheduleDate(
      MeetingListing listing, String jadwalPosting) async {
    final targetSheet =
        listing.sheetName.isNotEmpty ? listing.sheetName : _selectedMonth;
    final updatedListing = listing.copyWith(jadwalPosting: jadwalPosting);

    final index = _meetingListings.indexWhere(
        (l) => l.no == listing.no && l.idListing == listing.idListing);
    if (index != -1) {
      _meetingListings[index] = updatedListing;
    }
    final mList = _multiMonthMeetings[targetSheet];
    if (mList != null) {
      final mIdx = mList.indexWhere(
          (l) => l.no == listing.no && l.idListing == listing.idListing);
      if (mIdx != -1) mList[mIdx] = updatedListing;
    }
    notifyListeners();

    await _sheetsService.updateMeetingSchedule(
      sheetName: targetSheet,
      date: listing.date,
      row: listing.row,
      colIndex: listing.colIndex,
      idListing: listing.idListing,
      jadwalPosting: jadwalPosting,
    );
  }

  Future<bool> deleteMeetingListingItem(MeetingListing listing) async {
    final targetSheet =
        listing.sheetName.isNotEmpty ? listing.sheetName : _selectedMonth;
    final success = await _sheetsService.deleteMeetingListing(
      sheetName: targetSheet,
      date: listing.date,
      row: listing.row,
      colIndex: listing.colIndex,
      idListing: listing.idListing,
    );

    if (success) {
      _meetingListings.removeWhere(
          (l) => l.no == listing.no && l.idListing == listing.idListing);
      _multiMonthMeetings[targetSheet]?.removeWhere(
          (l) => l.no == listing.no && l.idListing == listing.idListing);
      notifyListeners();
    }
    return success;
  }

  // --- Attendance (Absensi) Operations ---
  Future<void> toggleAttendance({
    required AbsensiMarketing agent,
    required AbsensiDate dateCol,
  }) async {
    final current = agent.attendance[dateCol.col] == true;
    final nextVal = !current;

    final updatedList = _absensiResponse.marketingList.map((m) {
      if (m.row == agent.row) {
        return m.copyWithAttendance(dateCol.col, nextVal);
      }
      return m;
    }).toList();

    _absensiResponse = AbsensiResponse(
      status: _absensiResponse.status,
      dates: _absensiResponse.dates,
      marketingList: updatedList,
    );
    notifyListeners();

    await _sheetsService.updateAbsensiMeeting(
      sheetName: _selectedMonth,
      row: agent.row,
      col: dateCol.col,
      present: nextVal,
    );
  }

  // --- Publish & Reels Operations ---
  Future<void> toggleReelPosted(ReelItem reel) async {
    final key = reel.cleanId.isNotEmpty ? reel.cleanId : reel.no;
    final nextPosted = !reel.isPosted;
    if (nextPosted) {
      _localPostedReelIds.add(key);
    } else {
      _localPostedReelIds.remove(key);
    }

    _reelItems = _reelItems.map((r) {
      final rKey = r.cleanId.isNotEmpty ? r.cleanId : r.no;
      if (rKey == key) return r.copyWith(isPosted: nextPosted);
      return r;
    }).toList();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPostedReels, _localPostedReelIds.toList());
  }

  Future<bool> saveCustomCaption(String idListing, String caption) async {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    final key = cleanId.isNotEmpty ? cleanId : idListing.trim();
    _savedCaptions[key] = caption;
    notifyListeners();
    return _sheetsService.saveCaption(key, caption);
  }

  String? getSavedCaption(String idListing) {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    return _savedCaptions[cleanId] ?? _savedCaptions[idListing.trim()];
  }

  // --- Chat Operations ---
  Future<bool> sendChat(String rawMessage) async {
    final tempMsg = ChatMessage.fromRaw(
      id: '${_chatMessages.length + 2}',
      sender: _chatSender,
      rawMessage: rawMessage,
      timestamp: DateTime.now().toIso8601String(),
    );
    _chatMessages.add(tempMsg);
    _lastReadChatCount = _chatMessages.length;
    notifyListeners();

    final ok = await _sheetsService.sendChatMessage(
      sender: _chatSender,
      message: rawMessage,
    );
    if (ok) {
      await refreshChats(silent: true);
    }
    return ok;
  }

  Future<bool> editChat(String id, String newRawMessage) async {
    final ok = await _sheetsService.editChatMessage(
      id: id,
      newMessage: newRawMessage,
    );
    if (ok) {
      await refreshChats();
    }
    return ok;
  }

  Future<bool> deleteChat(String id) async {
    _chatMessages.removeWhere((m) => m.id == id);
    notifyListeners();
    return _sheetsService.deleteChatMessage(id);
  }

  // --- Unified Publish Feed Items ---
  List<PublishFeedItem> get allPublishFeedItems {
    final items = <PublishFeedItem>[];
    final targetMonths = _publishSelectedMonth == 'Semua Bulan'
        ? regularMonths
        : [_publishSelectedMonth];

    for (final m in targetMonths) {
      final tasks =
          m == _selectedMonth ? _editFotoTasks : (_multiMonthTasks[m] ?? []);
      for (final t in tasks) {
        if (t.idListing.trim().isEmpty) continue;
        final scraped = getListingDetail(t.idListing);
        final loc = resolveLocationFromText(
            '${t.judul} ${t.editNotes} ${scraped?.title ?? ""} ${scraped?.lokasi ?? ""}');
        items.add(PublishFeedItem(
          uniqueKey: 'task_${m}_${t.no}_${t.idListing}',
          idListing: t.idListing,
          namaMe: t.namaMe,
          judul: t.judul,
          catatan: t.editNotes,
          lokasi: loc,
          jadwalPosting: t.jadwalPosting,
          postingIg: t.postingIg,
          isEdited: t.done,
          isFromMeeting: false,
          sheetName: m,
          sourceTask: t,
        ));
      }

      final meetings = m == _selectedMonth
          ? _meetingListings
          : (_multiMonthMeetings[m] ?? []);
      for (final l in meetings) {
        if (!l.keterangan.toUpperCase().contains('IG')) continue;
        if (l.idListing.trim().isEmpty) continue;
        final scraped = getListingDetail(l.idListing);
        final loc = l.lokasi.isNotEmpty
            ? l.lokasi
            : resolveLocationFromText(
                '${l.judul} ${l.catatan} ${scraped?.title ?? ""} ${scraped?.lokasi ?? ""}');
        items.add(PublishFeedItem(
          uniqueKey: 'meet_${m}_${l.date}_${l.row}_${l.idListing}',
          idListing: l.idListing,
          namaMe: l.namaMe,
          judul: l.judul,
          catatan: l.catatan,
          lokasi: loc,
          jadwalPosting: l.jadwalPosting,
          postingIg: l.postingIg,
          isEdited: l.meHighlighted,
          isFromMeeting: true,
          sheetName: m,
          meetingDate: l.date,
          row: l.row,
          colIndex: l.colIndex,
          sourceMeeting: l,
        ));
      }
    }

    return items;
  }

  // --- Filtered Getters ---
  List<Schedule> get filteredSchedules {
    return _schedules.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          s.idListing.toLowerCase().contains(q) ||
          s.namaMe.toLowerCase().contains(q) ||
          s.lokasi.toLowerCase().contains(q) ||
          s.staff.toLowerCase().contains(q) ||
          s.type.toLowerCase().contains(q);

      final matchesFilter = switch (_mediaFilter) {
        'Aktif' => s.isActive,
        'Non-Aktif' => s.isNonActive,
        'Selesai' => s.isDone,
        'Foto Ulang' => s.isFotoUlang,
        _ => true,
      };

      final matchesStaff = _staffFilter == 'Semua' ||
          s.staff.toLowerCase().contains(_staffFilter.toLowerCase());

      bool matchesDate = true;
      if (_filterStartDate != null || _filterEndDate != null) {
        final d = parseIndonesianDate(s.tanggal);
        if (d != null) {
          if (_filterStartDate != null && d.isBefore(_filterStartDate!)) {
            matchesDate = false;
          }
          if (_filterEndDate != null && d.isAfter(_filterEndDate!)) {
            matchesDate = false;
          }
        }
      }

      return matchesSearch && matchesFilter && matchesStaff && matchesDate;
    }).toList();
  }

  List<MeetingListing> get filteredMeetingListings {
    return _meetingListings.where((l) {
      final matchesDate = _selectedMeetingDate == null ||
          _selectedMeetingDate!.isEmpty ||
          l.date == _selectedMeetingDate;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          l.idListing.toLowerCase().contains(q) ||
          l.namaMe.toLowerCase().contains(q) ||
          l.lokasi.toLowerCase().contains(q) ||
          l.keterangan.toLowerCase().contains(q) ||
          l.catatan.toLowerCase().contains(q);
      return matchesDate && matchesSearch;
    }).toList();
  }

  List<String> get availableMeetingDates {
    final dates = _meetingListings
        .map((l) => l.date)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    return dates;
  }
}
