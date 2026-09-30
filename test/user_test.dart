import 'package:flutter_test/flutter_test.dart';
import 'package:roque_advmobprog/models/user.dart';
import 'package:roque_advmobprog/utils/login_type.dart';

void main() {
  test('a DummyJSON user keeps its own id for the cart and gets a prefixed chat id', () {
    final user = UserProfile.fromDummyJson({
      'id': 1,
      'username': 'emilys',
      'firstName': 'Emily',
      'lastName': 'Johnson',
      'gender': 'female',
      'image': 'https://example.com/e.png',
    });
    expect(user.loginType, LoginType.dummyJson);
    expect(user.cartUserId, 1);
    expect(user.chatId, 'dummyjson_1');
    expect(user.displayName, 'Emily Johnson');
  });

  test('a Firebase uid maps to the same DummyJSON user id every time', () {
    const uid = 'nR3sQ8vYt2ZkP0aB1cD4eF5gH6i7';
    const a = UserProfile(loginType: LoginType.firebase, id: uid);
    const b = UserProfile(loginType: LoginType.firebase, id: uid);
    expect(a.cartUserId, b.cartUserId);
    expect(a.cartUserId, inInclusiveRange(1, 208));
    expect(a.chatId, uid);
  });
}
