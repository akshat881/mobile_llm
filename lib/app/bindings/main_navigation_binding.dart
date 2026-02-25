import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../controllers/model_discovery_controller.dart';
import '../controllers/chat_controller.dart';
import '../services/inference_service.dart';
import '../services/model_manager.dart';
import '../services/huggingface_service.dart';

class MainNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavigationController>(() => MainNavigationController());

    // Core services (permanent)
    Get.put<InferenceService>(InferenceService(), permanent: true);
    Get.put<ModelManager>(ModelManager(), permanent: true);
    Get.put<HuggingFaceService>(HuggingFaceService(), permanent: true);

    // Controllers
    Get.lazyPut<ModelDiscoveryController>(() => ModelDiscoveryController());
    Get.lazyPut<ChatController>(() => ChatController());
  }
}

