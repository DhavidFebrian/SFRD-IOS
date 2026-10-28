import 'dart:convert';
import '../../features/media/models/schedule.dart';

class ChatScheduleAttachment {
  final String idListing;
  final String namaMe;
  final String lokasi;
  final String tanggal;
  final String jam;
  final String type;
  final String status;

  const ChatScheduleAttachment({
    required this.idListing,
    this.namaMe = '',
    this.lokasi = '',
    this.tanggal = '',
    this.jam = '',
    this.type = '',
    this.status = '',
  });

  Map<String, dynamic> toJson() => {
        'idListing': idListing,
        'namaMe': namaMe,
        'lokasi': lokasi,
        'tanggal': tanggal,
        'jam': jam,
        'type': type,
        'status': status,
      };

  factory ChatScheduleAttachment.fromJson(Map<String, dynamic> json) =>
      ChatScheduleAttachment(
        idListing: (json['idListing'] ?? '').toString(),
        namaMe: (json['namaMe'] ?? '').toString(),
        lokasi: (json['lokasi'] ?? '').toString(),
        tanggal: (json['tanggal'] ?? '').toString(),
        jam: (json['jam'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
      );
}

class ChatMessage {
  final String id;
  final String sender;
  final String rawText;
  final String timestamp;
  final bool isEdited;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.rawText,
    required this.timestamp,
    this.isEdited = false,
  });

  factory ChatMessage.fromRaw({
    required String id,
    required String sender,
    required String rawMessage,
    required String timestamp,
    bool isEdited = false,
  }) =>
      ChatMessage(
        id: id,
        sender: sender,
        rawText: rawMessage,
        timestamp: timestamp,
        isEdited: isEdited,
      );

  String get rawMessage => rawText;
  String get cleanMessage => cleanMessageText;

  String? get replySender {
    final m = RegExp(r'\[REPLY:([^|\]]+)\|([^\]]*)\]').firstMatch(rawText);
    return m?.group(1)?.trim();
  }

  String? get replySnippet {
    final m = RegExp(r'\[REPLY:([^|\]]+)\|([^\]]*)\]').firstMatch(rawText);
    return m?.group(2)?.trim();
  }

  ChatScheduleAttachment? get attachedSchedule {
    final startIdx = rawText.indexOf('[SCHEDULE:');
    if (startIdx == -1) return null;
    final afterPrefix = rawText.substring(startIdx + 10);
    final endBracket = afterPrefix.lastIndexOf('}]');
    if (endBracket == -1) return null;
    final jsonStr = afterPrefix.substring(0, endBracket + 1);
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return ChatScheduleAttachment.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Schedule? get taggedSchedule {
    final att = attachedSchedule;
    if (att == null) return null;
    return Schedule(
      idListing: att.idListing,
      namaMe: att.namaMe,
      lokasi: att.lokasi,
      tanggal: att.tanggal,
      jam: att.jam,
      type: att.type,
      status: att.status,
    );
  }

  String get cleanMessageText {
    var cleaned = rawText.replaceAll(RegExp(r'\[REPLY:[^\]]*\]'), '');
    final startIdx = cleaned.indexOf('[SCHEDULE:');
    if (startIdx != -1) {
      final endIdx = cleaned.lastIndexOf('}]');
      if (endIdx != -1 && endIdx >= startIdx) {
        cleaned =
            cleaned.substring(0, startIdx) + cleaned.substring(endIdx + 2);
      }
    }
    return cleaned.trim();
  }

  static String composeRawMessage({
    String? text,
    String? cleanMessage,
    String? replySender,
    String? replySnippet,
    Schedule? schedule,
    ChatScheduleAttachment? attachedSchedule,
  }) {
    final sb = StringBuffer();
    if (replySender != null && replySender.isNotEmpty) {
      final safeSnippet = (replySnippet ?? '').replaceAll('\n', ' ').trim();
      sb.write('[REPLY:$replySender|$safeSnippet] ');
    }
    if (attachedSchedule != null) {
      sb.write('[SCHEDULE:${jsonEncode(attachedSchedule.toJson())}] ');
    } else if (schedule != null) {
      sb.write('[SCHEDULE:${jsonEncode(schedule.toJson())}] ');
    }
    final msgBody = (cleanMessage ?? text ?? '').trim();
    sb.write(msgBody);
    return sb.toString().trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'rawText': rawText,
        'message': rawText,
        'timestamp': timestamp,
        'isEdited': isEdited,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] ??
                json['rowIndex'] ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .toString(),
        sender: (json['sender'] ?? 'Alan').toString(),
        rawText:
            (json['rawText'] ?? json['message'] ?? json['text'] ?? '').toString(),
        timestamp: (json['timestamp'] ?? DateTime.now().toIso8601String())
            .toString(),
        isEdited: json['isEdited'] == true,
      );

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? rawText,
    String? timestamp,
    bool? isEdited,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        sender: sender ?? this.sender,
        rawText: rawText ?? this.rawText,
        timestamp: timestamp ?? this.timestamp,
        isEdited: isEdited ?? this.isEdited,
      );
}
