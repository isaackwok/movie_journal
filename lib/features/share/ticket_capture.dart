import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders the [RepaintBoundary] under [repaintKey] to a PNG.
///
/// Returns null when the boundary isn't laid out yet. [pixelRatio] should be
/// the device pixel ratio, read from MediaQuery *before* any async gap.
Future<Uint8List?> captureTicketAsBytes(
  GlobalKey repaintKey, {
  required double pixelRatio,
}) async {
  final boundary =
      repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;
  return byteData.buffer.asUint8List();
}

/// [captureTicketAsBytes], written to a temp file — the shape the share
/// plugins want.
Future<File?> captureTicketToFile(
  GlobalKey repaintKey,
  String filename, {
  required double pixelRatio,
}) async {
  final bytes = await captureTicketAsBytes(repaintKey, pixelRatio: pixelRatio);
  if (bytes == null) return null;
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsBytes(bytes);
  return file;
}
