import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../app/controllers/chat_controller.dart';
import '../../app/data/models/chat_message.dart';
import '../../app/data/models/attachment.dart';
import '../../app/services/chat_history_service.dart';
import '../../app/services/model_manager.dart';
import '../../core/theme/colors.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: _buildHistoryDrawer(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  if (message.role == MessageRole.user) {
                    return _buildUserMessage(message);
                  } else {
                    return _buildAssistantMessage(message);
                  }
                },
              );
            }),
          ),
          // Pending attachments preview
          _buildPendingAttachments(),
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context) {
    final historyService = Get.find<ChatHistoryService>();
    
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.startNewChat();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: Obx(() {
                if (historyService.sessions.isEmpty) {
                  return Center(
                    child: Text(
                      'No chat history',
                      style: GoogleFonts.notoSans(color: AppColors.textSecondaryDark),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: historyService.sessions.length,
                  itemBuilder: (context, index) {
                    final session = historyService.sessions[index];
                    final isSelected = controller.currentSession.value?.id == session.id;
                    
                    return ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                        size: 20,
                      ),
                      title: Text(
                        session.title,
                        style: GoogleFonts.notoSans(
                          color: isSelected ? Colors.white : AppColors.textPrimaryDark,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondaryDark),
                        onPressed: () async {
                          await historyService.deleteSession(session.id);
                          if (isSelected) {
                            controller.startNewChat();
                          }
                        },
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                      onTap: () {
                        controller.loadSession(session);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 8,
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
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimaryDark),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Chat History',
            ),
          ),
          Expanded(
            child: Obx(() => GestureDetector(
                  onTap: () => _showModelSelector(context),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: controller.isModelLoaded.value
                                  ? AppColors.success
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              controller.isModelLoaded.value
                                  ? controller.currentModelName.value
                                  : 'No Model Loaded',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.expand_more,
                            size: 16,
                            color: AppColors.textSecondaryDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (controller.isModelLoaded.value)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Obx(() => Text(
                                    '${controller.tokensPerSecond.value.toStringAsFixed(1)} t/s',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                    ],
                  ),
                )),
          ),
          Obx(() => controller.isGenerating.value
              ? IconButton(
                  icon: const Icon(Icons.stop_circle,
                      color: AppColors.error, size: 28),
                  onPressed: () => controller.stopGeneration(),
                  tooltip: 'Stop generating',
                )
              : IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textPrimaryDark),
                  onPressed: () {},
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                controller.isModelLoaded.value
                    ? Icons.chat_bubble_outline
                    : Icons.smart_toy_outlined,
                size: 64,
                color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                controller.isModelLoaded.value
                    ? 'Start a conversation'
                    : 'Load a model to begin',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.isModelLoaded.value
                    ? 'Type a message or attach files to chat with ${controller.currentModelName.value}'
                    : 'Go to My Models tab to load a model',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color:
                      AppColors.textSecondaryDark.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )),
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Show attachments if any
                if (message.attachments != null && message.attachments!.isNotEmpty)
                  ..._buildMessageAttachments(message.attachments!),
                // Text content
                if (message.content.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 20,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Build attachment chips/previews in sent messages
  List<Widget> _buildMessageAttachments(List<Attachment> attachments) {
    return attachments.map((attachment) {
      if (attachment.isImage) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220, maxHeight: 200),
              child: Image.file(
                attachment.file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDocumentChip(attachment),
              ),
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildDocumentChip(attachment),
        );
      }
    }).toList();
  }

  Widget _buildDocumentChip(Attachment attachment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.isImage ? Icons.image : Icons.description,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.fileName,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.sizeFormatted,
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentModelName.value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      message.content.isEmpty && message.isStreaming
                          ? Text(
                              '...',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                color: AppColors.textSecondaryDark,
                              ),
                            )
                          : MarkdownBody(
                              data: message.content,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  color: AppColors.textPrimaryDark,
                                ),
                                code: GoogleFonts.firaCode(
                                  fontSize: 14,
                                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                                  color: AppColors.primary,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                            ),
                      if (message.isStreaming) ...[
                        const SizedBox(height: 8),
                        _buildStreamingIndicator(),
                      ],
                      if (!message.isStreaming &&
                          message.tokensPerSecond != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.bolt,
                                size: 12, color: AppColors.textSecondaryDark),
                            const SizedBox(width: 4),
                            Text(
                              '${message.tokensPerSecond!.toStringAsFixed(1)} t/s',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!message.isStreaming && message.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActionButton(Icons.content_copy, 'Copy', () {
                        Clipboard.setData(
                            ClipboardData(text: message.content));
                        Get.snackbar(
                          'Copied',
                          'Response copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 1),
                          backgroundColor:
                              AppColors.surfaceDark.withValues(alpha: 0.9),
                          colorText: AppColors.textPrimaryDark,
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Generating...',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondaryDark),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pending attachments preview above input area
  Widget _buildPendingAttachments() {
    return Obx(() {
      if (controller.pendingAttachments.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.pendingAttachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final attachment = controller.pendingAttachments[index];
              return _buildPendingAttachmentChip(attachment, index);
            },
          ),
        ),
      );
    });
  }

  Widget _buildPendingAttachmentChip(Attachment attachment, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: attachment.isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    attachment.file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getFileIcon(attachment.fileName),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        attachment.fileName,
                        style: GoogleFonts.notoSans(
                          fontSize: 8,
                          color: AppColors.textSecondaryDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
        // Remove button
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => controller.removeAttachment(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'md':
      case 'log':
        return Icons.text_snippet;
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      default:
        return Icons.description;
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            GestureDetector(
              onTap: () => _showAttachmentOptions(Get.context!),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: AppColors.textSecondaryDark,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF120d1d),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: controller.textController,
                  style:
                      const TextStyle(color: AppColors.textPrimaryDark),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) => controller.sendMessage(text),
                  decoration: InputDecoration(
                    hintText: 'Message local model...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondaryDark,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => GestureDetector(
                  onTap: controller.isGenerating.value
                      ? controller.stopGeneration
                      : () => controller
                          .sendMessage(controller.textController.text),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: controller.isGenerating.value
                          ? AppColors.error
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isGenerating.value
                          ? Icons.stop
                          : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Show attachment options bottom sheet
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Attach File',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildAttachmentOption(
                icon: Icons.description,
                label: 'Document',
                subtitle: 'PDF, TXT, Markdown, CSV, JSON',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  controller.pickDocument();
                },
              ),
              const SizedBox(height: 8),
              _buildAttachmentOption(
                icon: Icons.photo_library,
                label: 'Photo Library',
                subtitle: 'Choose from gallery',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImageFromGallery();
                },
              ),
              const SizedBox(height: 8),
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                subtitle: 'Take a photo',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImageFromCamera();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.notoSans(
          fontSize: 12,
          color: AppColors.textSecondaryDark,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showModelSelector(BuildContext context) {
    final modelManager = Get.find<ModelManager>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Model',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (modelManager.downloadedModels.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No models found.\nImport a .gguf model from My Models tab.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: modelManager.downloadedModels.map((model) {
                    final isActive = controller.currentModelName.value ==
                        model.name;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.blue
                                  ],
                                )
                              : null,
                          color: isActive
                              ? null
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.smart_toy,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        model.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      subtitle: Text(
                        model.sizeFormatted,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_circle,
                              color: AppColors.success)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        controller.loadModel(model.filePath,
                            modelName: model.name);
                      },
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
