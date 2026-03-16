import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'tickets_screen.dart';
import 'wifi_settings_screen.dart';
import 'faq_chatbot_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<AnimationController> _animControllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _slideAnims;
  late final List<Widget> _pages;

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      isHighlight: false,
    ),
    _TabItem(
      icon: Icons.wifi_outlined,
      activeIcon: Icons.wifi_rounded,
      label: 'WiFi',
      isHighlight: false,
    ),
    _TabItem(
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number,
      label: 'Ticket',
      isHighlight: true,
    ),
    _TabItem(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy_rounded,
      label: 'FAQ Bot',
      isHighlight: false,
    ),
    _TabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
      isHighlight: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pages = const [
      HomeScreen(),
      WifiSettingsScreen(),
      TicketsScreen(),
      FaqChatbotScreen(),
      ProfileScreen(),
    ];

    _animControllers = List.generate(
      _tabs.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnims = _animControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.80), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.80, end: 1.12), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 25),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    _slideAnims = _animControllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -3,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    _animControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _animControllers) c.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _animControllers[_currentIndex].reset();
    _animControllers[index].forward(from: 0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        tabs: _tabs,
        scaleAnims: _scaleAnims,
        slideAnims: _slideAnims,
        onTap: _onTap,
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isHighlight;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isHighlight,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final List<Animation<double>> scaleAnims;
  final List<Animation<double>> slideAnims;
  final void Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.scaleAnims,
    required this.slideAnims,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // FIXED: tambah border atas tipis untuk pemisah visual bersih
        border: const Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(tabs.length, (i) {
              return Expanded(
                child: tabs[i].isHighlight
                    ? _HighlightTab(
                        tab: tabs[i],
                        isSelected: currentIndex == i,
                        scaleAnim: scaleAnims[i],
                        onTap: () => onTap(i),
                      )
                    : _NormalTab(
                        tab: tabs[i],
                        isSelected: currentIndex == i,
                        scaleAnim: scaleAnims[i],
                        slideAnim: slideAnims[i],
                        onTap: () => onTap(i),
                      ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NormalTab extends StatelessWidget {
  final _TabItem tab;
  final bool isSelected;
  final Animation<double> scaleAnim;
  final Animation<double> slideAnim;
  final VoidCallback onTap;

  const _NormalTab({
    required this.tab,
    required this.isSelected,
    required this.scaleAnim,
    required this.slideAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: scaleAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, isSelected ? slideAnim.value : 0),
          child: Transform.scale(
            scale: isSelected ? scaleAnim.value : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 46 : 36,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isSelected ? tab.activeIcon : tab.icon,
                    size: 22,
                    color: isSelected ? Colors.green : const Color(0xFFB0BEC5),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? Colors.green : const Color(0xFFB0BEC5),
                  ),
                  child: Text(tab.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightTab extends StatelessWidget {
  final _TabItem tab;
  final bool isSelected;
  final Animation<double> scaleAnim;
  final VoidCallback onTap;

  const _HighlightTab({
    required this.tab,
    required this.isSelected,
    required this.scaleAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: scaleAnim,
        builder: (_, __) => Transform.scale(
          scale: isSelected ? scaleAnim.value : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 58,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                        : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(isSelected ? 0.50 : 0.28),
                      blurRadius: isSelected ? 14 : 7,
                      spreadRadius: isSelected ? 1 : 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF2E7D32),
                ),
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
