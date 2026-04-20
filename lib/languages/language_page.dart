import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'language_controller.dart';
import 'language_storage_helper.dart';
import '../helpers/route_helper.dart';
import 'translation.dart';
import '../model/language_model.dart';
import '../utilities/colors_constant.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: FutureBuilder<List<LanguageModel>>(
        future: LanguageStorage.getLanguages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final languages = snapshot.data!;
          final currentTag = Get.locale?.toLanguageTag();

          return ListView.separated(
            itemCount: languages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lang = languages[index];
              final code = lang.code ?? '';

              final bool selected = code.isNotEmpty &&
                  currentTag == LocaleHelper.parse(code).toLanguageTag();

              return ListTile(
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.language,
                  color: selected ? ColorResources.btnColor : Colors.grey,
                ),
                title: Text(lang.title ?? code),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  if (code.isEmpty) return;

                  if (selected) {
                    Get.back();
                    return;
                  }

                  final languageController = Get.find<LanguageController>();
                  await languageController.changeLanguage(code);

                  if (context.mounted) {
                    Get.back();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}