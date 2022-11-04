import 'package:collection/collection.dart';
import 'package:flutter_i18n/widgets/I18nText.dart';
import 'package:revanced_manager/app/app.locator.dart';
import 'package:revanced_manager/models/patch.dart';
import 'package:revanced_manager/models/patched_application.dart';
import 'package:revanced_manager/services/manager_api.dart';
import 'package:revanced_manager/services/patcher_api.dart';
import 'package:revanced_manager/ui/views/patcher/patcher_viewmodel.dart';
import 'package:revanced_manager/ui/widgets/shared/custom_material_button.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';

class PatchesSelectorViewModel extends BaseViewModel {
  final PatcherAPI _patcherAPI = locator<PatcherAPI>();
  final ManagerAPI _managerAPI = locator<ManagerAPI>();
  final List<Patch> patches = [];
  final List<Patch> selectedPatches =
      locator<PatcherViewModel>().selectedPatches;
  String? patchesVersion = '';

  Future<void> initialize() async {
    getPatchesVersion();
    patches.addAll(await _patcherAPI.getFilteredPatches(
      locator<PatcherViewModel>().selectedApp!.originalPackageName,
    ));
    patches.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  bool isSelected(Patch patch) {
    return selectedPatches.any(
      (element) => element.name == patch.name,
    );
  }

  void selectPatch(Patch patch, bool isSelected) {
    if (isSelected && !selectedPatches.contains(patch)) {
      selectedPatches.add(patch);
    } else {
      selectedPatches.remove(patch);
    }
    notifyListeners();
  }

  Future<void> selectAllPatcherWarning(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: I18nText('patchesSelectorView.selectAllPatchesWarningTitle'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        content: I18nText('patchesSelectorView.selectAllPatchesWarningContent'),
        actions: <Widget>[
          CustomMaterialButton(
            label: I18nText('okButton'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void selectAllPatches(bool isSelected) {
    selectedPatches.clear();

    if (isSelected && _managerAPI.areExperimentalPatchesEnabled() == false) {
      selectedPatches
          .addAll(patches.where((element) => isPatchSupported(element)));
    }

    if (isSelected && _managerAPI.areExperimentalPatchesEnabled()) {
      selectedPatches.addAll(patches);
    }

    notifyListeners();
  }

  void selectPatches() {
    locator<PatcherViewModel>().selectedPatches = selectedPatches;
    locator<PatcherViewModel>().notifyListeners();
  }

  Future<String?> getPatchesVersion() async {
    patchesVersion = await _managerAPI.getLatestPatchesVersion();
    // print('Patches version: $patchesVersion');
    return patchesVersion ?? '0.0.0';
  }

  List<Patch> getQueriedPatches(String query) {
    return patches
        .where((patch) =>
            query.isEmpty ||
            query.length < 2 ||
            patch.name.toLowerCase().contains(query.toLowerCase()) ||
            patch.getSimpleName().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  String getAppVersion() {
    return locator<PatcherViewModel>().selectedApp!.version;
  }

  List<String> getSupportedVersions(Patch patch) {
    PatchedApplication app = locator<PatcherViewModel>().selectedApp!;
    Package? package = patch.compatiblePackages.firstWhereOrNull(
      (pack) => pack.name == app.packageName,
    );
    if (package != null) {
      return package.versions;
    } else {
      return List.empty();
    }
  }

  bool isPatchSupported(Patch patch) {
    PatchedApplication app = locator<PatcherViewModel>().selectedApp!;
    return patch.compatiblePackages.any((pack) =>
        pack.name == app.packageName &&
        (pack.versions.isEmpty || pack.versions.contains(app.version)));
  }
}
