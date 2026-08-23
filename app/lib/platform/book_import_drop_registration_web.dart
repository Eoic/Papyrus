import 'package:desktop_drop/desktop_drop_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

bool _isRegistered = false;

void ensureBookImportDropPluginRegistered() {
  if (_isRegistered) return;
  DesktopDropWeb.registerWith(webPluginRegistrar);
  webPluginRegistrar.registerMessageHandler();
  _isRegistered = true;
}
