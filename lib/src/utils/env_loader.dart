import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadMagoCalendarEnv({String fileName = '.env'}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: fileName);
}
