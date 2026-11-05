import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

class MantraPlayerScreen extends StatefulWidget {
  final MantraItem mantra;
  final AudioState audioState;

  const MantraPlayerScreen({
    super.key,
    required this.mantra,
    required this.audioState,
  });

  @override
  State<MantraPlayerScreen> createState() => _MantraPlayerScreenState();
}

class _MantraPlayerScreenState extends State<MantraPlayerScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.audioState.activeMantra?.id != widget.mantra.id) {
      widget.audioState.playMantra(widget.mantra, resetSessionCount: true);
    }
  }

  void _showCustomCountDialog(BuildContext context) {
    final controller = TextEditingController(text: '${widget.audioState.targetRepetitions}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Repetitions'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Chants (e.g. 1008)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                widget.audioState.setTargetRepetitions(count);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.audioState,
      builder: (context, _) {
        final state = widget.audioState;
        final isFav = state.isFavorite(widget.mantra.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.mantra.title),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () => state.toggleFavorite(widget.mantra.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Deity & Collection Tag Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.saffronPrimary.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.saffronPrimary),
                      ),
                      child: Text(
                        widget.mantra.deity.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.mantra.isBundled
                            ? Colors.green.withAlpha(30)
                            : Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.mantra.isBundled ? Icons.offline_pin : Icons.storage,
                            size: 14,
                            color: widget.mantra.isBundled ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.mantra.isBundled ? 'Offline Bundled' : 'Local Vault',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.mantra.isBundled ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sanskrit Mantra Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 28,
                          color: AppColors.saffronPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.mantra.mantraText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Visual Mala Counter (108 beads)
                VisualMalaWidget(
                  completedCount: state.completedRepetitions,
                  targetCount: state.targetRepetitions,
                  isPlaying: state.isPlaying,
                ),
                const SizedBox(height: 20),

                // Audio Progress Bar
                Column(
                  children: [
                    Slider(
                      value: state.position.inMilliseconds
                          .clamp(0, state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 1)
                          .toDouble(),
                      max: (state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 1).toDouble(),
                      activeColor: AppColors.saffronPrimary,
                      onChanged: (val) {
                        state.seek(Duration(milliseconds: val.round()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(state.position),
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            _formatDuration(state.duration),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 28),
                      tooltip: 'Reset Session',
                      onPressed: () => state.resetSession(),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.saffronPrimary,
                      ),
                      child: IconButton(
                        iconSize: 42,
                        color: Colors.white,
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (state.isPlaying) {
                            state.pause();
                          } else if (state.isPaused) {
                            state.resume();
                          } else {
                            state.playMantra(widget.mantra, resetSessionCount: false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.stop, size: 28),
                      tooltip: 'Stop',
                      onPressed: () => state.stop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Repeat Modes Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Repetitions (Mala Count):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final count in [1, 3, 11, 21, 54, 108])
                          ChoiceChip(
                            label: Text('$count'),
                            selected: state.targetRepetitions == count,
                            selectedColor: AppColors.saffronPrimary.withAlpha(50),
                            onSelected: (selected) {
                              if (selected) {
                                state.setTargetRepetitions(count);
                              }
                            },
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.tune, size: 16),
                          label: Text(
                            [1, 3, 11, 21, 54, 108].contains(state.targetRepetitions)
                                ? 'Custom'
                                : 'Custom (${state.targetRepetitions})',
                          ),
                          onPressed: () => _showCustomCountDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Spiritual Significance Container
                if (widget.mantra.significance.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.nightSurfaceElevated
                          : AppColors.creamBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.spa,
                              size: 16,
                              color: isDark ? AppColors.goldLight : AppColors.goldDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SPIRITUAL SIGNIFICANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark ? AppColors.goldLight : AppColors.goldDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.mantra.significance,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error Banner if any
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
