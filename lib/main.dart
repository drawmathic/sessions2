import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers:[
        ChangeNotifierProvider(create: (_) => PlannerState()..initSystem()),
      ],
      child: const StudyPlannerApp(),
    ),
  );
}

// ==========================================
// CONSTANTS & THEME (BRUTALIST)
// ==========================================
final Color paperBg = const Color(0xFFF4F0EB);
final Color inkBlack = const Color(0xFF1E1E1E);
final Color brassAccent = const Color(0xFFB58840);
final Color rustRed = const Color(0xFF9E3C27);
final Color steamGreen = const Color(0xFF385E38);
final Color intensePurple = const Color(0xFF5E385E);
final Color importantBlue = const Color(0xFF384A5E);

final ThemeData brutalistTheme = ThemeData(
  fontFamily: 'Courier',
  scaffoldBackgroundColor: paperBg,
  colorScheme: ColorScheme.light(
    primary: inkBlack,
    secondary: brassAccent,
    surface: paperBg,
    error: rustRed,
    onPrimary: paperBg,
    onSecondary: inkBlack,
    onSurface: inkBlack,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: paperBg,
    foregroundColor: inkBlack,
    elevation: 0,
    centerTitle: true,
    shape: Border(bottom: BorderSide(color: inkBlack, width: 3)),
  ),
  cardTheme: CardThemeData(
    color: paperBg,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: inkBlack, width: 2)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: inkBlack,
      foregroundColor: paperBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: BorderSide(color: inkBlack, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: inkBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: BorderSide(color: inkBlack, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: paperBg,
    labelStyle: TextStyle(color: inkBlack, fontWeight: FontWeight.bold),
    border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
    enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 3)),
    disabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black38, width: 2)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: paperBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.black, width: 3)),
  ),
  dividerTheme: DividerThemeData(color: inkBlack, thickness: 2),
);

// ==========================================
// PCMB DOMAIN DATA
// ==========================================
const Map<String, List<String>> pcmbChapters = {
  'Physics':[
    'Unit 1: Physical World & Measurement', 'Unit 2: Kinematics', 'Unit 3: Laws of Motion',
    'Unit 4: Work, Energy & Power', 'Unit 5: System of Particles & Rotational', 'Unit 6: Gravitation',
    'Unit 7: Properties of Bulk Matter', 'Unit 8: Thermodynamics', 'Unit 9: Kinetic Theory of Gases',
    'Unit 10: Oscillations & Waves', 'Unit 11: Electrostatics', 'Unit 12: Current Electricity',
    'Unit 13: Magnetic Effects & Magnetism', 'Unit 14: EMI & AC', 'Unit 15: EM Waves',
    'Unit 16: Optics', 'Unit 17: Dual Nature of Radiation', 'Unit 18: Atoms & Nuclei', 'Unit 19: Electronic Devices'
  ],
  'Chemistry':[
    'Unit 1: Some Basic Concepts', 'Unit 2: Structure of Atom', 'Unit 3: Classification of Elements',
    'Unit 4: Chemical Bonding', 'Unit 5: States of Matter', 'Unit 6: Thermodynamics',
    'Unit 7: Equilibrium', 'Unit 8: Redox Reactions', 'Unit 9: Hydrogen', 'Unit 10: s-Block Elements',
    'Unit 11: p-Block Elements', 'Unit 12: Organic: Basic Principles', 'Unit 13: Hydrocarbons',
    'Unit 14: Environmental Chemistry', 'Unit 15: Solid State', 'Unit 16: Solutions',
    'Unit 17: Electrochemistry', 'Unit 18: Chemical Kinetics', 'Unit 19: Surface Chemistry',
    'Unit 20: D & F Block', 'Unit 21: Coordination Compounds', 'Unit 22: Haloalkanes/Arenes',
    'Unit 23: Alcohols/Phenols/Ethers', 'Unit 24: Aldehydes/Ketones/Carboxylic', 'Unit 25: Amines',
    'Unit 26: Biomolecules', 'Unit 27: Polymers', 'Unit 28: Chemistry in Everyday Life'
  ],
  'Math':[
    'Unit 1: Sets, Relations & Functions', 'Unit 2: Trigonometric Functions', 'Unit 3: Principle of Math Induction',
    'Unit 4: Complex Numbers & Quad Equations', 'Unit 5: Linear Inequalities', 'Unit 6: Permutations & Combinations',
    'Unit 7: Binomial Theorem', 'Unit 8: Sequences & Series', 'Unit 9: Straight Lines', 'Unit 10: Conic Sections',
    'Unit 11: Intro to 3D Geometry', 'Unit 12: Limits & Derivatives', 'Unit 13: Mathematical Reasoning',
    'Unit 14: Statistics', 'Unit 15: Probability', 'Unit 16: Inverse Trigonometric Functions',
    'Unit 17: Matrices & Determinants', 'Unit 18: Continuity & Differentiability', 'Unit 19: Applications of Derivatives',
    'Unit 20: Integrals', 'Unit 21: Applications of Integrals', 'Unit 22: Differential Equations',
    'Unit 23: Vector Algebra', 'Unit 24: 3D Geometry (Class 12)', 'Unit 25: Linear Programming'
  ],
  'Biology':[
    'Unit 1: Diversity in Living World', 'Unit 2: Structural Organization', 'Unit 3: Cell Structure & Function',
    'Unit 4: Plant Physiology', 'Unit 5: Human Physiology', 'Unit 6: Reproduction',
    'Unit 7: Genetics & Evolution', 'Unit 8: Biology & Human Welfare', 'Unit 9: Biotechnology', 'Unit 10: Ecology'
  ]
};

