class Emotion {
  final String id;
  final String name;
  final String group;
  final String energyLevel; // "high" or "low"

  const Emotion({
    required this.id,
    required this.name,
    required this.group,
    required this.energyLevel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Emotion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          group == other.group &&
          energyLevel == other.energyLevel;

  @override
  int get hashCode => Object.hash(id, name, group, energyLevel);
}

enum EmotionType {

  // ------ v2 New Emotions ------
  // High Energy - Uplifting
  joyful,
  funny,
  inspired,
  mindBlown,
  hopeful,
  fulfilling,

  // High Energy - Intense
  shocked,
  angry,
  terrified,
  anxious,
  overwhelmed,
  disturbed,

  // Low Energy - Soothing
  heartwarming,
  touched,
  peaceful,
  therapeutic,
  nostalgic,
  cozy,

  // Low Energy - Quiet
  melancholic,
  confused,
  profound,
  bittersweet,
  powerless,
  lonely,
  // ------- END OF v2 New Emotions ------
}

// ------ v2 New Emotions ------
const emotionList = {
  // High Energy - Uplifting (uses FADD9E)
  EmotionType.joyful: Emotion(
    id: "joyful",
    name: "Joyful",
    group: "Uplifting",
    energyLevel: "high",
  ),
  EmotionType.funny: Emotion(
    id: "funny",
    name: "Funny",
    group: "Uplifting",
    energyLevel: "high",
  ),
  EmotionType.mindBlown: Emotion(
    id: "mindBlown",
    name: "Mind-blown",
    group: "Uplifting",
    energyLevel: "high",
  ),
  EmotionType.inspired: Emotion(
    id: "inspired",
    name: "Inspired",
    group: "Uplifting",
    energyLevel: "high",
  ),
  EmotionType.hopeful: Emotion(
    id: "hopeful",
    name: "Hopeful",
    group: "Uplifting",
    energyLevel: "high",
  ),
  EmotionType.fulfilling: Emotion(
    id: "fulfilling",
    name: "Fulfilling",
    group: "Uplifting",
    energyLevel: "high",
  ),

  // High Energy - Intense (uses FC8885)
  EmotionType.shocked: Emotion(
    id: "shocked",
    name: "Shocked",
    group: "Intense",
    energyLevel: "high",
  ),
  EmotionType.angry: Emotion(
    id: "angry",
    name: "Angry",
    group: "Intense",
    energyLevel: "high",
  ),
  EmotionType.disturbed: Emotion(
    id: "disturbed",
    name: "Disturbed",
    group: "Intense",
    energyLevel: "high",
  ),
  EmotionType.anxious: Emotion(
    id: "anxious",
    name: "Anxious",
    group: "Intense",
    energyLevel: "high",
  ),
  EmotionType.overwhelmed: Emotion(
    id: "overwhelmed",
    name: "Overwhelmed",
    group: "Intense",
    energyLevel: "high",
  ),
  EmotionType.terrified: Emotion(
    id: "terrified",
    name: "Terrified",
    group: "Intense",
    energyLevel: "high",
  ),

  // Low Energy - Soothing (uses FADD9E - same as Uplifting)
  EmotionType.heartwarming: Emotion(
    id: "heartwarming",
    name: "Heartwarming",
    group: "Soothing",
    energyLevel: "low",
  ),
  EmotionType.touched: Emotion(
    id: "touched",
    name: "Touched",
    group: "Soothing",
    energyLevel: "low",
  ),
  EmotionType.cozy: Emotion(
    id: "cozy",
    name: "Cozy",
    group: "Soothing",
    energyLevel: "low",
  ),
  EmotionType.peaceful: Emotion(
    id: "peaceful",
    name: "Peaceful",
    group: "Soothing",
    energyLevel: "low",
  ),
  EmotionType.therapeutic: Emotion(
    id: "therapeutic",
    name: "Therapeutic",
    group: "Soothing",
    energyLevel: "low",
  ),
  EmotionType.nostalgic: Emotion(
    id: "nostalgic",
    name: "Nostalgic",
    group: "Soothing",
    energyLevel: "low",
  ),

  // Low Energy - Quiet (uses FC8885 - same as Intense)
  EmotionType.melancholic: Emotion(
    id: "melancholic",
    name: "Melancholic",
    group: "Quiet",
    energyLevel: "low",
  ),
  EmotionType.bittersweet: Emotion(
    id: "bittersweet",
    name: "Bittersweet",
    group: "Quiet",
    energyLevel: "low",
  ),
  EmotionType.lonely: Emotion(
    id: "lonely",
    name: "Lonely",
    group: "Quiet",
    energyLevel: "low",
  ),
  EmotionType.profound: Emotion(
    id: "profound",
    name: "Profound",
    group: "Quiet",
    energyLevel: "low",
  ),
  EmotionType.confused: Emotion(
    id: "confused",
    name: "Confused",
    group: "Quiet",
    energyLevel: "low",
  ),
  EmotionType.powerless: Emotion(
    id: "powerless",
    name: "Powerless",
    group: "Quiet",
    energyLevel: "low",
  ),
};
// ------ END OF v2 New Emotions ------
