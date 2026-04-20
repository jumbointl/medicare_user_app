class InvoiceModel{
  int? id;
  int? paymentId;
  String? status;


  InvoiceModel({
    this.id,
    this.paymentId,
    this.status,
  });

  factory InvoiceModel.fromJson(Map<String,dynamic> json){
    return InvoiceModel(
        paymentId: json['patient_id'],
        id: json['id'],
        status: json['status'],

    );
  }

}