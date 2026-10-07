import '../l10n/app_localizations.dart';
import '../pet/catalog.dart';

/// Localized display names for catalog ids. A switch (not reflection) so a
/// missing translation is a compile error, not a blank label.
String foodName(AppLocalizations l, String id) => switch (id) {
  'apple' => l.foodApple,
  'carrot' => l.foodCarrot,
  'corn' => l.foodCorn,
  'lettuce' => l.foodLettuce,
  'watermelon' => l.foodWatermelon,
  'strawberry' => l.foodStrawberry,
  'cupcake' => l.foodCupcake,
  'donut' => l.foodDonut,
  'pumpkin' => l.foodPumpkin,
  'cookie' => l.foodCookie,
  _ => id,
};

String itemName(AppLocalizations l, String id) => switch (id) {
  'bow' => l.itemBow,
  'flowers' => l.itemFlowers,
  'party' => l.itemParty,
  'beanie' => l.itemBeanie,
  'chef' => l.itemChef,
  'cowboy' => l.itemCowboy,
  'frog' => l.itemFrog,
  'crown' => l.itemCrown,
  'witch' => l.itemWitch,
  'santa' => l.itemSanta,
  'round' => l.itemRound,
  'hearts' => l.itemHearts,
  'stars' => l.itemStars,
  'bandana' => l.itemBandana,
  'bowtie' => l.itemBowtie,
  'scarf' => l.itemScarf,
  'bell' => l.itemBell,
  'barn' => l.itemBarn,
  'meadow' => l.itemMeadow,
  'bedroom' => l.itemBedroom,
  'beach' => l.itemBeach,
  'snow' => l.itemSnow,
  _ => id,
};

String stageName(AppLocalizations l, Stage s) => switch (s) {
  Stage.piglet => l.stagePiglet,
  Stage.little => l.stageLittle,
  Stage.big => l.stageBig,
};
