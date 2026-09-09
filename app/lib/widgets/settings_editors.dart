import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salah/theme.dart';

/// A tappable "label … value ›" row inside a settings card.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.last = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF0EAD6))),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: GardenColors.muted, fontSize: 14.5),
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right,
                    size: 18, color: GardenColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single-select bottom sheet in the garden style.
Future<T?> chooseOne<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T current,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: GardenColors.parchment,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      title: Text(labelOf(option)),
                      trailing: option == current
                          ? const Icon(Icons.check, color: GardenColors.fern)
                          : null,
                      onTap: () => Navigator.pop(context, option),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// A simple single-field text editor dialog.
Future<String?> editText(
  BuildContext context, {
  required String title,
  required String initial,
  String? hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? formatters,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: GardenColors.paper,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        cursorColor: GardenColors.fern,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: GardenColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save', style: TextStyle(color: GardenColors.fern)),
        ),
      ],
    ),
  );
}

/// Result of the location editor.
class LocationResult {
  const LocationResult(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;
}

/// A three-field editor for place name + coordinates.
Future<LocationResult?> editLocation(
  BuildContext context, {
  required String name,
  required double latitude,
  required double longitude,
}) {
  final nameController = TextEditingController(text: name);
  final latController = TextEditingController(text: latitude.toString());
  final lngController = TextEditingController(text: longitude.toString());

  const coordType = TextInputType.numberWithOptions(signed: true, decimal: true);

  return showDialog<LocationResult>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: GardenColors.paper,
      title: Text('Location', style: Theme.of(context).textTheme.titleSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Place'),
            cursorColor: GardenColors.fern,
          ),
          TextField(
            controller: latController,
            keyboardType: coordType,
            decoration: const InputDecoration(labelText: 'Latitude'),
            cursorColor: GardenColors.fern,
          ),
          TextField(
            controller: lngController,
            keyboardType: coordType,
            decoration: const InputDecoration(labelText: 'Longitude'),
            cursorColor: GardenColors.fern,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: GardenColors.muted)),
        ),
        TextButton(
          onPressed: () {
            final lat = double.tryParse(latController.text.trim());
            final lng = double.tryParse(lngController.text.trim());
            if (lat == null || lng == null) {
              Navigator.pop(context); // invalid coords — discard
              return;
            }
            Navigator.pop(
              context,
              LocationResult(nameController.text.trim(), lat, lng),
            );
          },
          child: const Text('Save', style: TextStyle(color: GardenColors.fern)),
        ),
      ],
    ),
  );
}
