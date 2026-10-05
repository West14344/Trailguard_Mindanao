import 'mock_data.dart';

/// Mindanao peaks, falls and trail destinations.
///
/// Coordinates for major peaks are accurate. Smaller sites €” the falls,
/// ridges and local peaks €” use approximate positions derived from their
/// barangay or municipality and should be verified against a survey
/// source before any navigational use.
const kMountains = <Trail>[
  Trail(name: 'Mount Apo', region: 'Davao del Sur / Cotabato', latitude: 6.9875, longitude: 125.2731, difficulty: 'Advanced', duration: '2€“3 days'),
  Trail(name: 'Mount Agad-Agad', region: 'Iligan City, Lanao del Norte', latitude: 8.2100, longitude: 124.2600, difficulty: 'Beginner', duration: '2h'),
  Trail(name: 'Mount Bacayan', region: 'Sultan Kudarat', latitude: 6.4500, longitude: 124.4500, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Balatukan', region: 'Misamis Oriental', latitude: 8.7833, longitude: 124.9500, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Bintacan', region: 'Surigao del Norte', latitude: 9.6500, longitude: 125.5000, difficulty: 'Intermediate', duration: '6h'),
  Trail(name: 'Mount Busa', region: 'Sarangani', latitude: 6.0917, longitude: 124.7333, difficulty: 'Advanced', duration: '3 days'),
  Trail(name: 'Mount Candalaga', region: 'Davao de Oro', latitude: 7.5833, longitude: 126.1000, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Capistrano', region: 'Malaybalay, Bukidnon', latitude: 8.1500, longitude: 125.1300, difficulty: 'Intermediate', duration: '3h'),
  Trail(name: 'Mount Daguma', region: 'Sultan Kudarat', latitude: 6.4000, longitude: 124.5000, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Dinagsaan Peak', region: 'Banaybanay, Davao Oriental', latitude: 6.9700, longitude: 126.0100, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Diwata', region: 'Agusan del Norte / Sur', latitude: 8.7000, longitude: 125.9000, difficulty: 'Intermediate', duration: '1 day'),
  Trail(name: 'Mount Dinor', region: 'Santa Cruz, Davao del Sur', latitude: 6.8300, longitude: 125.4100, difficulty: 'Beginner', duration: '5h'),
  Trail(name: 'Mount Dulang-dulang', region: 'Bukidnon', latitude: 8.1936, longitude: 124.9053, difficulty: 'Advanced', duration: '2 days'),
  Trail(name: 'Mount Fortune', region: 'Santa Cruz, Davao del Sur', latitude: 6.8400, longitude: 125.4200, difficulty: 'Beginner', duration: '3h'),
  Trail(name: 'Gorilla Peak', region: 'Banaybanay, Davao Oriental', latitude: 6.9600, longitude: 126.0200, difficulty: 'Intermediate', duration: '4h'),
  Trail(name: 'Mount Hamiguitan', region: 'Davao Oriental', latitude: 6.7167, longitude: 126.1833, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Hibok-Hibok', region: 'Camiguin', latitude: 9.2033, longitude: 124.6733, difficulty: 'Intermediate', duration: '6h'),
  Trail(name: 'Mount Hilong-Hilong', region: 'Agusan del Norte / Sur', latitude: 9.1833, longitude: 125.7000, difficulty: 'Advanced', duration: '3 days'),
  Trail(name: 'Mount Inayawan', region: 'Lanao del Norte', latitude: 8.0500, longitude: 124.1500, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Kalatungan', region: 'Bukidnon', latitude: 7.9556, longitude: 124.8000, difficulty: 'Advanced', duration: '2 days'),
  Trail(name: 'Mount Kampalili', region: 'Davao de Oro', latitude: 7.4167, longitude: 126.1000, difficulty: 'Advanced', duration: '3 days'),
  Trail(name: 'Mount Kibonaan', region: 'Talaingod, Davao del Norte', latitude: 7.5400, longitude: 125.5600, difficulty: 'Intermediate', duration: '1 day'),
  Trail(name: 'Mount Kitanglad', region: 'Bukidnon', latitude: 8.1500, longitude: 124.9167, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Kolon Peak', region: 'Tampakan, South Cotabato', latitude: 6.4400, longitude: 124.9600, difficulty: 'Beginner', duration: '5h'),
  Trail(name: 'Mount Latukan', region: 'Lanao del Sur', latitude: 7.8000, longitude: 124.4000, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Lake Holon', region: "T'boli, South Cotabato", latitude: 6.1114, longitude: 124.8919, difficulty: 'Beginner', duration: '1 day'),
  Trail(name: 'Mount Loay', region: 'Santa Cruz, Davao del Sur', latitude: 6.8200, longitude: 125.4300, difficulty: 'Beginner', duration: '3h'),
  Trail(name: 'Mount Lumot', region: 'Bukidnon', latitude: 8.0500, longitude: 124.9500, difficulty: 'Intermediate', duration: '1 day'),
  Trail(name: 'Maavang-avang Peak', region: 'Arakan, North Cotabato', latitude: 7.3800, longitude: 125.1000, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Maagnaw', region: 'Bukidnon', latitude: 8.1700, longitude: 124.8800, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Magdiwata', region: 'Agusan del Sur', latitude: 8.5300, longitude: 125.9700, difficulty: 'Beginner', duration: '4h'),
  Trail(name: 'Mount Makaturing', region: 'Lanao del Sur', latitude: 7.6472, longitude: 124.3194, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Malindang', region: 'Misamis Occidental', latitude: 8.2167, longitude: 123.6333, difficulty: 'Advanced', duration: '3 days'),
  Trail(name: 'Mount Mambajao', region: 'Camiguin', latitude: 9.1833, longitude: 124.7167, difficulty: 'Beginner', duration: '2 days'),
  Trail(name: 'Mount Mas-ai', region: 'Surigao del Norte', latitude: 9.7500, longitude: 125.4800, difficulty: 'Intermediate', duration: '6h'),
  Trail(name: 'Mount Matutum', region: 'Tupi, South Cotabato', latitude: 6.3625, longitude: 125.0722, difficulty: 'Intermediate', duration: '1€“2 days'),
  Trail(name: 'Mount Mayo', region: 'Davao Oriental', latitude: 7.1667, longitude: 126.3667, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Megatong', region: 'Santo Tomas, Davao del Norte', latitude: 7.5300, longitude: 125.6100, difficulty: 'Intermediate', duration: '1 day'),
  Trail(name: 'Mount Miariri', region: 'Arakan, North Cotabato', latitude: 7.3700, longitude: 125.0800, difficulty: 'Intermediate', duration: '6h'),
  Trail(name: 'Mount Palaopao', region: 'Bukidnon', latitude: 8.3500, longitude: 124.9800, difficulty: 'Beginner', duration: '3h'),
  Trail(name: 'Mount Pandadagsaan', region: 'Davao de Oro', latitude: 7.5000, longitude: 126.0500, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Parker (Melibengoy)', region: "T'boli, South Cotabato", latitude: 6.1133, longitude: 124.8933, difficulty: 'Intermediate', duration: '1 day'),
  Trail(name: 'Mount Piapayungan', region: 'Lanao del Sur', latitude: 7.6667, longitude: 124.3333, difficulty: 'Advanced', duration: '3 days'),
  Trail(name: 'Mount Puting Bato', region: 'Davao Oriental', latitude: 6.8500, longitude: 126.2000, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Ragang', region: 'Lanao del Sur / Cotabato', latitude: 7.7167, longitude: 124.5000, difficulty: 'Advanced', duration: '3 days'),
  Trail(name: 'Sumalili Peak', region: 'Arakan, North Cotabato', latitude: 7.3650, longitude: 125.0750, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Tagubud', region: 'Davao City', latitude: 7.1200, longitude: 125.4200, difficulty: 'Intermediate', duration: '5h'),
  Trail(name: 'Mount Talomo', region: 'Davao City', latitude: 7.0167, longitude: 125.3000, difficulty: 'Advanced', duration: '2 days'),
  Trail(name: 'Mount Timpoong', region: 'Camiguin', latitude: 9.1833, longitude: 124.7000, difficulty: 'Intermediate', duration: '2 days'),
  Trail(name: 'Mount Tuminungan', region: 'Bukidnon', latitude: 8.2000, longitude: 124.9300, difficulty: 'Intermediate', duration: '1 day'),
  Trail(name: 'Bat Sanctuary', region: 'Kulaman Valley, Arakan, North Cotabato', latitude: 7.3900, longitude: 125.0900, difficulty: 'Beginner', duration: '2h'),

  // Local day trips and falls. Coordinates are approximate.
  Trail(name: 'Vipers Peak', region: 'Toril, Davao City', latitude: 7.0300, longitude: 125.4000, difficulty: 'Beginner', duration: '3h'),
  Trail(name: 'Al-ag Peak', region: 'Toril, Davao City', latitude: 7.0500, longitude: 125.4100, difficulty: 'Beginner', duration: '3h'),
  Trail(name: 'Tomari Falls', region: 'Santa Cruz, Davao del Sur', latitude: 6.8300, longitude: 125.4200, difficulty: 'Beginner', duration: '2h'),
  Trail(name: 'Tudaya Falls', region: 'Kapatagan, Davao del Sur', latitude: 6.8300, longitude: 125.3000, difficulty: 'Beginner', duration: '2h'),
  Trail(name: 'Tacublaya Falls', region: 'Santa Cruz, Davao del Sur', latitude: 6.8400, longitude: 125.3800, difficulty: 'Beginner', duration: '2h'),
  Trail(name: 'Matigol Falls', region: 'Marilog, Davao City', latitude: 7.3600, longitude: 125.1900, difficulty: 'Beginner', duration: '2h'),
  Trail(name: 'Kipilas Falls', region: 'Kitaotao, Bukidnon', latitude: 7.6200, longitude: 125.0300, difficulty: 'Beginner', duration: '2h'),
  Trail(name: 'Panimahawa Ridge', region: 'Impasug-ong, Bukidnon', latitude: 8.3000, longitude: 125.0500, difficulty: 'Beginner', duration: '4h'),
  Trail(name: 'Mount Kiamo', region: 'Malaybalay, Bukidnon', latitude: 8.2500, longitude: 125.1500, difficulty: 'Intermediate', duration: '1 day'),
];

/// Mountains at or below the hiker's level, hardest suitable ones first.
List<Trail> suggestedFor(int hikerRank) {
  final matches = kMountains.where((m) => m.suitsHiker(hikerRank)).toList()
    ..sort((a, b) {
      final byLevel = b.levelRank.compareTo(a.levelRank);
      return byLevel != 0 ? byLevel : a.name.compareTo(b.name);
    });
  return matches;
}

/// How many destinations sit at each level.
int countAtLevel(String difficulty) =>
    kMountains.where((m) => m.difficulty == difficulty).length;









