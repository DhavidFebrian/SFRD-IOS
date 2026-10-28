class AbsensiDate {
  final int colIndex;
  final String label;

  const AbsensiDate({
    int? colIndex,
    int? col,
    String? label,
    String? date,
  })  : colIndex = colIndex ?? col ?? 0,
        label = label ?? date ?? '';

  int get col => colIndex;
  String get date => label;

  factory AbsensiDate.fromJson(Map<String, dynamic> json) => AbsensiDate(
        colIndex:
            int.tryParse((json['colIndex'] ?? json['col'] ?? 0).toString()) ??
                0,
        label: (json['label'] ?? json['date'] ?? '').toString().trim(),
      );
}

class AbsensiMarketing {
  final int row;
  final String name;
  final Map<int, bool> attendance;
  final int totalHadirBulan;

  const AbsensiMarketing({
    required this.row,
    required this.name,
    this.attendance = const {},
    this.totalHadirBulan = 0,
  });

  factory AbsensiMarketing.fromJson(
    Map<String, dynamic> json, [
    List<AbsensiDate> dates = const [],
  ]) {
    final rawAtt = json['attendance'];
    final map = <int, bool>{};

    bool parseVal(dynamic e) {
      if (e is bool) return e;
      final s = e.toString().trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'hadir' || s == '✔';
    }

    if (rawAtt is List) {
      for (var i = 0; i < rawAtt.length; i++) {
        final val = parseVal(rawAtt[i]);
        map[i] = val;
        if (i < dates.length) {
          map[dates[i].colIndex] = val;
        }
      }
    } else if (rawAtt is Map) {
      rawAtt.forEach((k, v) {
        final colKey = int.tryParse(k.toString());
        if (colKey != null) {
          map[colKey] = parseVal(v);
        }
      });
    }

    return AbsensiMarketing(
      row: int.tryParse((json['row'] ?? 0).toString()) ?? 0,
      name: (json['name'] ?? '').toString().trim(),
      attendance: map,
      totalHadirBulan:
          int.tryParse((json['totalHadirBulan'] ?? 0).toString()) ??
              map.values.where((b) => b).length,
    );
  }

  AbsensiMarketing copyWithAttendance(int col, bool present) {
    final nextMap = Map<int, bool>.from(attendance);
    nextMap[col] = present;
    return AbsensiMarketing(
      row: row,
      name: name,
      attendance: nextMap,
      totalHadirBulan: nextMap.values.where((b) => b).length,
    );
  }

  AbsensiMarketing copyWith({
    int? row,
    String? name,
    Map<int, bool>? attendance,
    int? totalHadirBulan,
  }) =>
      AbsensiMarketing(
        row: row ?? this.row,
        name: name ?? this.name,
        attendance: attendance ?? this.attendance,
        totalHadirBulan: totalHadirBulan ?? this.totalHadirBulan,
      );
}

class AbsensiResponse {
  final String status;
  final String message;
  final int monthIndex;
  final List<AbsensiDate> dates;
  final List<AbsensiMarketing> marketingList;
  final List<int> dateTotals;

  const AbsensiResponse({
    this.status = '',
    this.message = '',
    this.monthIndex = 0,
    this.dates = const [],
    this.marketingList = const [],
    this.dateTotals = const [],
  });

  factory AbsensiResponse.fromJson(Map<String, dynamic> json) {
    final parsedDates = (json['dates'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AbsensiDate.fromJson)
        .toList();

    return AbsensiResponse(
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      monthIndex: int.tryParse((json['monthIndex'] ?? 0).toString()) ?? 0,
      dates: parsedDates,
      marketingList: (json['marketingList'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((m) => AbsensiMarketing.fromJson(m, parsedDates))
          .toList(),
      dateTotals: (json['dateTotals'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList(),
    );
  }
}
