class PaymentTypeHelper {
  static const int payAtClinic = 1100;
  static const int bankTransfer = 1200;
  static const int debitCard = 7000;
  static const int creditCard = 7500;
  static const int qrCode = 7900;
  static const int preApprovedCredit = 8000;
  static const int cash = 9001;
  static const int hospitalWallet = 9100;

  static const int convenioPresencial = 2100;
  static const int convenioOnline = 5100;

  static int normalize(int? value) {
    switch (value) {
      case 20:
        return payAtClinic;
      case 40:
        return creditCard;
      case 41:
        return qrCode;
      case 50:
        return debitCard;
      default:
        return value ?? creditCard;
    }
  }

  static String label(int? value) {
    switch (normalize(value)) {
      case payAtClinic:
        return 'PAGO EN CLINICA';
      case bankTransfer:
        return 'TRANSFERENCIA BANCARIA';
      case debitCard:
        return 'TARJETA DE DEBITO';
      case creditCard:
        return 'TARJETA DE CREDITO';
      case qrCode:
        return 'QR CODE';
      case preApprovedCredit:
        return 'CREDITO PREAPROBADO';
      case cash:
        return 'EFECTIVO';
      case hospitalWallet:
        return 'BILLETERA';
      case convenioPresencial:
        return 'CONVENIO MEDICO PRESENCIAL';
      case convenioOnline:
        return 'CONVENIO MEDICO ONLINE';
      default:
        return 'NO DEFINIDO';
    }
  }

  static int fromPaymentMethodText(String? method) {
    final m = (method ?? '').toUpperCase().trim();

    if (m.contains('DEBITO')) return debitCard;
    if (m.contains('QR')) return qrCode;
    if (m.contains('CREDITO')) return creditCard;
    if (m.contains('CLINICA')) return payAtClinic;
    if (m.contains('TRANSFER')) return bankTransfer;
    if (m.contains('CONVENIO') && m.contains('ONLINE')) return convenioOnline;
    if (m.contains('CONVENIO')) return convenioPresencial;
    if (m.contains('EFECTIVO')) return cash;
    if (m.contains('BILLETERA')) return hospitalWallet;

    return creditCard;
  }

  static bool isAutoPaid(int? value) => normalize(value) >= 8000;

  static bool isManualValidation(int? value) => normalize(value) < 5000;

  static bool isOnlineValidation(int? value) {
    final v = normalize(value);
    return v >= 5000 && v < 8000;
  }

  static bool isOnlinePayment(int selectedPaymentTypeId) {
    final v = normalize(selectedPaymentTypeId);
    return v >= 5000 && v < 8000;
  }

  static bool isPayInClinic(int selectedPaymentTypeId) {
    final v = normalize(selectedPaymentTypeId);
    return v < 5000;
  }
}