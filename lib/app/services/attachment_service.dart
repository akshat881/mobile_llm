import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../data/models/attachment.dart';

/// Service for picking files, extracting text from documents and images.
class AttachmentService {
  static const _pdfChannel = MethodChannel('com.lmstudio/pdf_extractor');
  final _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  /// Pick a document file (PDF, TXT, MD, etc.)
  Future<Attachment?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'csv', 'json', 'log'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    final ioFile = File(file.path!);
    final stat = await ioFile.stat();

    String? extractedText;
    final ext = file.extension?.toLowerCase() ?? '';

    if (ext == 'pdf') {
      extractedText = await extractTextFromPdf(file.path!);
    } else if (['txt', 'md', 'csv', 'json', 'log'].contains(ext)) {
      extractedText = await _readTextFile(file.path!);
    }

    return Attachment(
      id: _uuid.v4(),
      type: AttachmentType.document,
      filePath: file.path!,
      fileName: file.name,
      fileSize: stat.size,
      extractedText: extractedText,
      mimeType: _getMimeType(ext),
    );
  }

  /// Pick an image from gallery
  Future<Attachment?> pickImageFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return _processImage(image);
  }

  /// Pick an image from camera
  Future<Attachment?> pickImageFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return _processImage(image);
  }

  Future<Attachment?> _processImage(XFile? image) async {
    if (image == null) return null;

    final file = File(image.path);
    final stat = await file.stat();

    // Use Google ML Kit to extract text from the image
    String? extractedText;
    try {
      extractedText = await extractTextFromImage(image.path);
    } catch (_) {
      // OCR failed — that's okay, image will still be attached
    }

    final ext = image.path.split('.').last.toLowerCase();

    return Attachment(
      id: _uuid.v4(),
      type: AttachmentType.image,
      filePath: image.path,
      fileName: image.name,
      fileSize: stat.size,
      extractedText: extractedText,
      mimeType: _getMimeType(ext),
    );
  }

  /// Extract text from an image using Google ML Kit
  Future<String?> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();
      return text.isEmpty ? null : text;
    } finally {
      textRecognizer.close();
    }
  }

  /// Extract text from a PDF via native platform channel
  Future<String?> extractTextFromPdf(String pdfPath) async {
    try {
      if (Platform.isAndroid) {
        final result = await _pdfChannel.invokeMethod<String>(
          'extractText',
          {'path': pdfPath},
        );
        return result?.trim().isEmpty == true ? null : result?.trim();
      } else if (Platform.isIOS || Platform.isMacOS) {
        // iOS/macOS: use platform channel (implemented in Swift)
        final result = await _pdfChannel.invokeMethod<String>(
          'extractText',
          {'path': pdfPath},
        );
        return result?.trim().isEmpty == true ? null : result?.trim();
      } else {
        // Fallback: try reading as raw text (won't work for binary PDFs)
        return null;
      }
    } on PlatformException catch (e) {
      print('PDF extraction failed: ${e.message}');
      return null;
    }
  }

  /// Read a plain text file
  Future<String?> _readTextFile(String path) async {
    try {
      final content = await File(path).readAsString();
      // Limit text to ~4000 chars to avoid overflowing the model's context
      if (content.length > 4000) {
        return '${content.substring(0, 4000)}\n\n[... truncated, ${content.length} total characters]';
      }
      return content;
    } catch (e) {
      return null;
    }
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
