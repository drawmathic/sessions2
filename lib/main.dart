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
const Color paperBg = Color(0xFFF4F0EB);
const Color inkBlack = Color(0xFF1E1E1E);
const Color brassAccent = Color(0xFFB58840);
const Color rustRed = Color(0xFF9E3C27);
const Color steamGreen = Color(0xFF385E38);
const Color intensePurple = Color(0xFF5E385E);
const Color importantBlue = Color(0xFF384A5E);

final ThemeData brutalistTheme = ThemeData(
  fontFamily: 'Courier',
  scaffoldBackgroundColor: paperBg,
  colorScheme: const ColorScheme.light(
    primary: inkBlack, secondary: brassAccent, surface: paperBg,
    error: rustRed, onPrimary: paperBg, onSecondary: inkBlack, onSurface: inkBlack,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: paperBg, foregroundColor: inkBlack, elevation: 0, centerTitle: true,
    shape: Border(bottom: BorderSide(color: inkBlack, width: 3)),
  ),
  cardTheme: const CardThemeData(
    color: paperBg, elevation: 0, margin: EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: inkBlack, width: 2)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: inkBlack, foregroundColor: paperBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: const BorderSide(color: inkBlack, width: 2), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: inkBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: const BorderSide(color: inkBlack, width: 2), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true, fillColor: paperBg, labelStyle: TextStyle(color: inkBlack, fontWeight: FontWeight.bold),
    border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 3)),
    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black38, width: 2)),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: paperBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.black, width: 3)),
  ),
  dividerTheme: const DividerThemeData(color: inkBlack, thickness: 2),
);

// ==========================================
// UTILITY: TIME FORMATTER
// ==========================================
String formatDuration(int totalSeconds) {
  if (totalSeconds == 0) return '0S';
  int d = totalSeconds ~/ 86400;
  int h = (totalSeconds % 86400) ~/ 3600;
  int m = (totalSeconds % 3600) ~/ 60;
  int s = totalSeconds % 60;
  List<String> parts =[];
  if (d > 0) parts.add('${d}D');
  if (h > 0) parts.add('${h}H');
  if (m > 0) parts.add('${m}M');
  if (s > 0) parts.add('${s}S');
  return parts.join(' ');
}

// ==========================================
// PCMB DOMAIN DATA
// ==========================================
const Map<String, List<String>> pcmbChapters = {
  'Physics':['Unit 1: Physical World & Measurement', 'Unit 2: Kinematics', 'Unit 3: Laws of Motion', 'Unit 4: Work, Energy & Power', 'Unit 5: System of Particles & Rotational', 'Unit 6: Gravitation', 'Unit 7: Properties of Bulk Matter', 'Unit 8: Thermodynamics', 'Unit 9: Kinetic Theory of Gases', 'Unit 10: Oscillations & Waves', 'Unit 11: Electrostatics', 'Unit 12: Current Electricity', 'Unit 13: Magnetic Effects & Magnetism', 'Unit 14: EMI & AC', 'Unit 15: EM Waves', 'Unit 16: Optics', 'Unit 17: Dual Nature of Radiation', 'Unit 18: Atoms & Nuclei', 'Unit 19: Electronic Devices'],
  'Chemistry':['Unit 1: Some Basic Concepts', 'Unit 2: Structure of Atom', 'Unit 3: Classification of Elements', 'Unit 4: Chemical Bonding', 'Unit 5: States of Matter', 'Unit 6: Thermodynamics', 'Unit 7: Equilibrium', 'Unit 8: Redox Reactions', 'Unit 9: Hydrogen', 'Unit 10: s-Block Elements', 'Unit 11: p-Block Elements', 'Unit 12: Organic: Basic Principles', 'Unit 13: Hydrocarbons', 'Unit 14: Environmental Chemistry', 'Unit 15: Solid State', 'Unit 16: Solutions', 'Unit 17: Electrochemistry', 'Unit 18: Chemical Kinetics', 'Unit 19: Surface Chemistry', 'Unit 20: D & F Block', 'Unit 21: Coordination Compounds', 'Unit 22: Haloalkanes/Arenes', 'Unit 23: Alcohols/Phenols/Ethers', 'Unit 24: Aldehydes/Ketones/Carboxylic', 'Unit 25: Amines', 'Unit 26: Biomolecules', 'Unit 27: Polymers', 'Unit 28: Chemistry in Everyday Life'],
  'Math':['Unit 1: Sets, Relations & Functions', 'Unit 2: Trigonometric Functions', 'Unit 3: Principle of Math Induction', 'Unit 4: Complex Numbers & Quad Equations', 'Unit 5: Linear Inequalities', 'Unit 6: Permutations & Combinations', 'Unit 7: Binomial Theorem', 'Unit 8: Sequences & Series', 'Unit 9: Straight Lines', 'Unit 10: Conic Sections', 'Unit 11: Intro to 3D Geometry', 'Unit 12: Limits & Derivatives', 'Unit 13: Mathematical Reasoning', 'Unit 14: Statistics', 'Unit 15: Probability', 'Unit 16: Inverse Trigonometric Functions', 'Unit 17: Matrices & Determinants', 'Unit 18: Continuity & Differentiability', 'Unit 19: Applications of Derivatives', 'Unit 20: Integrals', 'Unit 21: Applications of Integrals', 'Unit 22: Differential Equations', 'Unit 23: Vector Algebra', 'Unit 24: 3D Geometry (Class 12)', 'Unit 25: Linear Programming'],
  'Biology':['Unit 1: Diversity in Living World', 'Unit 2: Structural Organization', 'Unit 3: Cell Structure & Function', 'Unit 4: Plant Physiology', 'Unit 5: Human Physiology', 'Unit 6: Reproduction', 'Unit 7: Genetics & Evolution', 'Unit 8: Biology & Human Welfare', 'Unit 9: Biotechnology', 'Unit 10: Ecology']
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
  Map<String, List<String>> customChapters;

  UserProfile({required this.id, required this.name, required this.customSubjects, required this.customChapters});
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> cChaps = {};
    if (json['customChapters'] != null) {
      (json['customChapters'] as Map).forEach((k, v) => cChaps[k.toString()] = List<String>.from(v));
    }
    return UserProfile(
      id: json['id'], name: json['name'],
      customSubjects: List<String>.from(json['customSubjects'] ??[]),
      customChapters: cChaps,
    );
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'customSubjects': customSubjects, 'customChapters': customChapters};
}

class Goal {
  String id;
  String text;
  GoalStatus status;
  bool isLocked;
  bool isBonus;
  Scope scope;
  String referenceId;
  String subjectContext;
  int timestamp;

  Goal({required this.id, required this.text, this.status = GoalStatus.pending, this.isLocked = false, this.isBonus = false, required this.scope, required this.referenceId, this.subjectContext = '', required this.timestamp});
  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'], text: json['text'],
        status: GoalStatus.values.firstWhere((e) => e.toString() == json['status'], orElse: () => GoalStatus.pending),
        isLocked: json['isLocked'] ?? false, isBonus: json['isBonus'] ?? false,
        scope: Scope.values.firstWhere((e) => e.toString() == json['scope'], orElse: () => Scope.session),
        referenceId: json['referenceId'] ?? '', subjectContext: json['subjectContext'] ?? '',
        timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'text': text, 'status': status.toString(), 'isLocked': isLocked, 'isBonus': isBonus,
        'scope': scope.toString(), 'referenceId': referenceId, 'subjectContext': subjectContext, 'timestamp': timestamp,
      };
}

class Remark {
  String id;
  String text;
  int timestamp;
  Scope scope;
  String referenceId;
  String subjectContext;

