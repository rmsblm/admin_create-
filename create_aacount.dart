import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_teacher_form.dart';
import 'create_student_form.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage>
    with SingleTickerProviderStateMixin {
  static const Color navy      = Color(0xFF001F3F);
  static const Color background = Color(0xFFEBF3FB);
  static const Color lightGrey  = Color(0xFFE2E8F0);
  static const Color textGrey   = Color(0xFF64748B);

  late TabController _tabController;

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
                      Text('Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 26, fontWeight: FontWeight.bold, color: navy)),
                      const SizedBox(height: 4),
                      Text('Add a new teacher or student to the system',
                        style: GoogleFonts.inter(fontSize: 13, color: textGrey)),
                      const SizedBox(height: 24),
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
                            color: navy,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                          labelColor: Colors.white,
                          unselectedLabelColor: textGrey,
                          tabs: const [
                            Tab(text: 'Teacher'),
                            Tab(text: 'Student'),
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
                    children: const [
                      TeacherForm(),
                      StudentForm(),
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
