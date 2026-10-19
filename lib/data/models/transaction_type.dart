enum TxType { buy, sell }

extension TxTypeX on TxType {
  String get label => this == TxType.buy ? 'Beli' : 'Jual';
  String get value => name;
}