  Remark({required this.id, required this.text, required this.timestamp, required this.scope, required this.referenceId, this.subjectContext = ''});
  factory Remark.fromJson(Map<String, dynamic> json) => Remark(
        id: json['id'], text: json['text'], timestamp: json['timestamp'],
        scope: Scope.values.firstWhere((e) => e.toString() == json['scope'], orElse: () => Scope.session),
        referenceId: json['referenceId'] ?? '', subjectContext: json['subjectContext'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'text': text, 'timestamp': timestamp, 'scope': scope.toString(), 'referenceId': referenceId, 'subjectContext': subjectContext,
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
  int pauseCount;
  bool isPaused;
  bool isBonusMode;
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
    this.pausedSeconds = 0, this.elapsedSeconds = 0, this.pauseCount = 0, this.isPaused = false, this.isBonusMode = false,
    required this.type, required this.subject, required this.chapter,
    required this.goals, required this.remarks, this.status = SessionStatus.scheduled, this.completionTime,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'], name: json['name'], description: json['description'],
        baseStartTime: json['baseStartTime'] ?? json['scheduledStartTime'],
        scheduledStartTime: json['scheduledStartTime'], durationMinutes: json['durationMinutes'],
        pausedSeconds: json['pausedSeconds'] ?? 0, elapsedSeconds: json['elapsedSeconds'] ?? 0,
        pauseCount: json['pauseCount'] ?? 0, isPaused: json['isPaused'] ?? false, isBonusMode: json['isBonusMode'] ?? false,
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
        'pausedSeconds': pausedSeconds, 'elapsedSeconds': elapsedSeconds, 'pauseCount': pauseCount, 'isPaused': isPaused, 'isBonusMode': isBonusMode,
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
        overallGoals: (json['overallGoals'] as List?)?.map((g) => Goal.fromJson(g)).toList() ??[],
        overallRemarks: (json['overallRemarks'] as List?)?.map((r) => Remark.fromJson(r)).toList() ??[],
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'customName': customName,
        'overallGoals': overallGoals.map((g) => g.toJson()).toList(),
        'overallRemarks': overallRemarks.map((r) => r.toJson()).toList()
      };
}

// ==========================================
// VISUAL UTILITY & WIDGETS
// ==========================================
class DoubleTapLockIcon extends StatefulWidget {
  final bool isLocked;
  final VoidCallback onLockConfirm;
  const DoubleTapLockIcon({super.key, required this.isLocked, required this.onLockConfirm});
  @override
  State<DoubleTapLockIcon> createState() => _DoubleTapLockIconState();
}
class _DoubleTapLockIconState extends State<DoubleTapLockIcon> {
  bool _primed = false;
  Timer? _timer;
  void _handleTap() {
    if (widget.isLocked) return; // Cannot unlock once locked. 
    if (_primed) {
      _timer?.cancel();
      setState(() => _primed = false);
      widget.onLockConfirm();
    } else {
      setState(() => _primed = true);
      _timer = Timer(const Duration(seconds: 2), () { if(mounted) setState(() => _primed = false); });
    }
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return const Icon(Icons.lock, color: rustRed);
    return IconButton(
      icon: Icon(_primed ? Icons.warning : Icons.lock_open, color: _primed ? brassAccent : Colors.black38),
      onPressed: _handleTap,
      tooltip: _primed ? 'TAP AGAIN TO LOCK PERMANENTLY' : 'DOUBLE TAP TO LOCK',
    );
  }
}

class VisualTileBuilder extends StatelessWidget {
  final Goal? goal;
  final Remark? remark;
  final PlannerState state;
  final VoidCallback? onGoalStatusCycle;

  const VisualTileBuilder({super.key, this.goal, this.remark, required this.state, this.onGoalStatusCycle});

