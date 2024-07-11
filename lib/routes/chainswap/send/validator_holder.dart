import 'package:synchronized/synchronized.dart';

class ValidatorHolder {
  final lock = Lock();
  var valid = false;

  @override
  String toString() {
    return 'ValidatorHolder{valid: $valid, inLock: ${lock.inLock}, locked ${lock.locked}, hash: $hashCode}';
  }
}
