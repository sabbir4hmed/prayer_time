import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  final bool useAutomaticLocation;
  final bool enableNotifications;
  final String city;
  final String country;
  final Function(bool useAutomatic, bool enableNotifications, String city, String country) onSave;

  const SettingsDialog({
    Key? key,
    required this.useAutomaticLocation,
    required this.enableNotifications,
    required this.city,
    required this.country,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _useAutomaticLocation;
  late bool _enableNotifications;
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _useAutomaticLocation = widget.useAutomaticLocation;
    _enableNotifications = widget.enableNotifications;
    _cityController = TextEditingController(text: widget.city);
    _countryController = TextEditingController(text: widget.country);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Use Automatic Location'),
              subtitle: const Text('Uses your device location for prayer times'),
              value: _useAutomaticLocation,
              onChanged: (value) {
                setState(() {
                  _useAutomaticLocation = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts for prayer times'),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                });
              },
            ),
            const Divider(),
            if (!_useAutomaticLocation) ...[
              const SizedBox(height: 8),
              const Text(
                'Manual Location Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(
              _useAutomaticLocation,
              _enableNotifications,
              _cityController.text,
              _countryController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}