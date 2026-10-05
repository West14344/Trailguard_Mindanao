import "package:flutter/material.dart";

enum AppLanguage { english, tagalog, bisaya }

/// Holds the chosen language and rebuilds the app when it changes.
///
/// Keys are the English strings themselves, so any text not yet
/// translated falls back to English instead of showing a blank or a
/// raw key. That makes translating the app possible screen by screen.
class Lang {
  static final notifier = ValueNotifier<AppLanguage>(AppLanguage.english);

  static AppLanguage get current => notifier.value;

  static void setLanguage(AppLanguage language) {
    notifier.value = language;
  }

  static String get label => switch (current) {
        AppLanguage.tagalog => "Tagalog",
        AppLanguage.bisaya => "Bisaya",
        AppLanguage.english => "English",
      };

  static String get code => switch (current) {
        AppLanguage.tagalog => "tl",
        AppLanguage.bisaya => "ceb",
        AppLanguage.english => "en",
      };

  static AppLanguage fromCode(String? code) => switch (code) {
        "tl" => AppLanguage.tagalog,
        "ceb" => AppLanguage.bisaya,
        _ => AppLanguage.english,
      };

  /// Translate. Returns the English key when no translation exists.
  static String t(String key) {
    if (current == AppLanguage.english) return key;
    final entry = _dictionary[key];
    if (entry == null) return key;
    return entry[current] ?? key;
  }
}

/// Shorthand so screens read as `"Continue".tr` rather than a call.
extension Translate on String {
  String get tr => Lang.t(this);
}

