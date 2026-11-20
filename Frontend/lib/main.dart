import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/syncfusion_license.dart';

void main() {
  SyncfusionLicense.register();
  runApp(const TAssistApp());
}