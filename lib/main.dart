import 'dart:async';
import 'dart:convert';
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
// CONSTANTS & THEME
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: inkBlack, width: 2),
    ),
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
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 2),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 2),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 3),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: paperBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: Colors.black, width: 3),
    ),
  ),
  dividerTheme: DividerThemeData(color: inkBlack, thickness: 2),
);

// ==========================================
// MODELS
// ==========================================
enum SessionType { normal, important, intense }
enum SessionStatus { scheduled, active, completed, missed }

class UserProfile {
  final String id;
  String name;
  List<String> customSubjects;

  UserProfile({
    required this.id,
    required this.name,
    required this.customSubjects,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        customSubjects: List<String>.from(json['customSubjects'] ??[]),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'customSubjects': customSubjects,
      };
}

class Goal {
  String id;
  String text;
  bool isFinished;

  Goal({required this.id, required this.text, this.isFinished = false});

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        text: json['text'],
        isFinished: json['isFinished'] ?? false,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isFinished': isFinished,
      };
}

class Remark {
  String id;
  String text;
  int timestamp;
  String relativeTimeString;

  Remark({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.relativeTimeString,
  });

  factory Remark.fromJson(Map<String, dynamic> json) => Remark(
        id: json['id'],
        text: json['text'],
        timestamp: json['timestamp'],
        relativeTimeString: json['relativeTimeString'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'timestamp': timestamp,
        'relativeTimeString': relativeTimeString,
      };
}

class StudySession {
  String id;
  String name;
  String description;
  int scheduledStartTime; // epoch
  int scheduledDurationMinutes;
  int actualDurationSeconds;
  SessionType type;
  String subject;
  List<Goal> goals;
  List<Remark> remarks;
  SessionStatus status;
  int? completionTime; // epoch

  StudySession({
    required this.id,
    required this.name,
    required this.description,
    required this.scheduledStartTime,
    required this.scheduledDurationMinutes,
    this.actualDurationSeconds = 0,
    required this.type,
    required this.subject,
    required this.goals,
    required this.remarks,
    this.status = SessionStatus.scheduled,
    this.completionTime,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        scheduledStartTime: json['scheduledStartTime'],
        scheduledDurationMinutes: json['scheduledDurationMinutes'],
        actualDurationSeconds: json['actualDurationSeconds'] ?? 0,
        type: SessionType.values.firstWhere(
            (e) => e.toString() == json['type'],
            orElse: () => SessionType.normal),
        subject: json['subject'],
        goals: (json['goals'] as List).map((g) => Goal.fromJson(g)).toList(),
        remarks:
            (json['remarks'] as List).map((r) => Remark.fromJson(r)).toList(),
        status: SessionStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
            orElse: () => SessionStatus.scheduled),
        completionTime: json['completionTime'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'scheduledStartTime': scheduledStartTime,
        'scheduledDurationMinutes': scheduledDurationMinutes,
        'actualDurationSeconds': actualDurationSeconds,
        'type': type.toString(),
        'subject': subject,
        'goals': goals.map((g) => g.toJson()).toList(),
        'remarks': remarks.map((r) => r.toJson()).toList(),
        'status': status.toString(),
        'completionTime': completionTime,
      };

  String get dateId {
    final dt = DateTime.fromMillisecondsSinceEpoch(scheduledStartTime);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  String get weekId {
    final dt = DateTime.fromMillisecondsSinceEpoch(scheduledStartTime);
    final int dayToMonday = dt.weekday - 1;
    final monday = dt.subtract(Duration(days: dayToMonday));
    return DateFormat('yyyy-MM-dd').format(monday);
  }
}

class Preset {
  String id;
  String name;
  String description;
  int durationMinutes;
  SessionType type;
  String subject;
  List<Goal> defaultGoals;

  Preset({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.type,
    required this.subject,
    required this.defaultGoals,
  });

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        durationMinutes: json['durationMinutes'],
        type: SessionType.values.firstWhere(
            (e) => e.toString() == json['type'],
            orElse: () => SessionType.normal),
        subject: json['subject'],
        defaultGoals: (json['defaultGoals'] as List)
            .map((g) => Goal.fromJson(g))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'durationMinutes': durationMinutes,
        'type': type.toString(),
        'subject': subject,
        'defaultGoals': defaultGoals.map((g) => g.toJson()).toList(),
      };
}

class DayPlan {
  String id; // yyyy-MM-dd
  String customName;
  List<Goal> overallGoals;
  List<Remark> overallRemarks;

  DayPlan({
    required this.id,
    required this.customName,
    required this.overallGoals,
    required this.overallRemarks,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        id: json['id'],
        customName: json['customName'] ?? '',
        overallGoals: (json['overallGoals'] as List?)
                ?.map((g) => Goal.fromJson(g))
                .toList() ??
            [],
        overallRemarks: (json['overallRemarks'] as List?)
                ?.map((r) => Remark.fromJson(r))
                .toList() ??[],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'customName': customName,
        'overallGoals': overallGoals.map((g) => g.toJson()).toList(),
        'overallRemarks': overallRemarks.map((r) => r.toJson()).toList(),
      };
}

class WeekPlan {
  String id; // Monday's date yyyy-MM-dd
  String customName;
  List<Goal> overallGoals;
  List<Remark> overallRemarks;