  @override
  Widget build(BuildContext context) {
    bool isGoal = goal != null;
    Scope scope = isGoal ? goal!.scope : remark!.scope;
    String refId = isGoal ? goal!.referenceId : remark!.referenceId;
    String text = isGoal ? goal!.text : remark!.text;
    int timestamp = isGoal ? goal!.timestamp : remark!.timestamp;
    bool isBonus = isGoal ? goal!.isBonus : false;

    String sourceName = '';
    Color borderColor = inkBlack;
    String tagLabel = '';

    if (scope == Scope.session) {
      try {
        final s = state.sessions.firstWhere((x) => x.id == refId);
        sourceName = s.name.toUpperCase();
        if (s.type == SessionType.important) { borderColor = importantBlue; tagLabel = '[IMPORTANT SESS]'; }
        else if (s.type == SessionType.intense) { borderColor = intensePurple; tagLabel = '[INTENSE SESS]'; }
        else { borderColor = inkBlack; tagLabel = '[NORMAL SESS]'; }
      } catch (_) { sourceName = '[DELETED SESSION]'; tagLabel = '[SESSION]'; }
    } else if (scope == Scope.day) {
      try { final d = state.days[refId]; sourceName = (d != null && d.customName.isNotEmpty) ? d.customName.toUpperCase() : 'DAY: $refId'; } catch (_) { sourceName = 'DAY: $refId'; }
      borderColor = steamGreen; tagLabel = '[DAY SCOPE]';
    } else if (scope == Scope.week) {
      try { final w = state.weeks[refId]; sourceName = (w != null && w.customName.isNotEmpty) ? w.customName.toUpperCase() : 'WEEK: $refId'; } catch (_) { sourceName = 'WEEK: $refId'; }
      borderColor = brassAccent; tagLabel = '[WEEK SCOPE]';
    }

    Widget leadingIcon;
    if (isGoal) {
      if (goal!.status == GoalStatus.completed) leadingIcon = const Icon(Icons.check_circle, color: steamGreen);
      else if (goal!.status == GoalStatus.failed) leadingIcon = const Icon(Icons.cancel, color: rustRed);
      else leadingIcon = const Icon(Icons.circle_outlined, color: inkBlack);
    } else {
      leadingIcon = Icon(Icons.comment, color: borderColor);
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: borderColor, width: 8))),
        child: ListTile(
          leading: isGoal ? IconButton(icon: leadingIcon, onPressed: goal!.isLocked ? null : onGoalStatusCycle) : leadingIcon,
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children:[
              Text(text, style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isGoal && goal!.status == GoalStatus.completed ? TextDecoration.lineThrough : null,
                color: isGoal && goal!.status == GoalStatus.failed ? rustRed : inkBlack,
              )),
              if (isBonus) Padding(padding: const EdgeInsets.only(left: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: const BoxDecoration(color: brassAccent), child: const Text('BONUS', style: TextStyle(fontSize: 10, color: paperBg, fontWeight: FontWeight.bold)))),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              const SizedBox(height: 4),
              Text('$tagLabel SRC: $sourceName', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: borderColor)),
              Text(DateFormat('MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp)), style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children:[
              if (isGoal) DoubleTapLockIcon(isLocked: goal!.isLocked, onLockConfirm: () => state.lockGoal(goal!)),
              IconButton(icon: const Icon(Icons.delete_outline, color: rustRed), onPressed: () => _confirmDelete(context, state, isGoal, isGoal ? goal : remark)),
            ],
          )
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlannerState state, bool isGoal, dynamic item) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('CONFIRM DELETE'), content: const Text('THIS DATA WILL BE PERMANENTLY ERASED.'),
      actions:[
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: rustRed), onPressed: () { state.deleteItem(isGoal, item); Navigator.pop(ctx); }, child: const Text('DELETE'))
      ]
    ));
  }
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
  Map<String, PlanNode> get days => _days;
  Map<String, PlanNode> get weeks => _weeks;
  bool get isLoading => _isLoading;

  List<String> get availableSubjects {
    List<String> base =['Physics', 'Chemistry', 'Math', 'Biology'];
    if (_currentUser != null) base.addAll(_currentUser!.customSubjects);
    return base.toSet().toList();
  }

  List<String> getChaptersForSubject(String subject) {
    List<String> combined =[];
    if (pcmbChapters.containsKey(subject)) combined.addAll(pcmbChapters[subject]!);
    if (_currentUser != null && _currentUser!.customChapters.containsKey(subject)) {
      combined.addAll(_currentUser!.customChapters[subject]!);
    }
    if (combined.isEmpty) combined.add('General');
    return combined.toSet().toList();
  }

  StudySession? get activeSession {
    try { return _sessions.firstWhere((s) => s.status == SessionStatus.active); } 
    catch (e) { return null; }
  }

  Future<void> initSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('sys_users_v7');
    if (usersJson != null) {
      _users = (jsonDecode(usersJson) as List).map((u) => UserProfile.fromJson(u)).toList();
    }
    if (_users.isEmpty) {
      _users.add(UserProfile(id: 'usr_${DateTime.now().millisecondsSinceEpoch}', name: 'OPERATOR_01', customSubjects:[], customChapters: {}));
      await prefs.setString('sys_users_v7', jsonEncode(_users.map((u) => u.toJson()).toList()));
    }
    final lastUserId = prefs.getString('last_user_id_v7') ?? _users.first.id;
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
        if (!s.isBonusMode && s.elapsedSeconds >= s.durationMinutes * 60) {
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
      if (_saveCounter > 5) { saveUserData(); _saveCounter = 0; }
    }
  }

  void _resolveOverlapsForDay(String dateId) {
    List<StudySession> daySessions = _sessions.where((s) => s.dateId == dateId && s.status != SessionStatus.terminated).toList();
    daySessions.sort((a, b) => a.baseStartTime.compareTo(b.baseStartTime));

    for (int i = 0; i < daySessions.length - 1; i++) {
      var curr = daySessions[i];
      var next = daySessions[i + 1];

      int currEnd = curr.calculateCurrentEndTime();
      int origGap = next.baseStartTime - (curr.baseStartTime + curr.durationMinutes * 60000);
      if (origGap < 0) origGap = 0;

      if (curr.status == SessionStatus.completed) {
        int expectedNextStart = curr.completionTime! + origGap;
        if (next.status == SessionStatus.scheduled && next.scheduledStartTime != expectedNextStart) {
          next.scheduledStartTime = expectedNextStart;
        }
      } else {
        if (currEnd > next.scheduledStartTime && next.status == SessionStatus.scheduled) {
          next.scheduledStartTime = currEnd + 60000; // Exact 1 min gap ONLY when overlapping dynamically
        }
      }
    }
  }

  bool checkOverlapCreation(int startMs, int durationMins) {
    int endMs = startMs + (durationMins * 60000);
    String dId = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(startMs));
    List<StudySession> daySessions = _sessions.where((s) => s.dateId == dId && s.status != SessionStatus.terminated).toList();
    for (var s in daySessions) {
      int sStart = s.scheduledStartTime;
      int sEnd = s.calculateCurrentEndTime();
      if (startMs < sEnd && endMs > sStart) return true;
    }
    return false;
  }

  Future<void> loadUserData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final sJson = prefs.getString('sessions_v7_$uid');
    _sessions = sJson != null ? (jsonDecode(sJson) as List).map((s) => StudySession.fromJson(s)).toList() :[];

    final dJson = prefs.getString('days_v7_$uid');
    if (dJson != null) _days = (jsonDecode(dJson) as Map).map((k, v) => MapEntry(k.toString(), PlanNode.fromJson(v))); else _days = {};

    final wJson = prefs.getString('weeks_v7_$uid');
    if (wJson != null) _weeks = (jsonDecode(wJson) as Map).map((k, v) => MapEntry(k.toString(), PlanNode.fromJson(v))); else _weeks = {};

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserData() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessions_v7_$uid', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
    await prefs.setString('days_v7_$uid', jsonEncode(_days.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setString('weeks_v7_$uid', jsonEncode(_weeks.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> switchUser(String id) async {
    _isLoading = true; notifyListeners();
    _currentUser = _users.firstWhere((u) => u.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user_id_v7', _currentUser!.id);
    await loadUserData(_currentUser!.id);
  }

  Future<void> createUser(String name) async {
    _users.add(UserProfile(id: 'usr_${DateTime.now().millisecondsSinceEpoch}', name: name, customSubjects:[], customChapters: {}));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_users_v7', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  Future<void> updateUserName(String newName) async {
    if (_currentUser != null) {
      _currentUser!.name = newName;
      int idx = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (idx != -1) _users[idx] = _currentUser!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sys_users_v7', jsonEncode(_users.map((u) => u.toJson()).toList()));
      notifyListeners();
    }
  }

  Future<void> addCustomSubject(String sub) async {
    if (_currentUser == null || _currentUser!.customSubjects.contains(sub)) return;
    _currentUser!.customSubjects.add(sub);
    _currentUser!.customChapters[sub] =[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_users_v7', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  Future<void> addCustomChapter(String sub, String chap) async {
    if (_currentUser == null) return;
    if (!_currentUser!.customChapters.containsKey(sub)) _currentUser!.customChapters[sub] =[];
    if (_currentUser!.customChapters[sub]!.contains(chap)) return;
    _currentUser!.customChapters[sub]!.add(chap);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_users_v7', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  void saveSession(StudySession session, {bool isNew = false}) {
    if (isNew) { _sessions.add(session); } else {
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
      if (!act.isPaused) act.pauseCount++;
      act.isPaused = !act.isPaused;
      saveUserData(); notifyListeners();
    }
  }

  void setSessionBonusMode(String id) {
    int idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) { _sessions[idx].isBonusMode = true; saveUserData(); notifyListeners(); }
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

  void addGoalToSession(String sessionId, String text) {
    int sIdx = _sessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      _sessions[sIdx].goals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, scope: Scope.session, referenceId: sessionId, subjectContext: _sessions[sIdx].subject, timestamp: DateTime.now().millisecondsSinceEpoch, isBonus: _sessions[sIdx].isBonusMode));
      saveUserData(); notifyListeners();
    }
  }

  void lockGoal(Goal goal) {
    goal.isLocked = true;
    saveUserData(); notifyListeners();
  }

  void addSessionRemark(String sessionId, String text) {
    int sIdx = _sessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      _sessions[sIdx].remarks.add(Remark(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, timestamp: DateTime.now().millisecondsSinceEpoch, scope: Scope.session, referenceId: sessionId, subjectContext: _sessions[sIdx].subject));
      saveUserData(); notifyListeners();
    }
  }

  void deleteItem(bool isGoal, dynamic item) {
    Scope scope = isGoal ? (item as Goal).scope : (item as Remark).scope;
    String refId = isGoal ? (item as Goal).referenceId : (item as Remark).referenceId;
    String id = isGoal ? (item as Goal).id : (item as Remark).id;

    if (scope == Scope.session) {
      int sIdx = _sessions.indexWhere((s) => s.id == refId);
      if (sIdx != -1) {
        if (isGoal) _sessions[sIdx].goals.removeWhere((g) => g.id == id);
        else _sessions[sIdx].remarks.removeWhere((r) => r.id == id);
      }
    } else if (scope == Scope.day) {
      if (_days.containsKey(refId)) {
        if (isGoal) _days[refId]!.overallGoals.removeWhere((g) => g.id == id);
        else _days[refId]!.overallRemarks.removeWhere((r) => r.id == id);
      }
    } else {
      if (_weeks.containsKey(refId)) {
        if (isGoal) _weeks[refId]!.overallGoals.removeWhere((g) => g.id == id);
        else _weeks[refId]!.overallRemarks.removeWhere((r) => r.id == id);
      }
    }
    saveUserData(); notifyListeners();
  }

  PlanNode getDayPlan(String dateId) {
    if (!_days.containsKey(dateId)) _days[dateId] = PlanNode(id: dateId, customName: '', overallGoals:[], overallRemarks: []);
    return _days[dateId]!;
  }
  void updateDayPlan(PlanNode plan) { _days[plan.id] = plan; saveUserData(); notifyListeners(); }

  PlanNode getWeekPlan(String weekId) {
    if (!_weeks.containsKey(weekId)) _weeks[weekId] = PlanNode(id: weekId, customName: '', overallGoals:[], overallRemarks: []);
    return _weeks[weekId]!;
  }
  void updateWeekPlan(PlanNode plan) { _weeks[plan.id] = plan; saveUserData(); notifyListeners(); }
}

// ==========================================
// FILTER ENGINE & SORT WIDGET (REUSABLE)
// ==========================================
class AdvancedFilterEngine extends StatefulWidget {
  final PlannerState state;
  final List<dynamic> items; 
  final String title;
  const AdvancedFilterEngine({super.key, required this.state, required this.items, required this.title});
  @override
  State<AdvancedFilterEngine> createState() => _AdvancedFilterEngineState();
}

class _AdvancedFilterEngineState extends State<AdvancedFilterEngine> {
  String _sortMode = 'CHRONO DESC';
  String _scopeFilter = 'ALL';
  String _statusFilter = 'ALL';
  String _intensityFilter = 'ALL';
  String _bonusFilter = 'ALL';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    List<dynamic> filtered = widget.items.where((item) {
      bool isGoal = item is Goal;
      Scope sc = isGoal ? item.scope : (item as Remark).scope;
      int ts = isGoal ? item.timestamp : (item as Remark).timestamp;

      if (_startDate != null && ts < _startDate!.millisecondsSinceEpoch) return false;
      if (_endDate != null && ts > _endDate!.millisecondsSinceEpoch + 86400000) return false;

      if (_scopeFilter != 'ALL') {
        if (_scopeFilter == 'SESSION' && sc != Scope.session) return false;
        if (_scopeFilter == 'DAY' && sc != Scope.day) return false;
        if (_scopeFilter == 'WEEK' && sc != Scope.week) return false;
      }

      if (_intensityFilter != 'ALL' && sc == Scope.session) {
        String refId = isGoal ? item.referenceId : (item as Remark).referenceId;
        try {
          SessionType t = widget.state.sessions.firstWhere((s) => s.id == refId).type;
          if (_intensityFilter == 'NORMAL' && t != SessionType.normal) return false;
          if (_intensityFilter == 'IMPORTANT' && t != SessionType.important) return false;
          if (_intensityFilter == 'INTENSE' && t != SessionType.intense) return false;
        } catch (_) { return false; }
      }

      if (isGoal) {
        if (_statusFilter != 'ALL') {
          if (_statusFilter == 'COMPLETED' && item.status != GoalStatus.completed) return false;
          if (_statusFilter == 'PENDING' && item.status != GoalStatus.pending) return false;
          if (_statusFilter == 'FAILED' && item.status != GoalStatus.failed) return false;
        }
        if (_bonusFilter != 'ALL') {
          if (_bonusFilter == 'BONUS ONLY' && !item.isBonus) return false;
          if (_bonusFilter == 'NON-BONUS' && item.isBonus) return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      bool aGoal = a is Goal; bool bGoal = b is Goal;
      int aTs = aGoal ? a.timestamp : (a as Remark).timestamp;
      int bTs = bGoal ? b.timestamp : (b as Remark).timestamp;

      if (_sortMode == 'UNFINISHED FIRST') {
        if (aGoal && bGoal) {
          int aVal = (a.status == GoalStatus.pending) ? 0 : 1;
          int bVal = (b.status == GoalStatus.pending) ? 0 : 1;
          if (aVal != bVal) return aVal.compareTo(bVal);
          return bTs.compareTo(aTs);
        } else if (aGoal) return -1;
        else if (bGoal) return 1;
        return bTs.compareTo(aTs);
      }
      if (_sortMode == 'CHRONO DESC') return bTs.compareTo(aTs);
      if (_sortMode == 'CHRONO ASC') return aTs.compareTo(bTs);
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), color: inkBlack,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text('${widget.title} (${filtered.length})', style: const TextStyle(color: paperBg, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(_showFilters ? Icons.expand_less : Icons.filter_list, color: paperBg), onPressed: () => setState(() => _showFilters = !_showFilters)),
            ],
          ),
        ),
        if (_showFilters) Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2), color: brassAccent.withOpacity(0.1)),
          child: Column(
            children:[
              Row(children:[
                Expanded(child: DropdownButtonFormField<String>(value: _sortMode, decoration: const InputDecoration(labelText: 'SORT BY', isDense: true), items: const[DropdownMenuItem(value: 'CHRONO DESC', child: Text('NEWEST')), DropdownMenuItem(value: 'CHRONO ASC', child: Text('OLDEST')), DropdownMenuItem(value: 'UNFINISHED FIRST', child: Text('UNFINISHED 1ST'))], onChanged: (v) => setState(() => _sortMode = v!))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(value: _scopeFilter, decoration: const InputDecoration(labelText: 'SCOPE', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'SESSION', child: Text('SESSION')), DropdownMenuItem(value: 'DAY', child: Text('DAY')), DropdownMenuItem(value: 'WEEK', child: Text('WEEK'))], onChanged: (v) => setState(() => _scopeFilter = v!))),
              ]),
              const SizedBox(height: 8),
              Row(children:[
                Expanded(child: DropdownButtonFormField<String>(value: _intensityFilter, decoration: const InputDecoration(labelText: 'INTENSITY', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'NORMAL', child: Text('NORMAL')), DropdownMenuItem(value: 'IMPORTANT', child: Text('IMPORTANT')), DropdownMenuItem(value: 'INTENSE', child: Text('INTENSE'))], onChanged: (v) => setState(() => _intensityFilter = v!))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(value: _statusFilter, decoration: const InputDecoration(labelText: 'GOAL STATUS', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')), DropdownMenuItem(value: 'PENDING', child: Text('PENDING')), DropdownMenuItem(value: 'FAILED', child: Text('FAILED'))], onChanged: (v) => setState(() => _statusFilter = v!))),
              ]),
              const SizedBox(height: 8),
              Row(children:[
                Expanded(child: OutlinedButton(child: Text(_startDate == null ? 'START DATE' : DateFormat('MM/dd/yyyy').format(_startDate!)), onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035)); if (d != null) setState(() => _startDate = d); })),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(child: Text(_endDate == null ? 'END DATE' : DateFormat('MM/dd/yyyy').format(_endDate!)), onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035)); if (d != null) setState(() => _endDate = d); })),
                IconButton(icon: const Icon(Icons.clear), onPressed: () => setState((){ _startDate = null; _endDate = null; }))
              ])
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              if (filtered[i] is Goal) {
                Goal g = filtered[i];
                return VisualTileBuilder(goal: g, state: widget.state,
                  onGoalStatusCycle: () {
                    g.status = g.status == GoalStatus.pending ? GoalStatus.completed : (g.status == GoalStatus.completed ? GoalStatus.failed : GoalStatus.pending);
                    widget.state.notifyListeners(); widget.state.saveUserData();
                  });
              }
              return VisualTileBuilder(remark: filtered[i], state: widget.state);
            },
          ),
        )
      ],
    );
  }
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
  final List<Widget> _screens = const[DashboardScreen(), CalendarScreen(), DataBrowserScreen(), GlobalStatsScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    if (state.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));

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
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: inkBlack, width: 3))),
        child: NavigationBar(
          backgroundColor: paperBg,
          indicatorColor: brassAccent.withOpacity(0.5),
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const[
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'TODAY'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'PLANNER'),
            NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'MATRIX'),
            NavigationDestination(icon: Icon(Icons.query_stats), label: 'STATS'),
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
      decoration: BoxDecoration(border: const Border(bottom: BorderSide(color: inkBlack, width: 3)), color: session.isPaused ? rustRed : inkBlack),
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
                      Text('ACTIVE: ${session.name.toUpperCase()}', style: const TextStyle(color: paperBg, fontWeight: FontWeight.bold)),
                      Text('${session.subject} > ${session.chapter}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                Text(timeStr, style: const TextStyle(color: paperBg, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Courier')),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(session.isPaused ? Icons.play_arrow : Icons.pause, color: paperBg),
                  onPressed: () => state.togglePauseActiveSession(),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: paperBg),
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
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description;
      _durCtrl.text = s.durationMinutes.toString();
      _date = DateTime.fromMillisecondsSinceEpoch(s.baseStartTime);
      _time = TimeOfDay.fromDateTime(_date);
      _type = s.type;
      _subject = s.subject;
      _chapter = s.chapter;
      _goals = List.from(s.goals);
    }
  }

  void _setToCurrentTime() {
    setState(() {
      _date = DateTime.now();
      _time = TimeOfDay.now();
    });
  }

  void _save(PlannerState state) {
    if (_nameCtrl.text.isEmpty || _durCtrl.text.isEmpty || _subject == null || _chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MISSING FIELDS'), backgroundColor: rustRed));
      return;
    }
    DateTime fullDt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

    int reqDuration = int.parse(_durCtrl.text);
    bool overlap = state.checkOverlapCreation(fullDt.millisecondsSinceEpoch, reqDuration);

    if (overlap && widget.existing == null) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('OVERLAP DETECTED'),
                content: const Text('THIS TIME PERIOD INTERSECTS WITH AN EXISTING OPERATION. PROCEED ANYWAY?'),
                actions:[
                  OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: rustRed),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _executeSave(state, fullDt, reqDuration);
                      },
                      child: const Text('PROCEED'))
                ],
              ));
    } else {
      _executeSave(state, fullDt, reqDuration);
    }
  }

  void _executeSave(PlannerState state, DateTime fullDt, int reqDuration) {
    if (widget.existing != null) {
      final s = widget.existing!;
      s.name = _nameCtrl.text;
      s.description = _descCtrl.text;
      if (s.status == SessionStatus.scheduled) {
        s.durationMinutes = reqDuration;
        s.baseStartTime = fullDt.millisecondsSinceEpoch;
        s.scheduledStartTime = s.baseStartTime;
        s.type = _type;
        s.subject = _subject!;
        s.chapter = _chapter!;
        s.goals = _goals;
      }
      state.saveSession(s);
    } else {
      String id = 'sess_${DateTime.now().millisecondsSinceEpoch}';
      for (var g in _goals) {
        g.referenceId = id;
        g.scope = Scope.session;
        g.subjectContext = _subject!;
      }
      final s = StudySession(
          id: id,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          baseStartTime: fullDt.millisecondsSinceEpoch,
          scheduledStartTime: fullDt.millisecondsSinceEpoch,
          durationMinutes: reqDuration,
          type: _type,
          subject: _subject!,
          chapter: _chapter!,
          goals: _goals,
          remarks:[]);
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
            if (!isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(onPressed: _setToCurrentTime, child: const Text('SET CREATION/INITIATION TIME TO NOW')),
              ),
            const SizedBox(height: 32),
            const Text('SESSION GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ..._goals.map((g) => Card(child: ListTile(title: Text(g.text), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: isLocked ? null : () => setState(() => _goals.remove(g)))))),
            if (!isLocked)
              FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('ADD GOAL'),
                  onPressed: () {
                    final c = TextEditingController();
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(title: const Text('NEW GOAL'), content: TextField(controller: c), actions:[
                              OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                              FilledButton(
                                  onPressed: () {
                                    if (c.text.isNotEmpty) setState(() => _goals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text, scope: Scope.session, referenceId: '', subjectContext: _subject!, timestamp: DateTime.now().millisecondsSinceEpoch)));
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('ADD'))
                            ]));
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
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('CRITICAL WARNING'),
              content: const Text('TERMINATING A SESSION WILL REMOVE IT FROM STATS AND LOGS COMPLETELY. PROCEED?'),
              actions:[
                OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: rustRed),
                    onPressed: () {
                      state.terminateSession(id);
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('TERMINATE'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final s = state.sessions.firstWhere((x) => x.id == session.id, orElse: () => session);

    bool allGoalsResolved = s.goals.isNotEmpty && !s.goals.any((g) => g.status == GoalStatus.pending);
    bool canCompleteEarly = s.status == SessionStatus.active && allGoalsResolved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RECORD DETAILS'),
        actions:[
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionEditorScreen(existing: s)))),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => const[PopupMenuItem(value: 'term', child: Text('TERMINATE OPERATION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))],
            onSelected: (v) {
              if (v == 'term') _confirmTerminate(context, state, s.id);
            },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Expanded(child: Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
                      if (s.status == SessionStatus.active)
                        IconButton(
                          icon: Icon(s.isPaused ? Icons.play_arrow : Icons.pause, size: 32),
                          onPressed: () => state.togglePauseActiveSession(),
                        )
                    ],
                  ),
                  Text(s.description),
                  const Divider(height: 32),
                  if (s.isBonusMode) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), color: brassAccent, child: const Text('OPERATION IN BONUS MODE', style: TextStyle(color: paperBg, fontWeight: FontWeight.bold))),
                  Text('STATUS: ${s.status.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: s.status == SessionStatus.completed ? steamGreen : (s.status == SessionStatus.active ? brassAccent : inkBlack))),
                  Text('SCHEDULED (BASE): ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.baseStartTime))}'),
                  Text('SCHEDULED (DYN): ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))}'),
                  Text('PAUSED EXTENSION: ${formatDuration(s.pausedSeconds)} | PAUSE COUNT: ${s.pauseCount}'),
                  if (s.status == SessionStatus.completed) Text('ACTUAL END: ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.completionTime!))}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (canCompleteEarly && !s.isBonusMode)
              Row(
                children:[
                  Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: steamGreen), onPressed: () { state.completeSessionEarly(s.id); Navigator.pop(context); }, child: const Text('COMPLETE SESS'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: brassAccent), onPressed: () { state.setSessionBonusMode(s.id); }, child: const Text('BONUS MODE'))),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                const Text('GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (s.status == SessionStatus.active)
                  IconButton(
                      icon: const Icon(Icons.add_task),
                      onPressed: () {
                        final ctrl = TextEditingController();
                        showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(title: const Text('NEW ONGOING GOAL'), content: TextField(controller: ctrl), actions:[
                                  OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                                  FilledButton(
                                      onPressed: () {
                                        if (ctrl.text.isNotEmpty) state.addGoalToSession(s.id, ctrl.text);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('ADD'))
                                ]));
                      })
              ],
            ),
            ...s.goals.map((g) => VisualTileBuilder(goal: g, state: state, 
              onGoalStatusCycle: () {
                GoalStatus next = GoalStatus.pending;
                if (g.status == GoalStatus.pending) next = GoalStatus.completed;
                else if (g.status == GoalStatus.completed) next = GoalStatus.failed;
                state.markGoal(s.id, g.id, next);
              },
            )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                const Text('REMARKS LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                    icon: const Icon(Icons.add_comment),
                    onPressed: () {
                      final ctrl = TextEditingController();
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(title: const Text('ADD REMARK'), content: TextField(controller: ctrl), actions:[
                                OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                                FilledButton(
                                    onPressed: () {
                                      if (ctrl.text.isNotEmpty) state.addSessionRemark(s.id, ctrl.text);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('ADD'))
                              ]));
                    })
              ],
            ),
            ...s.remarks.map((r) => VisualTileBuilder(remark: r, state: state)),
          ],
        ),
      ),
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
            padding: const EdgeInsets.all(16),
            color: inkBlack,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => setState(() => _date = _date.subtract(const Duration(days: 1)))),
                InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2035));
                      if (d != null) setState(() => _date = d);
                    },
                    child: Text(DateFormat('EEEE, MMM dd, yyyy').format(_date).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: () => setState(() => _date = _date.add(const Duration(days: 1)))),
              ],
            ),
          ),
          const TabBar(indicatorColor: brassAccent, labelColor: inkBlack, unselectedLabelColor: Colors.black54, tabs:[Tab(text: 'DAY LOG'), Tab(text: 'WEEK LOG')]),
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
          Row(children:[
            Expanded(child: Text(plan.customName.isEmpty ? 'UNNAMED ${scope.name.toUpperCase()}' : plan.customName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final c = TextEditingController(text: plan.customName);
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[
                            FilledButton(
                                onPressed: () {
                                  plan.customName = c.text;
                                  if (scope == Scope.day) state.updateDayPlan(plan);
                                  else state.updateWeekPlan(plan);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('SAVE'))
                          ]));
                })
          ]),
          const Divider(),
          const Text('OVERALL GOALS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallGoals.map((g) => VisualTileBuilder(goal: g, state: state,
            onGoalStatusCycle: () {
              g.status = g.status == GoalStatus.pending ? GoalStatus.completed : (g.status == GoalStatus.completed ? GoalStatus.failed : GoalStatus.pending);
              scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan);
            }
          )),
          FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('ADD GOAL'),
              onPressed: () {
                final c = TextEditingController();
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[
                          FilledButton(
                              onPressed: () {
                                plan.overallGoals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text, scope: scope, referenceId: refId, timestamp: DateTime.now().millisecondsSinceEpoch));
                                scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan);
                                Navigator.pop(ctx);
                              },
                              child: const Text('ADD'))
                        ]));
              }),
          const SizedBox(height: 24),
          const Text('OVERALL REMARKS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallRemarks.map((r) => VisualTileBuilder(remark: r, state: state)),
          FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('ADD REMARK'),
              onPressed: () {
                final c = TextEditingController();
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[
                          FilledButton(
                              onPressed: () {
                                plan.overallRemarks.add(Remark(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text, timestamp: DateTime.now().millisecondsSinceEpoch, scope: scope, referenceId: refId));
                                scope == Scope.day ? state.updateDayPlan(plan) : state.updateWeekPlan(plan);
                                Navigator.pop(ctx);
                              },
                              child: const Text('ADD'))
                        ]));
              }),
          if (scope == Scope.day) ...[
            const SizedBox(height: 24),
            const Text('SCHEDULED OPERATIONS', style: TextStyle(fontWeight: FontWeight.bold)),
            ...sessions.map((s) => ListTile(
                title: Text(s.name), subtitle: Text('${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))} | ${s.status.name.toUpperCase()}'), trailing: OutlinedButton(child: const Text('OPEN'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s))))))
          ]
        ],
      ),
    );
  }
}