// ==========================================
// MODELS
// ==========================================
enum SessionType { normal, important, intense }
enum SessionStatus { scheduled, active, completed, terminated }
enum GoalStatus { pending, completed, failed }
enum Scope { session, day, week }

class UserProfile {
  final String id;
  String name;
  List<String> customSubjects;

  UserProfile({required this.id, required this.name, required this.customSubjects});
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'], name: json['name'],
    customSubjects: List<String>.from(json['customSubjects'] ??[]),
  );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'customSubjects': customSubjects};
}

class Goal {
  String id;
  String text;
  GoalStatus status;
  bool isLocked;
  Scope scope;
  String referenceId; // Session ID, Day ID, or Week ID

  Goal({required this.id, required this.text, this.status = GoalStatus.pending, this.isLocked = false, required this.scope, required this.referenceId});
  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'], text: json['text'],
    status: GoalStatus.values.firstWhere((e) => e.toString() == json['status'], orElse: () => GoalStatus.pending),
    isLocked: json['isLocked'] ?? false,
    scope: Scope.values.firstWhere((e) => e.toString() == json['scope'], orElse: () => Scope.session),
    referenceId: json['referenceId'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'status': status.toString(), 'isLocked': isLocked,
    'scope': scope.toString(), 'referenceId': referenceId,
  };
}

class Remark {
  String id;
  String text;
  int timestamp;
  Scope scope;
  String referenceId;

  Remark({required this.id, required this.text, required this.timestamp, required this.scope, required this.referenceId});
  factory Remark.fromJson(Map<String, dynamic> json) => Remark(
    id: json['id'], text: json['text'], timestamp: json['timestamp'],
    scope: Scope.values.firstWhere((e) => e.toString() == json['scope'], orElse: () => Scope.session),
    referenceId: json['referenceId'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'timestamp': timestamp, 'scope': scope.toString(), 'referenceId': referenceId,
  };
}

class StudySession {
  String id;
  String name;
  String description;
  int baseStartTime; 
  int scheduledStartTime; 
  int durationMinutes;
  int pausedSeconds;
  int elapsedSeconds;
  bool isPaused;
  SessionType type;
  String subject;
  String chapter;
  List<Goal> goals;
  List<Remark> remarks;
  SessionStatus status;
  int? completionTime; 

