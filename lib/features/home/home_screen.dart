import 'dart:math' as math;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:quizbit_2/core/services/locController.dart';
import 'package:quizbit_2/core/session/ProfileSession.dart';
import 'package:quizbit_2/core/utils/snackbar_helper.dart';
import 'package:quizbit_2/features/auth/auth_controller.dart';
import 'package:quizbit_2/features/auth/screens/login.dart';
import 'package:quizbit_2/features/home/home_controller.dart';
import 'package:quizbit_2/features/home/topic_controller.dart';
import 'package:quizbit_2/features/leaderboard/leaderboard_controller.dart';
import 'package:quizbit_2/features/profile/profile_screen.dart';
import 'package:quizbit_2/features/quizExplore/quiz_explore_enum.dart';
import 'package:quizbit_2/features/quizExplore/quiz_explore_screen.dart';
import 'package:quizbit_2/features/quizdetail/quizdetail_screen.dart';
import 'package:quizbit_2/models/profileModel.dart';
import 'package:quizbit_2/models/quizModel.dart';
import 'package:quizbit_2/widgets/custom_slideshow.dart';
import 'package:quizbit_2/widgets/homeDrawer.dart';
import 'package:quizbit_2/widgets/quiz_item.dart';
import 'dart:async';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // --- Minimal palette (3 colors only) ---
  static const Color kDark = Color(0xFF1E2236);       // deep navy/charcoal
  static const Color kAccent = Color(0xFFFF7A3D);     // warm orange
  static const Color kBg = Color(0xFFFAF7F2);         // soft cream
  static const Color kSoft = Color(0xFFEFEAE2);       // muted card bg
  static const Color kMuted = Color(0xFF8A8A95);      // secondary text

  // --- Animations ---
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  // --- Controllers ---
  final LocationController _locationController = LocationController();
  final LeaderboardController leaderboardController = LeaderboardController();
  final AuthController authController = AuthController();
  final AuthController _controller = AuthController();
  final homeController = HomeController();
  final _topicCtrl = TextEditingController();
  final _topicController = TopicController();

  List<ProfileModel> top4Users = [];
  bool isLoading = false;
  String? error;
  bool _submittingtopic = false;

  initLocation() async {
    try {
      await _locationController.saveLocation();
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, "Location Error : ${e.toString()}");
    }
  }

  fetchTop4Users() async {
    final profiles = await leaderboardController.loadTop4Home();
    if (!mounted) return;
    setState(() => top4Users = profiles);
  }

  intiCreateSession() async {
    await authController.handleUserProfile();
  }

  loadHomeScreen() async {
    await homeController.loadHome();
    if (!mounted) return;
    setState(() {});
    _fadeController.forward();
  }

  Future<void> _logout() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    bool success = await _controller.logout();
    setState(() {
      isLoading = false;
      error = _controller.errorMessage;
    });
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> _submitTopic() async {
    if (_submittingtopic) return;
    setState(() => _submittingtopic = true);
    final result = await _topicController.submitTopic(_topicCtrl.text);
    if (!mounted) return;
    setState(() => _submittingtopic = false);

    if (result.success) {
      _topicCtrl.clear();
      SnackbarHelper.showSucess(context, result.message);
    } else {
      SnackbarHelper.showError(context, result.message);
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.97, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    intiCreateSession();
    initLocation();
    fetchTop4Users();
    loadHomeScreen();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ---- Helpers ----
  int _safeLen(List list, [int max = 15]) =>
      list.isEmpty ? 0 : math.min(list.length, max);

  Widget _animated(Widget child, {double delay = 0}) {
    final start = delay.clamp(0.0, 0.9);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _fadeController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  // ---- Section header (minimal) ----
  Widget _sectionHeader(String title, {String? subtitle, VoidCallback? onMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                  height: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "See all",
                  style: TextStyle(
                    color: kAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: kAccent),
              ],
            ),
          ),
      ],
    );
  }

  // ---- Top players (single-theme rings) ----
  Widget _topPlayers() {
    if (top4Users.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            "No champions yet — be the first!",
            style: TextStyle(color: kMuted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: top4Users.length,
        itemBuilder: (context, index) {
          final user = top4Users[index];
          final isFirst = index == 0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(profile_id: user.user_id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFirst ? kAccent : Colors.transparent,
                          border: isFirst
                              ? null
                              : Border.all(color: kSoft, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: kBg,
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage:
                                NetworkImage(user.profile_pic_url),
                          ),
                        ),
                      ),
                      // Rank chip — orange only for #1, dark for others
                      Positioned(
                        bottom: -4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFirst ? kAccent : kDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kBg, width: 2),
                            ),
                            child: Text(
                              "#${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 78,
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Horizontal quiz list ----
  Widget _quizRow(List<QuizModel> list) {
    final count = _safeLen(list, 15);
    if (count == 0) {
      return SizedBox(
        height: 270,
        child: Center(
          child: Text("Nothing here yet",
              style: TextStyle(color: kMuted)),
        ),
      );
    }
    return SizedBox(
      height: 270,
      child: ListView.separated(
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 60)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: QuizItem(quizModel: list[index]),
          );
        },
      ),
    );
  }

  // ---- Latest quiz hero (dark card, orange CTA) ----
  Widget _latestQuizCard() {
    final latest = homeController.newlyAdded;
    if (latest == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: kSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text("No latest quiz available",
              style: TextStyle(color: kMuted)),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizDetailScreen(quizModel: latest),
          ),
        );
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kDark.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background image with dark overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.network(
                    latest.quiz_cover_img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: kDark),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        kDark.withOpacity(0.95),
                        kDark.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "NEW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            latest.quiz_title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Tap to play now",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kAccent,
                          boxShadow: [
                            BoxShadow(
                              color: kAccent.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Topic submission (light card, orange accent) ----
  Widget _topicCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: kAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Suggest a Quiz",
                  style: TextStyle(
                    color: kDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Got an idea? Drop a topic and we'll build it for you.",
            style: TextStyle(color: kMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _topicCtrl,
                  enabled: !_submittingtopic,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: kDark),
                  onSubmitted: (value) => _submitTopic(),
                  decoration: InputDecoration(
                    hintText: "e.g. Space Exploration",
                    hintStyle: TextStyle(color: kMuted.withOpacity(0.7)),
                    filled: true,
                    fillColor: kBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _submittingtopic ? null : _submitTopic,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _submittingtopic
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (homeController.isLoading) {
      return _HomeLoadingSplash();
    }

    return Scaffold(
      backgroundColor: kBg,
      drawer: const HomeDrawer(),
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "QUIZBIT",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: kDark,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              " 2.0",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: kAccent,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: kDark),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _animated(
              CustomSlideshow(quizModels: homeController.random3Quiz),
              delay: 0.0,
            ),
            const SizedBox(height: 32),

            // Top players
            _animated(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      "Masters of QuizBit",
                      subtitle: "Top players this week",
                    ),
                    const SizedBox(height: 18),
                    _topPlayers(),
                  ],
                ),
              ),
              delay: 0.1,
            ),
            const SizedBox(height: 32),

            // Weekly Dhamaka
            _animated(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      "Weekly Dhamaka",
                      subtitle: "Fresh quizzes, just for you",
                      onMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizExploreScreen(
                                category: QuizCategory.newThisWeek),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _quizRow(homeController.weekelyDhamaka),
                  ],
                ),
              ),
              delay: 0.2,
            ),
            const SizedBox(height: 32),

            // Latest quiz hero
            _animated(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      "Latest Quiz",
                      subtitle: "Hot off the press",
                      onMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizExploreScreen(
                                category: QuizCategory.recentlyAdded),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _latestQuizCard(),
                  ],
                ),
              ),
              delay: 0.3,
            ),
            const SizedBox(height: 32),

            // Most played
            _animated(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      "Most Played",
                      subtitle: "Community favorites",
                      onMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizExploreScreen(
                                category: QuizCategory.mostPlayed),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _quizRow(homeController.mostPlayed),
                  ],
                ),
              ),
              delay: 0.4,
            ),
            const SizedBox(height: 32),

            // Topic submission
            _animated(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _topicCard(),
              ),
              delay: 0.5,
            ),

            const SizedBox(height: 48),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: kSoft,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "MADE WITH ",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kDark,
                              letterSpacing: 1,
                            ),
                          ),
                          Icon(Icons.favorite, color: kAccent, size: 14),
                          Text(
                            " BY",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "v1.0.0",
                          style: TextStyle(
                            fontSize: 11,
                            color: kDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kAccent,
                    ),
                    child: const CircleAvatar(
                      radius: 38,
                      backgroundImage: NetworkImage(
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFRuMxt2AcRvys2hE9KXrDWycKTSLUXZU7OA&s",
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Stay in Touch",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    children: [
                      _socialIcon(Icons.facebook_rounded),
                      _socialIcon(Icons.camera_alt_rounded),
                      _socialIcon(Icons.alternate_email_rounded),
                      _socialIcon(Icons.play_circle_fill_rounded),
                      _socialIcon(Icons.mail_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: kSoft, width: 1.5),
      ),
      child: Icon(icon, color: kDark, size: 18),
    );
  }
}


