  WeekPlan({
    required this.id,
    required this.customName,
    required this.overallGoals,
    required this.overallRemarks,
  });

  factory WeekPlan.fromJson(Map<String, dynamic> json) => WeekPlan(
        id: json['id'],
        customName: json['customName'] ?? '',
        overallGoals: (json['overallGoals'] as List?)
                ?.map((g) => Goal.fromJson(g))
                .toList() ??
            [],
        overallRemarks: (json['overallRemarks'] as List?)
                ?.map((r) => Remark.fromJson(r))
                .toList() ??[],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'customName': customName,
        'overallGoals': overallGoals.map((g) => g.toJson()).toList(),
        'overallRemarks': overallRemarks.map((r) => r.toJson()).toList(),
      };
}

// ==========================================
// STATE MANAGEMENT
// ==========================================
class PlannerState extends ChangeNotifier {
  List<UserProfile> _users =[];
  UserProfile? _currentUser;
  List<StudySession> _sessions = [];
  List<Preset> _presets =[];
  Map<String, DayPlan> _days = {};
  Map<String, WeekPlan> _weeks = {};
  bool _isLoading = true;
  Timer? _notificationTimer;

  List<UserProfile> get users => _users;
  UserProfile? get currentUser => _currentUser;
  List<StudySession> get sessions => _sessions;
  List<Preset> get presets => _presets;
  bool get isLoading => _isLoading;

  List<String> get availableSubjects {
    List<String> base = ['Math', 'Physics', 'Chemistry', 'Biology'];
    if (_currentUser != null) {
      base.addAll(_currentUser!.customSubjects);
    }
    return base.toSet().toList();
  }

  Future<void> initSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('sys_users_v2');
    if (usersJson != null) {
      _users = (jsonDecode(usersJson) as List)
          .map((u) => UserProfile.fromJson(u))
          .toList();
    }
    if (_users.isEmpty) {
      _users.add(UserProfile(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: 'STUDENT_01',
          customSubjects:[]));
      await prefs.setString(
          'sys_users_v2', jsonEncode(_users.map((u) => u.toJson()).toList()));
    }
    final lastUserId = prefs.getString('last_user_id_v2') ?? _users.first.id;
    _currentUser = _users.firstWhere((u) => u.id == lastUserId,
        orElse: () => _users.first);
    await loadUserData(_currentUser!.id);

    // Background checker for reminders
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    // In a pure dart non-manifest-modifying way, we can trigger an internal flag
    // to show a banner if app is open. True notifications require native modifications.
    // However, this state logic handles evaluating if a session is due soon.
    final now = DateTime.now();
    for (var s in _sessions) {
      if (s.status == SessionStatus.scheduled) {
        final start = DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime);
        final diff = start.difference(now).inMinutes;
        if (diff == 5 || diff == 0) {
          // Time to trigger logic (handled practically via UI listeners if needed)
          notifyListeners();
        }
      }
    }
  }

  Future<void> switchUser(String id) async {
    _isLoading = true;
    notifyListeners();
    _currentUser = _users.firstWhere((u) => u.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user_id_v2', _currentUser!.id);
    await loadUserData(_currentUser!.id);
  }

  Future<void> createUser(String name) async {
    final newUser = UserProfile(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        customSubjects:[]);
    _users.add(newUser);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sys_users_v2', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  Future<void> updateUserName(String newName) async {
    if (_currentUser == null) return;
    _currentUser!.name = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sys_users_v2', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  Future<void> addCustomSubject(String sub) async {
    if (_currentUser == null || _currentUser!.customSubjects.contains(sub)) return;
    _currentUser!.customSubjects.add(sub);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sys_users_v2', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  Future<void> removeCustomSubject(String sub) async {
    if (_currentUser == null) return;
    _currentUser!.customSubjects.remove(sub);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sys_users_v2', jsonEncode(_users.map((u) => u.toJson()).toList()));
    notifyListeners();
  }

  Future<void> loadUserData(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    final sJson = prefs.getString('sessions_$uid');
    _sessions = sJson != null
        ? (jsonDecode(sJson) as List).map((s) => StudySession.fromJson(s)).toList()
        :[];

    final pJson = prefs.getString('presets_$uid');
    _presets = pJson != null
        ? (jsonDecode(pJson) as List).map((p) => Preset.fromJson(p)).toList()
        :[];

    final dJson = prefs.getString('days_$uid');
    if (dJson != null) {
      final dec = jsonDecode(dJson) as Map<String, dynamic>;
      _days = dec.map((k, v) => MapEntry(k, DayPlan.fromJson(v)));
    } else {
      _days = {};
    }

    final wJson = prefs.getString('weeks_$uid');
    if (wJson != null) {
      final dec = jsonDecode(wJson) as Map<String, dynamic>;
      _weeks = dec.map((k, v) => MapEntry(k, WeekPlan.fromJson(v)));
    } else {
      _weeks = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserData() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sessions_$uid', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
    await prefs.setString(
        'presets_$uid', jsonEncode(_presets.map((p) => p.toJson()).toList()));
    await prefs.setString(
        'days_$uid', jsonEncode(_days.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setString(
        'weeks_$uid', jsonEncode(_weeks.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // --- Sessions Operations ---
  void addSession(StudySession session) {
    _sessions.add(session);
    _sessions.sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
    saveUserData();
    notifyListeners();
  }

  void updateSession(StudySession session) {
    int idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _sessions[idx] = session;
      saveUserData();
      notifyListeners();
    }
  }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    saveUserData();
    notifyListeners();
  }

  void markSessionActive(String id) {
    int idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sessions[idx].status = SessionStatus.active;
      saveUserData();
      notifyListeners();
    }
  }

  void completeSession(String id, int actualDurationSeconds, List<Goal> updatedGoals) {
    int idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sessions[idx].status = SessionStatus.completed;
      _sessions[idx].completionTime = DateTime.now().millisecondsSinceEpoch;
      _sessions[idx].actualDurationSeconds = actualDurationSeconds;
      _sessions[idx].goals = updatedGoals;
      saveUserData();
      notifyListeners();
    }
  }

  String calculateRelativeTime(StudySession s) {
    final now = DateTime.now();
    if (s.status == SessionStatus.scheduled) {
      final start = DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime);
      if (start.isAfter(now)) {
        final diff = start.difference(now);
        return "${diff.inHours}H ${diff.inMinutes % 60}M BEFORE";
      } else {
        return "DELAYED";
      }
    } else if (s.status == SessionStatus.completed) {
      final comp = DateTime.fromMillisecondsSinceEpoch(s.completionTime!);
      final diff = now.difference(comp);
      return "${diff.inHours}H ${diff.inMinutes % 60}M AFTER";
    }
    return "DURING ACTIVE SESSION";
  }

  void addRemarkToSession(String sessionId, String text) {
    int idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      final relTime = calculateRelativeTime(s);
      s.remarks.add(Remark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        relativeTimeString: relTime,
      ));
      saveUserData();
      notifyListeners();
    }
  }