// ==========================================
// GLOBAL & SUBJECT STATS SCREEN
// ==========================================
class GlobalStatsScreen extends StatelessWidget {
  const GlobalStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final validSessions = state.sessions.where((s) => s.status == SessionStatus.completed).toList();

    int totalSecs = validSessions.fold(0, (sum, s) => sum + s.elapsedSeconds);
    int totalGoals = validSessions.fold(0, (sum, s) => sum + s.goals.length);
    int compGoals = validSessions.fold(0, (sum, s) => sum + s.goals.where((g) => g.status == GoalStatus.completed).length);
    double completionRate = totalGoals > 0 ? (compGoals / totalGoals) * 100 : 0;
    int totalPauses = validSessions.fold(0, (sum, s) => sum + s.pauseCount);
    int totalExt = validSessions.fold(0, (sum, s) => sum + s.pausedSeconds);

    Map<String, int> subHours = {};
    for (var s in validSessions) {
      subHours[s.subject] = (subHours[s.subject] ?? 0) + s.elapsedSeconds;
    }

    List<BarChartGroupData> barGroups = [];
    List<String> subLabels =[];
    int xIndex = 0;
    double maxY = 1;
    
    subHours.forEach((sub, secs) {
      double yVal = secs / 3600.0;
      if (yVal > maxY) maxY = yVal;
      barGroups.add(BarChartGroupData(x: xIndex++, barRods:[BarChartRodData(toY: yVal, color: inkBlack, width: 24, borderRadius: BorderRadius.zero)]));
      subLabels.add(sub.length > 4 ? sub.substring(0, 4) : sub);
    });

