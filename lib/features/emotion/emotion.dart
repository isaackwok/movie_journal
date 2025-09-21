import 'dart:ui';

class Emotion {
  final String id;
  final String name;
  final List<Color> colors;

  const Emotion({required this.id, required this.name, required this.colors});
}

class Emotions {
  static const groups = {
    // Group Pleasant
    "Pleasant": [
      Emotion(
        id: "amazed",
        name: "Amazed",
        colors: [Color(0xFFFEFFE5), Color(0xFFFF7701)],
      ),
      Emotion(
        id: "excited",
        name: "Excited",
        colors: [Color(0xFFFFD7D3), Color(0xFFFF391B)],
      ),
      Emotion(
        id: "entertained",
        name: "Entertained",
        colors: [Color(0xFFFFDA62), Color(0xFFFF5304)],
      ),
      Emotion(
        id: "humorous",
        name: "Humorous",
        colors: [Color(0xFFE4FC11), Color(0xFF15FC11)],
      ),
      Emotion(
        id: "fulfilling",
        name: "Fulfilling",
        colors: [Color(0xFFFFFEC9), Color(0xFFFFDB3B)],
      ),
      Emotion(
        id: "joyful",
        name: "Joyful",
        colors: [Color(0xFFFADD9E), Color(0xFFFF9DC3)],
      ),
      Emotion(
        id: "hopeful",
        name: "Hopeful",
        colors: [Color(0xFF11FCEC), Color(0xFF00FF62)],
      ),
      Emotion(
        id: "inspired",
        name: "Inspired",
        colors: [Color(0xFF11FCEC), Color(0xFFB911FC)],
      ),
    ],
    // Group Unpleasant
    "Unpleasant": [
      Emotion(
        id: "melancholy",
        name: "Melancholy",
        colors: [Color(0xFF41F9FF), Color(0xFF0A3AD7)],
      ),
      Emotion(
        id: "frustrated",
        name: "Frustrated",
        colors: [Color(0xFFC0F0A7), Color(0xFF249B00)],
      ),
      Emotion(
        id: "disgust",
        name: "Disgust",
        colors: [Color(0xFFFFB42A), Color(0xFF3C8A00)],
      ),
      Emotion(
        id: "terrified",
        name: "Terrified",
        colors: [Color(0xFFFFFFFF), Color(0xFF767676)],
      ),
      Emotion(
        id: "angry",
        name: "Angry",
        colors: [Color(0xFFFFC2CB), Color(0xFFE40101)],
      ),
      Emotion(
        id: "confused",
        name: "Confused",
        colors: [Color(0xFFFFFBA9), Color(0xFFB78C00)],
      ),
      Emotion(
        id: "isolated",
        name: "Isolated",
        colors: [Color(0xFFFFFFFF), Color(0xFF1196FC)],
      ),
      Emotion(
        id: "bored",
        name: "Bored",
        colors: [Color(0xFFFEFFDA), Color(0xFFA56600)],
      ),
    ],
    // Group Others
    "Others": [
      Emotion(
        id: "calm",
        name: "Calm",
        colors: [Color(0xFFFCFEFF), Color(0xFF11D1FC)],
      ),
      Emotion(
        id: "touched",
        name: "Touched",
        colors: [Color(0xFFFFFFFF), Color(0xFFFF97B0)],
      ),
      Emotion(
        id: "bittersweet",
        name: "Bittersweet",
        colors: [Color(0xFFFEC4F6), Color(0xFF82CA93)],
      ),
      Emotion(
        id: "surprised",
        name: "Surprised",
        colors: [Color(0xFF5F11FC), Color(0xFFFF415A)],
      ),
      Emotion(
        id: "relatable",
        name: "Relatable",
        colors: [Color(0xFFFFE1A9), Color(0xFF105E06)],
      ),
      Emotion(
        id: "nervous",
        name: "Nervous",
        colors: [Color(0xFFFFBF50), Color(0xFF830709)],
      ),
      Emotion(
        id: "ironic",
        name: "Ironic",
        colors: [Color(0xFFFFFFFF), Color(0xFFB90DB6)],
      ),
      Emotion(
        id: "overwhelmed",
        name: "Overwhelmed",
        colors: [Color(0xFF86C900), Color(0xFFFE5E1F)],
      ),
    ],
  };
}
