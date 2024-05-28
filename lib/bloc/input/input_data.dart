import 'package:l_breez/bloc/input/input_source.dart';

class InputData {
  final String data;
  final InputSource source;

  const InputData({
    required this.data,
    required this.source,
  });

  @override
  String toString() {
    return 'InputData{data: $data, source: $source}';
  }
}