  // --- Day/Week Operations ---
  DayPlan getDayPlan(String dateId) {
    if (!_days.containsKey(dateId)) {
      _days[dateId] = DayPlan(id: dateId, customName: '', overallGoals: [], overallRemarks:[]);
    }
    return _days[dateId]!;
  }

  void updateDayPlan(DayPlan plan) {
    _days[plan.id] = plan;
    saveUserData();
    notifyListeners();
  }

  WeekPlan getWeekPlan(String weekId) {
    if (!_weeks.containsKey(weekId)) {
      _weeks[weekId] = WeekPlan(id: weekId, customName: '', overallGoals: [], overallRemarks: []);
    }
    return _weeks[weekId]!;
  }

  void updateWeekPlan(WeekPlan plan) {
    _weeks[plan.id] = plan;
    saveUserData();
    notifyListeners();
  }

  // --- Presets ---
  void addPreset(Preset p) {
    _presets.add(p);
    saveUserData();
    notifyListeners();
  }

  void deletePreset(String id) {
    _presets.removeWhere((p) => p.id == id);
    saveUserData();
    notifyListeners();
  }
}

// ==========================================
// ROOT APP
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

// ==========================================
// NAVIGATION SCREEN
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const[
    DashboardScreen(),
    CalendarScreen(),
    RemarksBrowserScreen(),
    StatsScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    if (state.isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator(color: Colors.black)));
    }
    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: inkBlack, width: 3))),
        child: NavigationBar(
          backgroundColor: paperBg,
          indicatorColor: brassAccent.withOpacity(0.5),
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const[
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'TODAY'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'PLANNER'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'REMARKS'),
            NavigationDestination(icon: Icon(Icons.query_stats), label: 'STATS'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DASHBOARD SCREEN
// ==========================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySessions = state.sessions.where((s) => s.dateId == todayStr).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 3), color: steamGreen.withOpacity(0.2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text('OPERATOR: ${state.currentUser?.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                Text('TODAY: ${DateFormat('MMM dd, yyyy').format(DateTime.now()).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 8),
                Text('TOTAL SESSIONS: ${todaySessions.length}'),
                Text('COMPLETED: ${todaySessions.where((s) => s.status == SessionStatus.completed).length}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              const Text('TODAY\'S MANIFEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              OutlinedButton.icon(
                icon: const Icon(Icons.add), label: const Text('NEW PLAN'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionEditorScreen())),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (todaySessions.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('NO OPERATIONS SCHEDULED.')))
          else
            ...todaySessions.map((s) => _buildSessionCard(context, s)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, StudySession s) {
    Color tColor = s.type == SessionType.intense ? intensePurple : (s.type == SessionType.important ? importantBlue : inkBlack);
    bool isCompleted = s.status == SessionStatus.completed;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s))),
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: tColor, width: 8))),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Text(DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isCompleted ? steamGreen : inkBlack),
                    child: Text(s.status.name.toUpperCase(), style: TextStyle(color: paperBg, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${s.subject.toUpperCase()} | ${s.scheduledDurationMinutes} MINS'),
              if (!isCompleted && s.status != SessionStatus.active)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton(
                    onPressed: () {
                      context.read<PlannerState>().markSessionActive(s.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTimerScreen(session: s)));
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: const Text('INITIATE OPERATION'),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CALENDAR & DAY/WEEK PLANNER
// ==========================================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final dayId = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayPlan = state.getDayPlan(dayId);
    
    final int dayToMonday = _selectedDate.weekday - 1;
    final monday = _selectedDate.subtract(Duration(days: dayToMonday));
    final weekId = DateFormat('yyyy-MM-dd').format(monday);
    final weekPlan = state.getWeekPlan(weekId);

    final daySessions = state.sessions.where((s) => s.dateId == dayId).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          Container(
            padding: const EdgeInsets.all(16),
            color: inkBlack,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                    if (d != null) setState(() => _selectedDate = d);
                  },
                  child: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)))),
              ],
            ),
          ),
          TabBar(
            indicatorColor: brassAccent, labelColor: inkBlack, unselectedLabelColor: Colors.black54, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Courier'),
            tabs: const [Tab(text: 'DAY LOG'), Tab(text: 'WEEK LOG')],
          ),
          Expanded(
            child: TabBarView(
              children:[
                _buildDayView(context, state, dayPlan, daySessions),
                _buildWeekView(context, state, weekPlan, weekId),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDayView(BuildContext context, PlannerState state, DayPlan plan, List<StudySession> sessions) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:[
              Expanded(child: Text(plan.customName.isEmpty ? 'UNNAMED DAY' : plan.customName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _editDayNameDialog(context, state, plan)),
            ],
          ),
          const Divider(),
          const Text('DAY GOALS', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...plan.overallGoals.map((g) => CheckboxListTile(
            title: Text(g.text, style: TextStyle(decoration: g.isFinished ? TextDecoration.lineThrough : null)),
            value: g.isFinished,
            activeColor: inkBlack, checkColor: paperBg,
            onChanged: (v) { g.isFinished = v ?? false; state.updateDayPlan(plan); },
            secondary: IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () { plan.overallGoals.remove(g); state.updateDayPlan(plan); }),
          )),
          FilledButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('ADD GOAL'), onPressed: () => _addDayGoalDialog(context, state, plan)),
          const SizedBox(height: 24),
          const Text('DAY REMARKS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallRemarks.map((r) => Card(color: brassAccent.withOpacity(0.1), child: ListTile(title: Text(r.text), subtitle: Text(DateFormat('HH:mm a').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp))), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { plan.overallRemarks.remove(r); state.updateDayPlan(plan); })))),
          FilledButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('ADD REMARK'), onPressed: () => _addDayRemarkDialog(context, state, plan)),
          const SizedBox(height: 24),
          const Text('SCHEDULED SESSIONS', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          sessions.isEmpty ? const Text('NO SESSIONS.') : Column(children: sessions.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.subject} | ${s.status.name.toUpperCase()}'),
            trailing: OutlinedButton(child: const Text('OPEN'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)))),
          )).toList())
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, PlannerState state, WeekPlan plan, String weekId) {
    final wkSessions = state.sessions.where((s) => s.weekId == weekId).toList();
    int wkHours = wkSessions.where((s) => s.status == SessionStatus.completed).fold(0, (sum, s) => sum + s.actualDurationSeconds) ~/ 3600;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:[
              Expanded(child: Text(plan.customName.isEmpty ? 'UNNAMED WEEK' : plan.customName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _editWeekNameDialog(context, state, plan)),
            ],
          ),
          Text('COMPLETED SESSIONS: ${wkSessions.where((s) => s.status == SessionStatus.completed).length} | HOURS: $wkHours'),
          const Divider(),
          const Text('WEEK GOALS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallGoals.map((g) => CheckboxListTile(
            title: Text(g.text, style: TextStyle(decoration: g.isFinished ? TextDecoration.lineThrough : null)),
            value: g.isFinished, activeColor: inkBlack,
            onChanged: (v) { g.isFinished = v ?? false; state.updateWeekPlan(plan); },
            secondary: IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () { plan.overallGoals.remove(g); state.updateWeekPlan(plan); }),
          )),
          FilledButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('ADD GOAL'), onPressed: () => _addWeekGoalDialog(context, state, plan)),
          const SizedBox(height: 24),
          const Text('WEEK REMARKS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plan.overallRemarks.map((r) => Card(color: intensePurple.withOpacity(0.1), child: ListTile(title: Text(r.text), subtitle: Text(DateFormat('EEE, HH:mm a').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp))), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { plan.overallRemarks.remove(r); state.updateWeekPlan(plan); })))),
          FilledButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('ADD REMARK'), onPressed: () => _addWeekRemarkDialog(context, state, plan)),
        ],
      ),
    );
  }

  void _editDayNameDialog(BuildContext context, PlannerState state, DayPlan plan) {
    final ctrl = TextEditingController(text: plan.customName);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('EDIT DAY NAME'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { plan.customName = ctrl.text.trim(); state.updateDayPlan(plan); Navigator.pop(ctx); }, child: const Text('SAVE'))]));
  }
  void _addDayGoalDialog(BuildContext context, PlannerState state, DayPlan plan) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW GOAL'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) { plan.overallGoals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: ctrl.text)); state.updateDayPlan(plan); } Navigator.pop(ctx); }, child: const Text('ADD'))]));
  }
  void _addDayRemarkDialog(BuildContext context, PlannerState state, DayPlan plan) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW REMARK'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) { plan.overallRemarks.add(Remark(id: DateTime.now().millisecondsSinceEpoch.toString(), text: ctrl.text, timestamp: DateTime.now().millisecondsSinceEpoch, relativeTimeString: 'Overall Day')); state.updateDayPlan(plan); } Navigator.pop(ctx); }, child: const Text('ADD'))]));
  }

  void _editWeekNameDialog(BuildContext context, PlannerState state, WeekPlan plan) {
    final ctrl = TextEditingController(text: plan.customName);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('EDIT WEEK NAME'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { plan.customName = ctrl.text.trim(); state.updateWeekPlan(plan); Navigator.pop(ctx); }, child: const Text('SAVE'))]));
  }
  void _addWeekGoalDialog(BuildContext context, PlannerState state, WeekPlan plan) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW GOAL'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) { plan.overallGoals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: ctrl.text)); state.updateWeekPlan(plan); } Navigator.pop(ctx); }, child: const Text('ADD'))]));
  }
  void _addWeekRemarkDialog(BuildContext context, PlannerState state, WeekPlan plan) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW REMARK'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) { plan.overallRemarks.add(Remark(id: DateTime.now().millisecondsSinceEpoch.toString(), text: ctrl.text, timestamp: DateTime.now().millisecondsSinceEpoch, relativeTimeString: 'Overall Week')); state.updateWeekPlan(plan); } Navigator.pop(ctx); }, child: const Text('ADD'))]));
  }
}

