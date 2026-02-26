import 'package:get/get.dart';
import '../../presentation/screens/server_screen.dart' show LogEntry;
import '../services/inference_service.dart';
import '../services/local_server_service.dart';

class ServerController extends GetxController {
  final InferenceService _inferenceService = Get.find<InferenceService>();
  final LocalServerService _localServerService = Get.find<LocalServerService>();

  final RxBool exposeToNetwork = true.obs;

  RxBool get isServerRunning => _localServerService.isRunning;
  RxString get serverIp => _localServerService.serverIp;
  RxInt get serverPort => _localServerService.serverPort;
  RxList<LogEntry> get logs => _localServerService.logs;

  RxBool get isModelLoaded => _inferenceService.isModelLoaded;
  RxString get currentModelName => _inferenceService.currentModelName;

  @override
  void onInit() {
    super.onInit();
    // Default start server on init
    _startServer();
  }

  void toggleServer() {
    if (isServerRunning.value) {
      _localServerService.stopServer();
    } else {
      _startServer();
    }
  }

  void setExposeToNetwork(bool value) {
    exposeToNetwork.value = value;
    if (isServerRunning.value) {
      // Restart server with new IP binding
      _localServerService.stopServer().then((_) {
        _startServer();
      });
    }
  }

  void _startServer() {
    _localServerService.startServer(exposeToNetwork: exposeToNetwork.value);
  }

  void clearLogs() {
    _localServerService.clearLogs();
  }
}
