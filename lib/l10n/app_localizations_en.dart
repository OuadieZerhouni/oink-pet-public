// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oink';

  @override
  String get loading => 'Waking up…';

  @override
  String get onbHello => 'Somebody\'s in the basket!';

  @override
  String get onbHelloBody => 'A tiny piglet needs a cozy home — and a friend.';

  @override
  String get onbHelloCta => 'Say hello';

  @override
  String get onbNameTitle => 'What\'s your piglet\'s name?';

  @override
  String get onbNameHint => 'Piglet name';

  @override
  String get onbNameCta => 'That\'s my name!';

  @override
  String onbTipsTitle(String name) {
    return 'How to care for $name';
  }

  @override
  String get onbTipFeed =>
      'Drag snacks onto your piglet when the tummy rumbles.';

  @override
  String get onbTipBath =>
      'Piglets love mud. Scrub with your finger, then rinse!';

  @override
  String get onbTipLove =>
      'Tap the snout to hear an oink. Rub the belly for giggles.';

  @override
  String get onbTipGrow =>
      'Care every day to grow up and earn acorns for outfits.';

  @override
  String get onbGo => 'Let\'s go!';

  @override
  String get needTummy => 'Tummy';

  @override
  String get needClean => 'Clean';

  @override
  String get needFun => 'Fun';

  @override
  String get needEnergy => 'Energy';

  @override
  String get actFeed => 'Feed';

  @override
  String get actBath => 'Bath';

  @override
  String get actPlay => 'Play';

  @override
  String get actSleep => 'Sleep';

  @override
  String get actWake => 'Wake';

  @override
  String get actCloset => 'Closet';

  @override
  String levelShort(int level) {
    return 'Lv $level';
  }

  @override
  String get stagePiglet => 'Piglet';

  @override
  String get stageLittle => 'Little pig';

  @override
  String get stageBig => 'Big pig';

  @override
  String get sayHungry => 'My tummy is rumbling…';

  @override
  String get sayDirty => 'I\'m all muddy!';

  @override
  String get sayBored => 'Play with me?';

  @override
  String get saySleepy => 'I\'m so sleepy…';

  @override
  String get sayNight => 'It\'s late… bedtime?';

  @override
  String get sayYum => 'Yum!';

  @override
  String get sayFull => 'I\'m full!';

  @override
  String get sayLocked => 'I\'m too little for that one!';

  @override
  String get sayOink => 'Oink!';

  @override
  String get wakeMoon => 'Tap the moon to wake up';

  @override
  String get sayOinkQ => 'Oink?';

  @override
  String get sayGiggle => 'Hehe, that tickles!';

  @override
  String get sayLove => 'I love you!';

  @override
  String get sayClean => 'Squeaky clean!';

  @override
  String get sayMorning => 'Good morning!';

  @override
  String sayHi(String name) {
    return 'Hi, it\'s me, $name!';
  }

  @override
  String get sayGrumble => 'Five more minutes…';

  @override
  String feedHint(String name) {
    return 'Drag a snack to $name';
  }

  @override
  String unlockLevel(int level) {
    return 'Lv $level';
  }

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get bathHint => 'Scrub the mud with your finger';

  @override
  String get bathRinse => 'Rinse';

  @override
  String sleepingHint(String name) {
    return 'Shh… $name is sleeping';
  }

  @override
  String tooTiredToPlay(String name) {
    return 'Too sleepy to play. Let $name nap first!';
  }

  @override
  String get giftTitle => 'Daily gift!';

  @override
  String giftBody(int day, int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      day,
      locale: localeName,
      other: 'Day $day in a row — here are $amount acorns!',
      one: 'Here are $amount acorns for today!',
    );
    return '$_temp0';
  }

  @override
  String get giftClaim => 'Yay!';

  @override
  String get giftTooltip => 'Daily gift';

  @override
  String levelUpTitle(int level) {
    return 'Level $level!';
  }

  @override
  String levelUpBody(String name) {
    return '$name is growing happier every day.';
  }

  @override
  String grewUpLittle(String name) {
    return '$name grew into a little pig!';
  }

  @override
  String grewUpBig(String name) {
    return '$name is a big pig now!';
  }

  @override
  String get gameTitle => 'Apple Catch';

  @override
  String gameHow(String name) {
    return 'Slide $name to catch apples. Stars and acorns are worth more. Watch out for bees!';
  }

  @override
  String get gameStart => 'Start';

  @override
  String get gameOver => 'Great catching!';

  @override
  String gameBest(int score) {
    return 'Best: $score';
  }

  @override
  String get gameNewBest => 'New best score!';

  @override
  String gameEarned(int acorns) {
    return '+$acorns acorns';
  }

  @override
  String get gameAgain => 'Play again';

  @override
  String get gameBack => 'Back home';

  @override
  String get closetTitle => 'Closet';

  @override
  String get tabHats => 'Hats';

  @override
  String get tabGlasses => 'Glasses';

  @override
  String get tabNeck => 'Neck';

  @override
  String get tabRooms => 'Rooms';

  @override
  String get closetWearing => 'Wearing';

  @override
  String get closetHome => 'Home';

  @override
  String get closetOwned => 'Owned';

  @override
  String get closetSeasonal => 'Seasonal';

  @override
  String closetBuyTitle(String item) {
    return 'Get the $item?';
  }

  @override
  String closetBuyBody(int price, int acorns) {
    return 'It costs $price acorns. You have $acorns.';
  }

  @override
  String get closetBuy => 'Get it';

  @override
  String get cancel => 'Cancel';

  @override
  String closetTooPoor(int missing, String name) {
    return 'You need $missing more acorns. Care for $name and play Apple Catch to earn more!';
  }

  @override
  String closetNeedLevel(int level) {
    return 'Unlocks at level $level.';
  }

  @override
  String get closetGone => 'Comes back during its season.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSound => 'Sounds';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String settingsRename(String name) {
    return 'Rename $name';
  }

  @override
  String get settingsRenameTitle => 'New name';

  @override
  String get save => 'Save';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsSupport => 'Help & support';

  @override
  String get settingsAbout => 'About Oink';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsReset => 'Start over with a new piglet';

  @override
  String get settingsResetTitle => 'Start over?';

  @override
  String settingsResetBody(String name) {
    return '$name, their level, acorns and outfits will be gone for good.';
  }

  @override
  String get settingsResetConfirm => 'Start over';

  @override
  String get settingsNoAds => 'No ads. No purchases. Just a piglet.';

  @override
  String statsTitle(String name) {
    return '$name\'s diary';
  }

  @override
  String statsAge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days together',
      one: '1 day together',
    );
    return '$_temp0';
  }

  @override
  String get statsMeals => 'Meals';

  @override
  String get statsBaths => 'Baths';

  @override
  String get statsOinks => 'Oinks';

  @override
  String get statsRubs => 'Belly rubs';

  @override
  String get statsGames => 'Games';

  @override
  String get statsBest => 'Best catch';

  @override
  String get statsFavorite => 'Favorite snack';

  @override
  String statsXp(int xp, int need, int next) {
    return '$xp / $need XP to level $next';
  }

  @override
  String get updateTitle => 'Time to update';

  @override
  String get updateBody =>
      'A newer version of Oink is available. Update to keep everything working smoothly.';

  @override
  String get updateCta => 'Update';

  @override
  String get later => 'Later';

  @override
  String get ok => 'OK';

  @override
  String get learnMore => 'Learn more';

  @override
  String get foodApple => 'Apple';

  @override
  String get foodCarrot => 'Carrot';

  @override
  String get foodCorn => 'Corn';

  @override
  String get foodLettuce => 'Lettuce';

  @override
  String get foodWatermelon => 'Watermelon';

  @override
  String get foodStrawberry => 'Strawberry';

  @override
  String get foodCupcake => 'Cupcake';

  @override
  String get foodDonut => 'Donut';

  @override
  String get foodPumpkin => 'Pumpkin';

  @override
  String get foodCookie => 'Cookie';

  @override
  String get itemBow => 'Pink bow';

  @override
  String get itemFlowers => 'Flower crown';

  @override
  String get itemParty => 'Party hat';

  @override
  String get itemBeanie => 'Cozy beanie';

  @override
  String get itemChef => 'Chef hat';

  @override
  String get itemCowboy => 'Cowboy hat';

  @override
  String get itemFrog => 'Froggy hat';

  @override
  String get itemCrown => 'Royal crown';

  @override
  String get itemWitch => 'Witch hat';

  @override
  String get itemSanta => 'Santa hat';

  @override
  String get itemRound => 'Round glasses';

  @override
  String get itemHearts => 'Heart shades';

  @override
  String get itemStars => 'Star shades';

  @override
  String get itemBandana => 'Red bandana';

  @override
  String get itemBowtie => 'Bow tie';

  @override
  String get itemScarf => 'Warm scarf';

  @override
  String get itemBell => 'Little bell';

  @override
  String get itemBarn => 'Cozy barn';

  @override
  String get itemMeadow => 'Sunny meadow';

  @override
  String get itemBedroom => 'Bedroom';

  @override
  String get itemBeach => 'Beach';

  @override
  String get itemSnow => 'Snowy hill';
}
