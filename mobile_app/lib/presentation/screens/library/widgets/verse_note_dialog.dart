import 'package:flutter/material.dart';
import '../../../../core/models/scripture.dart';
import '../../../../core/models/verse.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../state/scripture_reader_state.dart';

/// Dialog allowing devotees to write, edit, or delete private personal study notes.
class VerseNoteDialog extends StatefulWidget {
  final Verse verse;
  final Scripture scripture;
  final ScriptureReaderState readerState;

  const VerseNoteDialog({
    super.key,
    required this.verse,
    required this.scripture,
    required this.readerState,
  });

  static Future<void> show({
    required BuildContext context,
    required Verse verse,
    required Scripture scripture,
    required ScriptureReaderState readerState,
  }) {
    return showDialog(
      context: context,
      builder: (_) => VerseNoteDialog(
        verse: verse,
        scripture: scripture,
        readerState: readerState,
      ),
    );
  }

  @override
  State<VerseNoteDialog> createState() => _VerseNoteDialogState();
}

class _VerseNoteDialogState extends State<VerseNoteDialog> {
  late final TextEditingController _controller;
  bool _hasExistingNote = false;

  @override
  void initState() {
    super.initState();
    final gId = widget.verse.globalId(widget.scripture.contentId);
    final existing = widget.readerState.getNote(gId);
    _hasExistingNote = existing != null && existing.noteText.isNotEmpty;
    _controller = TextEditingController(text: existing?.noteText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.edit_note,
            color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Personal Study Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.scripture.canonicalTitle} • Verse ${widget.verse.verseNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Record personal reflections, grammar insights, or devotion...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF3EFE8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Personal devotee reflection. Stored privately on-device; not verified commentary.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_hasExistingNote)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final gId = widget.verse.globalId(widget.scripture.contentId);
              await widget.readerState.deleteNote(gId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('DELETE'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.saffronPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            await widget.readerState.saveNote(
              widget.verse,
              widget.scripture,
              _controller.text,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('SAVE NOTE'),
        ),
      ],
    );
  }
}
