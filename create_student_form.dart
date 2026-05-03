import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_helpers.dart';

class StudentForm extends StatefulWidget {
  const StudentForm({super.key});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  static const Color navy = Color(0xFF001F3F);

  final _studentIdController = TextEditingController();
  final _nameController      = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Dynamic years/specialties from Firestore ──────────────────
  List<String> _availableYears       = [];
  List<String> _availableSpecialties = [];
  bool _configLoading = true;
  final Set<String> _yearsWithoutSpecialty = {};

  String? _selectedYear;
  String? _selectedSpecialty;
  String? _selectedSection;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
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
          _yearsWithoutSpecialty.add(year);
        } else {
          specialtiesSet.add(specialty);
        }
      }

      setState(() {
        _availableYears       = yearsSet.toList()..sort();
        _availableSpecialties = specialtiesSet.toList()..sort();
        _configLoading        = false;
      });
    } catch (e) {
      setState(() => _configLoading = false);
    }
  }

  // Returns true if the selected year has no specialty
  bool get _selectedYearHasNoSpecialty =>
      _selectedYear != null &&
      _yearsWithoutSpecialty.contains(_selectedYear);

  Future<void> _createStudent() async {
    final id       = _studentIdController.text.trim();
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || name.isEmpty || email.isEmpty ||
        password.isEmpty || _selectedYear == null ||
        _selectedSection == null || _selectedGroup == null) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    // Only require specialty if the year has specialties
    if (!_selectedYearHasNoSpecialty && _selectedSpecialty == null) {
      setState(() =>
        _errorMessage = 'Please select a specialty for $_selectedYear.');
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
          .where('studentId', isEqualTo: id)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        setState(() =>
          _errorMessage = 'A student with this ID already exists.');
        return;
      }

      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final credential =
          await FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(
                email: '$id@present.app',
                password: password,
              );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'studentId': id,
        'name':      name,
        'email':     email,
        'role':      'student',
        'year':      _selectedYear,
        'specialty': _selectedYearHasNoSpecialty
                         ? 'None' : _selectedSpecialty,
        'section':   _selectedSection,
        'group':     _selectedGroup,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _successMessage = 'Student account created successfully!';
        _studentIdController.clear();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _selectedYear      = null;
        _selectedSpecialty = null;
        _selectedSection   = null;
        _selectedGroup     = null;
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
          // ── Student Info Card ──────────────────────────────────
          sectionCard(
            title: 'Student Information',
            child: Column(children: [
              Row(children: [
                Expanded(child: buildField(
                  'Student ID', _studentIdController,
                  hint: 'e.g. 221531',
                  formatters: [FilteringTextInputFormatter.digitsOnly])),
                const SizedBox(width: 16),
                Expanded(child: buildField(
                  'Full Name', _nameController,
                  hint: 'e.g. Amina Meziane')),
              ]),
              const SizedBox(height: 14),
              buildField('Email', _emailController,
                hint: 'e.g. a.meziane@univ.dz',
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

          // ── Academic Info Card ─────────────────────────────────
          sectionCard(
            title: 'Academic Information',
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: buildDropdown(
                    'Year', _availableYears, _selectedYear,
                    (v) => setState(() {
                      _selectedYear      = v;
                      _selectedSpecialty = null;
                    }),
                  ),
                ),
                const SizedBox(width: 14),

                // ✅ Specialty greyed out when year has no specialty
                Expanded(
                  child: Opacity(
                    opacity: (_selectedYear == null ||
                              _selectedYearHasNoSpecialty) ? 0.3 : 1.0,
                    child: IgnorePointer(
                      ignoring: _selectedYear == null ||
                                _selectedYearHasNoSpecialty,
                      child: buildDropdown(
                        'Specialty',
                        _availableSpecialties,
                        _selectedSpecialty,
                        (v) => setState(() => _selectedSpecialty = v)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: buildDropdown(
                  'Section', ['A', 'B'],
                  _selectedSection,
                  (v) => setState(() => _selectedSection = v))),
                const SizedBox(width: 14),
                Expanded(child: buildDropdown(
                  'Group', ['1', '2', '3'],
                  _selectedGroup,
                  (v) => setState(() => _selectedGroup = v))),
              ]),
            ]),
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
              onPressed: _isLoading ? null : _createStudent,
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
                : Text('CREATE STUDENT ACCOUNT',
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
}
