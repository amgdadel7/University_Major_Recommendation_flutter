import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../recommendations/presentation/pages/recommendations_page.dart';
import '../../../universities/presentation/pages/universities_page.dart';
import '../../../applications/presentation/pages/applications_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';
import '../../widgets/custom_app_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
  
  static _MainPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainPageState>();
  }
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  
  final List<Widget> _pages = [
    const HomePage(),
    const RecommendationsPage(),
    const UniversitiesPage(),
    const ApplicationsListPage(),
    const ProfilePage(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'navigation.home', index: 0),
    _NavItem(icon: Icons.stars_rounded, label: 'navigation.recommendations', index: 1),
    _NavItem(icon: Icons.school_rounded, label: 'navigation.universities', index: 2),
    _NavItem(icon: Icons.description_rounded, label: 'navigation.applications', index: 3),
    _NavItem(icon: Icons.person_rounded, label: 'navigation.profile', index: 4),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void changeTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      // Restart animation for visual feedback
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: const CustomAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _ModernBottomNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: changeTab,
        isDark: isDark,
        animationController: _animationController,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final Function(int) onTap;
  final bool isDark;
  final AnimationController animationController;

  const _ModernBottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.isDark,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 70,
        borderRadius: 25,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark.withOpacity(0.3),
                  AppColors.secondaryDark.withOpacity(0.2),
                ]
              : [
                  AppColors.primaryLight.withOpacity(0.2),
                  AppColors.secondaryLight.withOpacity(0.1),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = currentIndex == item.index;
            return Expanded(
              child: _NavBarItem(
                item: item,
                isActive: isActive,
                onTap: () => onTap(item.index),
                isDark: isDark,
                animationDelay: item.index * 50,
                animationController: animationController,
              ),
            );
          }).toList(),
        ),
      )
          .animate(controller: animationController)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final int animationDelay;
  final AnimationController animationController;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    required this.animationDelay,
    required this.animationController,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.isActive) {
      _bounceController.forward();
    }
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _bounceController.forward(from: 0);
      } else {
        _bounceController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_bounceController.value * 0.15),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.isActive
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.isDark
                                    ? [
                                        AppColors.primaryDark,
                                        AppColors.secondaryDark,
                                      ]
                                    : [
                                        AppColors.primaryLight,
                                        AppColors.secondaryLight,
                                      ],
                              )
                            : null,
                        color: widget.isActive
                            ? null
                            : Colors.transparent,
                        boxShadow: widget.isActive
                            ? [
                                BoxShadow(
                                  color: (widget.isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.item.icon,
                        color: widget.isActive
                            ? Colors.white
                            : (widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.isActive ? 11 : 10,
                    fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                    color: widget.isActive
                        ? (widget.isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight)
                        : (widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                  child: Text(
                    widget.item.label.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate(controller: widget.animationController)
                    .fadeIn(
                      delay: widget.animationDelay.ms,
                      duration: 200.ms,
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: widget.animationDelay.ms,
                      duration: 200.ms,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

