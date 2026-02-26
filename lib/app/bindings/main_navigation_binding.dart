import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../controllers/model_discovery_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/server_controller.dart';
import '../services/huggingface_service.dart';
import '../services/model_manager.dart';
import '../services/inference_service.dart';
import '../services/chat_history_service.dart';
import '../services/local_server_service.dart';

class MainNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavigationController>(() => MainNavigationController());

    // Core Services
    Get.lazyPut<HuggingFaceService>(() => HuggingFaceService(), fenix: true);
    Get.lazyPut<ModelManager>(() => ModelManager(), fenix: true);
    Get.lazyPut<InferenceService>(() => InferenceService(), fenix: true);
    Get.lazyPut<ChatHistoryService>(() => ChatHistoryService(), fenix: true);
    Get.lazyPut<LocalServerService>(() => LocalServerService(), fenix: true);

    // Controllers
    Get.lazyPut<ModelDiscoveryController>(() => ModelDiscoveryController(),
        fenix: true);
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    Get.lazyPut<ServerController>(() => ServerController(), fenix: true);
  }
}
