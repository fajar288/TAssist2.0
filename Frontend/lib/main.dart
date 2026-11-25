import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/fcm_service.dart';
import 'core/syncfusion_license.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncfusionLicense.register();
  await FcmService.instance.init();
  runApp(const TAssistApp());
}
