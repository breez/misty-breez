import 'package:synchronized/synchronized.dart';

class ValidatorHolder {
  final Lock lock = Lock();
  bool valid = false;

  @override
  String toString() {
    return 'ValidatorHolder{valid: $valid, inLock: ${lock.inLock}, locked ${lock.locked}, hash: $hashCode}';
  }
}
