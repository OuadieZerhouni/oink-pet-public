import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Oink'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Waking up…'**
  String get loading;

  /// No description provided for @onbHello.
  ///
  /// In en, this message translates to:
  /// **'Somebody\'s in the basket!'**
  String get onbHello;

  /// No description provided for @onbHelloBody.
  ///
  /// In en, this message translates to:
  /// **'A tiny piglet needs a cozy home — and a friend.'**
  String get onbHelloBody;

  /// No description provided for @onbHelloCta.
  ///
  /// In en, this message translates to:
  /// **'Say hello'**
  String get onbHelloCta;

  /// No description provided for @onbNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your piglet\'s name?'**
  String get onbNameTitle;

  /// No description provided for @onbNameHint.
  ///
  /// In en, this message translates to:
  /// **'Piglet name'**
  String get onbNameHint;

  /// No description provided for @onbNameCta.
  ///
  /// In en, this message translates to:
  /// **'That\'s my name!'**
  String get onbNameCta;

  /// No description provided for @onbTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to care for {name}'**
  String onbTipsTitle(String name);

  /// No description provided for @onbTipFeed.
  ///
  /// In en, this message translates to:
  /// **'Drag snacks onto your piglet when the tummy rumbles.'**
  String get onbTipFeed;

  /// No description provided for @onbTipBath.
  ///
  /// In en, this message translates to:
  /// **'Piglets love mud. Scrub with your finger, then rinse!'**
  String get onbTipBath;

  /// No description provided for @onbTipLove.
  ///
  /// In en, this message translates to:
  /// **'Tap the snout to hear an oink. Rub the belly for giggles.'**
  String get onbTipLove;

  /// No description provided for @onbTipGrow.
  ///
  /// In en, this message translates to:
  /// **'Care every day to grow up and earn acorns for outfits.'**
  String get onbTipGrow;

  /// No description provided for @onbGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get onbGo;

  /// No description provided for @needTummy.
  ///
  /// In en, this message translates to:
  /// **'Tummy'**
  String get needTummy;

  /// No description provided for @needClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get needClean;

  /// No description provided for @needFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get needFun;

  /// No description provided for @needEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get needEnergy;

  /// No description provided for @actFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get actFeed;

  /// No description provided for @actBath.
  ///
  /// In en, this message translates to:
  /// **'Bath'**
  String get actBath;

  /// No description provided for @actPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actPlay;

  /// No description provided for @actSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get actSleep;

  /// No description provided for @actWake.
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get actWake;

  /// No description provided for @actCloset.
  ///
  /// In en, this message translates to:
  /// **'Closet'**
  String get actCloset;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String levelShort(int level);

  /// No description provided for @stagePiglet.
  ///
  /// In en, this message translates to:
  /// **'Piglet'**
  String get stagePiglet;

  /// No description provided for @stageLittle.
  ///
  /// In en, this message translates to:
  /// **'Little pig'**
  String get stageLittle;

  /// No description provided for @stageBig.
  ///
  /// In en, this message translates to:
  /// **'Big pig'**
  String get stageBig;

  /// No description provided for @sayHungry.
  ///
  /// In en, this message translates to:
  /// **'My tummy is rumbling…'**
  String get sayHungry;

  /// No description provided for @sayDirty.
  ///
  /// In en, this message translates to:
  /// **'I\'m all muddy!'**
  String get sayDirty;

  /// No description provided for @sayBored.
  ///
  /// In en, this message translates to:
  /// **'Play with me?'**
  String get sayBored;

  /// No description provided for @saySleepy.
  ///
  /// In en, this message translates to:
  /// **'I\'m so sleepy…'**
  String get saySleepy;

  /// No description provided for @sayNight.
  ///
  /// In en, this message translates to:
  /// **'It\'s late… bedtime?'**
  String get sayNight;

  /// No description provided for @sayYum.
  ///
  /// In en, this message translates to:
  /// **'Yum!'**
  String get sayYum;

  /// No description provided for @sayFull.
  ///
  /// In en, this message translates to:
  /// **'I\'m full!'**
  String get sayFull;

  /// No description provided for @sayLocked.
  ///
  /// In en, this message translates to:
  /// **'I\'m too little for that one!'**
  String get sayLocked;

  /// No description provided for @sayOink.
  ///
  /// In en, this message translates to:
  /// **'Oink!'**
  String get sayOink;

  /// No description provided for @sayOinkQ.
  ///
  /// In en, this message translates to:
  /// **'Oink?'**
  String get sayOinkQ;

  /// No description provided for @sayGiggle.
  ///
  /// In en, this message translates to:
  /// **'Hehe, that tickles!'**
  String get sayGiggle;

  /// No description provided for @sayLove.
  ///
  /// In en, this message translates to:
  /// **'I love you!'**
  String get sayLove;

  /// No description provided for @sayClean.
  ///
  /// In en, this message translates to:
  /// **'Squeaky clean!'**
  String get sayClean;

  /// No description provided for @sayMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get sayMorning;

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Hi, it\'s me, {name}!'**
  String sayHi(String name);

  /// No description provided for @sayGrumble.
  ///
  /// In en, this message translates to:
  /// **'Five more minutes…'**
  String get sayGrumble;

  /// No description provided for @feedHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a snack to {name}'**
  String feedHint(String name);

  /// No description provided for @unlockLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String unlockLevel(int level);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @bathHint.
  ///
  /// In en, this message translates to:
  /// **'Scrub the mud with your finger'**
  String get bathHint;

  /// No description provided for @bathRinse.
  ///
  /// In en, this message translates to:
  /// **'Rinse'**
  String get bathRinse;

  /// No description provided for @sleepingHint.
  ///
  /// In en, this message translates to:
  /// **'Shh… {name} is sleeping'**
  String sleepingHint(String name);

  /// No description provided for @tooTiredToPlay.
  ///
  /// In en, this message translates to:
  /// **'Too sleepy to play. Let {name} nap first!'**
  String tooTiredToPlay(String name);

  /// No description provided for @giftTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily gift!'**
  String get giftTitle;

  /// No description provided for @giftBody.
  ///
  /// In en, this message translates to:
  /// **'{day, plural, =1{Here are {amount} acorns for today!} other{Day {day} in a row — here are {amount} acorns!}}'**
  String giftBody(int day, int amount);

  /// No description provided for @giftClaim.
  ///
  /// In en, this message translates to:
  /// **'Yay!'**
  String get giftClaim;

  /// No description provided for @giftTooltip.
  ///
  /// In en, this message translates to:
  /// **'Daily gift'**
  String get giftTooltip;

  /// No description provided for @levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level}!'**
  String levelUpTitle(int level);

  /// No description provided for @levelUpBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is growing happier every day.'**
  String levelUpBody(String name);

  /// No description provided for @grewUpLittle.
  ///
  /// In en, this message translates to:
  /// **'{name} grew into a little pig!'**
  String grewUpLittle(String name);

  /// No description provided for @grewUpBig.
  ///
  /// In en, this message translates to:
  /// **'{name} is a big pig now!'**
  String grewUpBig(String name);

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Catch'**
  String get gameTitle;

  /// No description provided for @gameHow.
  ///
  /// In en, this message translates to:
  /// **'Slide {name} to catch apples. Stars and acorns are worth more. Watch out for bees!'**
  String gameHow(String name);

  /// No description provided for @gameStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get gameStart;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Great catching!'**
  String get gameOver;

  /// No description provided for @gameBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {score}'**
  String gameBest(int score);

  /// No description provided for @gameNewBest.
  ///
  /// In en, this message translates to:
  /// **'New best score!'**
  String get gameNewBest;

  /// No description provided for @gameEarned.
  ///
  /// In en, this message translates to:
  /// **'+{acorns} acorns'**
  String gameEarned(int acorns);

  /// No description provided for @gameAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get gameAgain;

  /// No description provided for @gameBack.
  ///
  /// In en, this message translates to:
  /// **'Back home'**
  String get gameBack;

  /// No description provided for @closetTitle.
  ///
  /// In en, this message translates to:
  /// **'Closet'**
  String get closetTitle;

  /// No description provided for @tabHats.
  ///
  /// In en, this message translates to:
  /// **'Hats'**
  String get tabHats;

  /// No description provided for @tabGlasses.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get tabGlasses;

  /// No description provided for @tabNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get tabNeck;

  /// No description provided for @tabRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get tabRooms;

  /// No description provided for @closetWearing.
  ///
  /// In en, this message translates to:
  /// **'Wearing'**
  String get closetWearing;

  /// No description provided for @closetHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get closetHome;

  /// No description provided for @closetOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get closetOwned;

  /// No description provided for @closetSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get closetSeasonal;

  /// No description provided for @closetBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the {item}?'**
  String closetBuyTitle(String item);

  /// No description provided for @closetBuyBody.
  ///
  /// In en, this message translates to:
  /// **'It costs {price} acorns. You have {acorns}.'**
  String closetBuyBody(int price, int acorns);

  /// No description provided for @closetBuy.
  ///
  /// In en, this message translates to:
  /// **'Get it'**
  String get closetBuy;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @closetTooPoor.
  ///
  /// In en, this message translates to:
  /// **'You need {missing} more acorns. Care for {name} and play Apple Catch to earn more!'**
  String closetTooPoor(int missing, String name);

  /// No description provided for @closetNeedLevel.
  ///
  /// In en, this message translates to:
  /// **'Unlocks at level {level}.'**
  String closetNeedLevel(int level);

  /// No description provided for @closetGone.
  ///
  /// In en, this message translates to:
  /// **'Comes back during its season.'**
  String get closetGone;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get settingsSound;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String settingsRename(String name);

  /// No description provided for @settingsRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get settingsRenameTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get settingsSupport;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Start over with a new piglet'**
  String get settingsReset;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Start over?'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In en, this message translates to:
  /// **'{name}, their level, acorns and outfits will be gone for good.'**
  String settingsResetBody(String name);

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get settingsResetConfirm;

  /// No description provided for @settingsNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads. No purchases. Just a piglet.'**
  String get settingsNoAds;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s diary'**
  String statsTitle(String name);

  /// No description provided for @statsAge.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day together} other{{days} days together}}'**
  String statsAge(int days);

  /// No description provided for @statsMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get statsMeals;

  /// No description provided for @statsBaths.
  ///
  /// In en, this message translates to:
  /// **'Baths'**
  String get statsBaths;

  /// No description provided for @statsOinks.
  ///
  /// In en, this message translates to:
  /// **'Oinks'**
  String get statsOinks;

  /// No description provided for @statsRubs.
  ///
  /// In en, this message translates to:
  /// **'Belly rubs'**
  String get statsRubs;

  /// No description provided for @statsGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get statsGames;

  /// No description provided for @statsBest.
  ///
  /// In en, this message translates to:
  /// **'Best catch'**
  String get statsBest;

  /// No description provided for @statsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite snack'**
  String get statsFavorite;

  /// No description provided for @statsXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} / {need} XP to level {next}'**
  String statsXp(int xp, int need, int next);

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to update'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Oink is available. Update to keep everything working smoothly.'**
  String get updateBody;

  /// No description provided for @updateCta.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateCta;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @foodApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get foodApple;

  /// No description provided for @foodCarrot.
  ///
  /// In en, this message translates to:
  /// **'Carrot'**
  String get foodCarrot;

  /// No description provided for @foodCorn.
  ///
  /// In en, this message translates to:
  /// **'Corn'**
  String get foodCorn;

  /// No description provided for @foodLettuce.
  ///
  /// In en, this message translates to:
  /// **'Lettuce'**
  String get foodLettuce;

  /// No description provided for @foodWatermelon.
  ///
  /// In en, this message translates to:
  /// **'Watermelon'**
  String get foodWatermelon;

  /// No description provided for @foodStrawberry.
  ///
  /// In en, this message translates to:
  /// **'Strawberry'**
  String get foodStrawberry;

  /// No description provided for @foodCupcake.
  ///
  /// In en, this message translates to:
  /// **'Cupcake'**
  String get foodCupcake;

  /// No description provided for @foodDonut.
  ///
  /// In en, this message translates to:
  /// **'Donut'**
  String get foodDonut;

  /// No description provided for @foodPumpkin.
  ///
  /// In en, this message translates to:
  /// **'Pumpkin'**
  String get foodPumpkin;

  /// No description provided for @foodCookie.
  ///
  /// In en, this message translates to:
  /// **'Cookie'**
  String get foodCookie;

  /// No description provided for @itemBow.
  ///
  /// In en, this message translates to:
  /// **'Pink bow'**
  String get itemBow;

  /// No description provided for @itemFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flower crown'**
  String get itemFlowers;

  /// No description provided for @itemParty.
  ///
  /// In en, this message translates to:
  /// **'Party hat'**
  String get itemParty;

  /// No description provided for @itemBeanie.
  ///
  /// In en, this message translates to:
  /// **'Cozy beanie'**
  String get itemBeanie;

  /// No description provided for @itemChef.
  ///
  /// In en, this message translates to:
  /// **'Chef hat'**
  String get itemChef;

  /// No description provided for @itemCowboy.
  ///
  /// In en, this message translates to:
  /// **'Cowboy hat'**
  String get itemCowboy;

  /// No description provided for @itemFrog.
  ///
  /// In en, this message translates to:
  /// **'Froggy hat'**
  String get itemFrog;

  /// No description provided for @itemCrown.
  ///
  /// In en, this message translates to:
  /// **'Royal crown'**
  String get itemCrown;

  /// No description provided for @itemWitch.
  ///
  /// In en, this message translates to:
  /// **'Witch hat'**
  String get itemWitch;

  /// No description provided for @itemSanta.
  ///
  /// In en, this message translates to:
  /// **'Santa hat'**
  String get itemSanta;

  /// No description provided for @itemRound.
  ///
  /// In en, this message translates to:
  /// **'Round glasses'**
  String get itemRound;

  /// No description provided for @itemHearts.
  ///
  /// In en, this message translates to:
  /// **'Heart shades'**
  String get itemHearts;

  /// No description provided for @itemStars.
  ///
  /// In en, this message translates to:
  /// **'Star shades'**
  String get itemStars;

  /// No description provided for @itemBandana.
  ///
  /// In en, this message translates to:
  /// **'Red bandana'**
  String get itemBandana;

  /// No description provided for @itemBowtie.
  ///
  /// In en, this message translates to:
  /// **'Bow tie'**
  String get itemBowtie;

  /// No description provided for @itemScarf.
  ///
  /// In en, this message translates to:
  /// **'Warm scarf'**
  String get itemScarf;

  /// No description provided for @itemBell.
  ///
  /// In en, this message translates to:
  /// **'Little bell'**
  String get itemBell;

  /// No description provided for @itemBarn.
  ///
  /// In en, this message translates to:
  /// **'Cozy barn'**
  String get itemBarn;

  /// No description provided for @itemMeadow.
  ///
  /// In en, this message translates to:
  /// **'Sunny meadow'**
  String get itemMeadow;

  /// No description provided for @itemBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get itemBedroom;

  /// No description provided for @itemBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get itemBeach;

  /// No description provided for @itemSnow.
  ///
  /// In en, this message translates to:
  /// **'Snowy hill'**
  String get itemSnow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
