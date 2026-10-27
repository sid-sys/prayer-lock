class Verse {
  final String text;
  final String ref;
  const Verse(this.text, this.ref);
}

/// World English Bible (WEB). It is in the public domain, so no permission is
/// needed. Texts are word for word from the WEB; only the outer quotation
/// marks were removed (the screen adds its own) and the first letter of
/// 1 Peter 5:7 is a capital. Keep "(WEB)" in every reference.
const verses = <Verse>[
  Verse('Yahweh is my shepherd: I shall lack nothing.', 'Psalm 23:1 (WEB)'),
  Verse('Be still, and know that I am God. I will be exalted among the nations. I will be exalted in the earth.', 'Psalm 46:10 (WEB)'),
  Verse('I can do all things through Christ, who strengthens me.', 'Philippians 4:13 (WEB)'),
  Verse('Trust in Yahweh with all your heart, and don’t lean on your own understanding.', 'Proverbs 3:5 (WEB)'),
  Verse('Casting all your worries on him, because he cares for you.', '1 Peter 5:7 (WEB)'),
  Verse('Yahweh bless you, and keep you.', 'Numbers 6:24 (WEB)'),
  Verse('Come to me, all you who labor and are heavily burdened, and I will give you rest.', 'Matthew 11:28 (WEB)'),
  Verse('For I know the thoughts that I think toward you, says Yahweh, thoughts of peace, and not of evil, to give you hope and a future.', 'Jeremiah 29:11 (WEB)'),
  Verse('In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God.', 'Philippians 4:6 (WEB)'),
  Verse('Yahweh is near to those who have a broken heart, and saves those who have a crushed spirit.', 'Psalm 34:18 (WEB)'),
  Verse('Haven’t I commanded you? Be strong and courageous. Don’t be afraid. Don’t be dismayed, for Yahweh your God is with you wherever you go.', 'Joshua 1:9 (WEB)'),
  Verse('Your word is a lamp to my feet, and a light for my path.', 'Psalm 119:105 (WEB)'),
];

Verse verseOfDay([DateTime? d]) {
  final now = d ?? DateTime.now();
  final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays;
  return verses[day % verses.length];
}
