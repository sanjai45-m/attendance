import 'package:native_toolchain_c/src/native_toolchain/android_ndk.dart';
import 'package:logging/logging.dart';

void main() async {
  final logger = Logger('test');
  logger.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  print('Resolving NDKs...');
  try {
    final results = await androidNdkClang.defaultResolver!.resolve(
      logger: logger,
    );
    for (var r in results) {
      print('Found: ${r.tool.name} at ${r.uri}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
