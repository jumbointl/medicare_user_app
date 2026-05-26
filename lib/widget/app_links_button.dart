import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utilities/app_constans.dart';

// Dialog reutilizable que muestra los 3 links de descarga (APK stable, APK
// dev, Play Store). Patrón espejo de monalisa_app_001 / AppLinksButton.
class AppLinksButton extends StatelessWidget {
  const AppLinksButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.link),
      tooltip: 'links'.tr,
      onPressed: () => show(context),
    );
  }

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        Widget linkRow(String label, String url) {
          if (url.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('app_downloads_unavailable'.tr,
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(dialogContext);
                    try {
                      final ok = await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                      if (!ok) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('link: $url')),
                        );
                      }
                    } catch (_) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('link: $url')),
                      );
                    }
                  },
                  child: Text(
                    url,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          title: Text('app_downloads_title'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                linkRow('1. ${'apk_stable'.tr}', AppConstants.apkStableUrl),
                linkRow('2. ${'apk_dev'.tr}', AppConstants.apkDevUrl),
                linkRow('3. ${'play_store_label'.tr}', AppConstants.playStoreUrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('close'.tr),
            ),
          ],
        );
      },
    );
  }
}