    maxY = maxY * 1.2; 

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
            const Text('GLOBAL TELEMETRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            OutlinedButton.icon(icon: const Icon(Icons.folder_open), label: const Text('DIRECTORY'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalDirectoryScreen())))
          ]),
          const SizedBox(height: 16),
          Row(children:[
            Expanded(child: _buildStatBox('TOTAL TIME', formatDuration(totalSecs))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatBox('SESSIONS', validSessions.length.toString())),
            const SizedBox(width: 8),
            Expanded(child: _buildStatBox('GOAL COMP', '${completionRate.toStringAsFixed(0)}%')),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            Expanded(child: _buildStatBox('TOTAL PAUSES', totalPauses.toString())),
            const SizedBox(width: 8),
            Expanded(child: _buildStatBox('TOTAL EXT', formatDuration(totalExt))),
          ]),
          const SizedBox(height: 24),
          if (barGroups.isNotEmpty)
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)),
              child: BarChart(BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.toStringAsFixed(2)} h', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(subLabels[val.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) => Text('${val.toInt()}h', style: const TextStyle(fontSize: 12)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.black26, strokeWidth: 1, dashArray:[4, 4])),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              )),
            )
          else
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('NOT ENOUGH DATA FOR GRAPH.'))),
          const SizedBox(height: 32),
          const Text('SUBJECT DIRECTORIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          ...state.availableSubjects.map((sub) {
            int seconds = subHours[sub] ?? 0;
            return Card(
              child: ListTile(
                title: Text(sub.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('TOTAL TIME: ${formatDuration(seconds)}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectSpecificScreen(subject: sub))),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String val) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2), color: brassAccent.withOpacity(0.1)),
      child: Column(children:[Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)]),
    );
  }
}

// ==========================================
// LIST BUILDER W/ ADVANCED SORTING FOR TABS
// ==========================================
class AdvancedSortListBuilder extends StatefulWidget {
  final PlannerState state;
  final List<dynamic> items; 
  final String title;
  const AdvancedSortListBuilder({super.key, required this.state, required this.items, this.title = 'RECORDS'});
  @override
  State<AdvancedSortListBuilder> createState() => _AdvancedSortListBuilderState();
}

class _AdvancedSortListBuilderState extends State<AdvancedSortListBuilder> {
  String _sortMode = 'CHRONO DESC';
  String _scopeFilter = 'ALL';
  String _statusFilter = 'ALL';
  String _intensityFilter = 'ALL';
  String _bonusFilter = 'ALL';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    List<dynamic> filtered = widget.items.where((item) {
      bool isGoal = item is Goal;
      Scope sc = isGoal ? item.scope : (item as Remark).scope;
      int ts = isGoal ? item.timestamp : (item as Remark).timestamp;

      if (_startDate != null && ts < _startDate!.millisecondsSinceEpoch) return false;
      if (_endDate != null && ts > _endDate!.millisecondsSinceEpoch + 86400000) return false;

      if (_scopeFilter != 'ALL') {
        if (_scopeFilter == 'SESSION' && sc != Scope.session) return false;
        if (_scopeFilter == 'DAY' && sc != Scope.day) return false;
        if (_scopeFilter == 'WEEK' && sc != Scope.week) return false;
      }

      if (_intensityFilter != 'ALL' && sc == Scope.session) {
        String refId = isGoal ? item.referenceId : (item as Remark).referenceId;
        try {
          SessionType t = widget.state.sessions.firstWhere((s) => s.id == refId).type;
          if (_intensityFilter == 'NORMAL' && t != SessionType.normal) return false;
          if (_intensityFilter == 'IMPORTANT' && t != SessionType.important) return false;
          if (_intensityFilter == 'INTENSE' && t != SessionType.intense) return false;
        } catch (_) { return false; }
      }

      if (isGoal) {
        if (_statusFilter != 'ALL') {
          if (_statusFilter == 'COMPLETED' && item.status != GoalStatus.completed) return false;
          if (_statusFilter == 'PENDING' && item.status != GoalStatus.pending) return false;
          if (_statusFilter == 'FAILED' && item.status != GoalStatus.failed) return false;
        }
        if (_bonusFilter != 'ALL') {
          if (_bonusFilter == 'BONUS ONLY' && !item.isBonus) return false;
          if (_bonusFilter == 'NON-BONUS' && item.isBonus) return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      bool aGoal = a is Goal; bool bGoal = b is Goal;
      int aTs = aGoal ? a.timestamp : (a as Remark).timestamp;
      int bTs = bGoal ? b.timestamp : (b as Remark).timestamp;

      if (_sortMode == 'UNFINISHED FIRST') {
        if (aGoal && bGoal) {
          int aVal = (a.status == GoalStatus.pending) ? 0 : 1;
          int bVal = (b.status == GoalStatus.pending) ? 0 : 1;
          if (aVal != bVal) return aVal.compareTo(bVal);
          return bTs.compareTo(aTs);
        } else if (aGoal) return -1;
        else if (bGoal) return 1;
        return bTs.compareTo(aTs);
      }
      if (_sortMode == 'CHRONO DESC') return bTs.compareTo(aTs);
      if (_sortMode == 'CHRONO ASC') return aTs.compareTo(bTs);
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), color: inkBlack,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text('${widget.title} (${filtered.length})', style: const TextStyle(color: paperBg, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(_showFilters ? Icons.expand_less : Icons.filter_list, color: paperBg), onPressed: () => setState(() => _showFilters = !_showFilters)),
            ],
          ),
        ),
        if (_showFilters) Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2), color: brassAccent.withOpacity(0.1)),
          child: Column(
            children:[
              Row(children:[
                Expanded(child: DropdownButtonFormField<String>(value: _sortMode, decoration: const InputDecoration(labelText: 'SORT BY', isDense: true), items: const[DropdownMenuItem(value: 'CHRONO DESC', child: Text('NEWEST')), DropdownMenuItem(value: 'CHRONO ASC', child: Text('OLDEST')), DropdownMenuItem(value: 'UNFINISHED FIRST', child: Text('UNFINISHED 1ST'))], onChanged: (v) => setState(() => _sortMode = v!))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(value: _scopeFilter, decoration: const InputDecoration(labelText: 'SCOPE', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'SESSION', child: Text('SESSION')), DropdownMenuItem(value: 'DAY', child: Text('DAY')), DropdownMenuItem(value: 'WEEK', child: Text('WEEK'))], onChanged: (v) => setState(() => _scopeFilter = v!))),
              ]),
              const SizedBox(height: 8),
              Row(children:[
                Expanded(child: DropdownButtonFormField<String>(value: _intensityFilter, decoration: const InputDecoration(labelText: 'INTENSITY', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'NORMAL', child: Text('NORMAL')), DropdownMenuItem(value: 'IMPORTANT', child: Text('IMPORTANT')), DropdownMenuItem(value: 'INTENSE', child: Text('INTENSE'))], onChanged: (v) => setState(() => _intensityFilter = v!))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(value: _statusFilter, decoration: const InputDecoration(labelText: 'GOAL STATUS', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')), DropdownMenuItem(value: 'PENDING', child: Text('PENDING')), DropdownMenuItem(value: 'FAILED', child: Text('FAILED'))], onChanged: (v) => setState(() => _statusFilter = v!))),
              ]),
              const SizedBox(height: 8),
              Row(children:[
                Expanded(child: DropdownButtonFormField<String>(value: _bonusFilter, decoration: const InputDecoration(labelText: 'BONUS TAG', isDense: true), items: const[DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'BONUS ONLY', child: Text('BONUS ONLY')), DropdownMenuItem(value: 'NON-BONUS', child: Text('NON-BONUS'))], onChanged: (v) => setState(() => _bonusFilter = v!))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(child: Text(_startDate == null ? 'START DATE' : DateFormat('MM/dd/yyyy').format(_startDate!)), onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035)); if (d != null) setState(() => _startDate = d); })),
                IconButton(icon: const Icon(Icons.clear), onPressed: () => setState((){ _startDate = null; _endDate = null; }))
              ])
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              if (filtered[i] is Goal) {
                Goal g = filtered[i];
                return VisualTileBuilder(goal: g, state: widget.state,
                  onGoalStatusCycle: () {
                    g.status = g.status == GoalStatus.pending ? GoalStatus.completed : (g.status == GoalStatus.completed ? GoalStatus.failed : GoalStatus.pending);
                    widget.state.notifyListeners(); widget.state.saveUserData();
                  });
              }
              return VisualTileBuilder(remark: filtered[i], state: widget.state);
            },
          ),
        )
      ],
    );
  }
}

