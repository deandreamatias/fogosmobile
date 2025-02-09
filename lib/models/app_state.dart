import 'package:fogosmobile/models/contributor.dart';
import 'package:fogosmobile/models/fire.dart';
import 'package:fogosmobile/models/lightning.dart';
import 'package:fogosmobile/models/statistics.dart';
import 'package:fogosmobile/models/fire_details.dart';

class AppState {
  List<Fire> fires = [];
  Fire fire;
  List<FireStatus> activeFilters;
  MeansHistory fireMeansHistory;
  DetailsHistory fireDetailsHistory;
  String fireRisk;
  List<Contributor> contributors = [];
  List<Lightning> lightnings = [];
  bool isLoading = false;
  bool hasFirstLoad = false;
  bool hasPreferences = false;
  bool hasContributors = false;
  Map preferences = {};
  NowStats nowStats;
  TodayStats todayStats;
  YesterdayStats yesterdayStats;
  LastNightStats lastNightStats;
  WeekStats weekStats;
  LastHoursStats lastHoursStats;
  List errors = [];
  List warnings = [];
  List warningsMadeira = [];
  List viirs = [];
  List modis = [];
  bool showModis = false;
  bool showViirs = false;

  AppState({
    this.fires,
    this.fire,
    this.contributors,
    this.isLoading,
    this.hasFirstLoad,
    this.hasPreferences,
    this.fireMeansHistory,
    this.fireDetailsHistory,
    this.fireRisk,
    this.hasContributors,
    this.preferences,
    this.activeFilters,
    this.nowStats,
    this.todayStats,
    this.yesterdayStats,
    this.lastNightStats,
    this.weekStats,
    this.lastHoursStats,
    this.errors,
    this.warnings,
    this.warningsMadeira,
    this.viirs,
    this.modis,
    this.showModis,
    this.showViirs,
    this.lightnings,
  });

  AppState copyWith({
    List fires,
    Fire fire,
    List contributors,
    bool isLoading,
    bool hasFirstLoad,
    bool hasPreferences,
    bool hasContributors,
    Map preferences,
    List<FireStatus> activeFilters,
    MeansHistory fireMeansHistory,
    DetailsHistory fireDetailsHistory,
    String fireRisk,
    NowStats nowStats,
    TodayStats todayStats,
    YesterdayStats yesterdayStats,
    WeekStats weekStats,
    LastHoursStats lastHoursStats,
    List errors,
    List warnings,
    List warningsMadeira,
    List viirs,
    List modis,
    bool showModis,
    bool showViirs,
    List<Lightning> lightnings,
  }) {
    return new AppState(
      fires: fires ?? this.fires,
      fire: fire ?? this.fires,
      contributors: contributors ?? this.contributors,
      isLoading: isLoading ?? this.isLoading,
      hasFirstLoad: hasFirstLoad ?? this.hasFirstLoad,
      hasPreferences: hasPreferences ?? this.hasPreferences,
      hasContributors: hasContributors ?? this.hasContributors,
      preferences: preferences ?? this.preferences,
      activeFilters: activeFilters ?? this.activeFilters,
      fireMeansHistory: fireMeansHistory ?? this.fireMeansHistory,
      fireDetailsHistory: fireDetailsHistory ?? this.fireDetailsHistory,
      fireRisk: fireRisk ?? fireRisk,
      nowStats: nowStats ?? this.nowStats,
      todayStats: todayStats ?? this.todayStats,
      yesterdayStats: yesterdayStats ?? this.yesterdayStats,
      lastNightStats: lastNightStats ?? this.lastNightStats,
      weekStats: weekStats ?? this.weekStats,
      lastHoursStats: lastHoursStats ?? this.lastHoursStats,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
      warningsMadeira: warningsMadeira ?? this.warningsMadeira,
      viirs: viirs ?? this.viirs,
      modis: modis ?? this.modis,
      showModis: showModis ?? this.showModis,
      showViirs: showViirs ?? this.showViirs,
      lightnings: lightnings ?? this.lightnings,
    );
  }

  @override
  String toString() {
    return 'AppState\n{isLoading: $isLoading, \nfires count: ${fires?.length}, \ncontributors count: ${contributors?.length}, \nwarnings count: ${warnings?.length}, \nwarnings Madeira count: ${warningsMadeira?.length}, \nselected fire: $fire, \nhasFirstLoad: $hasFirstLoad, \nhasContributors: $hasContributors, \nhasPreferences: $hasPreferences, \nprefs: $preferences}';
  }

  String getErrors() {
    return this.errors.toString();
  }
}
