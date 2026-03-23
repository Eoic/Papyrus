import 'dart:convert';
import 'dart:typed_data';

/// Convert image bytes to a data URI string with auto-detected MIME type.
String bytesToDataUri(Uint8List bytes) {
  String mimeType = 'image/jpeg';
  if (bytes.length >= 8) {
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      mimeType = 'image/png';
    } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      mimeType = 'image/gif';
    } else if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      mimeType = 'image/webp';
    }
  }
  final base64Data = base64Encode(bytes);
  return 'data:$mimeType;base64,$base64Data';
}