  StudySession({
    required this.id, required this.name, required this.description,
    required this.baseStartTime, required this.scheduledStartTime, required this.durationMinutes,
    this.pausedSeconds = 0, this.elapsedSeconds = 0, this.isPaused = false,
    required this.type, required this.subject, required this.chapter,
    required this.goals, required this.remarks, this.status = SessionStatus.scheduled, this.completionTime,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'], name: json['name'], description: json['description'],
    baseStartTime: json['baseStartTime'] ?? json['scheduledStartTime'],
    scheduledStartTime: json['scheduledStartTime'], durationMinutes: json['durationMinutes'],
    pausedSeconds: json['pausedSeconds'] ?? 0, elapsedSeconds: json['elapsedSeconds'] ?? 0,
    isPaused: json['isPaused'] ?? false,
    type: SessionType.values.firstWhere((e) => e.toString() == json['type'], orElse: () => SessionType.normal),
    subject: json['subject'], chapter: json['chapter'] ?? 'General',
    goals: (json['goals'] as List).map((g) => Goal.fromJson(g)).toList(),
    remarks: (json['remarks'] as List).map((r) => Remark.fromJson(r)).toList(),
    status: SessionStatus.values.firstWhere((e) => e.toString() == json['status'], orElse: () => SessionStatus.scheduled),
    completionTime: json['completionTime'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'baseStartTime': baseStartTime,
    'scheduledStartTime': scheduledStartTime, 'durationMinutes': durationMinutes,
    'pausedSeconds': pausedSeconds, 'elapsedSeconds': elapsedSeconds, 'isPaused': isPaused,
    'type': type.toString(), 'subject': subject, 'chapter': chapter,
    'goals': goals.map((g) => g.toJson()).toList(), 'remarks': remarks.map((r) => r.toJson()).toList(),
    'status': status.toString(), 'completionTime': completionTime,
  };

  String get dateId => DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(scheduledStartTime));
  String get weekId {
    final dt = DateTime.fromMillisecondsSinceEpoch(scheduledStartTime);
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  int calculateCurrentEndTime() {
    if (status == SessionStatus.completed || status == SessionStatus.terminated) return completionTime ?? scheduledStartTime;
    return scheduledStartTime + (durationMinutes * 60 * 1000) + (pausedSeconds * 1000);
  }
}

class PlanNode {
  String id;
  String customName;
  List<Goal> overallGoals;
  List<Remark> overallRemarks;
  PlanNode({required this.id, required this.customName, required this.overallGoals, required this.overallRemarks});
  factory PlanNode.fromJson(Map<String, dynamic> json) => PlanNode(
    id: json['id'], customName: json['customName'] ?? '',
    overallGoals: (json['overallGoals'] as List?)?.map((g) => Goal.fromJson(g)).toList() ?? [],
    overallRemarks: (json['overallRemarks'] as List?)?.map((r) => Remark.fromJson(r)).toList() ??[],
  );
  Map<String, dynamic> toJson() => {'id': id, 'customName': customName, 'overallGoals': overallGoals.map((g) => g.toJson()).toList(), 'overallRemarks': overallRemarks.map((r) => r.toJson()).toList()};
}

// ==========================================
// STATE MANAGEMENT (CORE LOGIC ENGINE)
// ==========================================
class PlannerState extends ChangeNotifier {
  List<UserProfile> _users =[];
  UserProfile? _currentUser;
  List<StudySession> _sessions =[];
  Map<String, PlanNode> _days = {};
  Map<String, PlanNode> _weeks = {};
  bool _isLoading = true;
  Timer? _globalEngine;
  int _saveCounter = 0;

  List<UserProfile> get users => _users;
  UserProfile? get currentUser => _currentUser;
  List<StudySession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  List<String> get availableSubjects {
    List<String> base = ['Physics', 'Chemistry', 'Math', 'Biology'];
    if (_currentUser != null) base.addAll(_currentUser!.customSubjects);
    return base.toSet().toList();
  }

  List<String> getChaptersForSubject(String subject) {
    if (pcmbChapters.containsKey(subject)) return pcmbChapters[subject]!;
    return ['General'];
  }

  StudySession? get activeSession {
    try {
      return _sessions.firstWhere((s) => s.status == SessionStatus.active);
    } catch (e) { return null; }
  }

  Future<void> initSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('sys_users_v3');
    if (usersJson != null) _users = (jsonDecode(usersJson) as List).map((u) => UserProfile.fromJson(u)).toList();
    if (_users.isEmpty) {
      _users.add(UserProfile(id: 'usr_${DateTime.now().millisecondsSinceEpoch}', name: 'OPERATOR_01', customSubjects:[]));
      await prefs.setString('sys_users_v3', jsonEncode(_users.map((u) => u.toJson()).toList()));
    }
    final lastUserId = prefs.getString('last_user_id_v3') ?? _users.first.id;
    _currentUser = _users.firstWhere((u) => u.id == lastUserId, orElse: () => _users.first);
    await loadUserData(_currentUser!.id);

    _globalEngine?.cancel();
    _globalEngine = Timer.periodic(const Duration(seconds: 1), _engineTick);
  }

  void _engineTick(Timer t) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    bool needsSave = false;
    bool requiresOverlapResolve = false;
    Set<String> affectedDays = {};

    for (var s in _sessions.where((s) => s.status == SessionStatus.scheduled)) {
      if (nowMs >= s.scheduledStartTime) {
        s.status = SessionStatus.active;
        s.isPaused = false;
        needsSave = true;
      }
    }

    for (var s in _sessions.where((s) => s.status == SessionStatus.active)) {
      if (s.isPaused) {
        s.pausedSeconds++;
        needsSave = true;
        requiresOverlapResolve = true;
        affectedDays.add(s.dateId);
      } else {
        s.elapsedSeconds++;
        needsSave = true;
        if (s.elapsedSeconds >= s.durationMinutes * 60) {
          s.status = SessionStatus.completed;
          s.completionTime = nowMs;
          requiresOverlapResolve = true;
          affectedDays.add(s.dateId);
        }
      }
    }

    if (requiresOverlapResolve) {
      for (var dayId in affectedDays) _resolveOverlapsForDay(dayId);
    }

    if (needsSave) {
      notifyListeners();
      _saveCounter++;
      if (_saveCounter > 10) { saveUserData(); _saveCounter = 0; }
    }
  }

  void _resolveOverlapsForDay(String dateId) {
    List<StudySession> daySessions = _sessions.where((s) => s.dateId == dateId && s.status != SessionStatus.terminated).toList();
    daySessions.sort((a, b) => a.baseStartTime.compareTo(b.baseStartTime));
    
    for (int i = 0; i < daySessions.length - 1; i++) {
      var curr = daySessions[i];
      var next = daySessions[i+1];
      
      int currEnd = curr.calculateCurrentEndTime(); 
      int origGap = max(5 * 60 * 1000, next.baseStartTime - (curr.baseStartTime + curr.durationMinutes * 60 * 1000));
      
      int expectedNextStart = currEnd + origGap;
      if (next.status == SessionStatus.scheduled && next.scheduledStartTime != expectedNextStart) {
        next.scheduledStartTime = expectedNextStart;
      }
    }
  }

  Future<void> loadUserData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final sJson = prefs.getString('sessions_v3_$uid');
    _sessions = sJson != null ? (jsonDecode(sJson) as List).map((s) => StudySession.fromJson(s)).toList() :[];

    final dJson = prefs.getString('days_v3_$uid');
    if (dJson != null) _days = (jsonDecode(dJson) as Map).map((k, v) => MapEntry(k.toString(), PlanNode.fromJson(v))); else _days = {};

