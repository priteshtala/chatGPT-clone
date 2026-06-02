import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../cubit/chat_cubit.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _record = AudioRecorder();
  Timer? _timer;
  int _recordDuration = 0;
  bool _hasText = false;
  bool _isRecording = false;
  bool _isRecordingMode = false;
  bool _isTranscribing = false;
  File? _selectedImageFile;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _record.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  static const _models = [
    '__header_groq__',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'qwen/qwen3-32b',
    'meta-llama/llama-4-scout-17b-16e-instruct',
    '__header_gemini__',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash-exp',
  ];

  String _getDisplayName(String model) {
    if (model == 'llama-3.3-70b-versatile') return 'Llama 3.3 (70B)';
    if (model == 'llama-3.1-8b-instant') return 'Llama 3.1 (8B)';
    if (model == 'qwen/qwen3-32b') return 'Qwen 3 (32B)';
    if (model == 'meta-llama/llama-4-scout-17b-16e-instruct') return 'Llama 4 Scout (Vision)';
    if (model == 'gemini-1.5-flash') return 'Gemini 1.5 Flash';
    if (model == 'gemini-2.0-flash') return 'Gemini 2.0 Flash';
    if (model == 'gemini-1.5-pro') return 'Gemini 1.5 Pro';
    if (model == 'gemini-2.0-flash-exp') return 'Gemini 2.0 Flash Exp';
    if (model == 'gpt-4o') return 'GPT-4o';
    if (model == 'gpt-4o-mini') return 'GPT-4o Mini';
    return model;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF3F3F3);
    final hintColor = isDark ? const Color(0xFF9B9B9B) : const Color(0xFF6F6F6F);
    final sendEnabledColor = isDark ? Colors.white : Colors.black;
    final sendDisabledColor = isDark ? const Color(0xFF5A5A5A) : const Color(0xFFD7D7D7);
    final sendEnabledIconColor = isDark ? Colors.black : Colors.white;
    final sendDisabledIconColor = isDark ? const Color(0xFFB8B8B8) : const Color(0xFF777777);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedImageFile != null && !_isRecordingMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImageFile!, height: 80, width: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageFile = null;
                                _selectedImageBase64 = null;
                              });
                              final currentModel = context.read<ChatCubit>().state.selectedModel;
                              if (currentModel.contains('vision') || currentModel.contains('scout')) {
                                context.read<ChatCubit>().setModel('llama-3.3-70b-versatile');
                              }
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isRecordingMode || _isTranscribing)
                  _buildRecordingUI(hintColor, sendEnabledColor, sendEnabledIconColor)
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 6,
                      cursorColor: Theme.of(context).colorScheme.primary,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type something...',
                        hintStyle: TextStyle(color: hintColor),
                        fillColor: Colors.transparent,
                        filled: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Attach',
                        icon: const Icon(Icons.add, size: 24),
                        color: hintColor,
                        onPressed: () => _showToolSheet(context),
                      ),
                      Expanded(
                        child: BlocSelector<ChatCubit, ChatState, String>(
                          selector: (state) => state.selectedModel,
                          builder: (context, selectedModel) {
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showModelSelectionSheet(context, selectedModel),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _getDisplayName(selectedModel),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const Gap(4),
                                      Icon(Icons.keyboard_arrow_up, size: 16, color: hintColor),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Gap(8),
                      if (_hasText)
                        IconButton(
                          tooltip: 'Clear text',
                          icon: const Icon(Icons.close, size: 20),
                          color: hintColor,
                          onPressed: () {
                            _controller.clear();
                            setState(() => _hasText = false);
                          },
                        ),
                      BlocSelector<ChatCubit, ChatState, ChatStatus>(
                        selector: (state) => state.status,
                        builder: (context, status) {
                          final busy = status == ChatStatus.streaming || status == ChatStatus.loading;
                          final canSend = (_hasText || _selectedImageBase64 != null);

                          if (busy) {
                            return SizedBox.square(
                              dimension: 40,
                              child: IconButton(
                                tooltip: 'Stop generating',
                                style: IconButton.styleFrom(
                                  backgroundColor: sendEnabledColor,
                                  foregroundColor: sendEnabledIconColor,
                                  shape: const CircleBorder(),
                                ),
                                icon: const Icon(Icons.stop, size: 20),
                                onPressed: () => context.read<ChatCubit>().stopGeneration(),
                              ),
                            );
                          }

                          if (canSend) {
                            return SizedBox.square(
                              dimension: 40,
                              child: IconButton(
                                tooltip: 'Send',
                                style: IconButton.styleFrom(
                                  backgroundColor: sendEnabledColor,
                                  foregroundColor: sendEnabledIconColor,
                                  shape: const CircleBorder(),
                                ),
                                icon: const Icon(Icons.arrow_upward, size: 20),
                                onPressed: () => _sendText(context),
                              ),
                            );
                          }

                          return SizedBox.square(
                            dimension: 40,
                            child: IconButton(
                              tooltip: _isRecording ? 'Stop recording' : 'Voice input',
                              style: IconButton.styleFrom(
                                backgroundColor: _isRecording ? sendEnabledColor : sendDisabledColor,
                                foregroundColor: _isRecording ? sendEnabledIconColor : sendDisabledIconColor,
                                shape: const CircleBorder(),
                              ),
                              icon: Icon(_isRecording ? Icons.stop : Icons.mic_none, size: 20),
                              onPressed: () {
                                if (_isRecording) {
                                  _stopRecording(send: true);
                                } else {
                                  _startRecording();
                                }
                              },
                            ),
                          );
                        },
                      ),
                      const Gap(4),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showModelSelectionSheet(BuildContext context, String currentModel) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _models.length,
              itemBuilder: (context, index) {
                final model = _models[index];
                if (model.startsWith('__header_')) {
                  final title = model == '__header_groq__' ? '⚡️ GROQ MODELS' : '✨ GEMINI MODELS';
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
                    ),
                  );
                }

                final isSelected = model == currentModel;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(_getDisplayName(model), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () => Navigator.pop(sheetContext, model),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      context.read<ChatCubit>().setModel(selected);
    }
  }

  Future<void> _showToolSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ComposerTool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Upload image'),
                  subtitle: const Text('Ask a question about a photo'),
                  onTap: () => Navigator.pop(sheetContext, ComposerTool.uploadImage),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || selected == null) return;

    switch (selected) {
      case ComposerTool.uploadImage:
        final picker = ImagePicker();
        final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          if (!context.mounted) return;

          setState(() {
            _selectedImageFile = File(xfile.path);
            _selectedImageBase64 = base64Encode(bytes);
          });

          final currentModel = context.read<ChatCubit>().state.selectedModel;
          if (!currentModel.contains('vision') &&
              !currentModel.contains('gpt-4') &&
              !currentModel.contains('gemini') &&
              !currentModel.contains('scout')) {
            context.read<ChatCubit>().setModel('meta-llama/llama-4-scout-17b-16e-instruct');
          }
        }
        break;
    }
  }

  void _sendText(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBase64 == null) return;
    final imageBase64 = _selectedImageBase64;
    _controller.clear();
    setState(() {
      _selectedImageFile = null;
      _selectedImageBase64 = null;
      _hasText = false;
      _isRecordingMode = false;
    });
    context.read<ChatCubit>().sendText(text, imageBase64: imageBase64);
  }

  Widget _buildRecordingUI(Color hintColor, Color sendEnabledColor, Color sendEnabledIconColor) {
    if (_isTranscribing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const Gap(12),
            Text('Transcribing...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.mic, color: Colors.red),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              _formatDuration(_recordDuration),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          color: hintColor,
          onPressed: () => _stopRecording(send: false),
        ),
        const Gap(4),
        SizedBox.square(
          dimension: 40,
          child: IconButton(
            style: IconButton.styleFrom(backgroundColor: sendEnabledColor, foregroundColor: sendEnabledIconColor, shape: const CircleBorder()),
            icon: const Icon(Icons.send, size: 20),
            onPressed: () => _stopRecording(send: true),
          ),
        ),
        const Gap(4),
      ],
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _record.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);

        if (mounted) {
          setState(() {
            _isRecording = true;
            _isRecordingMode = true;
            _recordDuration = 0;
          });
          _startTimer();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required to record voice notes.')));
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() => _recordDuration++);
      }
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    _timer?.cancel();
    final path = await _record.stop();
    if (!mounted) return;

    if (!send || path == null) {
      setState(() {
        _isRecording = false;
        _isRecordingMode = false;
      });
      return;
    }

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    try {
      final transcribedText = await context.read<ChatCubit>().transcribeVoiceNote(path);
      if (mounted) {
        final current = _controller.text.trim();
        _controller.text = current.isEmpty ? transcribedText : '$current $transcribedText';
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingMode = false;
          _isTranscribing = false;
        });
      }
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

enum ComposerTool { uploadImage }