class SubjectSpecificScreen extends StatelessWidget {
  final String subject;
  const SubjectSpecificScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final sessions = state.sessions.where((s) => s.subject == subject && s.status == SessionStatus.completed).toList();
    final chapters = state.getChaptersForSubject(subject);

    int totalSecs = sessions.fold(0, (sum, s) => sum + s.elapsedSeconds);
    int totalGoals = sessions.fold(0, (sum, s) => sum + s.goals.length);
    int compGoals = sessions.fold(0, (sum, s) => sum + s.goals.where((g) => g.status == GoalStatus.completed).length);

    Map<String, int> chapSecs = {};
    for (var s in sessions) chapSecs[s.chapter] = (chapSecs[s.chapter] ?? 0) + s.elapsedSeconds;
    
    List<BarChartGroupData> barGroups =[];
    int xIndex = 0; double maxY = 1;
    chapSecs.forEach((chap, secs) {
      double yVal = secs / 3600.0;
      if (yVal > maxY) maxY = yVal;
      barGroups.add(BarChartGroupData(x: xIndex++, barRods:[BarChartRodData(toY: yVal, color: inkBlack, width: 16, borderRadius: BorderRadius.zero)]));
    });
    maxY = maxY * 1.2;

    List<Goal> allGoals = sessions.expand((s) => s.goals).toList();
    List<Remark> allRemarks = sessions.expand((s) => s.remarks).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.toUpperCase()),
          bottom: const TabBar(
              indicatorColor: inkBlack, labelColor: inkBlack, isScrollable: true,
              tabs:[Tab(text: 'OVERVIEW'), Tab(text: 'SESSIONS'), Tab(text: 'GOALS'), Tab(text: 'REMARKS')]),
        ),
        body: TabBarView(
          children:[
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  Row(children:[
                    Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)), child: Column(children:[Text(formatDuration(totalSecs), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const Text('TIME SPENT', style: TextStyle(fontSize: 10))]))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)), child: Column(children:[Text(sessions.length.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const Text('SESSIONS', style: TextStyle(fontSize: 10))]))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)), child: Column(children:[Text(totalGoals > 0 ? '${((compGoals/totalGoals)*100).toStringAsFixed(0)}%' : '0%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const Text('GOAL COMP', style: TextStyle(fontSize: 10))]))),
                  ]),
                  const SizedBox(height: 24),
                  if (barGroups.isNotEmpty)
                    Container(
                      height: 200, padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)),
                      child: BarChart(BarChartData(
                        maxY: maxY,
                        barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.toStringAsFixed(2)} h', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                        titlesData: FlTitlesData(bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) => Text('${val.toInt()}h', style: const TextStyle(fontSize: 10)))), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
                        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.black26, strokeWidth: 1, dashArray:[4, 4])), borderData: FlBorderData(show: false), barGroups: barGroups,
                      )),
                    ),
                  const SizedBox(height: 24),
                  const Text('CHAPTER DIRECTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...chapters.map((c) {
                    return Card(child: ListTile(title: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), trailing: Text(formatDuration(chapSecs[c] ?? 0)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterSpecificScreen(subject: subject, chapter: c)))));
                  })
                ],
              )
            ),
            ListView(padding: const EdgeInsets.all(16), children: sessions.map((s) => ListTile(title: Text(s.name), subtitle: Text('${s.chapter} | ${s.status.name.toUpperCase()}'), trailing: OutlinedButton(child: const Text('OPEN'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)))))).toList()),
            AdvancedSortListBuilder(state: state, items: allGoals, title: 'SUBJECT GOALS'),
            AdvancedSortListBuilder(state: state, items: allRemarks, title: 'SUBJECT REMARKS'),
          ],
        ),
      ),
    );
  }
}

