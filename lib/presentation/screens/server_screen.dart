import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  bool _isServerRunning = true;
  bool _exposeToNetwork = true;
  String _selectedModel = 'Gemma 2 9B (Quantized)';
  final List<String> _availableModels = [
    'Gemma 2 9B (Quantized)',
    'Mistral 7B Instruct v0.2',
    'Llama 3 8B Chat',
  ];

  final List<LogEntry> _logs = [
    LogEntry(
      type: LogType.info,
      time: '10:23:45',
      message: 'Server started on 0.0.0.0:1234',
    ),
    LogEntry(
      type: LogType.info,
      time: '10:23:46',
      message: 'Model \'Gemma 2 9B\' loaded successfully',
    ),
    LogEntry(
      type: LogType.debug,
      time: '10:23:46',
      message: 'GPU Layers: 33/33 allocated',
    ),
    LogEntry(
      type: LogType.post,
      time: '10:24:12',
      message: '/v1/chat/completions',
      status: '200 OK',
      duration: '124ms',
      payload: '{"model": "gemma-2-9b", "messages": [...]}',
    ),
    LogEntry(
      type: LogType.post,
      time: '10:24:15',
      message: '/v1/chat/completions',
      status: '200 OK',
      duration: '89ms',
    ),
    LogEntry(
      type: LogType.get,
      time: '10:24:20',
      message: '/v1/models',
      status: '200 OK',
      duration: '4ms',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Server',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isServerRunning ? AppColors.success : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServerRunning ? 'Running' : 'Stopped',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isServerRunning ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Server Status Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildServerStatusCard(),
                    ),
                    const SizedBox(height: 16),
                    // Server Logs Card - Expandable
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildServerLogsCard(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Status',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expose API to local network',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _exposeToNetwork,
                onChanged: (value) {
                  setState(() {
                    _exposeToNetwork = value;
                  });
                },
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Local Endpoint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF120d1d),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCAL ENDPOINT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'http://192.168.1.5:1234/v1',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.content_copy,
                        size: 20,
                        color: AppColors.textSecondaryDark,
                      ),
                      onPressed: () {
                        // Copy to clipboard
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Serving Model
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SERVING MODEL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF120d1d),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surfaceDark,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: AppColors.textPrimaryDark,
                  ),
                  items: _availableModels.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(model),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedModel = value;
                      });
                    }
                  },
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.expand_more,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.memory,
                    size: 16,
                    color: AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VRAM Usage: 6.2GB / 12GB',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerLogsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0d0a15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SERVER LOGS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    child: Text(
                      'Clear',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // Export logs
                    },
                    child: Text(
                      'Export',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _buildLogEntry(log);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Blinking cursor
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Opacity(
                opacity: value > 0.5 ? 1.0 : 0.0,
                child: Container(
                  width: 8,
                  height: 16,
                  color: AppColors.primary,
                ),
              );
            },
            onEnd: () {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    Color typeColor;
    String typeLabel;

    switch (log.type) {
      case LogType.info:
        typeColor = AppColors.success;
        typeLabel = '[INFO]';
        break;
      case LogType.debug:
        typeColor = AppColors.primary;
        typeLabel = '[DEBUG]';
        break;
      case LogType.post:
        typeColor = AppColors.primary;
        typeLabel = 'POST';
        break;
      case LogType.get:
        typeColor = AppColors.warning;
        typeLabel = 'GET';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (log.type == LogType.info || log.type == LogType.debug) ...[
                Text(
                  typeLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  log.time,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.message,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  typeLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  log.message,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                if (log.status != null)
                  Text(
                    log.status!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                if (log.duration != null) ...[
                  const Spacer(),
                  Text(
                    log.duration!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ],
            ],
          ),
          if (log.payload != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(
                log.payload!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum LogType { info, debug, post, get }

class LogEntry {
  final LogType type;
  final String time;
  final String message;
  final String? status;
  final String? duration;
  final String? payload;

  LogEntry({
    required this.type,
    required this.time,
    required this.message,
    this.status,
    this.duration,
    this.payload,
  });
}

