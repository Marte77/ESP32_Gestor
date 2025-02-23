extension UpperCaseFirstLetter on String {
  String toUpperCaseOnlyFirstLetter() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

String SHARED_PREFS_SERVER_KEY = "server";
String SHARED_PREFS_SERVER_PORT_KEY = "serverport";
