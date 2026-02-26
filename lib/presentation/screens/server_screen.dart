import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/controllers/server_controller.dart';
import '../../core/theme/colors.dart';

class ServerScreen extends GetView<ServerController> {
  const ServerScreen({super.key});

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
                Obx(() => Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.isServerRunning.value ? AppColors.success : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isServerRunning.value ? 'Running' : 'Stopped',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: controller.isServerRunning.value ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                )),
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
              Obx(() => Switch(
                value: controller.exposeToNetwork.value,
                onChanged: controller.setExposeToNetwork,
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
              )),
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
                      child: Obx(() => Text(
                        'http://${controller.serverIp.value}:${controller.serverPort.value}/v1',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      )),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.content_copy,
                        size: 20,
                        color: AppColors.textSecondaryDark,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: 'http://${controller.serverIp.value}:${controller.serverPort.value}/v1'));
                        Get.snackbar('Copied', 'API URL copied to clipboard',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.surfaceDark,
                            colorText: Colors.white);
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF120d1d),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Obx(() => Text(
                  controller.isModelLoaded.value ? controller.currentModelName.value : 'No model loaded',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: controller.isModelLoaded.value ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
                  ),
                )),
              ),
              const SizedBox(height: 12),
              Obx(() => Row(
                children: [
                  Icon(
                    controller.isModelLoaded.value ? Icons.memory : Icons.warning_amber_rounded,
                    size: 16,
                    color: controller.isModelLoaded.value ? AppColors.textSecondaryDark : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.isModelLoaded.value ? 'Ready for inference' : 'Load a model in My Models to start server',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: controller.isModelLoaded.value ? AppColors.textSecondaryDark : AppColors.warning,
                    ),
                  ),
                ],
              )),
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
                    onPressed: () => controller.clearLogs(),
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
                      // Optionally implement export logs later
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
              child: Obx(() => ListView.builder(
                itemCount: controller.logs.length,
                reverse: true, // Auto-scroll behavior since we insert at 0
                itemBuilder: (context, index) {
                  final log = controller.logs[index];
                  return _buildLogEntry(log);
                },
              )),
            ),
          ),
          const SizedBox(height: 8),
          // Blinking cursor
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
              // This creates an infinite loop naturally since it rebuilds
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

