import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../logic/settings_controller.dart';

/// Settings screen. Phase 4 slice 2: UI language (TR/EN). Phase 5: sound on/off.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(settingsControllerProvider)?.languageCode;
    final controller = ref.read(settingsControllerProvider.notifier);
    final soundEnabled = ref.watch(soundEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              l10n.settingsLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (code) {
              if (code != null) controller.setLocale(Locale(code));
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.languageEnglish),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text(l10n.languageTurkish),
                  value: 'tr',
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsSound),
            value: soundEnabled,
            onChanged: (enabled) =>
                ref.read(soundEnabledProvider.notifier).setEnabled(enabled),
          ),
        ],
      ),
    );
  }
}
