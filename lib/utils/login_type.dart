enum LoginType { dummyJson, firebase }

extension LoginTypeLabel on LoginType {
  String get label => this == LoginType.firebase ? 'Firebase' : 'DummyJSON';
}
