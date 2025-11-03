import 'package:flutter/material.dart';


typedef DentalFormTableData = Map<String, bool>;

class DentalFormTable extends StatefulWidget {
  final void Function(DentalFormTableData)? onChanged;
  final DentalFormTableData? initialData;
  const DentalFormTable({super.key, this.onChanged, this.initialData});

  @override
  State<DentalFormTable> createState() => _DentalFormTableState();
}

class _DentalFormTableState extends State<DentalFormTable> {
  // ASA checkboxes
  bool _asa1 = false;
  bool _asa2 = false;
  // 4th year checkboxes
  bool _surgery4 = false;
  bool _cons4 = false;
  bool _ortho4 = false;
  bool _peado4 = false;
  bool _prostho4 = false;
  bool _endo4 = false;
  bool _perio4 = false;
  // 5th year checkboxes
  bool _surgery5 = false;
  bool _cons5 = false;
  bool _ortho5 = false;
  bool _peado5 = false;
  bool _prostho5 = false;
  bool _endo5 = false;
  bool _perio5 = false;
  // Simple/Complex checkboxes
  bool _simple = false;
  bool _complex = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d != null) {
      _asa1 = d['asa1'] ?? false;
      _asa2 = d['asa2'] ?? false;
      _surgery4 = d['surgery4'] ?? false;
      _cons4 = d['cons4'] ?? false;
      _ortho4 = d['ortho4'] ?? false;
      _peado4 = d['peado4'] ?? false;
      _prostho4 = d['prostho4'] ?? false;
      _endo4 = d['endo4'] ?? false;
      _perio4 = d['perio4'] ?? false;
      _surgery5 = d['surgery5'] ?? false;
      _cons5 = d['cons5'] ?? false;
      _ortho5 = d['ortho5'] ?? false;
      _peado5 = d['peado5'] ?? false;
      _prostho5 = d['prostho5'] ?? false;
      _endo5 = d['endo5'] ?? false;
      _perio5 = d['perio5'] ?? false;
      _simple = d['simple'] ?? false;
      _complex = d['complex'] ?? false;
    }
  }

  void _notifyChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!({
        'asa1': _asa1,
        'asa2': _asa2,
        'surgery4': _surgery4,
        'cons4': _cons4,
        'ortho4': _ortho4,
        'peado4': _peado4,
        'prostho4': _prostho4,
        'endo4': _endo4,
        'perio4': _perio4,
        'surgery5': _surgery5,
        'cons5': _cons5,
        'ortho5': _ortho5,
        'peado5': _peado5,
        'prostho5': _prostho5,
        'endo5': _endo5,
        'perio5': _perio5,
        'simple': _simple,
        'complex': _complex,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: [
        // الصف العلوي ASA I / ASA II
        TableRow(
          children: [
            CheckboxListTile(
              value: _asa1,
              onChanged: (v) => setState(() { _asa1 = v ?? false; _notifyChanged(); }),
              title: const Text("ASA I", style: TextStyle(fontWeight: FontWeight.bold)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF2A7A94),
              checkColor: Colors.white,
            ),
            CheckboxListTile(
              value: _asa2,
              onChanged: (v) => setState(() { _asa2 = v ?? false; _notifyChanged(); }),
              title: const Text("ASA II", style: TextStyle(fontWeight: FontWeight.bold)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF2A7A94),
              checkColor: Colors.white,
            ),
          ],
        ),
        // الصف الثاني 4th year / 5th year
        TableRow(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("4th year"),
                CheckboxListTile(value: _surgery4, onChanged: (v) => setState(() { _surgery4 = v ?? false; _notifyChanged(); }), title: const Text("Surgery"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _cons4, onChanged: (v) => setState(() { _cons4 = v ?? false; _notifyChanged(); }), title: const Text("Cons"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _ortho4, onChanged: (v) => setState(() { _ortho4 = v ?? false; _notifyChanged(); }), title: const Text("Ortho"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _peado4, onChanged: (v) => setState(() { _peado4 = v ?? false; _notifyChanged(); }), title: const Text("Peado"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _prostho4, onChanged: (v) => setState(() { _prostho4 = v ?? false; _notifyChanged(); }), title: const Text("Prostho"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _endo4, onChanged: (v) => setState(() { _endo4 = v ?? false; _notifyChanged(); }), title: const Text("Endo"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _perio4, onChanged: (v) => setState(() { _perio4 = v ?? false; _notifyChanged(); }), title: const Text("Perio"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("5th year"),
                CheckboxListTile(value: _surgery5, onChanged: (v) => setState(() { _surgery5 = v ?? false; _notifyChanged(); }), title: const Text("Surgery"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _cons5, onChanged: (v) => setState(() { _cons5 = v ?? false; _notifyChanged(); }), title: const Text("Cons"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _ortho5, onChanged: (v) => setState(() { _ortho5 = v ?? false; _notifyChanged(); }), title: const Text("Ortho"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _peado5, onChanged: (v) => setState(() { _peado5 = v ?? false; _notifyChanged(); }), title: const Text("Peado"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _prostho5, onChanged: (v) => setState(() { _prostho5 = v ?? false; _notifyChanged(); }), title: const Text("Prostho"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _endo5, onChanged: (v) => setState(() { _endo5 = v ?? false; _notifyChanged(); }), title: const Text("Endo"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
                CheckboxListTile(value: _perio5, onChanged: (v) => setState(() { _perio5 = v ?? false; _notifyChanged(); }), title: const Text("Perio"), activeColor: const Color(0xFF2A7A94), checkColor: Colors.white),
              ],
            ),
          ],
        ),
        // الصف الثالث Simple / Complex
        TableRow(
          children: [
            CheckboxListTile(
              value: _simple,
              onChanged: (v) => setState(() { _simple = v ?? false; _notifyChanged(); }),
              title: const Text("Simple"),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF2A7A94),
              checkColor: Colors.white,
            ),
            CheckboxListTile(
              value: _complex,
              onChanged: (v) => setState(() { _complex = v ?? false; _notifyChanged(); }),
              title: const Text("Complex"),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF2A7A94),
              checkColor: Colors.white,
            ),
          ],
        ),
      ],
    );
  }
}
