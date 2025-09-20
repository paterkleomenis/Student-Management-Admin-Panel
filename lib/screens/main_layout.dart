import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../utils/desktop_constants.dart';
import '../widgets/simple_language_toggle.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({required this.child, super.key});
  final Widget child;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<NavigationItem> _getNavigationItems(LanguageService langService) => [
        NavigationItem(
          icon: Icons.dashboard,
          label: langService.dashboard,
          route: '/dashboard',
        ),
        NavigationItem(
          icon: Icons.school,
          label: langService.students,
          route: '/students',
        ),
        NavigationItem(
          icon: Icons.analytics,
          label: langService.reports,
          route: '/reports',
        ),
        NavigationItem(
          icon: Icons.settings,
          label: langService.settings,
          route: '/settings',
        ),
      ];

  Future<void> _signOut() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langService.logout),
        content: Text(langService.getString('auth.logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(langService.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(langService.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(langService.getString('auth.logout_error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).fullPath ?? '/dashboard';

    return Consumer<LanguageService>(
      builder: (context, langService, child) => Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isCollapsed ? 70 : DesktopConstants.sidebarWidth,
              child: _buildSidebar(currentLocation, langService),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(langService),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(String currentLocation, LanguageService langService) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(1, 0),
            ),
          ],
        ),
        child: _buildSidebarContent(currentLocation, langService),
      );

  Widget _buildSidebarContent(
    String currentLocation,
    LanguageService langService,
  ) {
    final navigationItems = _getNavigationItems(langService);

    return Column(
      children: [
        // Logo/Header
        Container(
          height: 70,
          padding: EdgeInsets.all(_isCollapsed ? 8.0 : 16.0),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showText = constraints.maxWidth > 120;
              return showText
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            langService.getString('app.admin_panel'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
            },
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: navigationItems.length,
            itemBuilder: (context, index) {
              final item = navigationItems[index];
              final isSelected = currentLocation.startsWith(item.route);

              return Container(
                margin: EdgeInsets.all(_isCollapsed ? 4.0 : 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      context.go(item.route);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isCollapsed ? 4.0 : 16.0,
                        vertical: _isCollapsed ? 8.0 : 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showText = constraints.maxWidth > 120;
                          return showText
                              ? Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      color: isSelected
                                          ? Colors.blue[600]
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        item.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.blue[600]
                                              : Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Icon(
                                    item.icon,
                                    color: isSelected
                                        ? Colors.blue[600]
                                        : Colors.grey[600],
                                    size: 18,
                                  ),
                                );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // User Profile Section
        Container(
          padding: EdgeInsets.all(_isCollapsed ? 4.0 : 16.0),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showUserInfo = constraints.maxWidth > 120;
              return showUserInfo
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    langService.getString('auth.admin_user'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    langService.getString('auth.administrator'),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout, size: 12),
                            label: Text(
                              langService.getString('auth.logout'),
                              style: const TextStyle(fontSize: 10),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 28),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: IconButton(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout, size: 16),
                        color: Colors.red[600],
                        tooltip: langService.getString('auth.logout'),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(LanguageService langService) => Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Collapse Button and Title
            Expanded(
              child: Row(
                children: [
                  // Collapse Button
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                      padding: const EdgeInsets.all(8),
                      iconSize: 20,
                      icon: Icon(
                        _isCollapsed ? Icons.menu : Icons.menu_open,
                        color: Colors.grey[600],
                      ),
                      tooltip: _isCollapsed
                          ? langService.getString('app.expand_sidebar')
                          : langService.getString('app.collapse_sidebar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Flexible(
                    child: Text(
                      langService.getString('app.admin_panel'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Right side: Language Toggle
            const SimpleLanguageToggle(),
          ],
        ),
      );
}

class NavigationItem {
  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;
}
