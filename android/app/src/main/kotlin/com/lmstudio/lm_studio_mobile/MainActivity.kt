package com.lmstudio.lm_studio_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PDF_CHANNEL = "com.lmstudio/pdf_extractor"
    private val pdfExtractor = PdfTextExtractor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractText" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            pdfExtractor.extractText(path, result)
                        } else {
                            result.error("INVALID_ARG", "Path is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
