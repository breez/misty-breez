import 'package:misty_breez/cubit/cubit.dart';

class InputData {
  final String data;
  final InputSource source;

  const InputData({required this.data, required this.source});

  @override
  String toString() {
    return 'InputData{data: $data, source: $source}';
  }
}
