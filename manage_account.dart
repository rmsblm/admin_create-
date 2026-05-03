import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAccountsPage extends StatefulWidget {
  const ManageAccountsPage({super.key});

  @override
  State<ManageAccountsPage> createState() => _ManageAccountsPageState();
}

class _ManageAccountsPageState extends State<ManageAccountsPage>
    with SingleTickerProviderStateMixin {
  static const Color navy      = Color(0xFF001F3F);
  static const Color background = Color(0xFFEBF3FB);
  static const Color lightGrey  = Color(0xFFE2E8F0);
  static const Color textGrey   = Color(0xFF64748B);

  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manage Accounts',
                        style: GoogleFonts.inter(
                          fontSize: 26, fontWeight: FontWeight.bold, color: navy)),
                      const SizedBox(height: 4),
                      Text('Edit or delete teacher and student accounts',
                        style: GoogleFonts.inter(fontSize: 13, color: textGrey)),
                      const SizedBox(height: 20),

                      // Search bar
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: lightGrey)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: lightGrey)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: navy, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tabs
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: lightGrey),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: navy, borderRadius: BorderRadius.circular(11)),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                          labelColor: Colors.white,
                          unselectedLabelColor: textGrey,
                          tabs: const [
                            Tab(text: 'Teachers'),
                            Tab(text: 'Students'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _UserList(role: 'teacher', searchQuery: _searchQuery),
                      _UserList(role: 'student', searchQuery: _searchQuery),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── List of users ─────────────────────────────────────────────────────────────
class _UserList extends StatelessWidget {
  final String role;
  final String searchQuery;
  const _UserList({required this.role, required this.searchQuery});

  static const Color navy     = Color(0xFF001F3F);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color textGrey  = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No ${role}s found.',
              style: GoogleFonts.inter(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['profName'] ?? data['name'] ?? '').toString().toLowerCase();
          final id   = (data['userId'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery) || id.contains(searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text('No results for "$searchQuery"',
              style: GoogleFonts.inter(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _UserCard(docId: docs[i].id, data: data, role: role);
          },
        );
      },
    );
  }
}

// ── Single user card ──────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String role;

  const _UserCard({required this.docId, required this.data, required this.role});

  static const Color navy     = Color(0xFF001F3F);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color textGrey  = Color(0xFF64748B);

  String get _displayName =>
    (data['profName'] ?? data['name'] ?? 'Unknown').toString();

  String get _subtitle => role == 'teacher'
    ? '${data['grade'] ?? ''} • ID: ${data['userId'] ?? ''}'
    : '${data['year'] ?? ''} ${data['specialty'] ?? ''} • Sec ${data['section'] ?? ''} Gr ${data['group'] ?? ''} • ID: ${data['userId'] ?? ''}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: navy.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_displayName[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: navy, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 14, color: navy)),
                const SizedBox(height: 3),
                Text(_subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: textGrey)),
              ],
            ),
          ),

          // Edit button
          IconButton(
            icon: Icon(Icons.edit_outlined, color: navy.withOpacity(0.6), size: 20),
            onPressed: () => _showEditDialog(context),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
              color: Colors.red.shade300, size: 20),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy)),
        content: Text('This will permanently delete $_displayName\'s account.',
          style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
              style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('DELETE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EditDialog(docId: docId, data: data, role: role),
    );
  }
}

// ── Edit Dialog ───────────────────────────────────────────────────────────────
class _EditDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String role;
  const _EditDialog({required this.docId, required this.data, required this.role});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  static const Color navy = Color(0xFF001F3F);

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final nameKey = widget.role == 'teacher' ? 'profName' : 'name';
    _nameController = TextEditingController(text: widget.data[nameKey] ?? '');
    _emailController = TextEditingController(text: widget.data['email'] ?? '');
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final nameKey = widget.role == 'teacher' ? 'profName' : 'name';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .update({
        nameKey:  _nameController.text.trim(),
        'email':  _emailController.text.trim(),
      });

      // Update password if provided
      if (_newPasswordController.text.trim().isNotEmpty) {
        // Note: updating password requires re-authentication in production
        // For admin use, this updates via Firestore flag for next login
        // Full implementation requires Firebase Admin SDK (Cloud Functions)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.docId)
            .update({'pendingPasswordReset': true});
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to update. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Edit Account',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Full Name', _nameController),
            const SizedBox(height: 14),
            _dialogField('Email', _emailController,
              keyboard: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _dialogField('New Password (optional)', _newPasswordController,
              obscure: true,
              hint: 'Leave blank to keep current'),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.red.shade600)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL',
            style: TextStyle(color: Colors.grey.shade600))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
          onPressed: _isLoading ? null : _saveChanges,
          child: _isLoading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
            : const Text('SAVE',
                style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _dialogField(String label, TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(
            fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: navy, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
