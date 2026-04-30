# Translation keys added — medicare_user_app

Tracking file for translation keys added during the i18n cleanup pass.
Locale files live in `lib/languages/` (`en`, `es`, `pt`, `zh`, `zh_tw`).

## Convention

- Keys are lowercase snake_case. Punctuation in the value goes in the value, not the key.
- **Named placeholders use `@name`** with `.trParams({...})`:
  - `"booking_id": "Booking #@id"` → `"booking_id".trParams({"id": "123"})`
  - Use this when there is **1 placeholder**, or when the substituted values have semantic meaning
    (e.g. `name`, `count`, `value`).
- **Positional placeholders use `%s`** with `.trArgs([...])`:
  - `"full_name": "%s %s"` → `"full_name".trArgs(["Pablo", "Lin"])`
  - Use this when there are **2 or more placeholders** with similar/uniform meaning, or for
    pure formatting templates (separators, ordering).
- Do **not** use `{name}` — that is the i18next/Vue style; GetX `.trParams` does not interpolate it.

## Keys added (alphabetical)

Format strings (`%s`-based) are deliberately identical across all 5 locales because they
contain no translatable text — they are templates for ordering/separators only.

| Key | en | es | pt | zh | zh_tw |
|---|---|---|---|---|---|
| `authors` | Author's | Autor(es) | Autor(es) | 作者 | 作者 |
| `blog_post` | Blog Post | Entrada de blog | Postagem do blog | 博文 | 部落格文章 |
| `city_state` | `%s, %s` | `%s, %s` | `%s, %s` | `%s, %s` | `%s, %s` |
| `coming_soon` | Coming soon | Próximamente | Em breve | 即将推出 | 即將推出 |
| `coming_soon_desc` | This feature isn't available yet. Stay tuned! | Esta funcionalidad aún no está disponible. ¡Pronto! | Esta funcionalidade ainda não está disponível. Em breve! | 该功能尚未上线，敬请期待！ | 此功能尚未推出，敬請期待！ |
| `continue_with_phone` | Continue with phone | Continuar con teléfono | Continuar com telefone | 使用电话继续 | 使用電話繼續 |
| `date_range` | `%s - %s` | `%s - %s` | `%s - %s` | `%s - %s` | `%s - %s` |
| `full_name` | `%s %s` | `%s %s` | `%s %s` | `%s %s` | `%s %s` |
| `language` | Language | Idioma | Idioma | 语言 | 語言 |
| `name_with_id` | `%s %s #%s` | `%s %s #%s` | `%s %s #%s` | `%s %s #%s` | `%s %s #%s` |
| `name_with_role` | `%s %s (%s)` | `%s %s (%s)` | `%s %s (%s)` | `%s %s (%s)` | `%s %s (%s)` |
| `seconds_value` | @value (s) | @value (s) | @value (s) | @value (s) | @value (s) |

## Sites converted to `.tr` / `.trParams` / `.trArgs`

### Plain `.tr`

| File:Line | Was | Now |
|---|---|---|
| `pages/payments/payment_page.dart:66` | `Text('Payment', ...)` | `Text('payment'.tr, ...)` |
| `pages/home_page.dart:1901` | `Text('Blog Post', ...)` | `Text('blog_post'.tr, ...)` |
| `languages/language_page.dart:18` | `const Text('Language')` | `Text('language'.tr)` |
| `pages/blog_details_page.dart:130` | `Text("Author's", ...)` | `Text("authors".tr, ...)` |
| `pages/auth/login_page.dart:174` | `Text("Continue with phone".tr)` | `Text("continue_with_phone".tr)` |
| `pages/auth/login_page.dart:423` | `Text("Cancel".tr, ...)` | `Text("cancel".tr, ...)` |
| `pages/doctors_list_page.dart:606` | `Text("No Data Found!".tr)` | `Text("no_data_found!".tr)` |

### `.trParams({...})` — single named placeholder

