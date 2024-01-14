extension UpperCaseFirstLetter on String {
  String toUpperCaseOnlyFirstLetter() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}
