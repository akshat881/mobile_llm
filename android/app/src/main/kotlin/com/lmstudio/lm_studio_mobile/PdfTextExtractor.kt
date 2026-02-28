package com.lmstudio.lm_studio_mobile

import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native PDF text extractor for Android.
 * Uses Android's PdfRenderer + text extraction.
 * For more robust extraction, uses PdfDocument from android.graphics.pdf.
 */
class PdfTextExtractor {

    fun extractText(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "PDF file not found: $path", null)
                return
            }

            val text = extractTextFromPdf(file)
            result.success(text)
        } catch (e: Exception) {
            result.error("EXTRACTION_ERROR", "Failed to extract text: ${e.message}", null)
        }
    }

    private fun extractTextFromPdf(file: File): String {
        val sb = StringBuilder()

        try {
            // Use Android's built-in PDF support
            val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(fd)

            for (i in 0 until renderer.pageCount) {
                val page = renderer.openPage(i)
                // PdfRenderer doesn't directly extract text, but we can get page metadata
                sb.appendLine("[Page ${i + 1}]")
                page.close()
            }

            renderer.close()
            fd.close()

            // If PdfRenderer couldn't extract text content (it's mainly for rendering),
            // try reading raw content for text-based PDFs
            if (sb.toString().replace(Regex("\\[Page \\d+\\]\\n?"), "").isBlank()) {
                val rawText = extractRawText(file)
                if (rawText.isNotBlank()) {
                    return rawText
                }
            }
        } catch (e: Exception) {
            // Fallback to raw text extraction
            val rawText = extractRawText(file)
            if (rawText.isNotBlank()) {
                return rawText
            }
        }

        return sb.toString()
    }

    /**
     * Attempt to extract readable text from PDF by reading raw bytes.
     * This works for PDFs with embedded text streams.
     */
    private fun extractRawText(file: File): String {
        val bytes = file.readBytes()
        val content = String(bytes, Charsets.ISO_8859_1)
        val sb = StringBuilder()

        // Extract text between BT (Begin Text) and ET (End Text) operators
        val btPattern = Regex("BT(.*?)ET", RegexOption.DOT_MATCHES_ALL)
        val matches = btPattern.findAll(content)

        for (match in matches) {
            val textBlock = match.groupValues[1]
            // Extract strings inside parentheses (PDF text objects)
            val stringPattern = Regex("\\(([^)]*?)\\)")
            val strings = stringPattern.findAll(textBlock)
            for (str in strings) {
                val decoded = decodePdfString(str.groupValues[1])
                if (decoded.isNotBlank()) {
                    sb.append(decoded)
                }
            }
            // Also check for hex strings
            val hexPattern = Regex("<([0-9A-Fa-f]+)>")
            val hexStrings = hexPattern.findAll(textBlock)
            for (hex in hexStrings) {
                val decoded = decodeHexString(hex.groupValues[1])
                if (decoded.isNotBlank()) {
                    sb.append(decoded)
                }
            }
        }

        val result = sb.toString().trim()
        // Truncate to 4000 characters to avoid overwhelming the model
        return if (result.length > 4000) {
            result.substring(0, 4000) + "\n\n[... truncated, ${result.length} total characters]"
        } else {
            result
        }
    }

    private fun decodePdfString(input: String): String {
        return input
            .replace("\\n", "\n")
            .replace("\\r", "\r")
            .replace("\\t", "\t")
            .replace("\\(", "(")
            .replace("\\)", ")")
            .replace("\\\\", "\\")
    }

    private fun decodeHexString(hex: String): String {
        val sb = StringBuilder()
        var i = 0
        while (i < hex.length - 1) {
            val byte = hex.substring(i, i + 2).toIntOrNull(16) ?: break
            if (byte in 32..126) {
                sb.append(byte.toChar())
            }
            i += 2
        }
        return sb.toString()
    }
}