| File:Line | Was | Now |
|---|---|---|
| `pages/payments/payment_success_page.dart:96` | `Text("$counterValue (s)", ...)` | `Text("seconds_value".trParams({"value": "$counterValue"}), ...)` |

### `.trArgs([...])` — 2+ positional placeholders

| File:Line | Pattern | Now |
|---|---|---|
| `pages/clinic_list_page.dart:265` | `"${city.title},${city.stateTitle}"` | `"city_state".trArgs([title, stateTitle])` |
| `pages/doctors_list_page.dart:628` | same | `"city_state".trArgs([...])` |
| `pages/home_page.dart:1838` | same | `"city_state".trArgs([...])` |
| `pages/pathologist_list_page.dart:317` | same | `"city_state".trArgs([...])` |
| `pages/clinic_page.dart:372` | `"${doctor.fName} ${doctor.lName}"` | `"full_name".trArgs([fName, lName])` |
| `pages/doctors_list_page.dart:233` | same | `"full_name".trArgs([...])` |
| `pages/family_member_list_page.dart:133` | `"${fm.fName} ${fm.lName}"` | `"full_name".trArgs([...])` |
| `pages/edit_profile_page.dart:170` | `"${user.fName} ${user.lName}"` | `"full_name".trArgs([...])` |
| `pages/lab_cart_check_out_page.dart:886` | same | `"full_name".trArgs([...])` |
| `pages/lab_cart_check_out_page.dart:1161` | same | `"full_name".trArgs([...])` |
| `pages/patient_file_page.dart:104` | same | `"full_name".trArgs([...])` |
| `pages/prescription_list_page.dart:84` | same (patient) | `"full_name".trArgs([...])` |
| `pages/vital_details_page.dart:473` | same | `"full_name".trArgs([...])` |
| `pages/blog_details_page.dart:180` | `"${a.f_name} ${a.l_name} (${a.role})"` | `"name_with_role".trArgs([fName, lName, role])` |
| `pages/prescription_list_page.dart:76` | `"${doctor.fName} ${doctor.lName} #${id}"` | `"name_with_id".trArgs([fName, lName, id])` |
| `pages/vital_details_page.dart:188` | `"${fmt(start)} -  ${fmt(end)}"` | `"date_range".trArgs([fmt(start), fmt(end)])` |

## Pure-data interpolations left as-is (intentional)

`Text("${var}")` widgets that contain a single variable with no surrounding translatable text
were not converted, because wrapping a runtime value in `.trParams` adds verbosity without
i18n benefit. Examples kept verbatim:

- `pages/blog_details_page.dart:174` — `Text("${authorDetails['notes']}")`
- `pages/blog_details_page.dart:188` — specialization
- `pages/contact_us_page.dart:57` — snapshot value
- `pages/clinic_page.dart:673` — testimonial title
- `pages/family_member_list_page.dart:185` — ISD code + phone (no separator, pure concatenation)
- `pages/home_page.dart:1537` — user fName
- `pages/lab_cart_check_out_page.dart:524` — `"-${formattedOffPrice}"` (currency sign)
- `pages/lab_cart_check_out_page.dart:1167` — phone
- `pages/notification_page.dart:129` — title
- `pages/pathology_page.dart:894` — testimonial title
- `pages/prescription_list_page.dart:90` — formatted date
- `pages/share_page.dart:87` — snapshot value
- `pages/vital_details_page.dart:357` — formatted date

If you want these wrapped for full consistency (e.g. `"value_only".trParams({"value": x})`),
say so — it's mechanical from here.

## `{param}` → `@param` migration

Audited all five locale files. **No values use `{param}` style placeholders** — already in
`@param`. Migration not needed. Convention documented above.

## Cross-locale parity audit

After this pass, all five locale files (`en`, `es`, `pt`, `zh`, `zh_tw`) hold **442 keys**
each, with zero missing keys between locales (verified by `comm -23` diff).
