import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:revanced_manager/app/app.locator.dart';
import 'package:revanced_manager/services/manager_api.dart';
import 'package:revanced_manager/services/toast.dart';
import 'package:revanced_manager/ui/widgets/shared/custom_material_button.dart';
import 'package:revanced_manager/ui/widgets/shared/custom_card.dart';

// ignore: must_be_immutable
class PatchItem extends StatefulWidget {
  final String name;
  final String simpleName;
  final String description;
  final String version;
  final String packageVersion;
  final List<String> supportedPackageVersions;
  final bool isUnsupported;
  bool isSelected;
  final Function(bool) onChanged;
  final Widget? child;
  final toast = locator<Toast>();
  final _managerAPI = locator<ManagerAPI>();

  PatchItem(
      {Key? key,
      required this.name,
      required this.simpleName,
      required this.description,
      required this.version,
      required this.packageVersion,
      required this.supportedPackageVersions,
      required this.isUnsupported,
      required this.isSelected,
      required this.onChanged,
      this.child})
      : super(key: key);

  @override
  State<PatchItem> createState() => _PatchItemState();
}

class _PatchItemState extends State<PatchItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: CustomCard(
        backgroundColor: widget.isUnsupported &&
                widget._managerAPI.areExperimentalPatchesEnabled() == false
            ? Theme.of(context).colorScheme.brightness == Brightness.light
                ? Colors.grey[400]
                : Colors.grey[700]
            : null,
        onTap: () {
          setState(() {
            if (widget.isUnsupported &&
                !widget._managerAPI.areExperimentalPatchesEnabled()
            ) {
              widget.isSelected = false;
              widget.toast.showBottom('patchItem.unsupportedPatchVersion');
            } else {
              widget.isSelected = !widget.isSelected;
            }
          });
          widget.onChanged(widget.isSelected);
        },
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            widget.simpleName,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.version,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: widget.isSelected,
                    activeColor: Theme.of(context).colorScheme.primary,
                    checkColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    side: BorderSide(
                      width: 2.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        if (widget.isUnsupported &&
                            !widget._managerAPI.areExperimentalPatchesEnabled()
                        ) {
                          widget.isSelected = false;
                          widget.toast
                              .showBottom('patchItem.unsupportedPatchVersion');
                        } else {
                          widget.isSelected = newValue!;
                        }
                      });
                      widget.onChanged(widget.isSelected);
                    },
                  ),
                )
              ],
            ),
            widget.isUnsupported
                ? Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          label: I18nText('patchItem.unsupportedWarningButton'),
                          icon: const Icon(Icons.warning, size: 20.0),
                          onPressed: () => _showUnsupportedWarningDialog(),
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  width: 1,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
            widget.child ?? const SizedBox(),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnsupportedWarningDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: I18nText('patchItem.unsupportedDialogTitle'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        content: I18nText(
          'patchItem.unsupportedDialogText',
          translationParams: {
            'packageVersion': widget.packageVersion,
            'supportedVersions':
                '\u2022 ${widget.supportedPackageVersions.reversed.join('\n\u2022 ')}',
          },
        ),
        actions: <Widget>[
          CustomMaterialButton(
            label: I18nText('okButton'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}
