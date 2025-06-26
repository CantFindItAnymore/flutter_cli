import 'package:flutter_cli/core/index.dart';
import 'index.dart';
import 'package:flutter/material.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  Widget _buildView() {
    return const Center(
      child: Text('Home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      id: 'home',
      builder: (_) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: _buildView(),
        );
      },
    );
  }
}
