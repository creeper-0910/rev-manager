import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:revanced_manager/app/app.locator.dart';
import 'package:revanced_manager/models/patch.dart';
import 'package:revanced_manager/models/patched_application.dart';
import 'package:revanced_manager/services/manager_api.dart';
import 'package:revanced_manager/services/patcher_api.dart';
import 'package:revanced_manager/ui/views/patcher/patcher_viewmodel.dart';
import 'package:revanced_manager/ui/widgets/installerView/custom_material_button.dart';
import 'package:stacked/stacked.dart';
import 'package:wakelock/wakelock.dart';

class InstallerViewModel extends BaseViewModel {
  final ManagerAPI _managerAPI = locator<ManagerAPI>();
  final PatcherAPI _patcherAPI = locator<PatcherAPI>();
  final PatchedApplication _app = locator<PatcherViewModel>().selectedApp!;
  final List<Patch> _patches = locator<PatcherViewModel>().selectedPatches;
  static const _installerChannel = MethodChannel(
    'app.revanced.manager.flutter/installer',
  );
  final ScrollController scrollController = ScrollController();
  double? progress = 0.0;
  String logs = '';
  String headerLogs = '';
  bool isPatching = true;
  bool isInstalled = false;
  bool hasErrors = false;

  Future<void> initialize(BuildContext context) async {
    if (await Permission.ignoreBatteryOptimizations.isGranted) {
      try {
        FlutterBackground.initialize(
          androidConfig: FlutterBackgroundAndroidConfig(
            notificationTitle: FlutterI18n.translate(
              context,
              'installerView.notificationTitle',
            ),
            notificationText: FlutterI18n.translate(
              context,
              'installerView.notificationText',
            ),
            notificationImportance: AndroidNotificationImportance.Default,
            notificationIcon: const AndroidResource(
              name: 'ic_notification',
              defType: 'drawable',
            ),
          ),
        ).then((value) => FlutterBackground.enableBackgroundExecution());
      } on Exception {
        // ignore
      }
    }
    await Wakelock.enable();
    await handlePlatformChannelMethods();
    await runPatcher();
  }

  Future<dynamic> handlePlatformChannelMethods() async {
    _installerChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'update':
          if (call.arguments != null) {
            Map<dynamic, dynamic> arguments = call.arguments;
            double progress = arguments['progress'];
            String header = arguments['header'];
            String log = arguments['log'];
            update(progress, header, log);
          }
          break;
      }
    });
  }

  void update(double value, String header, String log) {
    if (value > 0) {
      progress = value;
    }
    isPatching = progress == 1.0 ? false : true;
    if (progress == 0.0) {
      logs = '';
      isInstalled = false;
      hasErrors = false;
    }
    if (header.isNotEmpty) {
      headerLogs = header;
    }
    if (log.isNotEmpty && !log.startsWith('Merging L')) {
      if (logs.isNotEmpty) {
        logs += '\n';
      }
      logs += log;
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
        );
      });
    }
    notifyListeners();
  }

  Future<void> runPatcher() async {
    update(0.0, 'Initializing...', 'Initializing installer');
    if (_patches.isNotEmpty) {
      try {
        update(0.1, '', 'Creating working directory');
        await _patcherAPI.runPatcher(
          _app.packageName,
          _app.apkFilePath,
          _patches,
        );
      } catch (e) {
        hasErrors = true;
        update(-1.0, 'Aborting...', 'An error occurred! Aborting\nError: $e');
      }
    } else {
      hasErrors = true;
      update(-1.0, 'Aborting...', 'No app or patches selected! Aborting');
    }
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      try {
        FlutterBackground.disableBackgroundExecution();
      } on Exception {
        // ignore
      }
    }
    await Wakelock.disable();
    isPatching = false;
  }

  void installResult(BuildContext context, bool installAsRoot) async {
    _app.isRooted = installAsRoot;
    bool hasMicroG = _patches.any((p) => p.name.endsWith('microg-support'));
    bool rootMicroG = installAsRoot && hasMicroG;
    bool rootFromStorage = installAsRoot && _app.isFromStorage;
    bool ytWithoutRootMicroG =
        !installAsRoot && !hasMicroG && _app.packageName.contains('youtube');
    if (rootMicroG || rootFromStorage || ytWithoutRootMicroG) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: I18nText('installerView.installErrorDialogTitle'),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          content: I18nText(
            rootMicroG
                ? 'installerView.installErrorDialogText1'
                : rootFromStorage
                    ? 'installerView.installErrorDialogText3'
                    : 'installerView.installErrorDialogText2',
          ),
          actions: <Widget>[
            CustomMaterialButton(
              label: I18nText('okButton'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    } else {
      update(
        1.0,
        'Installing...',
        _app.isRooted
            ? 'Installing patched file using root method'
            : 'Installing patched file using nonroot method',
      );
      isInstalled = await _patcherAPI.installPatchedFile(_app);
      if (isInstalled) {
        update(1.0, 'Installed!', 'Installed!');
        _app.isFromStorage = false;
        _app.patchDate = DateTime.now();
        _app.appliedPatches = _patches.map((p) => p.name).toList();
        if (hasMicroG) {
          _app.packageName = _app.packageName.replaceFirst(
            'com.google.',
            'app.revanced.',
          );
        }
        await _managerAPI.savePatchedApp(_app);
      }
    }
  }

  void shareResult() {
    _patcherAPI.sharePatchedFile(_app.name, _app.version);
  }

  void shareLog() {
    _patcherAPI.sharePatcherLog(logs);
  }

  Future<void> cleanPatcher() async {
    _patcherAPI.cleanPatcher();
    locator<PatcherViewModel>().selectedApp = null;
    locator<PatcherViewModel>().selectedPatches.clear();
    locator<PatcherViewModel>().notifyListeners();
  }

  void openApp() {
    DeviceApps.openApp(_app.packageName);
  }

  void onMenuSelection(int value) {
    switch (value) {
      case 0:
        shareResult();
        break;
      case 1:
        shareLog();
        break;
    }
  }
}
