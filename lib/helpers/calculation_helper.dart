class CalculationHelper{
  static String calculatePercentageOff(double? mrp,double? price) {
    if(mrp!=null&&price!=null){
      final difference=mrp-price;
      final per=(difference/mrp)*100;

      return per.toStringAsFixed(2);
    }else {
      return "--";
    }
  }
  static String calculateDifferencePrice(double? mrp,double? price) {
    if(mrp!=null&&price!=null){
      final difference=mrp-price;

      return difference.toString();
    }else {
      return "--";
    }

  }

  static String calculateTaxPrice(double? price,double? tax) {
    if(tax!=null&&price!=null){
      final taxPrice=(price*tax)/100;

      return taxPrice.toStringAsFixed(2);
    }else {
      return "--";
    }
  }
  static String calculateTotalPrice(double? price,double? tax,int? qty) {
    if(tax!=null&&price!=null&&qty!=null){
      final taxPrice=(price*tax)/100;
      final totalPrice=(taxPrice+price)*qty;

      return totalPrice.toStringAsFixed(2);
    }else {
      return "--";
    }
  }
  static double calculateTotalPriceInDouble(double? price,double? tax,int? qty) {
    if(tax!=null&&price!=null&&qty!=null){
      final taxPrice=(price*tax)/100;
      final totalPrice=(taxPrice+price)*qty;
      return double.parse(totalPrice.toStringAsFixed(2));
    }else {
      return 0;
    }
  }


}