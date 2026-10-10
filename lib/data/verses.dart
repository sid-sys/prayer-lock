class Verse {
  final String text;
  final String ref;
  const Verse(this.text, this.ref);
}

const verses = <Verse>[
  Verse('The Lord is my shepherd; I shall not want.', 'Psalm 23:1'),
  Verse('Be still, and know that I am God.', 'Psalm 46:10'),
  Verse('I can do all things through Christ who strengthens me.', 'Philippians 4:13'),
  Verse('Trust in the Lord with all your heart, and lean not on your own understanding.', 'Proverbs 3:5'),
  Verse('Cast all your anxiety on him because he cares for you.', '1 Peter 5:7'),
  Verse('The Lord bless you and keep you.', 'Numbers 6:24'),
  Verse('Come to me, all who are weary and burdened, and I will give you rest.', 'Matthew 11:28'),
  Verse('For I know the plans I have for you, declares the Lord, plans to give you hope and a future.', 'Jeremiah 29:11'),
  Verse('Do not be anxious about anything, but in every situation, by prayer, present your requests to God.', 'Philippians 4:6'),
  Verse('The Lord is close to the brokenhearted.', 'Psalm 34:18'),
  Verse('Be strong and courageous. Do not be afraid, for the Lord your God is with you.', 'Joshua 1:9'),
  Verse('Your word is a lamp for my feet, a light on my path.', 'Psalm 119:105'),
];

Verse verseOfDay([DateTime? d]) {
  final now = d ?? DateTime.now();
  final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays;
  return verses[day % verses.length];
}
