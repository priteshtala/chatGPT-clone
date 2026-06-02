import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessageBubble extends StatefulWidget {
  const AudioMessageBubble({
    super.key,
    this.audioPath,
    this.base64Audio,
  }) : assert(audioPath != null || base64Audio != null);

  final String? audioPath;
  final String? base64Audio;

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    try {
      if (widget.audioPath != null) {
        await _player.setSourceDeviceFile(widget.audioPath!);
      } else if (widget.base64Audio != null) {
        final bytes = base64Decode(widget.base64Audio!);
        await _player.setSourceBytes(bytes);
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _isLoading
              ? null
              : () {
                  if (_isPlaying) {
                    _player.pause();
                  } else {
                    _player.resume();
                  }
                },
        ),
        Slider(
          value: _position.inMilliseconds.toDouble(),
          max: _duration.inMilliseconds.toDouble() > 0
              ? _duration.inMilliseconds.toDouble()
              : 1.0,
          onChanged: (value) {
            _player.seek(Duration(milliseconds: value.toInt()));
          },
        ),
        Text(
          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
