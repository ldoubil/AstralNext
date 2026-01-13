library;

export 'src/rust/api/simple.dart';
export 'src/rust/frb_generated.dart' show RustLib;

class AstralRustCore {
   static Future<int> add(int a, int b) async {
    return (a + b);
  }
}