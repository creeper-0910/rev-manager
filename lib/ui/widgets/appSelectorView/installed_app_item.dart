import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:revanced_manager/ui/widgets/shared/custom_card.dart';

class InstalledAppItem extends StatefulWidget {
  final String name;
  final String pkgName;
  final Uint8List icon;
  final Function()? onTap;

  const InstalledAppItem({
    Key? key,
    required this.name,
    required this.pkgName,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  State<InstalledAppItem> createState() => _InstalledAppItemState();
}

class _InstalledAppItemState extends State<InstalledAppItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: CustomCard(
        onTap: widget.onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              alignment: Alignment.center,
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Image.memory(widget.icon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.name,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.pkgName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
