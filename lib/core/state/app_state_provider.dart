import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sheets_service.dart';
import '../services/rwc_scraper_service.dart';
import '../../features/media/models/schedule.dart';
import '../../features/tasks/models/edit_foto_task.dart';
import '../../features/weekly_meeting/models/meeting_listing.dart';

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

  static const String _keySelectedMonth = 'selected_active_month';

  final SheetsService _sheetsService = SheetsService();
  final RwcScraperService _scraperService = RwcScraperService();

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

  String _mediaFilter = 'Semua';
  String get mediaFilter => _mediaFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Scraped website data cache from raywhitecipete.net
  final Map<String, ScrapedListingDetail> _scrapedDetails = {};
  Map<String, ScrapedListingDetail> get scrapedDetails => _scrapedDetails;

  final Set<String> _activeScrapes = {};
  Set<String> get activeScrapes => _activeScrapes;

  AppStateProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMonth = prefs.getString(_keySelectedMonth);
    if (savedMonth != null && availableMonths.contains(savedMonth)) {
      _selectedMonth = savedMonth;
    }
    await refreshData();
  }

  void setMediaFilter(String filter) {
    _mediaFilter = filter;
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
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedMonth, month);

    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _sheetsService.fetchMonthData(_selectedMonth),
        _sheetsService.fetchWeeklyMeetingListings(_selectedMonth, _selectedMeetingDate),
      ]);

      final monthData = results[0] as SheetsDataResponse;
      final listings = results[1] as List<MeetingListing>;

      _schedules = monthData.schedules;
      _editFotoTasks = monthData.editFotoTasks;
      _meetingListings = listings;

      if (_selectedMeetingDate == null && listings.isNotEmpty) {
        final dates = listings.map((l) => l.date).where((d) => d.isNotEmpty).toSet().toList();
        if (dates.isNotEmpty) {
          _selectedMeetingDate = dates.first;
        }
      }

      // Automatically trigger web scraping for all listing IDs in the background
      _autoScrapeListings();
    } catch (e) {
      _errorMessage = 'Gagal memuat data dari Google Sheets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Automatically fetches website images & details for all active items
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

    // Process scraping with small batching to avoid flooding network
    Future.microtask(() async {
      for (final entry in idsToScrape.entries) {
        fetchListingDetails(entry.key, defaultMeName: entry.value);
      }
    });
  }

  /// Fetches listing photos and details from raywhitecipete.net
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

  /// Toggle Done on EditFotoTask and sync with Sheets
  Future<void> toggleEditFotoDone(EditFotoTask task) async {
    final newDone = !task.done;
    final updatedTask = task.copyWith(done: newDone);

    final index = _editFotoTasks.indexWhere((t) => t.no == task.no && t.idListing == task.idListing);
    if (index != -1) {
      _editFotoTasks[index] = updatedTask;
      notifyListeners();
    }

    final success = await _sheetsService.updateEditFotoTask(updatedTask, _selectedMonth);
    if (!success && index != -1) {
      _editFotoTasks[index] = task;
      notifyListeners();
    }
  }

  /// Toggle Posting IG on EditFotoTask and sync with Sheets
  Future<void> toggleEditFotoPostingIg(EditFotoTask task) async {
    final newPostingIg = !task.postingIg;
    final updatedTask = task.copyWith(postingIg: newPostingIg);

    final index = _editFotoTasks.indexWhere((t) => t.no == task.no && t.idListing == task.idListing);
    if (index != -1) {
      _editFotoTasks[index] = updatedTask;
      notifyListeners();
    }

    final success = await _sheetsService.updateEditFotoTask(updatedTask, _selectedMonth);
    if (!success && index != -1) {
      _editFotoTasks[index] = task;
      notifyListeners();
    }
  }

  /// Update Edit Notes on EditFotoTask and sync with Sheets
  Future<void> updateEditNotes(EditFotoTask task, String notes) async {
    final updatedTask = task.copyWith(editNotes: notes);

    final index = _editFotoTasks.indexWhere((t) => t.no == task.no && t.idListing == task.idListing);
    if (index != -1) {
      _editFotoTasks[index] = updatedTask;
      notifyListeners();
    }

    await _sheetsService.updateEditFotoTask(updatedTask, _selectedMonth);
  }

  /// Toggle Posting IG on MeetingListing and sync with Sheets
  Future<void> toggleMeetingListingPostingIg(MeetingListing listing) async {
    final newPostingIg = !listing.postingIg;
    final updatedListing = listing.copyWith(postingIg: newPostingIg);

    final index = _meetingListings.indexWhere((l) => l.no == listing.no && l.idListing == listing.idListing);
    if (index != -1) {
      _meetingListings[index] = updatedListing;
      notifyListeners();
    }

    final success = await _sheetsService.updateMeetingPostingIg(
      sheetName: _selectedMonth,
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

  /// Add Schedule to active sheet
  Future<bool> addSchedule(Schedule schedule) async {
    final scheduleWithSheet = schedule.copyWith(sheetName: _selectedMonth);
    final success = await _sheetsService.addSchedule(scheduleWithSheet);
    if (success) {
      _schedules.insert(0, scheduleWithSheet);
      notifyListeners();
      fetchListingDetails(schedule.idListing, defaultMeName: schedule.namaMe);
    }
    return success;
  }

  /// Add Meeting Listing to active sheet
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
        idListing: idListing,
        namaMe: namaMe,
        keterangan: keterangan,
        catatan: catatan,
        lokasi: lokasi,
        date: date,
        sheetName: _selectedMonth,
      );
      _meetingListings.insert(0, newListing);
      notifyListeners();
      fetchListingDetails(idListing, defaultMeName: namaMe);
    }
    return success;
  }

  /// Delete Meeting Listing
  Future<bool> deleteMeetingListingItem(MeetingListing listing) async {
    final success = await _sheetsService.deleteMeetingListing(
      sheetName: _selectedMonth,
      date: listing.date,
      row: listing.row,
      colIndex: listing.colIndex,
      idListing: listing.idListing,
    );

    if (success) {
      _meetingListings.removeWhere((l) => l.no == listing.no && l.idListing == listing.idListing);
      notifyListeners();
    }
    return success;
  }

  // Filtered Getters
  List<Schedule> get filteredSchedules {
    return _schedules.filter((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.idListing.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.namaMe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.lokasi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.staff.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_mediaFilter) {
        'Aktif' => !s.isDone,
        'Selesai' => s.isDone,
        'Foto Ulang' => s.isFotoUlang,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    });
  }

  List<MeetingListing> get filteredMeetingListings {
    return _meetingListings.where((l) {
      final matchesDate = _selectedMeetingDate == null || _selectedMeetingDate!.isEmpty || l.date == _selectedMeetingDate;
      final matchesSearch = _searchQuery.isEmpty ||
          l.idListing.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.namaMe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.lokasi.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDate && matchesSearch;
    }).toList();
  }
}

extension ListFilterExt<T> on List<T> {
  List<T> filter(bool Function(T element) test) {
    return where(test).toList();
  }
}
