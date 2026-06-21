import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'app_router.dart';
import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_api_client.dart';
import 'core/services/supabase_auth_service.dart';
import 'core/services/theme_mode_service.dart';
import 'core/supabase_config.dart';
import 'dev/fake_api_client.dart';
import 'dev/fake_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthService authService;
  final ApiClient apiClient;
  if (kDebugMode) {
    final fakeApi = FakeApiClient();
    apiClient = fakeApi;
    authService = FakeAuthService(fakeApi);
  } else {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    apiClient = SupabaseApiClient();
    authService = SupabaseAuthService();
  }
  final themeModeService = ThemeModeService();
  await authService.initialize();

  final appRouter = AppRouter(
    authService: authService,
    apiClient: apiClient,
    themeModeService: themeModeService,
  );

  runApp(App(appRouter: appRouter, themeModeService: themeModeService));
}
