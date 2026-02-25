import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/controllers/main_navigation_controller.dart';
import 'model_discovery_screen.dart';
import 'chat_screen.dart';
import 'my_models_screen.dart';
import 'server_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class MainScreen extends GetView<MainNavigationController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: const [
          ModelDiscoveryScreen(),
          MyModelsScreen(),
          ChatScreen(),
          ServerScreen(),
        ],
      )),
      bottomNavigationBar: Obx(() => BottomNavBar(
        selectedIndex: controller.currentIndex.value,
        onTap: (index) => controller.changePage(index),
      )),
    );
  }
}

