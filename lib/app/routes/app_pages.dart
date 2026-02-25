import 'package:get/get.dart';
import '../bindings/main_navigation_binding.dart';
import '../../presentation/screens/main_screen.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.main;

  static final routes = [
    GetPage(
      name: Routes.main,
      page: () => const MainScreen(),
      binding: MainNavigationBinding(),
    ),
  ];
}

