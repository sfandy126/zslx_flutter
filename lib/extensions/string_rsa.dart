import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// 将字节数组转换为 BigInt（大端序）。
BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

/// 将 BigInt 转换为指定长度的字节数组（大端序）。
Uint8List _bigIntToBytes(BigInt value, int length) {
  final result = Uint8List(length);
  var remaining = value;
  for (var index = length - 1; index >= 0; index--) {
    result[index] = (remaining & BigInt.from(0xff)).toInt();
    remaining = remaining >> 8;
  }
  return result;
}

/// 读取 ASN.1 DER 长度字段。
(int, int)? _readASN1Length(List<int> bytes, int idx) {
  if (idx >= bytes.length) return null;
  final first = bytes[idx];
  idx += 1;
  if (first & 0x80 == 0) return (first, 1);
  final n = first & 0x7f;
  if (n == 0 || n > 4 || idx + n > bytes.length) return null;
  var length = 0;
  for (var i = 0; i < n; i++) {
    length = (length << 8) | bytes[idx + i];
  }
  return (length, 1 + n);
}

/// 剥离 SPKI 外层包装，返回内部 BIT STRING 内容（即 PKCS#1 RSAPublicKey）。
Uint8List? _stripSPKIHeader(Uint8List data) {
  final bytes = data;
  var idx = 0;
  if (bytes.isEmpty || bytes[idx] != 0x30) return data;
  idx += 1;
  if (_readASN1Length(bytes, idx) == null) return null;
  final (_, outerLenBytes) = _readASN1Length(bytes, idx)!;
  idx += outerLenBytes;
  if (idx >= bytes.length || bytes[idx] != 0x30) return data;
  idx += 1;
  final algResult = _readASN1Length(bytes, idx);
  if (algResult == null) return null;
  final (algLen, algLenBytes) = algResult;
  idx += algLenBytes + algLen;
  if (idx >= bytes.length || bytes[idx] != 0x03) return null;
  idx += 1;
  if (_readASN1Length(bytes, idx) == null) return null;
  final (_, bitLenBytes) = _readASN1Length(bytes, idx)!;
  idx += bitLenBytes;
  if (idx >= bytes.length) return null;
  idx += 1; // 跳过 unused bits 字节
  return Uint8List.sublistView(bytes, idx);
}

/// ASN.1 DER 解析器，用于从 PKCS#1 RSAPublicKey 中提取 modulus 和 exponent。
class _Asn1Parser {
  _Asn1Parser(this.bytes);

  final Uint8List bytes;
  int _offset = 0;

  Uint8List readSequence() => _readValue(0x30);

  BigInt readInteger() {
    var valueBytes = _readValue(0x02);
    // 去除前导零字节（符号位填充）
    while (valueBytes.length > 1 && valueBytes.first == 0) {
      valueBytes = Uint8List.sublistView(valueBytes, 1);
    }
    return _bytesToBigInt(valueBytes);
  }

  Uint8List _readValue(int expectedTag) {
    if (_offset >= bytes.length || bytes[_offset] != expectedTag) {
      throw FormatException('Invalid ASN.1 tag');
    }
    _offset++;
    final length = _readLength();
    if (_offset + length > bytes.length) {
      throw FormatException('Invalid ASN.1 length');
    }
    final value = Uint8List.sublistView(bytes, _offset, _offset + length);
    _offset += length;
    return value;
  }

  int _readLength() {
    if (_offset >= bytes.length) {
      throw FormatException('Invalid ASN.1 length');
    }
    final first = bytes[_offset++];
    if (first & 0x80 == 0) return first;

    final lengthBytes = first & 0x7f;
    if (lengthBytes == 0 ||
        lengthBytes > 4 ||
        _offset + lengthBytes > bytes.length) {
      throw FormatException('Invalid ASN.1 length');
    }

    var length = 0;
    for (var i = 0; i < lengthBytes; i++) {
      length = (length << 8) | bytes[_offset++];
    }
    return length;
  }
}

/// PKCS#1 v1.5 Type 2 
Uint8List _pkcs1Type2Pad(Uint8List message, int keyBytes) {
  final paddingLength = keyBytes - message.length - 3;
  final random = Random.secure();
  final block = Uint8List(keyBytes);
  block[0] = 0;
  block[1] = 2;
  for (var index = 0; index < paddingLength; index++) {
    var value = 0;
    while (value == 0) {
      value = random.nextInt(256);
    }
    block[index + 2] = value;
  }
  block[paddingLength + 2] = 0;
  block.setRange(paddingLength + 3, keyBytes, message);
  return block;
}

extension StringRsa on String {
  /// 使用 RSA PKCS#1 v1.5 对字符串进行公钥加密，返回 Base64 密文。
  String rsaPassword() {
    final pwd = this;
    if (pwd.isEmpty) return '';
    const pubKey =
        'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCTzg/8P8pNb7zTJ2yk+u6BbAqGqFsR90+SEoHJ4NZMr+jocp3rRMU+PNfd2+DkTnDePK3HPsTcOMrWQ7TolAe68abjCtF5UGkwk+wp37c92ayf9IvGgtyTFmXdoIDOKuqOy88QQr2fnsd0brjeAth+k/1tySWXSR3sH2kJB0RySwIDAQAB';

    try {
      // base64 解码 → 剥离 SPKI 头 → 得到 PKCS#1 RSAPublicKey
      final spki = base64Decode(pubKey);
      final pkcs1 = _stripSPKIHeader(Uint8List.fromList(spki));
      if (pkcs1 == null) return '';

      // 从 PKCS#1 结构中提取 modulus 和 exponent
      final parser = _Asn1Parser(pkcs1);
      final sequence = parser.readSequence();
      final keyParser = _Asn1Parser(sequence);
      final modulus = keyParser.readInteger();
      final exponent = keyParser.readInteger();

      final keyBytes = (modulus.bitLength + 7) ~/ 8;
      final message = Uint8List.fromList(utf8.encode(pwd));
      if (message.length > keyBytes - 11) return '';

      // PKCS#1 v1.5 填充 + RSA 加密（modPow）
      final block = _pkcs1Type2Pad(message, keyBytes);
      final encrypted = _bytesToBigInt(block).modPow(exponent, modulus);
      return base64Encode(_bigIntToBytes(encrypted, keyBytes));
    } catch (_) {
      return '';
    }
  }
}
