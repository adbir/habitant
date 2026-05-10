import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_router.dart';
import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_mode_service.dart';
import 'dev/fake_api_client.dart';

const _apiBaseUrl = 'https://api.habitant.dk';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient =
      kDebugMode ? FakeApiClient() : ApiClient(baseUrl: _apiBaseUrl);
  final authService = AuthService(apiClient: apiClient);
  final themeModeService = ThemeModeService();
  await authService.initialize();

  final appRouter = AppRouter(
    authService: authService,
    apiClient: apiClient,
    themeModeService: themeModeService,
  );

  runApp(App(appRouter: appRouter, themeModeService: themeModeService));
}
