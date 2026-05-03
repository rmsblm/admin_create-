import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _navy       = Color(0xFF001F3F);
const Color _lightGrey  = Color(0xFFE2E8F0);
const Color _textGrey   = Color(0xFF64748B);
const Color _background = Color(0xFFF8FAFC);

/* THIS FILE IS TO DONT RE-WRITE SAME WIDGETS BTWN STUDENT AND TEACHER FORM  */

Widget sectionCard({
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _lightGrey),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.bold, color: _navy)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 11, color: _textGrey)),
        ],
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

Widget buildField(
  String label,
  TextEditingController controller, {
  String hint = '',
  bool obscure = false,
  Widget? suffix,
  TextInputType keyboard = TextInputType.text,
  List<TextInputFormatter>? formatters,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: GoogleFonts.inter(fontSize: 13, color: _navy),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          suffixIcon: suffix,
          filled: true,
          fillColor: _background,
          contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _navy, width: 1.5)),
        ),
      ),
    ],
  );
}

Widget buildDropdown(
  String label,
  List<String> items,
  String? value,
  Function(String?) onChanged, {
  String hint = 'Select',
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildLabel(label),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: const TextStyle(fontSize: 12)),
        decoration: InputDecoration(
          filled: true,
          fillColor: _background,
          contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _navy, width: 1.5)),
        ),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget buildMultiChips({
  required List<String> items,
  required Set<String> selected,
  required VoidCallback onChanged,
}) {
  return StatefulBuilder(
    builder: (context, setLocalState) {
      return Wrap(
        spacing: 8, runSpacing: 8,
        children: items.map((item) {
          final isSel = selected.contains(item);
          return GestureDetector(
            onTap: () {
              isSel ? selected.remove(item) : selected.add(item);
              setLocalState(() {});
              onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? _navy : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? _navy : _lightGrey),
              ),
              child: Text(item, style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : _textGrey)),
            ),
          );
        }).toList(),
      );
    },
  );
}

Widget buildAlert(String msg, {required bool isError}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isError ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isError ? Colors.red.shade200 : Colors.green.shade200),
    ),
    child: Row(children: [
      Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError ? Colors.red.shade400 : Colors.green.shade400,
        size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.inter(
        fontSize: 12,
        color: isError ? Colors.red.shade700 : Colors.green.shade700))),
    ]),
  );
}

Widget buildLabel(String text) => Text(text,
  style: const TextStyle(
    fontSize: 10, color: _textGrey, fontWeight: FontWeight.bold));
