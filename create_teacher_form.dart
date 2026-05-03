import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_helpers.dart';

class TeacherForm extends StatefulWidget {
  const TeacherForm({super.key});

  @override
  State<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  static const Color navy      = Color(0xFF001F3F);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color textGrey  = Color(0xFF64748B);

  final _profIdController   = TextEditingController();
  final _profNameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Dynamic years/specialties from Firestore ──────────────────
  List<String> _availableYears       = [];
  List<String> _availableSpecialties = [];
  bool _configLoading = true;
  // Tracks which years have NO specialty (specialty == 'None')
  final Set<String> _yearsWithoutSpecialty = {};

  // ── Assignment builder ────────────────────────────────────────
  String? _assignYear;
  String? _assignSpecialty;
  String? _assignSubject;
  List<String> _assignSubjectsList = [];
  bool _subjectLoading = false;
  final Set<String> _assignSessionTypes = {};
  final Set<String> _assignSections     = {};
  final Set<String> _assignGroups       = {};
  String? _selectedGrade;

  final List<Map<String, dynamic>> _assignments = [];
  final List<String> _grades = ['MAA', 'MAB', 'MCA', 'MCB', 'PR'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _profIdController.dispose();
    _profNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Load years & specialties dynamically from config_subjects ─
  Future<void> _loadConfig() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('config_subjects')
          .get();

      final yearsSet       = <String>{};
      final specialtiesSet = <String>{};

      for (final doc in snapshot.docs) {
        final year      = doc.get('year').toString();
        final specialty = doc.get('specialty').toString();

        yearsSet.add(year);

        if (specialty == 'None' || specialty.isEmpty) {
          // Mark this year as having no specialty
          _yearsWithoutSpecialty.add(year);
        } else {
          specialtiesSet.add(specialty);
        }
      }

      final years = yearsSet.toList()..sort();
      final specialties = specialtiesSet.toList()..sort();

      setState(() {
        _availableYears       = years;
        _availableSpecialties = specialties;
        _configLoading        = false;
      });
    } catch (e) {
      setState(() => _configLoading = false);
    }
  }

  // Returns true if the selected year has no specialty
  bool get _selectedYearHasNoSpecialty =>
      _assignYear != null && _yearsWithoutSpecialty.contains(_assignYear);

  void _resetAssignmentFields() {
    setState(() {
      _assignYear = null;
      _assignSpecialty = null;
      _assignSubject = null;
      _assignSubjectsList = [];
      _assignSessionTypes.clear();
      _assignSections.clear();
      _assignGroups.clear();
    });
  }

  Future<void> _loadSubjects() async {
    if (_assignYear == null) return;

    // If year has no specialty, load directly
    if (_selectedYearHasNoSpecialty) {
      setState(() { _subjectLoading = true; _assignSubject = null; });
      try {
        final docId = '${_assignYear}_None';
        final doc   = await FirebaseFirestore.instance
            .collection('config_subjects').doc(docId).get();
        if (doc.exists) {
          final list = (doc.get('List') as List)
              .map((e) => e.toString()).toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          setState(() => _assignSubjectsList = list);
        }
      } finally {
        setState(() => _subjectLoading = false);
      }
      return;
    }

    // Year has specialties but none selected yet
    if (_assignSpecialty == null) {
      setState(() { _assignSubjectsList = []; _assignSubject = null; });
      return;
    }

    setState(() { _subjectLoading = true; _assignSubject = null; });
    try {
      final docId = '${_assignYear}_$_assignSpecialty';
      final doc   = await FirebaseFirestore.instance
          .collection('config_subjects').doc(docId).get();
      if (doc.exists) {
        final list = (doc.get('List') as List)
            .map((e) => e.toString()).toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        setState(() => _assignSubjectsList = list);
      }
    } finally {
      setState(() => _subjectLoading = false);
    }
  }

  void _addAssignment() {
    if (_assignYear == null || _assignSubject == null ||
        _assignSessionTypes.isEmpty ||
        _assignSections.isEmpty ||
        _assignGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all assignment fields.')));
      return;
    }
    setState(() {
      _assignments.add({
        'year':         _assignYear,
        'specialty':    _selectedYearHasNoSpecialty
                            ? 'None' : (_assignSpecialty ?? 'None'),
        'subject':      _assignSubject,
        'sessionTypes': _assignSessionTypes.toList(),
        'sections':     _assignSections.toList(),
        'groups':       _assignGroups.toList(),
      });
    });
    _resetAssignmentFields();
  }

  Future<void> _createTeacher() async {
    final id       = _profIdController.text.trim();
    final name     = _profNameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || name.isEmpty || email.isEmpty ||
        password.isEmpty || _selectedGrade == null) {
      setState(() => _errorMessage = 'Please fill in all teacher details.');
      return;
    }
    if (_assignments.isEmpty) {
      setState(() => _errorMessage = 'Add at least one teaching assignment.');
      return;
    }

    setState(() {
      _isLoading      = true;
      _errorMessage   = null;
      _successMessage = null;
    });

    FirebaseApp? secondaryApp;

    try {
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('profId', isEqualTo: id)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        setState(() => _errorMessage = 'A teacher with this ID already exists.');
        return;
      }

      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final credential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
            email: '$id@present.app',
            password: password,
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'profId':      id,
        'profName':    name,
        'email':       email,
        'grade':       _selectedGrade,
        'role':        'teacher',
        'assignments': _assignments,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      setState(() {
        _successMessage = 'Teacher account created successfully!';
        _assignments.clear();
        _profIdController.clear();
        _profNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _selectedGrade = null;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Failed to create account.');
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      await secondaryApp?.delete();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_configLoading) {
      return const Center(
        child: CircularProgressIndicator(color: navy));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Teacher Info Card ──────────────────────────────────
          sectionCard(
            title: 'Teacher Information',
            child: Column(children: [
              Row(children: [
                Expanded(child: buildField(
                  'Teacher ID', _profIdController,
                  hint: 'e.g. PR001',
                  formatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s'))])),
                const SizedBox(width: 16),
                Expanded(child: buildDropdown(
                  'Grade', _grades, _selectedGrade,
                  (v) => setState(() => _selectedGrade = v))),
              ]),
              const SizedBox(height: 14),
              buildField('Full Name', _profNameController,
                hint: 'e.g. Dr. Ahmed Benali'),
              const SizedBox(height: 14),
              buildField('Email', _emailController,
                hint: 'e.g. a.benali@univ.dz',
                keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              buildField('Initial Password', _passwordController,
                hint: 'Set a password',
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                    size: 18, color: Colors.grey),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword))),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Assignment Builder Card ────────────────────────────
          sectionCard(
            title: 'Teaching Assignments',
            subtitle: "Build the teacher's schedule subject by subject",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Year + Specialty row
                Row(children: [
                  Expanded(
                    child: buildDropdown(
                      'Year', _availableYears, _assignYear,
                      (v) {
                        setState(() {
                          _assignYear      = v;
                          _assignSpecialty = null;
                          _assignSubjectsList = [];
                          _assignSubject   = null;
                        });
                        _loadSubjects();
                      }),
                  ),
                  const SizedBox(width: 14),

                  // ✅ Specialty greyed out when year has no specialty
                  Expanded(
                    child: Opacity(
                      opacity: (_assignYear == null ||
                                _selectedYearHasNoSpecialty) ? 0.3 : 1.0,
                      child: IgnorePointer(
                        ignoring: _assignYear == null ||
                                  _selectedYearHasNoSpecialty,
                        child: buildDropdown(
                          'Specialty',
                          _availableSpecialties,
                          _assignSpecialty,
                          (v) {
                            setState(() => _assignSpecialty = v);
                            _loadSubjects();
                          }),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Subject
                buildDropdown(
                  'Subject', _assignSubjectsList, _assignSubject,
                  (v) => setState(() => _assignSubject = v),
                  hint: _subjectLoading
                      ? 'Loading...' : 'Select subject'),
                const SizedBox(height: 14),

                // Session Types
                buildLabel('Session Types'),
                const SizedBox(height: 8),
                buildMultiChips(
                  items: ['Lecture', 'TD', 'TP'],
                  selected: _assignSessionTypes,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 14),

                // Sections
                buildLabel('Sections'),
                const SizedBox(height: 8),
                buildMultiChips(
                  items: ['A', 'B'],
                  selected: _assignSections,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 14),

                // Groups
                buildLabel('Groups'),
                const SizedBox(height: 8),
                buildMultiChips(
                  items: ['1', '2', '3'],
                  selected: _assignGroups,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Add Assignment button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addAssignment,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('Add Assignment',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: navy,
                      side: BorderSide(color: navy.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),

                // Built assignment cards
                if (_assignments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ..._assignments.asMap().entries.map(
                    (e) => _buildAssignmentCard(e.value, e.key)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null)
            buildAlert(_errorMessage!, isError: true),
          if (_successMessage != null)
            buildAlert(_successMessage!, isError: false),
          if (_errorMessage != null || _successMessage != null)
            const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createTeacher,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                : Text('CREATE TEACHER ACCOUNT',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> a, int index) {
    final specialty =
        (a['specialty'] == 'None' || a['specialty'] == null)
            ? '' : ' • ${a['specialty']}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: navy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: navy.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${a['subject']}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13, color: navy)),
                const SizedBox(height: 2),
                Text(
                  '${a['year']}$specialty  •  '
                  '${(a['sessionTypes'] as List).join(', ')}  •  '
                  'Sec ${(a['sections'] as List).join(', ')}  •  '
                  'Gr ${(a['groups'] as List).join(', ')}',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _assignments.removeAt(index)),
            child: Icon(Icons.delete_outline_rounded,
              color: Colors.red.shade300, size: 20),
          ),
        ],
      ),
    );
  }
}
