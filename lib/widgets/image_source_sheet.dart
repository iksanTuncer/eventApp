import 'package:flutter/material.dart';

/// Fotoğraf kaynağı seçimi için alttan açılan sayfa.
/// Dönüş: true = kamera, false = galeri, null = vazgeçildi.
Future<bool?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera, color: Color(0xFF6F4E37)),
            title: const Text('Kamera ile çek'),
            onTap: () => Navigator.pop(ctx, true),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF6F4E37)),
            title: const Text('Galeriden seç'),
            onTap: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    ),
  );
}
