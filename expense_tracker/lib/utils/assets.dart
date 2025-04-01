import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Assets {
  // Clean base64 string without any newlines or spaces
  static const String _googleLogoBase64 = "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABmJLR0QA/wD/AP+gvaeTAAAAB3RJTUUH5gQBAwAUFJA0vAAAAcBJREFUOMvN1D9oFEEUBvDf7l1MsqKYNKKFBLGJjRgQGwsLURRBBCsLCzsLi3SpUoiIoCAWWgQMiI0oKGpAhBBREEUUJIHoGZOcMTk9907vZtlbTZFcyjzYj4F5M9+bN/M+toJt2IadeADvcuQRHMEuXMcMvuTIyRx5DCNd8DZM4GqOPNkFz+bI/p5c5shcWwFbsAPXcuSJtgJ5BidxAWeTJGxCzmEHtsYYn/UDhhC6z19OkuR6feMAXNxsMHAUF3Gi3/VbGFXH8ajN+Xv8rCu8XCX5jUc4nJyO/TUMjDVEq5eG8LSBS7iRJAmSZBZjrI7rFx5XyfFxlXTOVEnrUxNXUxs/17n5M8AYB0cXnV/Iqh+L2frGMcbXTVw9jDHOxBjf/KE1ifEY49mm4qG64Fft8Z8c+VQj/xzL2JcktbRnSZJQffRZkiTnuxYe9yGtbQGG+xWOwSoVi2XZnTLLZsssW08xsIZLFqrVe63l5fG0KIbTohgY7KKVZdnrdrv9pLWyciQrihO96oyyaxnYkCNP5cgDW5w56gzsy5H7cuTeHHl3jnygAzvVY8s349Z6tP8DVbqZ1gn6z3+Xvz8lVgIctP7GAAAAAElFTkSuQmCC";

  static Widget googleLogo({double width = 24, double height = 24}) {
    try {
      return Image.memory(
        base64Decode(_googleLogoBase64),
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.account_circle, size: width, color: Colors.blue);
        },
      );
    } catch (e) {
      return Icon(Icons.account_circle, size: width, color: Colors.blue);
    }
  }

  static Uint8List base64Decode(String str) {
    // Remove any whitespace or line breaks that could cause decoding issues
    final cleanString = str.replaceAll(RegExp(r'\s'), '');
    return base64.decode(cleanString);
  }
} 