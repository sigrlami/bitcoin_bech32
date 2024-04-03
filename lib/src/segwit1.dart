import 'dart:convert';

import 'bech32m.dart';
import 'exceptions.dart';

/// An instance of the default implementation of the Segwit1Codec
const Segwit1Codec segwit1 = Segwit1Codec();

/// A codec which converts a Segwit class to its String representation and vice versa.
class Segwit1Codec extends Codec<Segwit1, String> {
  const Segwit1Codec();

  @override
  Segwit1Decoder get decoder => Segwit1Decoder();
  @override
  Segwit1Encoder get encoder => Segwit1Encoder();

  @override
  String encode(Segwit1 data) {
    return Segwit1Encoder().convert(data);
  }

  @override
  Segwit1 decode(String data) {
    return Segwit1Decoder().convert(data);
  }
}

/// This class converts a Segwit1 class instance to a String.
class Segwit1Encoder extends Converter<Segwit1, String> with Segwit1Validations {
  @override
  String convert(Segwit1 input) {
    var program = input.program;

    if (isTooShortProgram(program)) {
      throw InvalidProgramLength('too short');
    }

    if (isTooLongProgram(program)) {
      throw InvalidProgramLength('too long');
    }

    var data = _convertBits(program, 8, 5, true);

    return bech32m.encode(Bech32m(input.hrp, data));
  }
}

/// This class converts a String to a Segwit1 class instance.
class Segwit1Decoder extends Converter<String, Segwit1> with Segwit1Validations {
  @override
  Segwit1 convert(String input) {
    var decoded = bech32m.decode(input);

    if (isEmptyProgram(decoded.data)) {
      throw InvalidProgramLength('empty');
    }

    var program = _convertBits(decoded.data, 5, 8, false);

    if (isTooShortProgram(program)) {
      throw InvalidProgramLength('too short');
    }

    if (isTooLongProgram(program)) {
      throw InvalidProgramLength('too long');
    }

    return Segwit1(decoded.hrp, program);
  }
}

/// Generic validations for a Segwit1 class.
class Segwit1Validations {
  bool isEmptyProgram(List<int> data) {
    return data.isEmpty;
  }

  bool isTooLongProgram(List<int> program) {
    return program.length > 40;
  }

  bool isTooShortProgram(List<int> program) {
    return program.length < 2;
  }
}

/// A representation of a Segwit1 Bech32 address. This class can be used to obtain the `scriptPubKey`.
class Segwit1 {
  Segwit1(this.hrp, this.program);

  final String hrp;
  final List<int> program;

  String get scriptPubKey {
    return program
        .map((c) => c.toRadixString(16).padLeft(2, '0'))
        .toList()
        .join('');
  }
}

List<int> _convertBits(List<int> data, int from, int to, bool pad) {
  var acc = 0;
  var bits = 0;
  var result = <int>[];
  var maxv = (1 << to) - 1;

  data.forEach((v) {
    if (v < 0 || (v >> from) != 0) {
      throw Exception();
    }
    acc = (acc << from) | v;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((acc >> bits) & maxv);
    }
  });

  if (pad) {
    if (bits > 0) {
      result.add((acc << (to - bits)) & maxv);
    }
  }
  return result;
}
