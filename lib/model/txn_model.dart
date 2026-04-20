class TxnModel{
  int? id;
  double? amount;
  String? type;
  String?createdAt;
  String? notes;
  TxnModel({
    this.id,
    this.amount,
    this.type,
    this.createdAt,
    this.notes

  });

  factory TxnModel.fromJson(Map<String,dynamic> json){
    return TxnModel(
      id: json['id'],
      amount: json['amount']!=null?double.parse(json['amount'].toString()):null,
      type: json['transaction_type'],
      createdAt: json['created_at'],
      notes: json['notes']

    );
  }

}