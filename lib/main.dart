import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_api_client.dart';
import 'core/services/theme_mode_service.dart';
import 'core/supabase_config.dart';
import 'dev/fake_api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  final apiClient =
      kDebugMode ? FakeApiClient() : SupabaseApiClient();
  final authService = AuthService();
  final themeModeService = ThemeModeService();
  await authService.initialize();

  final appRouter = AppRouter(
    authService: authService,
    apiClient: apiClient,
    themeModeService: themeModeService,
  );

  runApp(App(appRouter: appRouter, themeModeService: themeModeService));
}
