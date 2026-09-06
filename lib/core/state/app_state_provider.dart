import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sheets_service.dart';
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

      // Automatically select first meeting date if available and not selected yet
      if (_selectedMeetingDate == null && listings.isNotEmpty) {
        final dates = listings.map((l) => l.date).where((d) => d.isNotEmpty).toSet().toList();
        if (dates.isNotEmpty) {
          _selectedMeetingDate = dates.first;
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data dari Google Sheets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle Done on EditFotoTask and sync with Sheets
  Future<void> toggleEditFotoDone(EditFotoTask task) async {
    final newDone = !task.done;
    final updatedTask = task.copyWith(done: newDone);

    // Optimistic local update
    final index = _editFotoTasks.indexWhere((t) => t.no == task.no && t.idListing == task.idListing);
    if (index != -1) {
      _editFotoTasks[index] = updatedTask;
      notifyListeners();
    }

    // Remote sync
    final success = await _sheetsService.updateEditFotoTask(updatedTask, _selectedMonth);
    if (!success && index != -1) {
      // Revert on failure
      _editFotoTasks[index] = task;
      notifyListeners();
    }
  }

  /// Toggle Posting IG on EditFotoTask and sync with Sheets
  Future<void> toggleEditFotoPostingIg(EditFotoTask task) async {
    final newPostingIg = !task.postingIg;
    final updatedTask = task.copyWith(postingIg: newPostingIg);

    // Optimistic local update
    final index = _editFotoTasks.indexWhere((t) => t.no == task.no && t.idListing == task.idListing);
    if (index != -1) {
      _editFotoTasks[index] = updatedTask;
      notifyListeners();
    }

    // Remote sync
    final success = await _sheetsService.updateEditFotoTask(updatedTask, _selectedMonth);
    if (!success && index != -1) {
      // Revert on failure
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

    // Optimistic local update
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
