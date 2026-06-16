import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/strings.dart';
import 'event_form_screen.dart';

/// Hazır 4 tip + "Diğer" seçimi. Seçince form ekranına yönlendirir.
/// Hazır tipte form ön-dolu gelir; "Diğer"de boş/serbest.
class EventTypePickerScreen extends StatelessWidget {
  const EventTypePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.chooseType)),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
        children: EventTypes.all.map((t) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => EventFormScreen(type: t),
                ),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        t.assetImage,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE0D5C5),
                          child: const Icon(Icons.local_cafe, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(t.label,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