class _HomeLoadingSplash extends StatefulWidget {
  const _HomeLoadingSplash();

  @override
  State<_HomeLoadingSplash> createState() => _HomeLoadingSplashState();
}

class _HomeLoadingSplashState extends State<_HomeLoadingSplash>
    with TickerProviderStateMixin {
  // --- Shared palette ---
  static const Color kDark = Color(0xFF1E2236);
  static const Color kAccent = Color(0xFFFF7A3D);
  static const Color kBg = Color(0xFFFAF7F2);
  static const Color kSoft = Color(0xFFEFEAE2);
  static const Color kMuted = Color(0xFF8A8A95);

  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _floatController;
  late final AnimationController _progressController;
  late final AnimationController _dotsController;

  late final Animation<double> _pulse;
  late final Animation<double> _logoBob;

  // Rotating loading messages
  final List<String> _messages = const [
    "Warming up the trivia engine",
    "Picking the perfect quizzes for you",
    "Sharpening the questions",
    "Setting up the leaderboard",
    "Almost ready",
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);
    _logoBob = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Rotate messages every 1.6s
    _messageTimer =
        Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Widget _bubble({
    required double size,
    required Color color,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final offset = ((_floatController.value + delay) % 1.0) * 2 - 1;
        return Transform.translate(
          offset: Offset(0, offset * 8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Decorative floating bubbles ----
            Positioned(
              top: 80,
              left: 40,
              child: _bubble(
                size: 10,
                color: kAccent.withOpacity(0.2),
                delay: 0.0,
              ),
            ),
            Positioned(
              top: 140,
              right: 50,
              child: _bubble(
                size: 6,
                color: kAccent.withOpacity(0.35),
                delay: 0.3,
              ),
            ),
            Positioned(
              top: 220,
              left: 70,
              child: _bubble(
                size: 8,
                color: kDark.withOpacity(0.15),
                delay: 0.6,
              ),
            ),
            Positioned(
              bottom: 180,
              right: 60,
              child: _bubble(
                size: 12,
                color: kAccent.withOpacity(0.18),
                delay: 0.8,
              ),
            ),
            Positioned(
              bottom: 260,
              left: 50,
              child: _bubble(
                size: 6,
                color: kDark.withOpacity(0.2),
                delay: 0.2,
              ),
            ),
            Positioned(
              top: 320,
              right: 80,
              child: _bubble(
                size: 5,
                color: kAccent.withOpacity(0.3),
                delay: 0.5,
              ),
            ),

            // ---- Main content ----
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ====== Logo with pulsing rings ======
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            return Container(
                              width: 130 + (_pulse.value * 60),
                              height: 130 + (_pulse.value * 60),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kAccent
                                    .withOpacity(0.08 * (1 - _pulse.value)),
                              ),
                            );
                          },
                        ),
                        // Middle pulse ring
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            return Container(
                              width: 100 + (_pulse.value * 40),
                              height: 100 + (_pulse.value * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kAccent
                                    .withOpacity(0.12 * (1 - _pulse.value)),
                              ),
                            );
                          },
                        ),
                        // Static soft disc
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kAccent.withOpacity(0.1),
                          ),
                        ),
                        // Rotating orbit ring (subtle)
                        AnimatedBuilder(
                          animation: _ringController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _ringController.value * 2 * 3.14159,
                              child: CustomPaint(
                                size: const Size(90, 90),
                                painter: _OrbitPainter(),
                              ),
                            );
                          },
                        ),
                        // Bouncing logo
                        AnimatedBuilder(
                          animation: _logoBob,
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, _logoBob.value),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: kAccent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kAccent.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ====== Wordmark ======
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "QuizBit",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: kDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        " 2.0",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: kAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ====== Status pill ======
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bolt_rounded, size: 11, color: kAccent),
                        SizedBox(width: 4),
                        Text(
                          "PREPARING YOUR EXPERIENCE",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: kAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ====== Rotating message ======
                  SizedBox(
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: Row(
                        key: ValueKey(_messageIndex),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _messages[_messageIndex],
                            style: const TextStyle(
                              fontSize: 13,
                              color: kDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            width: 18,
                            child: AnimatedBuilder(
                              animation: _dotsController,
                              builder: (context, _) {
                                final count =
                                    ((_dotsController.value * 4).floor() % 4);
                                return Text(
                                  "." * count,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kDark,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ====== Indeterminate progress bar ======
                  Container(
                    width: 220,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(220, 6),
                            painter: _ProgressBarPainter(
                              progress: _progressController.value,
                              color: kAccent,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ====== Tip line ======
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "💡 Tip: Save lifelines for the harder questions",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: kMuted.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Custom painters ----

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A3D).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw three arc segments around the circle
    for (int i = 0; i < 3; i++) {
      final startAngle = (i * 2 * 3.14159 / 3) - 1.5708;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        0.8, // arc length in radians
        false,
        paint,
      );
    }

    // Draw three small dots between arcs
    final dotPaint = Paint()
      ..color = const Color(0xFFFF7A3D)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * 3.14159 / 3) - 1.5708 + 1.0;
      final dx = center.dx + radius * (math.cos(angle));
      final dy = center.dy + radius * (math.sin(angle));
      canvas.drawCircle(Offset(dx, dy), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Animated traveling segment
    const segmentWidth = 80.0;
    final travelDistance = size.width + segmentWidth;
    final position = (progress * travelDistance) - segmentWidth;

    final rect = Rect.fromLTWH(position, 0, segmentWidth, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}