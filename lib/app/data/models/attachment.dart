import 'dart:io';

enum AttachmentType { image, document }

class Attachment {
  final String id;
  final AttachmentType type;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String? extractedText;
  final String? mimeType;

  const Attachment({
    required this.id,
    required this.type,
    required this.filePath,
    required this.fileName,
    this.fileSize = 0,
    this.extractedText,
    this.mimeType,
  });

  Attachment copyWith({
    String? id,
    AttachmentType? type,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? extractedText,
    String? mimeType,
  }) {
    return Attachment(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      extractedText: extractedText ?? this.extractedText,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  bool get hasExtractedText =>
      extractedText != null && extractedText!.trim().isNotEmpty;

  bool get isImage => type == AttachmentType.image;
  bool get isDocument => type == AttachmentType.document;

  File get file => File(filePath);

  String get sizeFormatted {
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (fileSize >= 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSize B';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'extractedText': extractedText,
      'mimeType': mimeType,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AttachmentType.document,
      ),
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      fileSize: map['fileSize'] as int? ?? 0,
      extractedText: map['extractedText'] as String?,
      mimeType: map['mimeType'] as String?,
    );
  }
}