class ChapterSpecificScreen extends StatelessWidget {
  final String subject;
  final String chapter;
  const ChapterSpecificScreen({super.key, required this.subject, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final sessions = state.sessions.where((s) => s.subject == subject && s.chapter == chapter && s.status != SessionStatus.terminated).toList();

    List<Goal> allGoals = sessions.expand((s) => s.goals).toList();
    List<Remark> allRemarks = sessions.expand((s) => s.remarks).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CHAPTER DETAILS'),
          bottom: const TabBar(indicatorColor: inkBlack, labelColor: inkBlack, tabs:[Tab(text: 'SESSIONS'), Tab(text: 'GOALS'), Tab(text: 'REMARKS')]),
        ),
        body: TabBarView(
          children:[
            ListView(padding: const EdgeInsets.all(16), children: sessions.map((s) => ListTile(title: Text(s.name), subtitle: Text(s.status.name.toUpperCase()), trailing: OutlinedButton(child: const Text('OPEN'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)))))).toList()),
            AdvancedSortListBuilder(state: state, items: allGoals, title: 'CHAPTER GOALS'),
            AdvancedSortListBuilder(state: state, items: allRemarks, title: 'CHAPTER REMARKS'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// GLOBAL DIRECTORY (Visual & Sorted Lists)
// ==========================================
class GlobalDirectoryScreen extends StatefulWidget {
  const GlobalDirectoryScreen({super.key});
  @override
  State<GlobalDirectoryScreen> createState() => _GlobalDirectoryScreenState();
}

class _GlobalDirectoryScreenState extends State<GlobalDirectoryScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    
    List<dynamic> items =[];
    items.addAll(state.sessions.where((s)=>s.status!=SessionStatus.terminated).expand((s) => s.goals));
    items.addAll(state.days.values.expand((d) => d.overallGoals));
    items.addAll(state.weeks.values.expand((w) => w.overallGoals));
    items.addAll(state.sessions.where((s)=>s.status!=SessionStatus.terminated).expand((s) => s.remarks));
    items.addAll(state.days.values.expand((d) => d.overallRemarks));
    items.addAll(state.weeks.values.expand((w) => w.overallRemarks));

    return Scaffold(
      appBar: AppBar(title: const Text('GLOBAL DIRECTORY')),
      body: AdvancedSortListBuilder(state: state, items: items, title: 'ALL GLOBAL RECORDS'),
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
  bool _incSessions = true;
  bool _incGoals = true;
  bool _incRemarks = true;
  bool _incPending = true;
  bool _incCompleted = true;
  bool _incFailed = true;
  bool _incNormal = true;
  bool _incImportant = true;
  bool _incIntense = true;

  String _generateMatrixText(PlannerState state) {
    StringBuffer sb = StringBuffer();
    sb.writeln("=== AI PARSING LEGEND & GLOSSARY ===");
    sb.writeln("[ ] : Pending/Unfinished Goal");
    sb.writeln("[X] : Completed Goal");
    sb.writeln("[!] : Failed Goal");
    sb.writeln("[BONUS] : Goal added during Bonus Time");
    sb.writeln("[NORMAL] / [IMPORTANT] / [INTENSE] : Session Intensity Type");
    sb.writeln("[DAY] / [WEEK] /[SESSION] : The scope/level the item belongs to");
    sb.writeln("SRC: The name of the parent session, day, or week.");
    sb.writeln("Ext: Extended paused time in format Days Hours Mins Secs.");
    sb.writeln("====================================\n");

    sb.writeln("=== DATA MATRIX EXPORT (${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}) ===");

    List<StudySession> validSessions = state.sessions.where((s) => s.status != SessionStatus.terminated).toList();
    if (_subFilter != null) validSessions = validSessions.where((s) => s.subject == _subFilter).toList();
    validSessions = validSessions.where((s) => (s.type == SessionType.normal && _incNormal) || (s.type == SessionType.important && _incImportant) || (s.type == SessionType.intense && _incIntense)).toList();

    if (_incSessions) {
      sb.writeln("\n>>> SESSIONS DIRECTORY");
      for (var s in validSessions) {
        int comp = s.goals.where((g) => g.status == GoalStatus.completed).length;
        int incomp = s.goals.where((g) => g.status != GoalStatus.completed).length;
        sb.writeln("[${s.type.name.toUpperCase()}] [${s.status.name.toUpperCase()}] ${s.name} | ${s.subject} -> ${s.chapter} (${DateFormat('MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))})");
        sb.writeln("    > Pauses: ${s.pauseCount} | Ext: ${formatDuration(s.pausedSeconds)} | Goals Total: ${s.goals.length} (C: $comp, I: $incomp)");
      }
    }

    if (_incGoals) {
      sb.writeln("\n>>> GOALS DIRECTORY");
      List<Goal> allGoals =[];
      if (_scopeFilter == null || _scopeFilter == Scope.session) allGoals.addAll(validSessions.expand((s) => s.goals));
      if (_subFilter == null) {
        if (_scopeFilter == null || _scopeFilter == Scope.day) allGoals.addAll(state._days.values.expand((d) => d.overallGoals));
        if (_scopeFilter == null || _scopeFilter == Scope.week) allGoals.addAll(state._weeks.values.expand((w) => w.overallGoals));
      }
      for (var g in allGoals) {
        if (!((g.status == GoalStatus.pending && _incPending) || (g.status == GoalStatus.completed && _incCompleted) || (g.status == GoalStatus.failed && _incFailed))) continue;
        String marker = g.status == GoalStatus.pending ? '[ ]' : (g.status == GoalStatus.completed ? '[X]' : '[!]');
        String sourceName = ''; String tagType = '';
        if (g.scope == Scope.session) {
          try { final s = state.sessions.firstWhere((s) => s.id == g.referenceId); sourceName = s.name; tagType = s.type.name.toUpperCase(); } catch (_) {}
        } else if (g.scope == Scope.day) {
          try { final d = state.days[g.referenceId]; sourceName = d?.customName ?? 'DAY'; } catch (_) {} tagType = 'DAY';
        } else {
          try { final w = state.weeks[g.referenceId]; sourceName = w?.customName ?? 'WEEK'; } catch (_) {} tagType = 'WEEK';
        }
        sb.writeln("$marker ${g.text} ${g.isBonus ? '[BONUS]' : ''} |[$tagType] SRC: $sourceName | Scope: ${g.scope.name.toUpperCase()} | Sub: ${g.subjectContext.isNotEmpty ? g.subjectContext : 'GLOBAL'}");
      }
    }

    if (_incRemarks) {
      sb.writeln("\n>>> REMARKS DIRECTORY");
      List<Remark> allRemarks =[];
      if (_scopeFilter == null || _scopeFilter == Scope.session) allRemarks.addAll(validSessions.expand((s) => s.remarks));
      if (_subFilter == null) {
        if (_scopeFilter == null || _scopeFilter == Scope.day) allRemarks.addAll(state._days.values.expand((d) => d.overallRemarks));
        if (_scopeFilter == null || _scopeFilter == Scope.week) allRemarks.addAll(state._weeks.values.expand((w) => w.overallRemarks));
      }
      for (var r in allRemarks) {
        String sourceName = ''; String tagType = '';
        if (r.scope == Scope.session) {
          try { final s = state.sessions.firstWhere((s) => s.id == r.referenceId); sourceName = s.name; tagType = s.type.name.toUpperCase(); } catch (_) {}
        } else if (r.scope == Scope.day) {
          try { final d = state.days[r.referenceId]; sourceName = d?.customName ?? 'DAY'; } catch (_) {} tagType = 'DAY';
        } else {
          try { final w = state.weeks[r.referenceId]; sourceName = w?.customName ?? 'WEEK'; } catch (_) {} tagType = 'WEEK';
        }
        sb.writeln("* ${r.text} | [$tagType] SRC: $sourceName | Scope: ${r.scope.name.toUpperCase()} | Sub: ${r.subjectContext.isNotEmpty ? r.subjectContext : 'GLOBAL'}");
      }
    }

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    String generatedText = _generateMatrixText(state);

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
                const Divider(),
                Row(children:[Expanded(child: CheckboxListTile(title: const Text('NORMAL'), value: _incNormal, activeColor: inkBlack, dense: true, onChanged: (v) => setState(() => _incNormal = v ?? false))), Expanded(child: CheckboxListTile(title: const Text('IMPORTANT'), value: _incImportant, activeColor: importantBlue, dense: true, onChanged: (v) => setState(() => _incImportant = v ?? false))), Expanded(child: CheckboxListTile(title: const Text('INTENSE'), value: _incIntense, activeColor: intensePurple, dense: true, onChanged: (v) => setState(() => _incIntense = v ?? false)))]),
                const Divider(),
                CheckboxListTile(title: const Text('INCLUDE SESSIONS'), value: _incSessions, activeColor: inkBlack, onChanged: (v) => setState(() => _incSessions = v ?? false)),
                CheckboxListTile(title: const Text('INCLUDE REMARKS'), value: _incRemarks, activeColor: inkBlack, onChanged: (v) => setState(() => _incRemarks = v ?? false)),
                CheckboxListTile(title: const Text('INCLUDE GOALS'), value: _incGoals, activeColor: inkBlack, onChanged: (v) => setState(() => _incGoals = v ?? false)),
                if (_incGoals) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Row(
                      children:[
                        Expanded(child: CheckboxListTile(title: const Text('PENDING'), value: _incPending, activeColor: inkBlack, dense: true, onChanged: (v) => setState(() => _incPending = v ?? false))),
                        Expanded(child: CheckboxListTile(title: const Text('COMPLETED'), value: _incCompleted, activeColor: steamGreen, dense: true, onChanged: (v) => setState(() => _incCompleted = v ?? false))),
                        Expanded(child: CheckboxListTile(title: const Text('FAILED'), value: _incFailed, activeColor: rustRed, dense: true, onChanged: (v) => setState(() => _incFailed = v ?? false))),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
              icon: const Icon(Icons.copy), label: const Text('COPY MATRIX TO CLIPBOARD'),
              onPressed: () { Clipboard.setData(ClipboardData(text: generatedText)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('COPIED!'))); }),
          const SizedBox(height: 24),
          const Text('PREVIEW:', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            height: 300, padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.black26), color: Colors.white),
            child: SingleChildScrollView(child: Text(generatedText, style: const TextStyle(fontSize: 10, fontFamily: 'Courier'))),
          )
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
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children:[
            const Icon(Icons.person, size: 64), 
            Text(user?.name ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            OutlinedButton(child: const Text('RENAME OPERATOR'), onPressed: () {
              final c = TextEditingController(text: user?.name);
              showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[
                FilledButton(child: const Text('SAVE'), onPressed: () { state.updateUserName(c.text); Navigator.pop(ctx); })
              ]));
            })
          ]))),
          const SizedBox(height: 24),
          const Text('ACCOUNTS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...state.users.map((u) => ListTile(title: Text(u.name), trailing: u.id == user?.id ? const Icon(Icons.check_circle) : OutlinedButton(child: const Text('SWITCH'), onPressed: () => state.switchUser(u.id)))),
          FilledButton(child: const Text('NEW OPERATOR'), onPressed: () {
            final c = TextEditingController();
            showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(child: const Text('CREATE'), onPressed: () { state.createUser(c.text); Navigator.pop(ctx); })]));
          }),
          const SizedBox(height: 24),
          const Text('CUSTOM SUBJECTS & CHAPTERS', style: TextStyle(fontWeight: FontWeight.bold)),
          if (user != null) ...user.customSubjects.map((s) => ExpansionTile(
            title: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ...user.customChapters[s]?.map((c) => ListTile(title: Text(c, style: const TextStyle(fontSize: 12)))) ??[],
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('ADD CHAPTER'), onPressed: () {
                  final c = TextEditingController();
                  showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c, decoration: const InputDecoration(labelText: 'CHAPTER NAME')), actions:[FilledButton(child: const Text('ADD'), onPressed: () { state.addCustomChapter(s, c.text); Navigator.pop(ctx); })]));
                }),
              )
            ],
          )),
          const SizedBox(height: 16),
          FilledButton(child: const Text('ADD SUBJECT'), onPressed: () {
            final c = TextEditingController();
            showDialog(context: context, builder: (ctx) => AlertDialog(content: TextField(controller: c), actions:[FilledButton(child: const Text('ADD'), onPressed: () { state.addCustomSubject(c.text); Navigator.pop(ctx); })]));
          }),
        ],
      ),
    );
  }
}
