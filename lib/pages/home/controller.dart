import 'package:flutter_cli/core/index.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class HomeController extends GetxController with BaseControllerMixin {
  @override
  String get builderId => 'home';

  HomeController();

  @override
  void onInit() {
    super.onInit();
    FlutterNativeSplash.remove();
  }
}
