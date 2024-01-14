class BuildException implements Exception {
  final String msg;
  const BuildException(this.msg);
  @override
  String toString() => 'BuildException: $msg';
}
