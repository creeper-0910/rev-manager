// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:app_installer/app_installer.dart';
import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:revanced_manager/app/app.locator.dart';
import 'package:revanced_manager/app/app.router.dart';
import 'package:revanced_manager/models/patched_application.dart';
import 'package:revanced_manager/services/manager_api.dart';
import 'package:revanced_manager/services/patcher_api.dart';
import 'package:revanced_manager/services/toast.dart';
import 'package:revanced_manager/ui/views/navigation/navigation_viewmodel.dart';
import 'package:revanced_manager/ui/views/patcher/patcher_viewmodel.dart';
import 'package:revanced_manager/ui/widgets/shared/custom_material_button.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:timezone/timezone.dart' as tz;

@lazySingleton
class HomeViewModel extends BaseViewModel {
  final NavigationService _navigationService = locator<NavigationService>();
  final ManagerAPI _managerAPI = locator<ManagerAPI>();
  final PatcherAPI _patcherAPI = locator<PatcherAPI>();
  final Toast _toast = locator<Toast>();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  DateTime? _lastUpdate;
  bool showUpdatableApps = false;
  List<PatchedApplication> patchedInstalledApps = [];
  List<PatchedApplication> patchedUpdatableApps = [];

  Future<void> initialize(BuildContext context) async {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onSelectNotification: (p) =>
          DeviceApps.openApp('app.revanced.manager.flutter'),
    );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    bool isConnected = await Connectivity().checkConnection();
    if (!isConnected) {
      _toast.show('homeView.noConnection');
    }
    _getPatchedApps();
    _managerAPI.reAssessSavedApps().then((_) => _getPatchedApps());
  }

  void navigateToAppInfo(PatchedApplication app) {
    _navigationService.navigateTo(
      Routes.appInfoView,
      arguments: AppInfoViewArguments(app: app),
    );
  }

  void toggleUpdatableApps(bool value) {
    showUpdatableApps = value;
    notifyListeners();
  }

  void navigateToPatcher(PatchedApplication app) async {
    locator<PatcherViewModel>().selectedApp = app;
    locator<PatcherViewModel>().selectedPatches =
        await _patcherAPI.getAppliedPatches(app.appliedPatches);
    locator<PatcherViewModel>().notifyListeners();
    locator<NavigationViewModel>().setIndex(1);
  }

  void _getPatchedApps() {
    patchedInstalledApps = _managerAPI
        .getPatchedApps()
        .where((app) => app.hasUpdates == false)
        .toList();
    patchedUpdatableApps = _managerAPI
        .getPatchedApps()
        .where((app) => app.hasUpdates == true)
        .toList();
    notifyListeners();
  }

  Future<bool> hasManagerUpdates() async {
    String? latestVersion = await _managerAPI.getLatestManagerVersion();
    String currentVersion = await _managerAPI.getCurrentManagerVersion();
    if (latestVersion != null) {
      try {
        int latestVersionInt =
            int.parse(latestVersion.replaceAll(RegExp('[^0-9]'), ''));
        int currentVersionInt =
            int.parse(currentVersion.replaceAll(RegExp('[^0-9]'), ''));
        return latestVersionInt > currentVersionInt;
      } on Exception catch (e, s) {
        await Sentry.captureException(e, stackTrace: s);
        return false;
      }
    }
    return false;
  }

  Future<void> updateManager(BuildContext context) async {
    try {
      _toast.show('homeView.downloadingMessage');
      File? managerApk = await _managerAPI.downloadManager();
      if (managerApk != null) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          FlutterI18n.translate(
            context,
            'homeView.notificationTitle',
          ),
          FlutterI18n.translate(
            context,
            'homeView.notificationText',
          ),
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'revanced_manager_channel',
              'ReVanced Manager Channel',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        _toast.show('homeView.installingMessage');
        await AppInstaller.installApk(managerApk.path);
      } else {
        _toast.show('homeView.errorDownloadMessage');
      }
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      _toast.show('homeView.errorInstallMessage');
    }
  }

  void updatesAreDisabled() {
    _toast.show('homeView.updatesDisabled');
  }

  Future<void> showUpdateConfirmationDialog(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: I18nText('homeView.updateDialogTitle'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        content: I18nText('homeView.updateDialogText'),
        actions: <Widget>[
          CustomMaterialButton(
            isFilled: false,
            label: I18nText('noButton'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomMaterialButton(
            label: I18nText('yesButton'),
            onPressed: () {
              Navigator.of(context).pop();
              updateManager(parentContext);
            },
          )
        ],
      ),
    );
  }

  Future<String?> getLatestPatcherReleaseTime() async {
    return _managerAPI.getLatestPatcherReleaseTime();
  }

  Future<String?> getLatestManagerReleaseTime() async {
    return _managerAPI.getLatestManagerReleaseTime();
  }

  Future<void> forceRefresh(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_lastUpdate == null ||
        _lastUpdate!.difference(DateTime.now()).inSeconds > 2) {
      _managerAPI.clearAllData();
    }
    initialize(context);
  }
}