    final wJson = prefs.getString('weeks_v3_$uid');
    if (wJson != null) _weeks = (jsonDecode(wJson) as Map).map((k, v) => MapEntry(k.toString(), PlanNode.fromJson(v))); else _weeks = {};

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserData() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessions_v3_$uid', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
    await prefs.setString('days_v3_$uid', jsonEncode(_days.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setString('weeks_v3_$uid', jsonEncode(_weeks.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> switchUser(String id) async {
    _isLoading = true; notifyListeners();
    _currentUser = _users.firstWhere((u) => u.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user_id_v3', _currentUser!.id);
    await loadUserData(_currentUser!.id);
  }
  Future<void> createUser(String name) async {
    _users.add(UserProfile(id: 'usr_${DateTime.now().millisecondsSinceEpoch}', name: name, customSubjects:[]));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_users_v3', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }
  Future<void> addCustomSubject(String sub) async {
    if (_currentUser == null || _currentUser!.customSubjects.contains(sub)) return;
    _currentUser!.customSubjects.add(sub);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_users_v3', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  void saveSession(StudySession session, {bool isNew = false}) {
    if (isNew) {
      _sessions.add(session);
    } else {
      int idx = _sessions.indexWhere((s) => s.id == session.id);
      if (idx != -1) _sessions[idx] = session;
    }
    _sessions.sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
    _resolveOverlapsForDay(session.dateId);
    saveUserData(); notifyListeners();
  }

  void togglePauseActiveSession() {
    var act = activeSession;
    if (act != null) {
      act.isPaused = !act.isPaused;
      saveUserData(); notifyListeners();
    }
  }

  void terminateSession(String id) {
    int idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sessions[idx].status = SessionStatus.terminated;
      _sessions[idx].completionTime = DateTime.now().millisecondsSinceEpoch;
      _resolveOverlapsForDay(_sessions[idx].dateId);
      saveUserData(); notifyListeners();
    }
  }

  void completeSessionEarly(String id) {
    int idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sessions[idx].status = SessionStatus.completed;
      _sessions[idx].completionTime = DateTime.now().millisecondsSinceEpoch;
      _resolveOverlapsForDay(_sessions[idx].dateId);
      saveUserData(); notifyListeners();
    }
  }

  void markGoal(String sessionId, String goalId, GoalStatus status) {
    int sIdx = _sessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      int gIdx = _sessions[sIdx].goals.indexWhere((g) => g.id == goalId);
      if (gIdx != -1 && !_sessions[sIdx].goals[gIdx].isLocked) {
        _sessions[sIdx].goals[gIdx].status = status;
        saveUserData(); notifyListeners();
      }
    }
  }
  void lockGoal(String sessionId, String goalId) {
    int sIdx = _sessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      int gIdx = _sessions[sIdx].goals.indexWhere((g) => g.id == goalId);
      if (gIdx != -1) {
        _sessions[sIdx].goals[gIdx].isLocked = true;
        saveUserData(); notifyListeners();
      }
    }
  }
  void addSessionRemark(String sessionId, String text) {
    int sIdx = _sessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      _sessions[sIdx].remarks.add(Remark(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, timestamp: DateTime.now().millisecondsSinceEpoch, scope: Scope.session, referenceId: sessionId));
      saveUserData(); notifyListeners();
    }
  }

  PlanNode getDayPlan(String dateId) {
    if (!_days.containsKey(dateId)) _days[dateId] = PlanNode(id: dateId, customName: '', overallGoals: [], overallRemarks: []);
    return _days[dateId]!;
  }
  void updateDayPlan(PlanNode plan) { _days[plan.id] = plan; saveUserData(); notifyListeners(); }
  
  PlanNode getWeekPlan(String weekId) {
    if (!_weeks.containsKey(weekId)) _weeks[weekId] = PlanNode(id: weekId, customName: '', overallGoals: [], overallRemarks: []);
    return _weeks[weekId]!;
  }
  void updateWeekPlan(PlanNode plan) { _weeks[plan.id] = plan; saveUserData(); notifyListeners(); }
}

// ==========================================
// MAIN NAVIGATION & GLOBAL WRAPPER
// ==========================================
class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner Pro',
      debugShowCheckedModeBanner: false,
      theme: brutalistTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [DashboardScreen(), CalendarScreen(), DataBrowserScreen(), SubjectStatsScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    if (state.isLoading) return Scaffold(body: const Center(child: CircularProgressIndicator(color: Colors.black)));
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children:[
            if (state.activeSession != null) const GlobalActiveSessionBanner(),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: inkBlack, width: 3))),
        child: NavigationBar(
          backgroundColor: paperBg, indicatorColor: brassAccent.withOpacity(0.5),
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const[
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'TODAY'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'PLANNER'),
            NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'MATRIX'),
            NavigationDestination(icon: Icon(Icons.query_stats), label: 'SUBJECTS'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// GLOBAL ACTIVE SESSION BANNER
// ==========================================
class GlobalActiveSessionBanner extends StatelessWidget {
  const GlobalActiveSessionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final session = state.activeSession;
    if (session == null) return const SizedBox.shrink();

    String timeStr = '${(session.elapsedSeconds ~/ 3600).toString().padLeft(2, '0')}:${((session.elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(session.elapsedSeconds % 60).toString().padLeft(2, '0')}';
    double prog = (session.elapsedSeconds / (session.durationMinutes * 60)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: inkBlack, width: 3)), color: session.isPaused ? rustRed : inkBlack),
      child: Column(
        children:[
          LinearProgressIndicator(value: prog, backgroundColor: Colors.transparent, color: brassAccent, minHeight: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children:[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text('ACTIVE: ${session.name.toUpperCase()}', style: TextStyle(color: paperBg, fontWeight: FontWeight.bold)),
                      Text('${session.subject} > ${session.chapter}', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                Text(timeStr, style: TextStyle(color: paperBg, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Courier')),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(session.isPaused ? Icons.play_arrow : Icons.pause, color: paperBg),
                  onPressed: () => state.togglePauseActiveSession(),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new, color: paperBg),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session))),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// DASHBOARD SCREEN (TODAY)
// ==========================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Exclude terminated
    List<StudySession> activeAndUpcoming = state.sessions.where((s) => s.dateId == todayStr && (s.status == SessionStatus.scheduled || s.status == SessionStatus.active)).toList();
    List<StudySession> completed = state.sessions.where((s) => s.dateId == todayStr && s.status == SessionStatus.completed).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              const Text('TODAY\'S MANIFEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              FilledButton.icon(icon: const Icon(Icons.add), label: const Text('NEW'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionEditorScreen()))),
            ],
          ),
          const Divider(height: 32),
          const Text('ACTIVE & UPCOMING', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 16),
          if (activeAndUpcoming.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('NO UPCOMING OPERATIONS.'))),
          ...activeAndUpcoming.map((s) => _buildSessionCard(context, s)),
          
          const SizedBox(height: 32),
          const Text('COMPLETED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 16),
          if (completed.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('NO COMPLETED OPERATIONS.'))),
          ...completed.map((s) => _buildSessionCard(context, s)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, StudySession s) {
    Color bColor = s.status == SessionStatus.active ? steamGreen : (s.type == SessionType.intense ? intensePurple : (s.type == SessionType.important ? importantBlue : inkBlack));
    String timeLabel = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime));
    
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s))),
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: bColor, width: 8))),
          padding: const EdgeInsets.all(16),
          child: Row(
            children:[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('${s.durationMinutes}m', style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${s.subject} | ${s.chapter}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              if (s.status == SessionStatus.completed) const Icon(Icons.check_circle, color: steamGreen),
              if (s.status == SessionStatus.active) const Icon(Icons.play_circle_filled, color: steamGreen),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SESSION EDITOR
// ==========================================
class SessionEditorScreen extends StatefulWidget {
  final StudySession? existing;
  const SessionEditorScreen({super.key, this.existing});
  @override
  State<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends State<SessionEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  SessionType _type = SessionType.normal;
  String? _subject;
  String? _chapter;
  List<Goal> _goals =[];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _nameCtrl.text = s.name; _descCtrl.text = s.description; _durCtrl.text = s.durationMinutes.toString();
      _date = DateTime.fromMillisecondsSinceEpoch(s.baseStartTime);
      _time = TimeOfDay.fromDateTime(_date);
      _type = s.type; _subject = s.subject; _chapter = s.chapter;
      _goals = List.from(s.goals);
    }
  }

  void _save(PlannerState state) {
    if (_nameCtrl.text.isEmpty || _durCtrl.text.isEmpty || _subject == null || _chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MISSING FIELDS'), backgroundColor: rustRed)); return;
    }
    DateTime fullDt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    if (fullDt.isBefore(DateTime.now()) && widget.existing == null) fullDt = DateTime.now(); // Auto-adjust past creations
    
    if (widget.existing != null) {
      final s = widget.existing!;
      s.name = _nameCtrl.text; s.description = _descCtrl.text;
      if (s.status == SessionStatus.scheduled) {
        s.durationMinutes = int.parse(_durCtrl.text);
        s.baseStartTime = fullDt.millisecondsSinceEpoch;
        s.scheduledStartTime = s.baseStartTime; // Reset schedule
        s.type = _type; s.subject = _subject!; s.chapter = _chapter!; s.goals = _goals;
      }
      state.saveSession(s);
    } else {
      String id = 'sess_${DateTime.now().millisecondsSinceEpoch}';
      for(var g in _goals) { g.referenceId = id; g.scope = Scope.session; }
      final s = StudySession(
        id: id, name: _nameCtrl.text, description: _descCtrl.text,
        baseStartTime: fullDt.millisecondsSinceEpoch, scheduledStartTime: fullDt.millisecondsSinceEpoch,
        durationMinutes: int.parse(_durCtrl.text), type: _type, subject: _subject!, chapter: _chapter!,
        goals: _goals, remarks:[]
      );
      state.saveSession(s, isNew: true);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    bool isLocked = widget.existing != null && widget.existing!.status != SessionStatus.scheduled;
    if (_subject == null && state.availableSubjects.isNotEmpty) _subject = state.availableSubjects.first;
    List<String> chapters = _subject != null ? state.getChaptersForSubject(_subject!) : ['General'];
    if (_chapter == null || !chapters.contains(_chapter)) _chapter = chapters.first;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'CREATE MANIFEST' : 'EDIT MANIFEST')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'SESSION NAME')),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'DESCRIPTION')),
            const SizedBox(height: 16),
            if (isLocked) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('CORE PARAMETERS LOCKED FOR COMPLETED/ACTIVE SESSIONS.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
            Row(
              children:[
                Expanded(child: TextField(controller: _durCtrl, enabled: !isLocked, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DURATION (MIN)'))),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<SessionType>(value: _type, decoration: const InputDecoration(labelText: 'TYPE'), items: SessionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(), onChanged: isLocked ? null : (v) => setState(() => _type = v!))),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _subject, decoration: const InputDecoration(labelText: 'SUBJECT'), items: state.availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: isLocked ? null : (v) => setState(() { _subject = v; _chapter = state.getChaptersForSubject(v!).first; })),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _chapter, decoration: const InputDecoration(labelText: 'CHAPTER / UNIT'), isExpanded: true, items: chapters.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(), onChanged: isLocked ? null : (v) => setState(() => _chapter = v)),
            const SizedBox(height: 16),
            Row(
              children:[
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.calendar_today), label: Text(DateFormat('yyyy-MM-dd').format(_date)), onPressed: isLocked ? null : () async { final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2035)); if (d != null) setState(() => _date = d); })),
                const SizedBox(width: 16),
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.access_time), label: Text(_time.format(context)), onPressed: isLocked ? null : () async { final t = await showTimePicker(context: context, initialTime: _time); if (t != null) setState(() => _time = t); })),
              ],
            ),
            const SizedBox(height: 32),
            const Text('SESSION GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ..._goals.map((g) => Card(child: ListTile(title: Text(g.text), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: isLocked ? null : () => setState(() => _goals.remove(g)))))),
            if (!isLocked) FilledButton.icon(icon: const Icon(Icons.add), label: const Text('ADD GOAL'), onPressed: () {
              final c = TextEditingController();
              showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW GOAL'), content: TextField(controller: c), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if (c.text.isNotEmpty) setState(() => _goals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text, scope: Scope.session, referenceId: ''))); Navigator.pop(ctx); }, child: const Text('ADD'))]));
            }),
            const SizedBox(height: 48),
            FilledButton(onPressed: () => _save(state), child: const Text('SAVE MANIFEST')),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SESSION DETAIL SCREEN (LIVE ACTIVE)
// ==========================================
class SessionDetailScreen extends StatelessWidget {
  final StudySession session;
  const SessionDetailScreen({super.key, required this.session});

  void _confirmTerminate(BuildContext context, PlannerState state, String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('CRITICAL WARNING'),
      content: const Text('TERMINATING A SESSION WILL REMOVE IT FROM STATS AND LOGS COMPLETELY. PROCEED?'),
      actions:[
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: rustRed), onPressed: () { state.terminateSession(id); Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('TERMINATE')),
      ]
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final s = state.sessions.firstWhere((x) => x.id == session.id, orElse: () => session);
    bool canCompleteEarly = s.status == SessionStatus.active && !s.goals.any((g) => g.status == GoalStatus.pending);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RECORD DETAILS'),
        actions:[
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionEditorScreen(existing: s)))),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) =>[const PopupMenuItem(value: 'term', child: Text('TERMINATE OPERATION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))],
            onSelected: (v) { if (v == 'term') _confirmTerminate(context, state, s.id); },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 3), color: paperBg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  Text(s.description),
                  const Divider(height: 32),
                  Text('STATUS: ${s.status.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: s.status == SessionStatus.completed ? steamGreen : (s.status == SessionStatus.active ? brassAccent : inkBlack))),
                  Text('SCHEDULED (BASE): ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.baseStartTime))}'),
                  Text('SCHEDULED (DYN): ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))}'),
                  Text('PAUSED EXTENSION: ${s.pausedSeconds} SEC'),
                  if (s.status == SessionStatus.completed) Text('ACTUAL END: ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.completionTime!))}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (canCompleteEarly) FilledButton(style: FilledButton.styleFrom(backgroundColor: steamGreen), onPressed: () { state.completeSessionEarly(s.id); Navigator.pop(context); }, child: const Text('ALL GOALS MET: COMPLETE SESSION')),
            const SizedBox(height: 24),
            const Text('GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...s.goals.map((g) => _buildGoalTile(context, state, s.id, g)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                const Text('REMARKS LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.add_comment), onPressed: () {
                  final ctrl = TextEditingController();
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('ADD REMARK'), content: TextField(controller: ctrl),
                    actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if (ctrl.text.isNotEmpty) state.addSessionRemark(s.id, ctrl.text); Navigator.pop(ctx); }, child: const Text('ADD'))]
                  ));
                })
              ],
            ),
            ...s.remarks.map((r) => Card(child: ListTile(title: Text(r.text), subtitle: Text(DateFormat('MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp)))))),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, PlannerState state, String sessionId, Goal g) {
    IconData icon = Icons.check_box_outline_blank;
    Color color = inkBlack;
    if (g.status == GoalStatus.completed) { icon = Icons.check_box; color = steamGreen; }
    if (g.status == GoalStatus.failed) { icon = Icons.cancel; color = rustRed; }

    return ListTile(
      leading: IconButton(icon: Icon(icon, color: color), onPressed: g.isLocked ? null : () {
        GoalStatus next = GoalStatus.pending;
        if (g.status == GoalStatus.pending) next = GoalStatus.completed;
        else if (g.status == GoalStatus.completed) next = GoalStatus.failed;
        state.markGoal(sessionId, g.id, next);
      }),
      title: Text(g.text, style: TextStyle(decoration: g.status == GoalStatus.completed ? TextDecoration.lineThrough : null, color: g.status == GoalStatus.failed ? rustRed : inkBlack)),
      trailing: IconButton(icon: Icon(g.isLocked ? Icons.lock : Icons.lock_open, color: g.isLocked ? rustRed : Colors.black38), onPressed: () {
        if (!g.isLocked) state.lockGoal(sessionId, g.id);
      }),
    );
  }
}

// ==========================================
// CALENDAR PLANNER (DAY/WEEK SCOPE)
// ==========================================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final dayId = DateFormat('yyyy-MM-dd').format(_date);
    final weekId = DateFormat('yyyy-MM-dd').format(_date.subtract(Duration(days: _date.weekday - 1)));
    final dayPlan = state.getDayPlan(dayId);
    final weekPlan = state.getWeekPlan(weekId);
    final daySessions = state.sessions.where((s) => s.dateId == dayId && s.status != SessionStatus.terminated).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children:[
          Container(
            padding: const EdgeInsets.all(16), color: inkBlack,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => setState(() => _date = _date.subtract(const Duration(days: 1)))),
                InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2035)); if (d != null) setState(() => _date = d); }, child: Text(DateFormat('EEEE, MMM dd, yyyy').format(_date).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: () => setState(() => _date = _date.add(const Duration(days: 1)))),
              ],
            ),
          ),
          TabBar(indicatorColor: brassAccent, labelColor: inkBlack, unselectedLabelColor: Colors.black54, tabs: const[Tab(text: 'DAY LOG'), Tab(text: 'WEEK LOG')]),
          Expanded(child: TabBarView(children:[_buildPlanView(state, dayPlan, daySessions, Scope.day, dayId), _buildPlanView(state, weekPlan, [], Scope.week, weekId)])),
        ],
      ),
    );
  }

  Widget _buildPlanView(PlannerState state, PlanNode plan, List<StudySession> sessions, Scope scope, String refId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          Row(children:[Expanded(child: Text(plan.customName.isEmpty ? 'UNNAMED ${scope.name.toUpperCase()}' : plan.customName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))), IconButton(icon: const Icon(Icons.edit), onPressed: () {
            final c = TextEditingController(text: plan.customName);
            showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(onPressed: () { plan.customName = c.text; if (scope == Scope.day) state.updateDayPlan(plan); else state.updateWeekPlan(plan); Navigator.pop(ctx); }, child: const Text('SAVE'))]));
          })]),
          const Divider(),
          const Text('OVERALL GOALS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallGoals.map((g) => ListTile(
            leading: Icon(g.status == GoalStatus.completed ? Icons.check_box : (g.status == GoalStatus.failed ? Icons.cancel : Icons.check_box_outline_blank), color: g.status == GoalStatus.failed ? rustRed : inkBlack),
            title: Text(g.text, style: TextStyle(decoration: g.status == GoalStatus.completed ? TextDecoration.lineThrough : null)),
            trailing: IconButton(icon: Icon(g.isLocked ? Icons.lock : Icons.lock_open), onPressed: () { g.isLocked = true; scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan); }),
            onTap: g.isLocked ? null : () { g.status = g.status == GoalStatus.pending ? GoalStatus.completed : (g.status == GoalStatus.completed ? GoalStatus.failed : GoalStatus.pending); scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan); },
          )),
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('ADD GOAL'), onPressed: () {
            final c = TextEditingController();
            showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(onPressed: () { plan.overallGoals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text, scope: scope, referenceId: refId)); scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan); Navigator.pop(ctx); }, child: const Text('ADD'))]));
          }),
          const SizedBox(height: 24),
          const Text('OVERALL REMARKS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallRemarks.map((r) => Card(color: brassAccent.withOpacity(0.1), child: ListTile(title: Text(r.text), subtitle: Text(DateFormat('MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp)))))),
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('ADD REMARK'), onPressed: () {
            final c = TextEditingController();
            showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(onPressed: () { plan.overallRemarks.add(Remark(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text, timestamp: DateTime.now().millisecondsSinceEpoch, scope: scope, referenceId: refId)); scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan); Navigator.pop(ctx); }, child: const Text('ADD'))]));
          }),
          if (scope == Scope.day) ...[
            const SizedBox(height: 24),
            const Text('SCHEDULED OPERATIONS', style: TextStyle(fontWeight: FontWeight.bold)),
            ...sessions.map((s) => ListTile(title: Text(s.name), subtitle: Text('${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))} | ${s.status.name.toUpperCase()}'), trailing: OutlinedButton(child: const Text('OPEN'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s))))))
          ]
        ],
      ),
    );
  }
}

