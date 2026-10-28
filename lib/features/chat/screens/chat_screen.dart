import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/state/app_state_provider.dart';
import '../../media/models/schedule.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  ChatMessage? _replyingTo;
  ChatMessage? _editingMessage;
  Schedule? _attachedSchedule;
  bool _showScheduleSuggestions = false;
  String _tagFilterQuery = '';

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onInputChanged() {
    final text = _inputCtrl.text;
    final hashIdx = text.lastIndexOf('#');
    if (hashIdx != -1) {
      final afterHash = text.substring(hashIdx + 1);
      if (!afterHash.contains(' ')) {
        setState(() {
          _showScheduleSuggestions = true;
          _tagFilterQuery = afterHash.toLowerCase();
        });
        return;
      }
    }
    if (_showScheduleSuggestions) {
      setState(() => _showScheduleSuggestions = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _switchIdentity(AppStateProvider state) async {
    if (state.chatSender == 'Alan') {
      // Require PIN "2332" to switch to David Staff
      final pinCtrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkCardSurface,
          title: const Text('PIN David Staff'),
          content: TextField(
            controller: pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Masukkan PIN Staff',
              hintText: '****',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, pinCtrl.text.trim() == '2332'),
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await state.setChatSender('David Staff');
      } else if (ok == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN tidak valid!')),
        );
      }
    } else {
      await state.setChatSender('Alan');
    }
  }

  Future<void> _sendOrSave(AppStateProvider state) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _attachedSchedule == null) return;

    final rawPayload = ChatMessage.composeRawMessage(
      cleanMessage: text.isNotEmpty ? text : '📌 Lampiran Jadwal Foto',
      replySender: _replyingTo?.sender,
      replySnippet: _replyingTo?.cleanMessage,
      attachedSchedule: _attachedSchedule != null
          ? ChatScheduleAttachment(
              idListing: _attachedSchedule!.idListing,
              namaMe: _attachedSchedule!.namaMe,
              lokasi: _attachedSchedule!.lokasi,
              tanggal: _attachedSchedule!.tanggal,
              jam: _attachedSchedule!.jam,
              type: _attachedSchedule!.type,
              status: _attachedSchedule!.status,
            )
          : null,
    );

    _inputCtrl.clear();
    final editing = _editingMessage;
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _attachedSchedule = null;
      _showScheduleSuggestions = false;
    });

    if (editing != null) {
      await state.editChat(editing.id, rawPayload);
    } else {
      await state.sendChat(rawPayload);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final palette = AppColors.paletteFor(state.selectedThemeStyle);
    final messages = state.chatMessages;

    final matchingSchedules = state.schedules.where((s) {
      if (_tagFilterQuery.isEmpty) return true;
      return s.idListing.toLowerCase().contains(_tagFilterQuery) ||
          s.namaMe.toLowerCase().contains(_tagFilterQuery) ||
          s.lokasi.toLowerCase().contains(_tagFilterQuery);
    }).take(6).toList();

    return Scaffold(
      backgroundColor: palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: palette.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => state.openChatScreen(false),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Chat Production',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            Text(
              'Login sebagai: ${state.chatSender}',
              style: TextStyle(
                fontSize: 11.5,
                color: palette.secondaryAccentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandYellow,
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(
              state.chatSender == 'Alan' ? 'Ganti ke David' : 'Ganti ke Alan',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            onPressed: () => _switchIdentity(state),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => state.refreshChats(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada percakapan tim.\nKetik # untuk melampirkan jadwal foto!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.sender.toLowerCase() ==
                          state.chatSender.toLowerCase();

                      return Dismissible(
                        key: ValueKey('chat_${msg.id}_$index'),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (_) async {
                          setState(() => _replyingTo = msg);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(
                            Icons.reply_rounded,
                            color: palette.accentColor,
                          ),
                        ),
                        child: GestureDetector(
                          onLongPress: () =>
                              _showMessageActions(context, state, msg),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? palette.accentColor.withValues(alpha: 0.24)
                                    : palette.surfaceColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(isMe ? 16 : 4),
                                  bottomRight:
                                      Radius.circular(isMe ? 4 : 16),
                                ),
                                border: Border.all(
                                  color: isMe
                                      ? palette.accentColor
                                          .withValues(alpha: 0.5)
                                      : palette.borderColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        msg.sender,
                                        style: TextStyle(
                                          color: isMe
                                              ? AppColors.brandYellow
                                              : palette.secondaryAccentColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTimestamp(msg.timestamp),
                                        style: const TextStyle(
                                          color: AppColors.darkTextTertiary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (msg.replySender != null &&
                                      msg.replySnippet != null) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.28),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(
                                          left: BorderSide(
                                            color: palette.secondaryAccentColor,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.replySender!,
                                            style: TextStyle(
                                              color:
                                                  palette.secondaryAccentColor,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            msg.replySnippet!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (msg.attachedSchedule != null) ...[
                                    const SizedBox(height: 8),
                                    _buildAttachedScheduleCard(
                                      state,
                                      msg.attachedSchedule!,
                                      palette,
                                    ),
                                  ],
                                  if (msg.cleanMessage.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      msg.cleanMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Schedule Tagging Popup when typing '#'
          if (_showScheduleSuggestions && matchingSchedules.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 190),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: palette.elevatedSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.accentColor),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: matchingSchedules.length,
                itemBuilder: (context, idx) {
                  final s = matchingSchedules[idx];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.tag_rounded,
                      color: AppColors.brandYellow,
                      size: 18,
                    ),
                    title: Text(
                      '#${s.cleanId} — ${s.namaMe}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    subtitle: Text(
                      '${s.lokasi} • ${s.tanggal} (${s.jam})',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      final text = _inputCtrl.text;
                      final hashIdx = text.lastIndexOf('#');
                      final newText = hashIdx != -1
                          ? '${text.substring(0, hashIdx)}#${s.cleanId} '
                          : text;
                      setState(() {
                        _attachedSchedule = s;
                        _showScheduleSuggestions = false;
                        _inputCtrl.text = newText;
                        _inputCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: _inputCtrl.text.length),
                        );
                      });
                    },
                  );
                },
              ),
            ),

          // Reply / Edit / Attachment Banner
          if (_replyingTo != null ||
              _editingMessage != null ||
              _attachedSchedule != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: palette.elevatedSurfaceColor,
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null
                        ? Icons.edit_rounded
                        : (_attachedSchedule != null
                            ? Icons.event_note_rounded
                            : Icons.reply_rounded),
                    color: AppColors.brandYellow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editingMessage != null
                          ? 'Mengedit pesan: ${_editingMessage!.cleanMessage}'
                          : (_attachedSchedule != null
                              ? 'Lampiran Jadwal #${_attachedSchedule!.cleanId} (${_attachedSchedule!.namaMe})'
                              : 'Membalas ${_replyingTo!.sender}: ${_replyingTo!.cleanMessage}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _replyingTo = null;
                        _editingMessage = null;
                        _attachedSchedule = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: palette.surfaceColor,
                border: Border(top: BorderSide(color: palette.borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.tag_rounded,
                      color: AppColors.brandYellow,
                    ),
                    tooltip: 'Tag Jadwal (#)',
                    onPressed: () {
                      _inputCtrl.text = '${_inputCtrl.text}#';
                      _inputCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _inputCtrl.text.length),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan atau # untuk tag jadwal...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendOrSave(state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: palette.accentColor,
                    radius: 21,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      onPressed: () => _sendOrSave(state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedScheduleCard(
    AppStateProvider state,
    ChatScheduleAttachment att,
    ThemePalette palette,
  ) {
    return GestureDetector(
      onTap: () {
        final match = state.schedules.where(
            (s) => s.cleanId == RwcScraperService.extractCleanId(att.idListing));
        if (match.isNotEmpty) {
          state.openChatScreen(false);
          state.openScheduleDetail(match.first, initialPage: 1);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.brandYellow.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.brandYellow,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'JADWAL #${att.idListing} • ${att.namaMe}',
                  style: const TextStyle(
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '📍 ${att.lokasi} • 📅 ${att.tanggal} (${att.jam})',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageActions(
    BuildContext context,
    AppStateProvider state,
    ChatMessage msg,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardSurface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Colors.white),
              title: const Text('Balas Pesan'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: const Text('Edit Pesan'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _editingMessage = msg;
                  _inputCtrl.text = msg.cleanMessage;
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.statusUrgent,
              ),
              title: const Text(
                'Hapus Pesan',
                style: TextStyle(color: AppColors.statusUrgent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                state.deleteChat(msg.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
