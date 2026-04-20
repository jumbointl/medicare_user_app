import 'package:medicare_user_app/model/currency_model.dart';

class CurrencyFormatterHelper {
  static String format(double amount) {

    String v = amount.toStringAsFixed(Currency.currencyDecimal);

    v = v.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => Currency.currencyThousandSeparator,
    );

    v = v.replaceAll(".", Currency.currencyDecimalSeparator);


    if (Currency.currencyPosition == "Left") {
      return "${Currency.currencySymbol}$v";
    }

    if (Currency.currencyPosition == "Left With Space") {
      return "${Currency.currencySymbol} $v";
    }
    if (Currency.currencyPosition == "Right With Space") {
      return "$v ${Currency.currencySymbol}";
    }

    else {
      return "$v${Currency.currencySymbol}";
    }
  }
}
