import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Small enough to sit inside a Firestore document, big enough to look
/// right in a 40px avatar on a high-density screen.
const int kThumbnailPx = 192;
const int kThumbnailQuality = 70;

/// Shrinks a picked photo to a small square JPEG and returns it Base64
/// encoded, so it can travel inside a Firestore document instead of
/// needing Firebase Storage, which requires a paid plan.
///
/// Returns null if the file has gone or cannot be decoded; the caller
/// then falls back to initials.
Future<String?> thumbnailBase64(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    // Decoding and resizing is slow enough to drop frames, so it runs
    // off the UI isolate.
    return await compute(_encodeThumbnail, bytes);
  } catch (_) {
    return null;
  }
}

String? _encodeThumbnail(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // Centre square crop first, so a portrait photo does not end up
  // squashed inside a circular avatar.
  final side =
      decoded.width < decoded.height ? decoded.width : decoded.height;
  final square = img.copyCrop(
    decoded,
    x: ((decoded.width - side) / 2).round(),
    y: ((decoded.height - side) / 2).round(),
    width: side,
    height: side,
  );

  final small = img.copyResize(
    square,
    width: kThumbnailPx,
    height: kThumbnailPx,
  );

  return base64Encode(img.encodeJpg(small, quality: kThumbnailQuality));
}

/// Decodes what [thumbnailBase64] produced. Returns null on anything
/// unexpected, so one corrupt value shows initials rather than breaking
/// a whole list.
Uint8List? decodeThumbnail(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}