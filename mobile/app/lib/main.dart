import 'package:flutter/widgets.dart';

import 'src/app/ummah_app.dart';
import 'src/bootstrap/app_controller.dart';
import 'src/bootstrap/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppEnvironment environment = AppEnvironment.fromCompileTime();
  final AppController controller = AppController(environment: environment);
  await controller.initialize();
  runApp(UmmahApp(controller: controller));
}
