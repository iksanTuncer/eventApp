// Uygulama genelindeki sabitler ve hazır event tipleri.

class EventType {
  final String key; // Firestore'da saklanan değer
  final String label; // Arayüzde gösterilen Türkçe ad
  final String defaultTitle;
  final String assetImage; // assets/event_images/ altındaki hazır görsel
  final bool isCustom; // "Diğer" tipi mi

  const EventType({
    required this.key,
    required this.label,
    required this.defaultTitle,
    required this.assetImage,
    this.isCustom = false,
  });
}

class EventTypes {
  static const filterCoffee = EventType(
    key: 'filter_coffee',
    label: 'Filtre Kahve',
    defaultTitle: 'Filtre Kahve Buluşması',
    assetImage: 'assets/event_images/filter_coffee.png',
  );
  static const tea = EventType(
    key: 'tea',
    label: 'Çay',
    defaultTitle: 'Çay Buluşması',
    assetImage: 'assets/event_images/tea.png',
  );
  static const coldDrink = EventType(
    key: 'cold_drink',
    label: 'Soğuk İçecek',
    defaultTitle: 'Soğuk İçecek Buluşması',
    assetImage: 'assets/event_images/cold_drink.png',
  );
  static const turkishCoffee = EventType(
    key: 'turkish_coffee',
    label: 'Türk Kahvesi',
    defaultTitle: 'Türk Kahvesi Buluşması',
    assetImage: 'assets/event_images/turkish_coffee.png',
  );
  static const other = EventType(
    key: 'other',
    label: 'Diğer',
    defaultTitle: '',
    assetImage: 'assets/event_images/other.png',
    isCustom: true,
  );

  static const all = [filterCoffee, tea, coldDrink, turkishCoffee, other];

  static EventType byKey(String key) =>
      all.firstWhere((e) => e.key == key, orElse: () => other);
}

class RsvpStatus {
  static const pending = 'pending';
  static const yes = 'yes';
  static const no = 'no';
}

class AppConfig {
  // Fotoğraf sıkıştırma hedefleri (Firestore 1MB döküman limiti için)
  static const int imageMaxDimension = 800; // uzun kenar px
  static const int imageQuality = 70; // JPEG kalite
  static const int maxImageBytes = 250 * 1024; // ~250KB üst sınır
}
