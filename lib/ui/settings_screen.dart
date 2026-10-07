import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_services.dart';
import '../core/sfx.dart';
import '../l10n/l10n.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = '${p.version} (${p.buildNumber})');
    }).catchError((Object _) {});
  }

  Future<void> _rename() async {
    final l = context.l10n;
    final s = AppScope.of(context);
    final ctrl = TextEditingController(text: s.pet.state.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsRenameTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l.onbNameHint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(l.save)),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      s.pet.rename(name);
      s.sfx.play(Sfx.oink);
    }
  }

  Future<void> _reset() async {
    final l = context.l10n;
    final s = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsResetTitle),
        content: Text(l.settingsResetBody(s.pet.state.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.settingsResetConfirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      await s.pet.reset();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: ValueListenableBuilder(
        valueListenable: s.settings,
        builder: (context, settings, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_rounded, color: AppColors.pinkDeep),
                    title: Text(l.settingsSound),
                    value: settings.sound,
                    onChanged: (v) {
                      s.settings.update(settings.copyWith(sound: v));
                      if (v) s.sfx.play(Sfx.oink);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_rounded, color: AppColors.pinkDeep),
                    title: Text(l.settingsHaptics),
                    value: settings.haptics,
                    onChanged: (v) => s.settings.update(settings.copyWith(haptics: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListenableBuilder(
                listenable: s.pet,
                builder: (context, _) => ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.pinkDeep),
                  title: Text(l.settingsRename(s.pet.state.name)),
                  onTap: _rename,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.pinkDeep),
                    title: Text(l.settingsSupport),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _open(s.remote.value.supportUrl),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.pinkDeep),
                    title: Text(l.settingsPrivacy),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _open(s.remote.value.privacyUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
                title: Text(l.settingsReset, style: const TextStyle(color: AppColors.danger)),
                onTap: _reset,
              ),
            ),
            const SizedBox(height: 24),
            Text(l.settingsNoAds, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            if (_version.isNotEmpty)
              Text(l.settingsVersion(_version), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
