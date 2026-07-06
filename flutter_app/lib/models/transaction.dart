class Transaction {
  final String? id;
  final double amount;
  final String type; // 'debit' | 'credit'
  final String? merchant;
  final String category;
  final String? bank;
  final String? rawSms;
  final DateTime transactionDate;
  final String? smsHash;

  const Transaction({
    this.id,
    required this.amount,
    required this.type,
    this.merchant,
    this.category = 'Other',
    this.bank,
    this.rawSms,
    required this.transactionDate,
    this.smsHash,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        merchant: map['merchant'] as String?,
        category: (map['category'] as String?) ?? 'Other',
        bank: map['bank'] as String?,
        rawSms: map['raw_sms'] as String?,
        transactionDate: DateTime.parse(map['transaction_date'] as String),
        smsHash: map['sms_hash'] as String?,
      );
}
