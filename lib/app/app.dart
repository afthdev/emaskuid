import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/core/config/app_config.dart';
import 'package:emaskuid/app/theme/app_theme.dart';
import 'package:emaskuid/screens/shell/main_shell.dart';

class EmasKuApp extends StatelessWidget {
  const EmasKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      defaultTransition: Transition.cupertino,
      home: const MainShell(),
    );
  }
}
