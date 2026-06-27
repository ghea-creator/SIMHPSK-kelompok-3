import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../login_screen.dart';
import 'register_screen.dart';
import '../widgets/landing_animations.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, String> _landingContent = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Scroll controller to track sticky navigation style
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isMobileMenuOpen = false;
  bool _hasStatSectionEntered = false;

  // Scroll to a specific section by its key/id (simulating HTML anchor)
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _fiturKey = GlobalKey();
  final GlobalKey _statistikKey = GlobalKey();
  final GlobalKey _caraKerjaKey = GlobalKey();
  final GlobalKey _testimoniKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  // ── Blob animation controllers (liquid morph effect) ──────────────────────
  late final AnimationController _blob1Ctrl;
  late final AnimationController _blob2Ctrl;
  late final AnimationController _blob3Ctrl;
  late final AnimationController _blob4Ctrl;
  late final AnimationController _blob5Ctrl;

  // Translate animations (dx, dy)
  late final Animation<Offset> _blob1Trans;
  late final Animation<Offset> _blob2Trans;
  late final Animation<Offset> _blob3Trans;
  late final Animation<Offset> _blob4Trans;
  late final Animation<Offset> _blob5Trans;

  // Rotation animations (radians)
  late final Animation<double> _blob1Rot;
  late final Animation<double> _blob2Rot;
  late final Animation<double> _blob3Rot;
  late final Animation<double> _blob4Rot;
  late final Animation<double> _blob5Rot;

  // ── Wave animation controllers (nullable to prevent hot restart crashes) ──
  AnimationController? _wave1Ctrl;
  AnimationController? _wave2Ctrl;

  @override
  void initState() {
    super.initState();
    // PENTING: init blob controllers PERTAMA sebelum apapun memanggil setState
    _initBlobAnimations();
    _scrollController.addListener(_onScroll);
    _loadLandingContent();
  }

  void _initBlobAnimations() {
    // Blob 1 — large green top-left (12s cycle)
    _blob1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat(reverse: true);
    _blob1Trans = Tween<Offset>(
      begin: const Offset(-20, -15),
      end: const Offset(80, 60),
    ).animate(CurvedAnimation(parent: _blob1Ctrl, curve: Curves.easeInOut));
    _blob1Rot = Tween<double>(begin: -0.12, end: 0.12)
        .animate(CurvedAnimation(parent: _blob1Ctrl, curve: Curves.easeInOut));

    // Blob 2 — amber top-right (7s, offset phase)
    _blob2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat(reverse: true);
    _blob2Trans = Tween<Offset>(
      begin: const Offset(15, -10),
      end: const Offset(-70, 90),
    ).animate(CurvedAnimation(parent: _blob2Ctrl, curve: Curves.easeInOut));
    _blob2Rot = Tween<double>(begin: 0.10, end: -0.10)
        .animate(CurvedAnimation(parent: _blob2Ctrl, curve: Curves.easeInOut));

    // Blob 3 — green bottom-center (16s)
    _blob3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    )..repeat(reverse: true);
    _blob3Trans = Tween<Offset>(
      begin: const Offset(-30, 20),
      end: const Offset(100, -80),
    ).animate(CurvedAnimation(parent: _blob3Ctrl, curve: Curves.easeInOut));
    _blob3Rot = Tween<double>(begin: -0.08, end: 0.08)
        .animate(CurvedAnimation(parent: _blob3Ctrl, curve: Curves.easeInOut));

    // Blob 4 — amber bottom-right (18s)
    _blob4Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat(reverse: true);
    _blob4Trans = Tween<Offset>(
      begin: const Offset(10, 15),
      end: const Offset(-60, -70),
    ).animate(CurvedAnimation(parent: _blob4Ctrl, curve: Curves.easeInOut));
    _blob4Rot = Tween<double>(begin: 0.07, end: -0.12)
        .animate(CurvedAnimation(parent: _blob4Ctrl, curve: Curves.easeInOut));

    // Blob 5 — small green bottom-left (14s)
    _blob5Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    )..repeat(reverse: true);
    _blob5Trans = Tween<Offset>(
      begin: const Offset(-15, 10),
      end: const Offset(50, -60),
    ).animate(CurvedAnimation(parent: _blob5Ctrl, curve: Curves.easeInOut));
    _blob5Rot = Tween<double>(begin: -0.06, end: 0.10)
        .animate(CurvedAnimation(parent: _blob5Ctrl, curve: Curves.easeInOut));

    // Wave controllers — continuous horizontal phase shift
    _wave1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(); // continuous forward, 0→1→0→1...
    _wave2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _blob1Ctrl.dispose();
    _blob2Ctrl.dispose();
    _blob3Ctrl.dispose();
    _blob4Ctrl.dispose();
    _blob5Ctrl.dispose();
    _wave1Ctrl?.dispose();
    _wave2Ctrl?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasStatSectionEntered && _scrollController.hasClients) {
      final context = _statistikKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero, ancestor: null);
          final viewportHeight = MediaQuery.of(context).size.height;
          final triggerPoint = viewportHeight * 0.35;

          if (position.dy <= triggerPoint) {
            setState(() {
              _hasStatSectionEntered = true;
            });
          }
        }
      }
    }

    if (_scrollController.hasClients) {
      final scrolled = _scrollController.offset > 30;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
    }
  }

  Future<void> _loadLandingContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getLandingContent();
      if (mounted) {
        setState(() {
          _landingContent = data?.map((key, value) => MapEntry(key, value?.toString() ?? '')) ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _landingValue(String key, String fallback) {
    final value = _landingContent[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  void _scrollToKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    if (Scrollable.maybeOf(targetContext) != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else if (_scrollController.hasClients) {
      final targetBox = targetContext.findRenderObject() as RenderBox?;
      final scrollBox = _scrollController.position.context.storageContext.findRenderObject() as RenderBox?;
      if (targetBox != null && scrollBox != null) {
        final targetOffset = targetBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy +
            _scrollController.offset;
        final alignedOffset = targetOffset.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          alignedOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    }

    setState(() {
      _isMobileMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE3), // Figma warm-bg
      body: Stack(
        children: [
          // Background Blobs (Liquid Morphs in Figma)
          Positioned.fill(
            child: _buildBackgroundBlobs(size),
          ),

          // Main Scroll View
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D6A4F),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Spacer for Navigation Bar height (70px)
                        const SizedBox(height: 70),

                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFFEE2E2),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFC0392B),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Hero Section
                        FadeSlideOnScroll(
                          child: Container(
                            key: _heroKey,
                            child: _buildHeroSection(context, isDesktop),
                          ),
                        ),

                        // Wave transition between Hero and Stats Section
                        _buildWaveTransition(const Color(0xFF1A3428), 0.97, true),

                        // Stats Section
                        Container(
                          key: _statistikKey,
                          child: _buildStatsSection(isDesktop),
                        ),

                        // Wave transition between Stats and Features Section
                        _buildWaveTransition(const Color(0xFFF2EDE3), 0.95, false),

                        // Features Section
                        Container(
                          key: _fiturKey,
                          child: _buildFeaturesSection(isDesktop),
                        ),

                        // Wave transition between Features and How It Works Section
                        _buildWaveTransition(const Color(0xFF1E3A2A), 0.9, true),

                        // How It Works Section
                        Container(
                          key: _caraKerjaKey,
                          child: _buildHowItWorksSection(isDesktop),
                        ),

                        // Wave transition between How It Works and Testimonials Section
                        _buildWaveTransition(const Color(0xFFF2EDE3), 0.9, false),

                        // Testimonials Section
                        FadeSlideOnScroll(
                          child: Container(
                            key: _testimoniKey,
                            child: _buildTestimonialsSection(isDesktop),
                          ),
                        ),

                        // Wave transition between Testimonials and CTA Section
                        _buildWaveTransition(const Color(0xFF1A3428), 0.92, true),

                        // CTA Section
                        FadeSlideOnScroll(
                          child: Container(
                            key: _ctaKey,
                            child: _buildCtaSection(context, isDesktop),
                          ),
                        ),

                        // Footer (No wave transition here, direct border line)
                        FadeSlideOnScroll(
                          child: _buildFooter(isDesktop),
                        ),
                      ],
                    ),
                  ),
          ),

          // Sticky Top Navigation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNavigation(context, isDesktop),
          ),

          // Mobile Drawer Overlay Menu
          if (_isMobileMenuOpen && !isDesktop)
            _buildMobileMenuOverlay(context),
        ],
      ),
    );
  }

  // 1. Animated Background Blobs (liquid morph)
  Widget _buildBackgroundBlobs(Size size) {
    return Stack(
      children: [
        // ── Blob 1 ── large green, top-left ────────────────────────────
        Positioned(
          top: -200,
          left: -200,
          width: 700,
          height: 700,
          child: AnimatedBuilder(
            animation: _blob1Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: _blob1Trans.value,
                child: Transform.rotate(
                  angle: _blob1Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.30,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      radius: 0.8,
                      colors: [
                        Color(0xFF74C69D),
                        Color(0xFF52B788),
                        Color(0xFF2D6A4F),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.38, 0.77, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 2 ── amber, top-right ─────────────────────────────────
        Positioned(
          top: 80,
          right: -150,
          width: 500,
          height: 500,
          child: AnimatedBuilder(
            animation: _blob2Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: _blob2Trans.value,
                child: Transform.rotate(
                  angle: _blob2Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.25,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0.2, 0.2),
                      radius: 0.8,
                      colors: [
                        Color(0xFFFCD34D),
                        Color(0xFFF59E0B),
                        Color(0xFFD97706),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.47, 0.82, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 3 ── green, bottom-center ─────────────────────────────
        Positioned(
          bottom: 40,
          left: size.width / 2 - 300,
          width: 600,
          height: 600,
          child: AnimatedBuilder(
            animation: _blob3Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: _blob3Trans.value,
                child: Transform.rotate(
                  angle: _blob3Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.28,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0.0, 0.2),
                      radius: 0.7,
                      colors: [
                        Color(0xFF52B788),
                        Color(0xFF2D6A4F),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.51, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 4 ── amber, bottom-right ──────────────────────────────
        Positioned(
          bottom: -30,
          right: size.width * 0.05,
          width: 380,
          height: 380,
          child: AnimatedBuilder(
            animation: _blob4Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: _blob4Trans.value,
                child: Transform.rotate(
                  angle: _blob4Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.22,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFD97706),
                        Color(0xFFF5A623),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.57, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 5 ── small green, bottom-left ─────────────────────────
        Positioned(
          bottom: 20,
          left: size.width * 0.03,
          width: 300,
          height: 300,
          child: AnimatedBuilder(
            animation: _blob5Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: _blob5Trans.value,
                child: Transform.rotate(
                  angle: _blob5Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF74C69D),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Wave transition renderer — animated ocean-like waves
  Widget _buildWaveTransition(Color fill, double opacity, bool isBottom) {
    if (_wave1Ctrl == null || _wave2Ctrl == null) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: Container(color: fill.withValues(alpha: opacity)),
      );
    }

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          // Wave layer 1 (background, slower)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _wave1Ctrl!,
              builder: (context, _) {
                return Opacity(
                  opacity: opacity * 0.45,
                  child: CustomPaint(
                    painter: _AnimatedWavePainter(
                      fill: fill,
                      phase: _wave1Ctrl!.value * 2 * 3.14159,
                      isBottom: isBottom,
                      isLayer2: false,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          // Wave layer 2 (foreground, faster)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _wave2Ctrl!,
              builder: (context, _) {
                return Opacity(
                  opacity: opacity,
                  child: CustomPaint(
                    painter: _AnimatedWavePainter(
                      fill: fill,
                      phase: _wave2Ctrl!.value * 2 * 3.14159,
                      isBottom: isBottom,
                      isLayer2: true,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 2. Navigation Bar
  Widget _buildNavigation(BuildContext context, bool isDesktop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 70,
      decoration: BoxDecoration(
        color: _isScrolled ? Colors.white.withValues(alpha: 0.95) : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: const Color(0xFF2C2314).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
        border: _isScrolled
            ? const Border(
                bottom: BorderSide(
                  color: Color(0x1A2C2314),
                  width: 1.0,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              GestureDetector(
                onTap: () => _scrollToKey(_heroKey),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SIMHPSK',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Color(0xFF1A3428),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Text(
                            'MANAJEMEN PERTANIAN',
                            style: TextStyle(
                              color: const Color(0xFF6B6050),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation Links (Desktop)
              if (isDesktop)
                Row(
                  children: [
                    _buildNavLink('Fitur', () => _scrollToKey(_fiturKey)),
                    const SizedBox(width: 28),
                    _buildNavLink('Statistik', () => _scrollToKey(_statistikKey)),
                    const SizedBox(width: 28),
                    _buildNavLink('Cara Kerja', () => _scrollToKey(_caraKerjaKey)),
                    const SizedBox(width: 28),
                    _buildNavLink('Ulasan', () => _scrollToKey(_testimoniKey)),
                  ],
                ),

              // Actions (Desktop)
              if (isDesktop)
                Row(
                  children: [
                    HoverButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    HoverButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          shadowColor: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mulai Gratis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Hamburger Menu Button (Mobile)
              if (!isDesktop)
                IconButton(
                  icon: Icon(
                    _isMobileMenuOpen ? Icons.close : Icons.menu,
                    color: const Color(0xFF374151),
                  ),
                  onPressed: () {
                    setState(() {
                      _isMobileMenuOpen = !_isMobileMenuOpen;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 14.4, // Matches 0.9rem
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Mobile Drawer Overlay Menu
  Widget _buildMobileMenuOverlay(BuildContext context) {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMobileMenuLink('Fitur', () => _scrollToKey(_fiturKey)),
                  _buildMobileMenuLink('Statistik', () => _scrollToKey(_statistikKey)),
                  _buildMobileMenuLink('Cara Kerja', () => _scrollToKey(_caraKerjaKey)),
                  _buildMobileMenuLink('Ulasan', () => _scrollToKey(_testimoniKey)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x1A2C2314)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isMobileMenuOpen = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isMobileMenuOpen = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Daftar Gratis',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMobileMenuOpen = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF52B788),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Hero Section
  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 48.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Badge
              FadeSlideOnScroll(
                delay: Duration.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x40166534), // 25% opacity
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dot animation representation
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D6A4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Platform Manajemen Pertanian Digital #1',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 100),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 42.0, // Matches clamp styling
                      color: Color(0xFF1A3428),
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                    children: [
                      TextSpan(text: '${_landingValue('hero_title', 'Kelola Pertanian')} '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _landingValue('hero_title_emphasis', 'Kentang'),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 42.0,
                                color: Color(0xFF2D6A4F),
                                letterSpacing: -1.0,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(220, 8),
                              painter: WaveUnderlinePainter(),
                            ),
                          ],
                        ),
                      ),
                      const TextSpan(text: '\nLebih '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                          ).createShader(bounds),
                          child: const Text(
                            'Cerdas',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 42.0,
                              color: Colors.white, // transparent fills from shader
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subtitle
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  _landingValue(
                    'hero_description',
                    'SIMHPSK hadir membantu petani mengelola panen, stok, penjualan, dan laporan keuangan — dalam satu platform yang modern, mudah, dan bisa diakses kapan saja dari HP.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.75,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // CTA buttons
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 300),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    HoverButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shadowColor: const Color(0xFF2D6A4F).withValues(alpha: 0.35),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mulai Sekarang — Gratis',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                    HoverButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0x262C2314), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Masuk ke Akun',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Trust Indicators
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 400),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTrustItem('✅', 'Tidak perlu kartu kredit'),
                    _buildTrustItem('🆓', 'Gratis selamanya'),
                    _buildTrustItem('🔒', 'Data aman & terenkripsi'),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Mockup Dashboard Illustration
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 500),
                child: HoverCard(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildMockupDashboard(isDesktop),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustItem(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B6050),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Dashboard mockup illustration matching Figma
  Widget _buildMockupDashboard(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.22),
            blurRadius: 100,
            offset: const Offset(0, 40),
          ),
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Browser header bar
          Container(
            color: const Color(0xFF1A3428),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Window controls dots
                Row(
                  children: [
                    _buildDot(const Color(0xFFC0392B)),
                    const SizedBox(width: 6),
                    _buildDot(const Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    _buildDot(const Color(0xFF52B788)),
                  ],
                ),
                const SizedBox(width: 16),
                // Browser address bar
                Expanded(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'simhpsk.app/dashboard',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Browser Body
          Container(
            color: const Color(0xFFF2EDE3),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Welcome card with background wave representation
                Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3428), Color(0xFF2D6A4F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Circular glow
                      Positioned(
                        right: -20,
                        top: -40,
                        width: 120,
                        height: 120,
                        child: Opacity(
                          opacity: 0.2,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0xFF74C69D), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang 👋',
                              style: TextStyle(
                                color: const Color(0xFFD4E8D0).withValues(alpha: 0.7),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Petani Kentang — Musim 1 · 2026',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Stats row
                isDesktop
                    ? Row(
                        children: [
                          Expanded(child: _buildMockStatCard('Stok Gudang', '4.500 kg', const Color(0xFFD97706), const Color(0xFFFEF3C7))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMockStatCard('Total Panen', '12.400 kg', const Color(0xFF166534), const Color(0xFFDCFCE7))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMockStatCard('Pendapatan', 'Rp 74,4 jt', const Color(0xFF1E40AF), const Color(0xFFDBEAFE))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMockStatCard('Est. Untung', 'Rp 28,6 jt', const Color(0xFF2D6A4F), const Color(0xFFE8F2EC))),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildMockStatCard('Stok Gudang', '4.500 kg', const Color(0xFFD97706), const Color(0xFFFEF3C7))),
                              const SizedBox(width: 10),
                              Expanded(child: _buildMockStatCard('Total Panen', '12.400 kg', const Color(0xFF166534), const Color(0xFFDCFCE7))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildMockStatCard('Pendapatan', 'Rp 74,4 jt', const Color(0xFF1E40AF), const Color(0xFFDBEAFE))),
                              const SizedBox(width: 10),
                              Expanded(child: _buildMockStatCard('Est. Untung', 'Rp 28,6 jt', const Color(0xFF2D6A4F), const Color(0xFFE8F2EC))),
                            ],
                          ),
                        ],
                      ),
                const SizedBox(height: 10),

                // Chart card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2C2314).withValues(alpha: 0.08),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grafik Panen & Penjualan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3428),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Bars container
                      SizedBox(
                        height: 56,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMockChartBar(0.6, true),
                            _buildMockChartBar(0.8, false),
                            _buildMockChartBar(0.45, true),
                            _buildMockChartBar(0.9, false),
                            _buildMockChartBar(0.7, true),
                            _buildMockChartBar(1.0, false),
                            _buildMockChartBar(0.75, true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Labels
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Jan', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Feb', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Mar', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Apr', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Mei', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Jun', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Jul', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMockStatCard(String label, String value, Color textCol, Color bgCol) {
    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B6050),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 15.2,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockChartBar(double heightFactor, bool isGreen) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: isGreen
                    ? [const Color(0xFF2D6A4F), const Color(0xFF52B788)]
                    : [const Color(0xFFD97706), const Color(0xFFF5A623)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. Stats Section
  Widget _buildStatsSection(bool isDesktop) {
    return FadeSlideOnScroll(
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1A3428),
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                const Text(
                  'Dipercaya Petani di Seluruh Jawa Tengah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 24, // Matches clamp
                    color: Color(0xFFD4E8D0),
                  ),
                ),
                const SizedBox(height: 40),
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: _buildStatItem(1200, '+', 'Petani Aktif', Icons.people_alt_rounded, delay: 0)),
                          Expanded(child: _buildStatItem(98, '%', 'Kepuasan Pengguna', Icons.star_rounded, delay: 100)),
                          Expanded(child: _buildStatItem(45, ' jt', 'Transaksi Tercatat', Icons.trending_up_rounded, delay: 200)),
                          Expanded(child: _buildStatItem(100, '%', 'Aman & Terenkripsi', Icons.shield_rounded, delay: 300)),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatItem(1200, '+', 'Petani Aktif', Icons.people_alt_rounded, delay: 0)),
                              Expanded(child: _buildStatItem(98, '%', 'Kepuasan', Icons.star_rounded, delay: 100)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildStatItem(45, ' jt', 'Transaksi', Icons.trending_up_rounded, delay: 200)),
                              Expanded(child: _buildStatItem(100, '%', 'Aman', Icons.shield_rounded, delay: 300)),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(int targetVal, String suffix, String label, IconData icon, {int delay = 0}) {
    return FadeSlideOnScroll(
      delay: Duration(milliseconds: delay),
      child: Column(
        children: [
          // Scale + Fade In icon when stat section becomes visible
          ScaleFadeOnScroll(
            duration: const Duration(milliseconds: 500),
            startScale: 0.9,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF52B788).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF52B788), size: 24),
            ),
          ),
          const SizedBox(height: 12),
        CountUpText(
          targetValue: targetVal,
          suffix: suffix,
          duration: const Duration(milliseconds: 2000),
          delay: Duration(milliseconds: delay + 300),
          start: _hasStatSectionEntered,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 32,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xB2D4E8D0), // 70% opacity
            fontSize: 13.1,
          ),
        ),
      ],
    ),
  );
}

  // 5. Features Section
  Widget _buildFeaturesSection(bool isDesktop) {
    final features = [
      {
        'title': _landingValue('feature_1_title', 'Pencatatan Panen'),
        'desc': _landingValue('feature_1_desc', 'Catat setiap hasil panen lengkap dengan foto, berat, dan keterangan blok kebun.'),
        'emoji': '🌾',
        'color': const Color(0xFF2D6A4F),
        'bg': const Color(0xFFE8F2EC)
      },
      {
        'title': _landingValue('feature_2_title', 'Manajemen Stok'),
        'desc': _landingValue('feature_2_desc', 'Pantau stok gudang secara real-time dengan notifikasi batas minimum otomatis.'),
        'emoji': '📦',
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7)
      },
      {
        'title': _landingValue('feature_3_title', 'Laporan Keuangan'),
        'desc': _landingValue('feature_3_desc', 'Hitung pendapatan, biaya produksi, dan estimasi untung-rugi per musim tanam.'),
        'emoji': '💰',
        'color': const Color(0xFF1E40AF),
        'bg': const Color(0xFFDBEAFE)
      },
      {
        'title': _landingValue('feature_4_title', 'Manajemen Penjualan'),
        'desc': _landingValue('feature_4_desc', 'Kelola transaksi penjualan dan data pembeli dalam satu platform terpadu.'),
        'emoji': '🛒',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFEDE9FE)
      },
      {
        'title': _landingValue('feature_5_title', 'Analitik & Grafik'),
        'desc': _landingValue('feature_5_desc', 'Visualisasi data panen dan penjualan dengan grafik interaktif yang mudah dipahami.'),
        'emoji': '📊',
        'color': const Color(0xFF0E7490),
        'bg': const Color(0xFFCFFAFE)
      },
      {
        'title': _landingValue('feature_6_title', 'Musim Tanam'),
        'desc': _landingValue('feature_6_desc', 'Atur dan pantau setiap periode musim tanam dengan riwayat lengkap.'),
        'emoji': '🌱',
        'color': const Color(0xFF166534),
        'bg': const Color(0xFFDCFCE7)
      },
    ];

    return FadeSlideOnScroll(
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF2EDE3),
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2EC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    '🌿 Fitur Lengkap',
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Semua yang Anda Butuhkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 28, // Matches clamp
                    color: Color(0xFF1A3428),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dari pencatatan panen hingga laporan keuangan, SIMHPSK menyediakan semua alat untuk petani modern.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 56),

                // Grid/Column list
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isDesktop ? 1.4 : 1.5,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    final f = features[index];
                    return FadeSlideOnScroll(
                      delay: Duration(milliseconds: 100 * index),
                      child: HoverCard(
                        child: _buildFeatureCard(
                          f['emoji'] as String,
                          f['title'] as String,
                          f['desc'] as String,
                          f['color'] as Color,
                          f['bg'] as Color,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String desc, Color color, Color bg) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C2314).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [color, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A3428),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. How It Works Section
  Widget _buildHowItWorksSection(bool isDesktop) {
    final steps = [
      {
        'num': '01',
        'emoji': '👤',
        'title': 'Daftar & Masuk',
        'desc': 'Buat akun gratis dalam hitungan menit.'
      },
      {
        'num': '02',
        'emoji': '📅',
        'title': 'Atur Musim Tanam',
        'desc': 'Tentukan periode dan blok kebun Anda.'
      },
      {
        'num': '03',
        'emoji': '✏️',
        'title': 'Catat Aktivitas',
        'desc': 'Rekam panen, transaksi, dan pengeluaran.'
      },
      {
        'num': '04',
        'emoji': '📈',
        'title': 'Analisis & Tumbuh',
        'desc': 'Gunakan laporan untuk keputusan lebih cerdas.'
      },
    ];

    return FadeSlideOnScroll(
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1E3A2A),
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52B788).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF52B788).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    '🚀 Cara Kerja',
                    style: TextStyle(
                      color: Color(0xFF74C69D),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mulai dalam 4 Langkah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 28, // Matches clamp
                    color: Color(0xFFD4E8D0),
                  ),
                ),
                const SizedBox(height: 56),

                // Steps Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isDesktop ? 1.0 : 1.25,
                  ),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final s = steps[index];
                    return FadeSlideOnScroll(
                      delay: Duration(milliseconds: 100 * index),
                      child: HoverCard(
                        child: _buildStepCard(
                          s['num']!,
                          s['emoji']!,
                          s['title']!,
                          s['desc']!,
                          index < steps.length - 1,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(String num, String emoji, String title, String desc, bool showNextArrow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          // Small radial gradient blob on top right
          Positioned(
            right: -32,
            top: -32,
            width: 96,
            height: 96,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF52B788), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number and emoji row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF52B788), Color(0xFF74C69D)],
                    ).createShader(bounds),
                    child: Text(
                      num,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 44.8, // Matches 2.8rem
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD4E8D0),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13.6, // Matches 0.85rem
                    color: const Color(0xFFD4E8D0).withValues(alpha: 0.6),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Testimonials Section
  Widget _buildTestimonialsSection(bool isDesktop) {
    final testimonials = [
      {
        'nama': 'Pak Hendra Wijaya',
        'lokasi': 'Wonosobo',
        'bintang': 5,
        'komentar': 'Aplikasi ini luar biasa mudah digunakan! Sekarang saya bisa pantau stok dan untung-rugi dengan mudah dari HP.',
        'avatar': '👨‍🌾'
      },
      {
        'nama': 'Bu Sari Dewi',
        'lokasi': 'Dieng, Jawa Tengah',
        'bintang': 5,
        'komentar': 'Sangat membantu untuk mencatat hasil panen. Tulisannya besar dan jelas, cocok untuk saya yang sudah tua.',
        'avatar': '👩‍🌾'
      },
      {
        'nama': 'Pak Bambang Susilo',
        'lokasi': 'Magelang',
        'bintang': 5,
        'komentar': 'Laporan keuangannya sangat detail. Saya jadi tahu persis berapa untung setiap musim panen.',
        'avatar': '🧑‍🌾'
      }
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF2EDE3),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF92400E).withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  '⭐ Ulasan Pengguna',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kata Mereka',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 28, // Matches clamp
                  color: Color(0xFF1A3428),
                ),
              ),
              const SizedBox(height: 56),

              // Testimonial Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: isDesktop ? 1.3 : 1.8,
                ),
                itemCount: testimonials.length,
                itemBuilder: (context, index) {
                  final t = testimonials[index];
                  return FadeSlideOnScroll(
                    delay: Duration(milliseconds: 120 * index),
                    child: HoverCard(
                      child: _buildTestimonialCard(
                        t['nama'] as String,
                        t['lokasi'] as String,
                        t['bintang'] as int,
                        t['komentar'] as String,
                        t['avatar'] as String,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(String name, String location, int stars, String comment, String avatar) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C2314).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top right small blob
          Positioned(
            right: -40,
            top: -40,
            width: 112,
            height: 112,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF52B788), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stars row
                Row(
                  children: List.generate(
                    stars,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Comment
                Expanded(
                  child: Text(
                    '"$comment"',
                    style: const TextStyle(
                      fontSize: 14.7, // Matches 0.92rem
                      color: Color(0xFF374151),
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  height: 1,
                  color: const Color(0xFF2C2314).withValues(alpha: 0.07),
                ),
                const SizedBox(height: 12),
                // Avatar + User Info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F2EC),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        avatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 14.4, // Matches 0.9rem
                            color: Color(0xFF1A3428),
                          ),
                        ),
                        Text(
                          '📍 $location',
                          style: const TextStyle(
                            fontSize: 12, // Matches 0.75rem
                            color: Color(0xFF6B6050),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. CTA Section
  Widget _buildCtaSection(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A3428),
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                '🌿',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Siap Kelola Pertanian\nLebih Cerdas?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 28.8, // Matches clamp
                  color: Color(0xFFD4E8D0),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bergabunglah dengan 1.200+ petani yang sudah menggunakan SIMHPSK dan rasakan perbedaannya.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xB2D4E8D0), // 70% opacity
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 40),

              // Buttons
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  HoverButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shadowColor: const Color(0xFF52B788).withValues(alpha: 0.35),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🚀 Daftar Sekarang — Gratis',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  HoverButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD4E8D0),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Sudah punya akun? Masuk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Trust points
              Wrap(
                spacing: 20,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildCtaTrustPoint('Tanpa kartu kredit'),
                  _buildCtaTrustPoint('Setup 5 menit'),
                  _buildCtaTrustPoint('Support 7 hari'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaTrustPoint(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF52B788),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.6, // Matches 0.85rem
            color: const Color(0xFFD4E8D0).withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  // 9. Footer Widget
  Widget _buildFooter(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDE3),
        border: Border(
          top: BorderSide(color: Color(0x1A2C2314), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFooterLogo(),
                    _buildFooterNav(),
                    _buildFooterCopyright(),
                  ],
                )
              : Column(
                  children: [
                    _buildFooterLogo(),
                    const SizedBox(height: 24),
                    _buildFooterNav(),
                    const SizedBox(height: 24),
                    _buildFooterCopyright(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooterLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), // rounded-xl
            gradient: const LinearGradient(
              colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIMHPSK',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 16, // Matches 1rem
                color: Color(0xFF1A3428),
              ),
            ),
            Text(
              'Sistem Informasi Manajemen Hasil Pertanian',
              style: TextStyle(
                fontSize: 11.2, // Matches 0.7rem
                color: Color(0xFF6B6050),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterNav() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFooterNavLink('Fitur', () => _scrollToKey(_fiturKey)),
        const SizedBox(width: 24),
        _buildFooterNavLink('Cara Kerja', () => _scrollToKey(_caraKerjaKey)),
        const SizedBox(width: 24),
        _buildFooterNavLink('Ulasan', () => _scrollToKey(_testimoniKey)),
      ],
    );
  }

  Widget _buildFooterNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.1, // Matches 0.82rem
          color: Color(0xFF6B6050),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooterCopyright() {
    return const Text(
      '© 2026 SIMHPSK. All rights reserved.',
      style: TextStyle(
        fontSize: 12.5, // Matches 0.78rem
        color: Color(0xFFA8A090),
      ),
    );
  }
}

// Waveunderline painter for the title accent
class WaveUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF52B788)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 4)
      ..cubicTo(25, 0, 50, 8, 75, 4)
      ..cubicTo(100, 0, 125, 8, 150, 4)
      ..cubicTo(175, 0, 200, 8, 220, 4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated wave painter — draws an undulating Bezier wave based on Figma's original paths
class _AnimatedWavePainter extends CustomPainter {
  final Color fill;
  final double phase;  // phase offset (radians)
  final bool isBottom; // true = Gs (fills down), false = Ly (fills up)
  final bool isLayer2; // true = foreground layer, false = background layer

  _AnimatedWavePainter({
    required this.fill,
    required this.phase,
    required this.isBottom,
    required this.isLayer2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fill;
    final path = Path();

    // Scale factors to fit size
    final w = size.width / 1440.0;
    final h = size.height / 120.0;

    // We oscillate the control points and endpoints vertically using sine of phase
    // each segment gets a slightly shifted phase to create a wave propagation effect
    final waveAmp = isLayer2 ? 8.0 * h : 13.0 * h; // amplitude of motion

    if (isBottom) {
      // ── Gs style wave (fills downward) ──
      if (!isLayer2) {
        // Gs Wave 1 animated Bezier
        final y0 = (60.0 + waveAmp * _sin(phase)) * h;
        final y1_c1 = (20.0 + waveAmp * _sin(phase + 1.0)) * h;
        final y1_c2 = (100.0 + waveAmp * _sin(phase + 2.0)) * h;
        final y1_end = (60.0 + waveAmp * _sin(phase + 3.0)) * h;

        final y2_c1 = (20.0 + waveAmp * _sin(phase + 4.0)) * h;
        final y2_c2 = (100.0 + waveAmp * _sin(phase + 5.0)) * h;
        final y2_end = (60.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y3_c1 = (20.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y3_c2 = (100.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y3_end = (60.0 + waveAmp * _sin(phase + 3.5)) * h;

        path.moveTo(0, y0);
        path.cubicTo(180 * w, y1_c1, 360 * w, y1_c2, 540 * w, y1_end);
        path.cubicTo(720 * w, y2_c1, 900 * w, y2_c2, 1080 * w, y2_end);
        path.cubicTo(1260 * w, y3_c1, 1440 * w, y3_c2, size.width, y3_end);
      } else {
        // Gs Wave 2 animated Bezier
        final y0 = (70.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y1_c1 = (30.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y1_c2 = (110.0 + waveAmp * _sin(phase + 3.5)) * h;
        final y1_end = (70.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y2_c1 = (30.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y2_c2 = (110.0 + waveAmp * _sin(phase + 2.2)) * h;
        final y2_end = (70.0 + waveAmp * _sin(phase + 3.2)) * h;

        final y3_c1 = (30.0 + waveAmp * _sin(phase + 0.2)) * h;
        final y3_c2 = (110.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y3_end = (70.0 + waveAmp * _sin(phase + 2.2)) * h;

        path.moveTo(0, y0);
        path.cubicTo(120 * w, y1_c1, 240 * w, y1_c2, 360 * w, y1_end);
        path.cubicTo(480 * w, y2_c1, 600 * w, y2_c2, 720 * w, y2_end);
        path.cubicTo(840 * w, y3_c1, 960 * w, y3_c2, 1080 * w, y3_end);
        path.cubicTo(1200 * w, y1_c1, 1320 * w, y1_c2, size.width, y1_end);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      // ── Ly style wave (fills upward) ──
      if (!isLayer2) {
        // Ly Wave 1 animated Bezier
        final y0 = (60.0 + waveAmp * _sin(phase)) * h;
        final y1_c1 = (100.0 + waveAmp * _sin(phase + 1.0)) * h;
        final y1_c2 = (20.0 + waveAmp * _sin(phase + 2.0)) * h;
        final y1_end = (60.0 + waveAmp * _sin(phase + 3.0)) * h;

        final y2_c1 = (100.0 + waveAmp * _sin(phase + 4.0)) * h;
        final y2_c2 = (20.0 + waveAmp * _sin(phase + 5.0)) * h;
        final y2_end = (60.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y3_c1 = (100.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y3_c2 = (20.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y3_end = (60.0 + waveAmp * _sin(phase + 3.5)) * h;

        path.moveTo(0, y0);
        path.cubicTo(180 * w, y1_c1, 360 * w, y1_c2, 540 * w, y1_end);
        path.cubicTo(720 * w, y2_c1, 900 * w, y2_c2, 1080 * w, y2_end);
        path.cubicTo(1260 * w, y3_c1, 1440 * w, y3_c2, size.width, y3_end);
      } else {
        // Ly Wave 2 animated Bezier
        final y0 = (70.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y1_c1 = (110.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y1_c2 = (30.0 + waveAmp * _sin(phase + 3.5)) * h;
        final y1_end = (70.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y2_c1 = (110.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y2_c2 = (30.0 + waveAmp * _sin(phase + 2.2)) * h;
        final y2_end = (70.0 + waveAmp * _sin(phase + 3.2)) * h;

        final y3_c1 = (110.0 + waveAmp * _sin(phase + 0.2)) * h;
        final y3_c2 = (30.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y3_end = (70.0 + waveAmp * _sin(phase + 2.2)) * h;

        path.moveTo(0, y0);
        path.cubicTo(120 * w, y1_c1, 240 * w, y1_c2, 360 * w, y1_end);
        path.cubicTo(480 * w, y2_c1, 600 * w, y2_c2, 720 * w, y2_end);
        path.cubicTo(840 * w, y3_c1, 960 * w, y3_c2, 1080 * w, y3_end);
        path.cubicTo(1200 * w, y1_c1, 1320 * w, y1_c2, size.width, y1_end);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  double _sin(double x) {
    double v = x % (2 * 3.14159);
    if (v < 0) v += 2 * 3.14159;
    if (v > 3.14159) v -= 2 * 3.14159;
    final x2 = v * v;
    return v * (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0 * (1.0 - x2 / 72.0))));
  }

  @override
  bool shouldRepaint(_AnimatedWavePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
