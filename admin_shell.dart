import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_account.dart';
import 'manage_accounts.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const Color navy = Color(0xFF001F3F);
  static const Color lightNavy = Color(0xFF1A3755);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color background = Color(0xFFF0F4F8);

  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.person_add_rounded,    label: 'Create Account'),
    _NavItem(icon: Icons.manage_accounts_rounded, label: 'Manage Accounts'),
    _NavItem(icon: Icons.receipt_long_rounded,  label: 'Justifications'),
    _NavItem(icon: Icons.bar_chart_rounded,     label: 'Statistics'),
    _NavItem(icon: Icons.settings_rounded,      label: 'Settings'),
  ];

  // Only first 2 are built — rest show coming soon
  Widget _buildPage(int index) {
    switch (index) {
      case 0: return const CreateAccountPage();
      case 1: return const ManageAccountsPage();
      default: return _ComingSoonPage(label: _navItems[index].label);
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: sidebar on wide screens, bottom nav on mobile
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: background,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ── DESKTOP: persistent sidebar ──────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(child: _buildPage(_selectedIndex)),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('PRESENT!',
              style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w900,
                fontSize: 20, letterSpacing: 2)),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Admin Panel',
              style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 40),

          // Nav items
          ...List.generate(_navItems.length, (i) => _buildSidebarItem(i)),

          const Spacer(),
          _buildSidebarItem(-1, isLogout: true),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, {bool isLogout = false}) {
    final bool isSel = !isLogout && _selectedIndex == index;
    final item = isLogout
      ? _NavItem(icon: Icons.logout_rounded, label: 'Logout')
      : _navItems[index];

    return GestureDetector(
      onTap: isLogout ? _handleLogout : () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSel ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(item.icon,
              color: isSel ? Colors.white : Colors.white54, size: 20),
            const SizedBox(width: 14),
            Text(item.label,
              style: GoogleFonts.inter(
                color: isSel ? Colors.white : Colors.white54,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MOBILE: bottom navbar ─────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildPage(_selectedIndex)),
        _buildBottomNav(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: lightGrey)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ..._navItems.asMap().entries.map((e) => _buildBottomNavItem(e.key, e.value)),
              _buildBottomNavItem(-1,
                _NavItem(icon: Icons.logout_rounded, label: 'Logout'),
                isLogout: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, _NavItem item, {bool isLogout = false}) {
    final bool isSel = !isLogout && _selectedIndex == index;
    return GestureDetector(
      onTap: isLogout ? _handleLogout : () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon,
              color: isSel ? navy : Colors.grey.shade400, size: 22),
            const SizedBox(height: 3),
            Text(item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? navy : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _ComingSoonPage extends StatelessWidget {
  final String label;
  const _ComingSoonPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: const Color(0xFF001F3F))),
          const SizedBox(height: 8),
          Text('Coming soon',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