/// English key, then Tagalog and Bisaya.
///
/// Difficulty values ("Beginner", "Intermediate", "Advanced") are stored
/// in Firestore and compared in code, so only their display labels are
/// translated, never the stored values themselves.
const Map<String, Map<AppLanguage, String>> _dictionary = {
  // --- shared actions ------------------------------------------------------
  "Continue": {
    AppLanguage.tagalog: "Magpatuloy",
    AppLanguage.bisaya: "Padayon",
  },
  "Back": {
    AppLanguage.tagalog: "Bumalik",
    AppLanguage.bisaya: "Balik",
  },
  "Cancel": {
    AppLanguage.tagalog: "Kanselahin",
    AppLanguage.bisaya: "Kanselahon",
  },
  "Save changes": {
    AppLanguage.tagalog: "I-save ang pagbabago",
    AppLanguage.bisaya: "I-save ang kausaban",
  },
  "Try again": {
    AppLanguage.tagalog: "Subukan ulit",
    AppLanguage.bisaya: "Sulayi pag-usab",
  },
  "Done": {
    AppLanguage.tagalog: "Tapos na",
    AppLanguage.bisaya: "Human na",
  },

  // --- welcome and auth ----------------------------------------------------
  "Explore with confidence.\nHike with intelligence.": {
    AppLanguage.tagalog: "Maglakbay nang may tiwala.\nMag-hike nang matalino.",
    AppLanguage.bisaya: "Panaw nga may kasaligan.\nMo-hike nga maalamon.",
  },
  "Get started": {
    AppLanguage.tagalog: "Magsimula",
    AppLanguage.bisaya: "Sugdi",
  },
  "I already have an account": {
    AppLanguage.tagalog: "May account na ako",
    AppLanguage.bisaya: "Naa na koy account",
  },
  "Welcome back": {
    AppLanguage.tagalog: "Maligayang pagbabalik",
    AppLanguage.bisaya: "Maayong pagbalik",
  },
  "Log in": {
    AppLanguage.tagalog: "Mag-log in",
    AppLanguage.bisaya: "Mo-log in",
  },
  "Log in to pick up your saved trails and group.": {
    AppLanguage.tagalog:
        "Mag-log in para makita ang iyong mga trail at grupo.",
    AppLanguage.bisaya:
        "Mo-log in aron makita ang imong mga trail ug grupo.",
  },
  "Email": {
    AppLanguage.tagalog: "Email",
    AppLanguage.bisaya: "Email",
  },
  "Password": {
    AppLanguage.tagalog: "Password",
    AppLanguage.bisaya: "Password",
  },
  "Your password": {
    AppLanguage.tagalog: "Ang iyong password",
    AppLanguage.bisaya: "Imong password",
  },
  "Forgot password?": {
    AppLanguage.tagalog: "Nakalimutan ang password?",
    AppLanguage.bisaya: "Nakalimtan ang password?",
  },
  "New here?": {
    AppLanguage.tagalog: "Bago ka ba dito?",
    AppLanguage.bisaya: "Bag-o ka dinhi?",
  },
  "Create an account": {
    AppLanguage.tagalog: "Gumawa ng account",
    AppLanguage.bisaya: "Paghimo og account",
  },
  "Create account": {
    AppLanguage.tagalog: "Gumawa ng account",
    AppLanguage.bisaya: "Paghimo og account",
  },
  "Full name": {
    AppLanguage.tagalog: "Buong pangalan",
    AppLanguage.bisaya: "Tibuok nga ngalan",
  },
  "Emergency contact": {
    AppLanguage.tagalog: "Emergency contact",
    AppLanguage.bisaya: "Emergency contact",
  },
  "Name of contact person": {
    AppLanguage.tagalog: "Pangalan ng contact person",
    AppLanguage.bisaya: "Ngalan sa contact person",
  },
  "Number of contact person": {
    AppLanguage.tagalog: "Numero ng contact person",
    AppLanguage.bisaya: "Numero sa contact person",
  },
  "Takes about a minute. You can change any of this later.": {
    AppLanguage.tagalog:
        "Isang minuto lang. Maaari mong baguhin ito mamaya.",
    AppLanguage.bisaya:
        "Usa ka minuto ra. Mabag-o nimo kini unya.",
  },

  // --- onboarding ----------------------------------------------------------
  "What's your hiking experience?": {
    AppLanguage.tagalog: "Ano ang iyong karanasan sa hiking?",
    AppLanguage.bisaya: "Unsa imong kasinatian sa hiking?",
  },
  "Beginner": {
    AppLanguage.tagalog: "Baguhan",
    AppLanguage.bisaya: "Cloutchaser",
  },
  "Intermediate": {
    AppLanguage.tagalog: "Katamtaman",
    AppLanguage.bisaya: "Kasarangan",
  },
  "Advanced": {
    AppLanguage.tagalog: "Bihasa",
    AppLanguage.bisaya: "Kuyaw",
  },
  "New to hiking": {
    AppLanguage.tagalog: "Bago sa hiking",
    AppLanguage.bisaya: "Bag-o sa hiking",
  },
  "Hike a few times a year": {
    AppLanguage.tagalog: "Ilang beses sa isang taon",
    AppLanguage.bisaya: "Pipila ka beses sa usa ka tuig",
  },
  "Frequent, technical trails": {
    AppLanguage.tagalog: "Madalas, mahihirap na trail",
    AppLanguage.bisaya: "Kanunay, lisod nga mga trail",
  },
  "Enable permissions": {
    AppLanguage.tagalog: "I-enable ang mga permission",
    AppLanguage.bisaya: "I-enable ang mga permission",
  },
  "Location access": {
    AppLanguage.tagalog: "Access sa lokasyon",
    AppLanguage.bisaya: "Access sa lokasyon",
  },
  "Notifications": {
    AppLanguage.tagalog: "Mga notification",
    AppLanguage.bisaya: "Mga notification",
  },
  "Offline maps": {
    AppLanguage.tagalog: "Offline na mapa",
    AppLanguage.bisaya: "Offline nga mapa",
  },
  "Go to dashboard": {
    AppLanguage.tagalog: "Pumunta sa dashboard",
    AppLanguage.bisaya: "Adto sa dashboard",
  },

  // --- dashboard -----------------------------------------------------------
  "Good morning": {
    AppLanguage.tagalog: "Magandang umaga",
    AppLanguage.bisaya: "Maayong buntag",
  },
  "Good afternoon": {
    AppLanguage.tagalog: "Magandang hapon",
    AppLanguage.bisaya: "Maayong hapon",
  },
  "Good evening": {
    AppLanguage.tagalog: "Magandang gabi",
    AppLanguage.bisaya: "Maayong gabii",
  },
  "PICKED FOR YOU TODAY": {
    AppLanguage.tagalog: "PARA SA IYO NGAYON",
    AppLanguage.bisaya: "PARA NIMO KARON",
  },
  "See conditions": {
    AppLanguage.tagalog: "Tingnan ang kondisyon",
    AppLanguage.bisaya: "Tan-awa ang kahimtang",
  },
  "View all": {
    AppLanguage.tagalog: "Tingnan lahat",
    AppLanguage.bisaya: "Tan-awa tanan",
  },
  "All mountains": {
    AppLanguage.tagalog: "Lahat ng bundok",
    AppLanguage.bisaya: "Tanang bukid",
  },
  "Search by name or province": {
    AppLanguage.tagalog: "Maghanap ayon sa pangalan o probinsya",
    AppLanguage.bisaya: "Pangitaa pinaagi sa ngalan o probinsya",
  },
  "For you": {
    AppLanguage.tagalog: "Para sa iyo",
    AppLanguage.bisaya: "Para nimo",
  },
  "All": {
    AppLanguage.tagalog: "Lahat",
    AppLanguage.bisaya: "Tanan",
  },

  // --- trail detail --------------------------------------------------------
  "Safe to hike today": {
    AppLanguage.tagalog: "Ligtas mag-hike ngayon",
    AppLanguage.bisaya: "Luwas mo-hike karon",
  },
  "Hike with caution today": {
    AppLanguage.tagalog: "Mag-ingat sa pag-hike ngayon",
    AppLanguage.bisaya: "Pag-amping sa pag-hike karon",
  },
  "Not recommended today": {
    AppLanguage.tagalog: "Hindi inirerekomenda ngayon",
    AppLanguage.bisaya: "Dili girekomendar karon",
  },
  "Right now": {
    AppLanguage.tagalog: "Ngayon mismo",
    AppLanguage.bisaya: "Karon dayon",
  },
  "Next three days": {
    AppLanguage.tagalog: "Susunod na tatlong araw",
    AppLanguage.bisaya: "Sunod nga tulo ka adlaw",
  },
  "Today": {
    AppLanguage.tagalog: "Ngayon",
    AppLanguage.bisaya: "Karon",
  },
  "Tomorrow": {
    AppLanguage.tagalog: "Bukas",
    AppLanguage.bisaya: "Ugma",
  },
  "Weather": {
    AppLanguage.tagalog: "Panahon",
    AppLanguage.bisaya: "Panahon",
  },
  "Rainfall risk": {
    AppLanguage.tagalog: "Panganib ng ulan",
    AppLanguage.bisaya: "Peligro sa ulan",
  },
  "Wind": {
    AppLanguage.tagalog: "Hangin",
    AppLanguage.bisaya: "Hangin",
  },
  "Difficulty": {
    AppLanguage.tagalog: "Antas ng hirap",
    AppLanguage.bisaya: "Ang-ang sa kalisod",
  },
  "Low": {
    AppLanguage.tagalog: "Mababa",
    AppLanguage.bisaya: "Ubos",
  },
  "Moderate": {
    AppLanguage.tagalog: "Katamtaman",
    AppLanguage.bisaya: "Kasarangan",
  },
  "High": {
    AppLanguage.tagalog: "Mataas",
    AppLanguage.bisaya: "Taas",
  },
  "Start hike": {
    AppLanguage.tagalog: "Simulan ang hike",
    AppLanguage.bisaya: "Sugdi ang hike",
  },
  "Report hazard": {
    AppLanguage.tagalog: "Mag-report ng panganib",
    AppLanguage.bisaya: "Ireport ang peligro",
  },
  "Checking live conditions": {
    AppLanguage.tagalog: "Tinitingnan ang kondisyon",
    AppLanguage.bisaya: "Gisusi ang kahimtang",
  },

  // --- tracking ------------------------------------------------------------
  "MOVING TIME": {
    AppLanguage.tagalog: "ORAS NG PAGLAKAD",
    AppLanguage.bisaya: "ORAS SA PAGLAKAW",
  },
  "Distance": {
    AppLanguage.tagalog: "Distansya",
    AppLanguage.bisaya: "Gilay-on",
  },
  "Pace": {
    AppLanguage.tagalog: "Bilis",
    AppLanguage.bisaya: "Kakusog",
  },
  "Pause": {
    AppLanguage.tagalog: "I-pause",
    AppLanguage.bisaya: "I-pause",
  },
  "Resume": {
    AppLanguage.tagalog: "Ituloy",
    AppLanguage.bisaya: "Padayona",
  },
  "Stop": {
    AppLanguage.tagalog: "Itigil",
    AppLanguage.bisaya: "Hunonga",
  },
  "Moving": {
    AppLanguage.tagalog: "Naglalakad",
    AppLanguage.bisaya: "Naglakaw",
  },
  "Paused": {
    AppLanguage.tagalog: "Naka-pause",
    AppLanguage.bisaya: "Naka-pause",
  },
  "Finding GPS": {
    AppLanguage.tagalog: "Hinahanap ang GPS",
    AppLanguage.bisaya: "Gipangita ang GPS",
  },
  "Hike saved": {
    AppLanguage.tagalog: "Na-save ang hike",
    AppLanguage.bisaya: "Na-save ang hike",
  },

  // --- alerts and SOS ------------------------------------------------------
  "Alerts": {
    AppLanguage.tagalog: "Mga alerto",
    AppLanguage.bisaya: "Mga alerto",
  },
  "All clear": {
    AppLanguage.tagalog: "Walang panganib",
    AppLanguage.bisaya: "Walay peligro",
  },
  "Nothing to report right now": {
    AppLanguage.tagalog: "Walang ireport ngayon",
    AppLanguage.bisaya: "Walay ireport karon",
  },
  "Emergency SOS": {
    AppLanguage.tagalog: "Emergency SOS",
    AppLanguage.bisaya: "Emergency SOS",
  },
  "Hold to SOS": {
    AppLanguage.tagalog: "Pindutin nang matagal",
    AppLanguage.bisaya: "Pislita og dugay",
  },
  "SOS active": {
    AppLanguage.tagalog: "Aktibo ang SOS",
    AppLanguage.bisaya: "Aktibo ang SOS",
  },
  "I am safe now": {
    AppLanguage.tagalog: "Ligtas na ako",
    AppLanguage.bisaya: "Luwas na ko",
  },
  "Your position": {
    AppLanguage.tagalog: "Iyong lokasyon",
    AppLanguage.bisaya: "Imong lokasyon",
  },
  "Contact number": {
    AppLanguage.tagalog: "Numero ng contact",
    AppLanguage.bisaya: "Numero sa contact",
  },
  "Report a hazard": {
    AppLanguage.tagalog: "Mag-report ng panganib",
    AppLanguage.bisaya: "Ireport ang peligro",
  },
  "What did you see?": {
    AppLanguage.tagalog: "Ano ang nakita mo?",
    AppLanguage.bisaya: "Unsa imong nakita?",
  },
  "Fallen tree": {
    AppLanguage.tagalog: "Bagsak na puno",
    AppLanguage.bisaya: "Natumba nga kahoy",
  },
  "Flooded trail": {
    AppLanguage.tagalog: "Binahang trail",
    AppLanguage.bisaya: "Gibahaan nga trail",
  },
  "Wildfire": {
    AppLanguage.tagalog: "Sunog sa gubat",
    AppLanguage.bisaya: "Sunog sa lasang",
  },
  "Landslide": {
    AppLanguage.tagalog: "Pagguho ng lupa",
    AppLanguage.bisaya: "Pagdahili sa yuta",
  },
  "Blocked path": {
    AppLanguage.tagalog: "Baradong daan",
    AppLanguage.bisaya: "Naaligan nga agianan",
  },
  "Damaged bridge": {
    AppLanguage.tagalog: "Sirang tulay",
    AppLanguage.bisaya: "Guba nga taytayan",
  },
  "Wildlife": {
    AppLanguage.tagalog: "Mababangis na hayop",
    AppLanguage.bisaya: "Ihalas nga hayop",
  },
  "Missing trail sign": {
    AppLanguage.tagalog: "Nawawalang trail sign",
    AppLanguage.bisaya: "Nawala nga trail sign",
  },
  "Other": {
    AppLanguage.tagalog: "Iba pa",
    AppLanguage.bisaya: "Uban pa",
  },
  "Photo": {
    AppLanguage.tagalog: "Larawan",
    AppLanguage.bisaya: "Litrato",
  },
  "Add a photo": {
    AppLanguage.tagalog: "Magdagdag ng larawan",
    AppLanguage.bisaya: "Pagdugang og litrato",
  },
  "Take a photo": {
    AppLanguage.tagalog: "Kumuha ng larawan",
    AppLanguage.bisaya: "Pagkuha og litrato",
  },
  "Choose from gallery": {
    AppLanguage.tagalog: "Pumili sa gallery",
    AppLanguage.bisaya: "Pagpili sa gallery",
  },
  "Description": {
    AppLanguage.tagalog: "Paglalarawan",
    AppLanguage.bisaya: "Paghulagway",
  },
  "Submit report": {
    AppLanguage.tagalog: "Isumite ang report",
    AppLanguage.bisaya: "Ipadala ang report",
  },

  // --- group ---------------------------------------------------------------
  "Group hiking": {
    AppLanguage.tagalog: "Group hiking",
    AppLanguage.bisaya: "Group hiking",
  },
  "Keep track of each other on the trail.": {
    AppLanguage.tagalog: "Magbantayan sa isa't isa sa trail.",
    AppLanguage.bisaya: "Pagbantayay sa usag usa sa trail.",
  },
  "You are not in a group": {
    AppLanguage.tagalog: "Wala ka sa anumang grupo",
    AppLanguage.bisaya: "Wala ka sa bisan unsang grupo",
  },
  "Create a group": {
    AppLanguage.tagalog: "Gumawa ng grupo",
    AppLanguage.bisaya: "Paghimo og grupo",
  },
  "Join a group": {
    AppLanguage.tagalog: "Sumali sa grupo",
    AppLanguage.bisaya: "Apil sa grupo",
  },
  "Group name": {
    AppLanguage.tagalog: "Pangalan ng grupo",
    AppLanguage.bisaya: "Ngalan sa grupo",
  },
  "Group code": {
    AppLanguage.tagalog: "Code ng grupo",
    AppLanguage.bisaya: "Code sa grupo",
  },
  "Create group": {
    AppLanguage.tagalog: "Gumawa ng grupo",
    AppLanguage.bisaya: "Paghimo og grupo",
  },
  "Join group": {
    AppLanguage.tagalog: "Sumali",
    AppLanguage.bisaya: "Apil",
  },
  "Leave group": {
    AppLanguage.tagalog: "Umalis sa grupo",
    AppLanguage.bisaya: "Mobiya sa grupo",
  },
  "Leave this group?": {
    AppLanguage.tagalog: "Aalis ka sa grupong ito?",
    AppLanguage.bisaya: "Mobiya ka niining grupo?",
  },
  "Stay in group": {
    AppLanguage.tagalog: "Manatili sa grupo",
    AppLanguage.bisaya: "Magpabilin sa grupo",
  },
  "Group chat": {
    AppLanguage.tagalog: "Group chat",
    AppLanguage.bisaya: "Group chat",
  },
  "Message your group": {
    AppLanguage.tagalog: "Mag-message sa grupo",
    AppLanguage.bisaya: "Pagmensahe sa grupo",
  },
  "No messages yet": {
    AppLanguage.tagalog: "Wala pang mensahe",
    AppLanguage.bisaya: "Wala pay mensahe",
  },
  "You": {
    AppLanguage.tagalog: "Ikaw",
    AppLanguage.bisaya: "Ikaw",
  },
  "Together": {
    AppLanguage.tagalog: "Magkasama",
    AppLanguage.bisaya: "Nagkuyog",
  },
  "No position": {
    AppLanguage.tagalog: "Walang lokasyon",
    AppLanguage.bisaya: "Walay lokasyon",
  },

  // --- profile -------------------------------------------------------------
  "Edit profile": {
    AppLanguage.tagalog: "I-edit ang profile",
    AppLanguage.bisaya: "I-edit ang profile",
  },
  "Hikes completed": {
    AppLanguage.tagalog: "Natapos na hike",
    AppLanguage.bisaya: "Nahuman nga hike",
  },
  "Time on trail": {
    AppLanguage.tagalog: "Oras sa trail",
    AppLanguage.bisaya: "Oras sa trail",
  },
  "Badges": {
    AppLanguage.tagalog: "Mga badge",
    AppLanguage.bisaya: "Mga badge",
  },
  "View achievements": {
    AppLanguage.tagalog: "Tingnan ang achievements",
    AppLanguage.bisaya: "Tan-awa ang achievements",
  },
  "Achievements": {
    AppLanguage.tagalog: "Mga achievement",
    AppLanguage.bisaya: "Mga achievement",
  },
  "Mountains climbed": {
    AppLanguage.tagalog: "Naakyat na bundok",
    AppLanguage.bisaya: "Nasak-an nga bukid",
  },
  "No hikes yet": {
    AppLanguage.tagalog: "Wala pang hike",
    AppLanguage.bisaya: "Wala pay hike",
  },
  "Account": {
    AppLanguage.tagalog: "Account",
    AppLanguage.bisaya: "Account",
  },
  "Language": {
    AppLanguage.tagalog: "Wika",
    AppLanguage.bisaya: "Pinulongan",
  },
  "Log out": {
    AppLanguage.tagalog: "Mag-log out",
    AppLanguage.bisaya: "Mo-log out",
  },
  "Log out?": {
    AppLanguage.tagalog: "Mag-log out?",
    AppLanguage.bisaya: "Mo-log out?",
  },
  "Stay signed in": {
    AppLanguage.tagalog: "Manatiling naka-sign in",
    AppLanguage.bisaya: "Magpabilin nga naka-sign in",
  },

  // --- navigation ----------------------------------------------------------
  "Home": {
    AppLanguage.tagalog: "Home",
    AppLanguage.bisaya: "Home",
  },
  "Map": {
    AppLanguage.tagalog: "Mapa",
    AppLanguage.bisaya: "Mapa",
  },
  "Group": {
    AppLanguage.tagalog: "Grupo",
    AppLanguage.bisaya: "Grupo",
  },
  "Profile": {
    AppLanguage.tagalog: "Profile",
    AppLanguage.bisaya: "Profile",
  },
  "Trail map": {
    AppLanguage.tagalog: "Mapa ng trail",
    AppLanguage.bisaya: "Mapa sa trail",
  },
  "Hiker": {
    AppLanguage.tagalog: "Hiker",
    AppLanguage.bisaya: "Hiker",
  },
};
