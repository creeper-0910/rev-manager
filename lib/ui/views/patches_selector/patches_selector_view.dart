import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:revanced_manager/ui/views/patches_selector/patches_selector_viewmodel.dart';
import 'package:revanced_manager/ui/widgets/patchesSelectorView/patch_item.dart';
import 'package:revanced_manager/ui/widgets/shared/search_bar.dart';
import 'package:stacked/stacked.dart';

class PatchesSelectorView extends StatefulWidget {
  const PatchesSelectorView({Key? key}) : super(key: key);

  @override
  State<PatchesSelectorView> createState() => _PatchesSelectorViewState();
}

class _PatchesSelectorViewState extends State<PatchesSelectorView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PatchesSelectorViewModel>.reactive(
      onModelReady: (model) => model.initialize(),
      viewModelBuilder: () => PatchesSelectorViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: Visibility(
          visible: model.patches.isNotEmpty,
          child: FloatingActionButton.extended(
            label: I18nText('patchesSelectorView.doneButton'),
            icon: const Icon(Icons.check),
            onPressed: () {
              model.selectPatches();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: false,
              title: I18nText(
                'patchesSelectorView.viewTitle',
                child: Text(
                  '',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headline6!.color,
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).textTheme.headline6!.color,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Container(
                  height: 2,
                  margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    model.patchesVersion!,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headline6!.color,
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 12.0,
                  ),
                  child: SearchBar(
                    showSelectIcon: true,
                    hintText: FlutterI18n.translate(
                      context,
                      'patchesSelectorView.searchBarHint',
                    ),
                    onQueryChanged: (searchQuery) {
                      setState(() {
                        _query = searchQuery;
                      });
                    },
                    onSelectAll: (value) {
                      if (value) {
                        model.selectAllPatcherWarning(context);
                      }
                      model.selectAllPatches(value);
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: model.patches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: I18nText(
                          'patchesSelectorView.noPatchesFound',
                          child: Text(
                            '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0)
                          .copyWith(bottom: 80),
                      child: Column(
                        children: model
                            .getQueriedPatches(_query)
                            .map(
                              (patch) => PatchItem(
                                name: patch.name,
                                simpleName: patch.getSimpleName(),
                                version: patch.version,
                                description: patch.description,
                                packageVersion: model.getAppVersion(),
                                supportedPackageVersions:
                                    model.getSupportedVersions(patch),
                                isUnsupported: !model.isPatchSupported(patch),
                                isSelected: model.isSelected(patch),
                                onChanged: (value) =>
                                    model.selectPatch(patch, value),
                              ),
                              /* TODO: Enable this and make use of new Patch Options implementation
                                   patch.hasOptions ? ExpandablePanel(
                                    controller: expController,
                                    theme: const ExpandableThemeData(
                                      hasIcon: false,
                                      tapBodyToExpand: true,
                                      tapBodyToCollapse: true,
                                      tapHeaderToExpand: true,
                                    ),
                                    header: Column(
                                      children: <Widget>[
                                        GestureDetector(
                                          onLongPress: () =>
                                              expController.toggle(),
                                          child: PatchItem(
                                            name: patch.name,
                                            simpleName: patch.getSimpleName(),
                                            description: patch.description,
                                            version: patch.version,
                                            packageVersion:
                                                model.getAppVersion(),
                                            supportedPackageVersions: model
                                                .getSupportedVersions(patch),
                                            isUnsupported: !model
                                                .isPatchSupported(patch),
                                            isSelected:
                                                model.isSelected(patch),
                                            onChanged: (value) => model
                                                .selectPatch(patch, value),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8.0,
                                              ),
                                              child: Text(
                                                  'Long press for additional options.',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    expanded: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              'Patch options',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const OptionsTextField(
                                                hint: 'App name'),
                                            const OptionsFilePicker(
                                              optionName: 'Choose a logo',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    collapsed: Container(),
                                  ) */
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
