class BuildException implements Exception {
  final String msg;
  const BuildException(this.msg);
  String toString() => 'BuildException: $msg';
}
