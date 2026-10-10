
extension StringPrice on String {

  String mdToPrice() {
    final String value = this;
    final price = value.trim();
    if (price.isEmpty || price == '0' || price == '0.00' || price == '免费') {
      return '免费';
    }
    return price.startsWith('¥') || price.startsWith('￥') ? price : '¥$price';
  }

  String mdToOldPrice() {
    final String value = this;
    final price = value.trim();
    if (price.isEmpty || price == '0' || price == '0.00') return '';
    return price.startsWith('¥') || price.startsWith('￥') ? price : '¥$price';
  }
}