// ==========================================
// SESSION EDITOR / CREATOR
// ==========================================
class SessionEditorScreen extends StatefulWidget {
  final StudySession? existingSession;
  const SessionEditorScreen({super.key, this.existingSession});

  @override
  State<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends State<SessionEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durCtrl = TextEditingController();
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  SessionType _type = SessionType.normal;
  String? _subject;
  List<Goal> _goals =[];

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null) {
      final s = widget.existingSession!;
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description;
      _durCtrl.text = s.scheduledDurationMinutes.toString();
      _scheduledDate = DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime);
      _scheduledTime = TimeOfDay.fromDateTime(_scheduledDate);
      _type = s.type;
      _subject = s.subject;
      _goals = List.from(s.goals);
    }
  }

  void _save() {
    final state = context.read<PlannerState>();
    if (_nameCtrl.text.isEmpty || _durCtrl.text.isEmpty || _subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MISSING FIELDS'), backgroundColor: Colors.red));
      return;
    }
    final fullDt = DateTime(_scheduledDate.year, _scheduledDate.month, _scheduledDate.day, _scheduledTime.hour, _scheduledTime.minute);
    
    if (widget.existingSession != null) {
      final updated = widget.existingSession!;
      updated.name = _nameCtrl.text;
      updated.description = _descCtrl.text;
      updated.scheduledDurationMinutes = int.tryParse(_durCtrl.text) ?? 30;
      updated.scheduledStartTime = fullDt.millisecondsSinceEpoch;
      updated.type = _type;
      updated.subject = _subject!;
      updated.goals = _goals;
      state.updateSession(updated);
    } else {
      final newS = StudySession(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text, description: _descCtrl.text,
        scheduledStartTime: fullDt.millisecondsSinceEpoch,
        scheduledDurationMinutes: int.tryParse(_durCtrl.text) ?? 30,
        type: _type, subject: _subject!,
        goals: _goals, remarks:[],
      );
      state.addSession(newS);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    if (_subject == null && state.availableSubjects.isNotEmpty) _subject = state.availableSubjects.first;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existingSession == null ? 'CREATE MANIFEST' : 'EDIT MANIFEST')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'SESSION NAME')),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'DESCRIPTION')),
            const SizedBox(height: 16),
            Row(
              children:[
                Expanded(child: TextField(controller: _durCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DURATION (MIN)'))),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'SUBJECT'),
                  value: _subject,
                  items: state.availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _subject = v),
                ))
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SessionType>(
              decoration: const InputDecoration(labelText: 'INTENSITY TYPE'),
              value: _type,
              items: SessionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children:[
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.calendar_today), label: Text(DateFormat('yyyy-MM-dd').format(_scheduledDate)), onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _scheduledDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2035));
                  if(d!=null) setState(() => _scheduledDate = d);
                })),
                const SizedBox(width: 16),
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.access_time), label: Text(_scheduledTime.format(context)), onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: _scheduledTime);
                  if(t!=null) setState(() => _scheduledTime = t);
                })),
              ],
            ),
            const SizedBox(height: 24),
            const Text('SESSION GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ..._goals.map((g) => Card(child: ListTile(title: Text(g.text), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _goals.remove(g)))))),
            FilledButton.icon(
              icon: const Icon(Icons.add), label: const Text('ADD GOAL'),
              onPressed: () {
                final c = TextEditingController();
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('NEW GOAL'), content: TextField(controller: c),
                  actions:[
                    OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                    FilledButton(onPressed: () { if(c.text.isNotEmpty) setState(() => _goals.add(Goal(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text))); Navigator.pop(ctx); }, child: const Text('ADD'))
                  ]
                ));
              },
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _save, child: const Text('SAVE CONFIGURATION')),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SESSION DETAIL SCREEN
// ==========================================
class SessionDetailScreen extends StatelessWidget {
  final StudySession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final s = state.sessions.firstWhere((x) => x.id == session.id, orElse: () => session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DATA RECORD'),
        actions:[
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionEditorScreen(existingSession: s)))),
          IconButton(icon: const Icon(Icons.delete), onPressed: () { state.deleteSession(s.id); Navigator.pop(context); }),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
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
                  Text('STATUS: ${s.status.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: s.status == SessionStatus.completed ? steamGreen : rustRed)),
                  Text('SCHEDULED: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))}'),
                  Text('PLANNED DUR: ${s.scheduledDurationMinutes} MINS'),
                  if(s.status == SessionStatus.completed) Text('ACTUAL DUR: ${(s.actualDurationSeconds/60).toStringAsFixed(1)} MINS'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (s.status == SessionStatus.scheduled)
              FilledButton(
                onPressed: () {
                  state.markSessionActive(s.id);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActiveTimerScreen(session: s)));
                },
                child: const Text('INITIATE OPERATION'),
              ),
            const SizedBox(height: 24),
            const Text('GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...s.goals.map((g) => ListTile(
              leading: Icon(g.isFinished ? Icons.check_box : Icons.check_box_outline_blank, color: inkBlack),
              title: Text(g.text, style: TextStyle(decoration: g.isFinished ? TextDecoration.lineThrough : null)),
            )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                const Text('REMARKS LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.add_comment), onPressed: () {
                  final ctrl = TextEditingController();
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('ADD REMARK'), content: TextField(controller: ctrl),
                    actions:[
                      OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                      FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) state.addRemarkToSession(s.id, ctrl.text); Navigator.pop(ctx); }, child: const Text('ADD'))
                    ]
                  ));
                })
              ],
            ),
            ...s.remarks.map((r) => Card(child: ListTile(
              title: Text(r.text),
              subtitle: Text('${DateFormat('MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp))} [${r.relativeTimeString}]', style: const TextStyle(fontSize: 10)),
            ))),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ACTIVE TIMER SCREEN