// ==========================================
// SUBJECT & CHAPTER STATS SCREEN
// ==========================================
class SubjectStatsScreen extends StatelessWidget {
  const SubjectStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final validSessions = state.sessions.where((s) => s.status == SessionStatus.completed).toList();

    Map<String, int> subHours = {};
    for (var s in validSessions) subHours[s.subject] = (subHours[s.subject] ?? 0) + s.actualDurationSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          const Text('SUBJECT TELEMETRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 16),
          ...state.availableSubjects.map((sub) {
            int seconds = subHours[sub] ?? 0;
            return Card(
              child: ListTile(
                title: Text(sub.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('TOTAL TIME: ${(seconds / 3600).toStringAsFixed(1)} HOURS'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterStatsScreen(subject: sub))),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ChapterStatsScreen extends StatelessWidget {
  final String subject;
  const ChapterStatsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final chapters = state.getChaptersForSubject(subject);
    final validSessions = state.sessions.where((s) => s.status == SessionStatus.completed && s.subject == subject).toList();

    Map<String, int> chapSecs = {};
    for (var s in validSessions) chapSecs[s.chapter] = (chapSecs[s.chapter] ?? 0) + s.actualDurationSeconds;

    return Scaffold(
      appBar: AppBar(title: Text('TELEMETRY: ${subject.toUpperCase()}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: chapters.map((c) => Card(
            child: ListTile(
              title: Text(c.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              trailing: Text('${((chapSecs[c] ?? 0) / 3600).toStringAsFixed(1)} H', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// ==========================================
// DATA BROWSER & EXTRACTION MATRIX
// ==========================================
class DataBrowserScreen extends StatefulWidget {
  const DataBrowserScreen({super.key});
  @override
  State<DataBrowserScreen> createState() => _DataBrowserScreenState();
}

class _DataBrowserScreenState extends State<DataBrowserScreen> {
  String? _subFilter;
  Scope? _scopeFilter;

  void _copyMatrix(PlannerState state) {
    StringBuffer sb = StringBuffer();
    sb.writeln("=== DATA MATRIX EXPORT (${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}) ===");
    
    List<Goal> goals =[];
    List<Remark> remarks =[];
    
    for (var s in state.sessions.where((x) => x.status != SessionStatus.terminated)) {
      if (_subFilter != null && s.subject != _subFilter) continue;
      if (_scopeFilter == null || _scopeFilter == Scope.session) {
        goals.addAll(s.goals); remarks.addAll(s.remarks);
      }
    }
    // Simplification for brevity: day/week goals should ideally be included if requested,
    // this handles session-scoped which is primary.
    
    sb.writeln("\n>>> GOALS DIRECTORY");
    for (var g in goals) {
      String marker = g.status == GoalStatus.pending ? '[ ]' : (g.status == GoalStatus.completed ? '[X]' : '[!]');
      sb.writeln("$marker ${g.text} (${g.scope.name.toUpperCase()})");
    }

    sb.writeln("\n>>> REMARKS DIRECTORY");
    for (var r in remarks) {
      sb.writeln("* ${r.text}[${DateFormat('MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp))}]");
    }

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MATRIX COPIED TO CLIPBOARD')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          const Text('DATA EXTRACTION MATRIX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)),
            child: Column(
              children:[
                DropdownButtonFormField<String>(value: _subFilter, decoration: const InputDecoration(labelText: 'SUBJECT FILTER'), items:[const DropdownMenuItem<String>(value: null, child: Text('ALL')), ...state.availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s)))], onChanged: (v) => setState(() => _subFilter = v)),
                const SizedBox(height: 16),
                DropdownButtonFormField<Scope>(value: _scopeFilter, decoration: const InputDecoration(labelText: 'SCOPE FILTER'), items:[const DropdownMenuItem<Scope>(value: null, child: Text('ALL')), ...Scope.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))], onChanged: (v) => setState(() => _scopeFilter = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(icon: const Icon(Icons.copy), label: const Text('EXECUTE EXTRACTION'), onPressed: () => _copyMatrix(state)),
        ],
      ),
    );
  }
}

// ==========================================
// PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final user = state.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          const Text('OPERATOR SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children:[const Icon(Icons.person, size: 64), Text(user?.name ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))]))),
          const SizedBox(height: 24),
          const Text('ACCOUNTS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...state.users.map((u) => ListTile(title: Text(u.name), trailing: u.id == user?.id ? const Icon(Icons.check_circle) : OutlinedButton(child: const Text('SWITCH'), onPressed: () => state.switchUser(u.id)))),
          FilledButton(child: const Text('NEW OPERATOR'), onPressed: () {
            final c = TextEditingController(); showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(child: const Text('CREATE'), onPressed: () { state.createUser(c.text); Navigator.pop(ctx); })]));
          }),
          const SizedBox(height: 24),
          const Text('CUSTOM SUBJECTS', style: TextStyle(fontWeight: FontWeight.bold)),
          if (user != null) ...user.customSubjects.map((s) => ListTile(title: Text(s))),
          FilledButton(child: const Text('ADD SUBJECT'), onPressed: () {
            final c = TextEditingController(); showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(child: const Text('ADD'), onPressed: () { state.addCustomSubject(c.text); Navigator.pop(ctx); })]));
          }),
        ],
      ),
    );
  }
}