// ==========================================
class ActiveTimerScreen extends StatefulWidget {
  final StudySession session;
  const ActiveTimerScreen({super.key, required this.session});
  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  int _elapsedSeconds = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _elapsedSeconds++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _finishSession() {
    _timer.cancel();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SessionWrapUpScreen(session: widget.session, actualSeconds: _elapsedSeconds)));
  }

  @override
  Widget build(BuildContext context) {
    int plannedSeconds = widget.session.scheduledDurationMinutes * 60;
    double progress = plannedSeconds > 0 ? (_elapsedSeconds / plannedSeconds).clamp(0.0, 1.0) : 0;
    String timeStr = '${(_elapsedSeconds ~/ 3600).toString().padLeft(2, '0')}:${((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: inkBlack,
      body: SafeArea(
        child: Column(
          children:[
            LinearProgressIndicator(value: progress, color: brassAccent, backgroundColor: inkBlack, minHeight: 10),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Text('ACTIVE OPERATION', style: TextStyle(color: brassAccent, fontSize: 18, letterSpacing: 4)),
                    const SizedBox(height: 16),
                    Text(widget.session.name.toUpperCase(), style: TextStyle(color: paperBg, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 48),
                    Text(timeStr, style: TextStyle(color: paperBg, fontSize: 64, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                    const SizedBox(height: 16),
                    Text('PLANNED: ${widget.session.scheduledDurationMinutes} MIN', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children:[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: paperBg, side: BorderSide(color: paperBg, width: 2)),
                      icon: const Icon(Icons.add_comment), label: const Text('LOG REMARK'),
                      onPressed: () {
                        final ctrl = TextEditingController();
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('QUICK REMARK'), content: TextField(controller: ctrl),
                          actions:[
                            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                            FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) context.read<PlannerState>().addRemarkToSession(widget.session.id, ctrl.text); Navigator.pop(ctx); }, child: const Text('ADD'))
                          ]
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: rustRed),
                      icon: const Icon(Icons.stop), label: const Text('TERMINATE'),
                      onPressed: _finishSession,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SESSION WRAP UP (POST-OP)
// ==========================================
class SessionWrapUpScreen extends StatefulWidget {
  final StudySession session;
  final int actualSeconds;
  const SessionWrapUpScreen({super.key, required this.session, required this.actualSeconds});
  @override
  State<SessionWrapUpScreen> createState() => _SessionWrapUpScreenState();
}

class _SessionWrapUpScreenState extends State<SessionWrapUpScreen> {
  late List<Goal> _goals;

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.session.goals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POST-OP REVIEW'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 3), color: brassAccent.withOpacity(0.2)),
              child: Column(
                children:[
                  const Text('OPERATION CONCLUDED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Divider(),
                  Text('TOTAL TIME: ${(widget.actualSeconds / 60).toStringAsFixed(1)} MIN'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('MARK COMPLETED GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ..._goals.map((g) => CheckboxListTile(
              title: Text(g.text, style: TextStyle(decoration: g.isFinished ? TextDecoration.lineThrough : null)),
              value: g.isFinished, activeColor: inkBlack,
              onChanged: (v) => setState(() => g.isFinished = v ?? false),
            )),
            const SizedBox(height: 24),
            const Text('FINAL REMARK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(hintText: 'Enter final thoughts...'),
              onSubmitted: (v) { if(v.isNotEmpty) context.read<PlannerState>().addRemarkToSession(widget.session.id, v); },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                context.read<PlannerState>().completeSession(widget.session.id, widget.actualSeconds, _goals);
                Navigator.pop(context);
              },
              child: const Text('SAVE & CLOSE RECORD'),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// REMARKS BROWSER (CLIPBOARD EXP)
// ==========================================
class RemarksBrowserScreen extends StatefulWidget {
  const RemarksBrowserScreen({super.key});
  @override
  State<RemarksBrowserScreen> createState() => _RemarksBrowserScreenState();
}

class _RemarksBrowserScreenState extends State<RemarksBrowserScreen> {
  final Set<String> _selectedSubjects = {};
  final Set<SessionType> _selectedTypes = {};
  bool _includeFinishedGoals = true;
  bool _includeUnfinishedGoals = true;
  bool _includeRemarks = true;

  void _exportToClipboard(PlannerState state) {
    List<StudySession> filtered = state.sessions.where((s) {
      if (_selectedSubjects.isNotEmpty && !_selectedSubjects.contains(s.subject)) return false;
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(s.type)) return false;
      return true;
    }).toList();

    StringBuffer sb = StringBuffer();
    sb.writeln("=== DATA EXPORT (${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}) ===");
    for (var s in filtered) {
      sb.writeln("\n> SESSION: ${s.name} [${s.subject}][${s.type.name.toUpperCase()}] (${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(s.scheduledStartTime))})");
      
      if (_includeFinishedGoals || _includeUnfinishedGoals) {
        sb.writeln("  --- GOALS ---");
        for (var g in s.goals) {
          if (g.isFinished && _includeFinishedGoals) sb.writeln("  [X] ${g.text}");
          if (!g.isFinished && _includeUnfinishedGoals) sb.writeln("  [ ] ${g.text}");
        }
      }
      
      if (_includeRemarks) {
        sb.writeln("  --- REMARKS ---");
        for (var r in s.remarks) {
          sb.writeln("  * ${r.text} (${r.relativeTimeString})");
        }
      }
    }

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DATA COPIED TO CLIPBOARD'), backgroundColor: Colors.black));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          const Text('DATA EXTRACTION MATRIX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                const Text('FILTERS', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('SUBJECTS'),
                Wrap(
                  spacing: 8,
                  children: state.availableSubjects.map((sub) => FilterChip(
                    label: Text(sub),
                    selected: _selectedSubjects.contains(sub),
                    onSelected: (val) => setState(() { val ? _selectedSubjects.add(sub) : _selectedSubjects.remove(sub); }),
                    backgroundColor: paperBg, selectedColor: brassAccent.withOpacity(0.5), shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.black)),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('TYPES'),
                Wrap(
                  spacing: 8,
                  children: SessionType.values.map((t) => FilterChip(
                    label: Text(t.name.toUpperCase()),
                    selected: _selectedTypes.contains(t),
                    onSelected: (val) => setState(() { val ? _selectedTypes.add(t) : _selectedTypes.remove(t); }),
                    backgroundColor: paperBg, selectedColor: intensePurple.withOpacity(0.5), shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.black)),
                  )).toList(),
                ),
                const Divider(),
                CheckboxListTile(title: const Text('INCLUDE FINISHED GOALS'), value: _includeFinishedGoals, activeColor: inkBlack, onChanged: (v) => setState(() => _includeFinishedGoals = v ?? false)),
                CheckboxListTile(title: const Text('INCLUDE UNFINISHED GOALS'), value: _includeUnfinishedGoals, activeColor: inkBlack, onChanged: (v) => setState(() => _includeUnfinishedGoals = v ?? false)),
                CheckboxListTile(title: const Text('INCLUDE REMARKS'), value: _includeRemarks, activeColor: inkBlack, onChanged: (v) => setState(() => _includeRemarks = v ?? false)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.copy), label: const Text('EXECUTE EXTRACTION TO CLIPBOARD'),
            onPressed: () => _exportToClipboard(state),
          ),
          const SizedBox(height: 32),
          const Text('GLOBAL REMARKS STREAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...state.sessions.expand((s) => s.remarks.map((r) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(r.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('SRC: ${s.name} | ${s.subject}'),
                  Text('TIME: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp))} | [${r.relativeTimeString}]', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          )))
        ],
      ),
    );
  }
}

// ==========================================
// STATS & GRAPHS
// ==========================================
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final completed = state.sessions.where((s) => s.status == SessionStatus.completed).toList();
    int totalSecs = completed.fold(0, (sum, s) => sum + s.actualDurationSeconds);
    double totalHours = totalSecs / 3600;

    int totalGoals = 0;
    int unfulfilledGoals = 0;
    for(var s in state.sessions) {
      totalGoals += s.goals.length;
      unfulfilledGoals += s.goals.where((g) => !g.isFinished).length;
    }

    Map<String, int> subjectCount = {};
    for(var s in state.sessions) { subjectCount[s.subject] = (subjectCount[s.subject] ?? 0) + 1; }
    
    List<PieChartSectionData> pieData =[];
    int i = 0;
    final colors = [inkBlack, brassAccent, rustRed, steamGreen, intensePurple, importantBlue];
    subjectCount.forEach((key, value) {
      pieData.add(PieChartSectionData(value: value.toDouble(), title: key, color: colors[i % colors.length], radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)));
      i++;
    });

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          const Text('GLOBAL STATISTICS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children:[
              Expanded(child: _buildStatBox('HOURS STUDIED', totalHours.toStringAsFixed(1))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBox('SESSIONS COMP', completed.length.toString())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children:[
              Expanded(child: _buildStatBox('UNFULFILLED GOALS', unfulfilledGoals.toString(), color: rustRed.withOpacity(0.2))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBox('TOTAL GOALS', totalGoals.toString())),
            ],
          ),
          const SizedBox(height: 32),
          const Text('SUBJECT DISTRIBUTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          if (pieData.isNotEmpty)
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: pieData)),
            )
          else
            const Text('NO DATA FOR GRAPH'),
          const SizedBox(height: 32),
          const Text('UNFINISHED GOALS REGISTRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...state.sessions.expand((s) => s.goals.where((g) => !g.isFinished).map((g) => ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text(g.text),
            subtitle: Text('SRC: ${s.name} (${s.subject})'),
          )))
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: inkBlack, width: 2), color: color ?? paperBg),
      child: Column(
        children:[
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
          Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ==========================================
// PROFILE, SETTINGS & PRESETS
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final user = state.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          const Text('OPERATOR SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children:[
                  const Icon(Icons.person, size: 64),
                  const SizedBox(height: 8),
                  Text(user?.name ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  OutlinedButton(onPressed: () => _renameDialog(context, state), child: const Text('RENAME')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('SYSTEM ACCOUNTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ...state.users.map((u) => ListTile(
            title: Text(u.name),
            trailing: u.id == user?.id ? const Icon(Icons.check_circle) : OutlinedButton(onPressed: () => state.switchUser(u.id), child: const Text('SWITCH')),
          )),
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('NEW OPERATOR'), onPressed: () => _newUserDialog(context, state)),
          const SizedBox(height: 24),
          const Text('CUSTOM SUBJECTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (user != null)
            ...user.customSubjects.map((s) => ListTile(title: Text(s), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => state.removeCustomSubject(s)))),
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('ADD SUBJECT'), onPressed: () => _newSubjectDialog(context, state)),
          const SizedBox(height: 24),
          const Text('PRESETS CONFIGURATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ...state.presets.map((p) => Card(child: ListTile(
            title: Text(p.name), subtitle: Text('${p.subject} | ${p.durationMinutes}m'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                IconButton(icon: const Icon(Icons.schedule), onPressed: () => _schedulePresetDialog(context, state, p)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => state.deletePreset(p.id)),
              ],
            ),
          ))),
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('CREATE PRESET'), onPressed: () => _createPresetDialog(context, state)),
        ],
      ),
    );
  }

  void _renameDialog(BuildContext context, PlannerState state) {
    final ctrl = TextEditingController(text: state.currentUser?.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('RENAME'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) state.updateUserName(ctrl.text); Navigator.pop(ctx); }, child: const Text('SAVE'))]));
  }
  void _newUserDialog(BuildContext context, PlannerState state) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW OPERATOR'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) state.createUser(ctrl.text); Navigator.pop(ctx); }, child: const Text('CREATE'))]));
  }
  void _newSubjectDialog(BuildContext context, PlannerState state) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('NEW SUBJECT'), content: TextField(controller: ctrl), actions:[OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')), FilledButton(onPressed: () { if(ctrl.text.isNotEmpty) state.addCustomSubject(ctrl.text); Navigator.pop(ctx); }, child: const Text('ADD'))]));
  }

  void _createPresetDialog(BuildContext context, PlannerState state) {
    final nCtrl = TextEditingController();
    final dCtrl = TextEditingController();
    String? subj = state.availableSubjects.isNotEmpty ? state.availableSubjects.first : null;
    SessionType type = SessionType.normal;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      title: const Text('NEW PRESET'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'NAME')),
            const SizedBox(height: 8),
            TextField(controller: dCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DURATION (MIN)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: subj, items: state.availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => subj = v)),
            const SizedBox(height: 8),
            DropdownButtonFormField<SessionType>(value: type, items: SessionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(), onChanged: (v) => setState(() => type = v!)),
          ],
        ),
      ),
      actions:[
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        FilledButton(onPressed: () {
          if(nCtrl.text.isNotEmpty && dCtrl.text.isNotEmpty && subj != null) {
            state.addPreset(Preset(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nCtrl.text, description: '', durationMinutes: int.parse(dCtrl.text), type: type, subject: subj!, defaultGoals: []));
            Navigator.pop(ctx);
          }
        }, child: const Text('SAVE'))
      ]
    )));
  }

  void _schedulePresetDialog(BuildContext context, PlannerState state, Preset p) async {
    DateTime selDate = DateTime.now();
    TimeOfDay selTime = TimeOfDay.now();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      title: Text('SCHEDULE: ${p.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          OutlinedButton(child: Text(DateFormat('yyyy-MM-dd').format(selDate)), onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: selDate, firstDate: DateTime.now(), lastDate: DateTime(2035)); if(d!=null) setState(()=>selDate=d); }),
          const SizedBox(height: 8),
          OutlinedButton(child: Text(selTime.format(context)), onPressed: () async { final t = await showTimePicker(context: ctx, initialTime: selTime); if(t!=null) setState(()=>selTime=t); }),
        ],
      ),
      actions:[
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        FilledButton(onPressed: () {
          final fullDt = DateTime(selDate.year, selDate.month, selDate.day, selTime.hour, selTime.minute);
          state.addSession(StudySession(
            id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
            name: p.name, description: p.description,
            scheduledStartTime: fullDt.millisecondsSinceEpoch,
            scheduledDurationMinutes: p.durationMinutes,
            type: p.type, subject: p.subject, goals: List.from(p.defaultGoals), remarks: []
          ));
          Navigator.pop(ctx);
        }, child: const Text('SCHEDULE'))
      ]
    )));
  }
}
