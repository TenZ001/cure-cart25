import 'package:flutter/material.dart';
import '../api_service.dart';

class DeliverySignupScreen extends StatefulWidget {
  const DeliverySignupScreen({Key? key}) : super(key: key);

  @override
  State<DeliverySignupScreen> createState() => _DeliverySignupScreenState();
}

class _DeliverySignupScreenState extends State<DeliverySignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _dlCtrl = TextEditingController();
  final ApiService _api = ApiService();
  bool _bike = false, _car = false, _three = false, _van = false;
  bool _submitting = false;
  Map<String, dynamic>? _profile;
  bool _editing = false;
  bool _prefilled = false;

  List<String> get _vehicles {
    final v = <String>[];
    if (_bike) v.add('bike');
    if (_car) v.add('car');
    if (_three) v.add('threewheeler');
    if (_van) v.add('van');
    return v;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one vehicle')),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await _api.submitDeliverySignup(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      licenseNumber: _dlCtrl.text.trim(),
      vehicles: _vehicles,
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted. Await admin approval.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Signup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _api.getDeliveryProfile(),
          builder: (context, snap) {
            _profile = snap.data;
            final status = (_profile?['status'] ?? '').toString();
            final isPending = status == 'pending';
            final isApproved = status == 'approved';
            // Prefill controllers and vehicle checks once when profile loaded
            if (!snap.hasError && snap.connectionState == ConnectionState.done && _profile != null && !_prefilled) {
              final m = _profile!;
              _nameCtrl.text = (m['name'] ?? _nameCtrl.text);
              _phoneCtrl.text = (m['contact'] ?? _phoneCtrl.text);
              _nicCtrl.text = (m['nic'] ?? _nicCtrl.text);
              _dlCtrl.text = (m['licenseNumber'] ?? _dlCtrl.text);
              final vstr = (m['vehicleNo'] ?? '').toString().toLowerCase();
              _bike = vstr.contains('bike');
              _car = vstr.contains('car');
              _three = vstr.contains('three');
              _van = vstr.contains('van');
              _prefilled = true;
            }
            return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                  child: const Text('Waiting for approve the request', style: TextStyle(color: Colors.black87)),
                ),
              if (isApproved)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Approved delivery partner', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(()=> _editing = !_editing),
                      child: Text(_editing ? 'Cancel' : 'Edit'),
                    )
                  ],
                ),
              if (isApproved)
                const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => (v != null && v.trim().length >= 2) ? null : 'Enter your name',
                readOnly: isApproved && !_editing,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                validator: (v) => RegExp(r'^\d{10}$').hasMatch(v?.trim() ?? '') ? null : 'Enter 10-digit number',
                readOnly: isApproved && !_editing,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _nicCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'NIC (12 digits)', border: OutlineInputBorder()),
                    validator: (v) => RegExp(r'^\d{12}$').hasMatch(v?.trim() ?? '') ? null : 'Enter 12 digits',
                    readOnly: isApproved && !_editing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dlCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'License (8 digits)', border: OutlineInputBorder()),
                    validator: (v) => RegExp(r'^\d{8}$').hasMatch(v?.trim() ?? '') ? null : 'Enter 8 digits',
                    readOnly: isApproved && !_editing,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Vehicles', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(value: _bike, onChanged: (isApproved && !_editing) ? null : (v)=>setState(()=>_bike=v??false), title: const Text('Bike'), controlAffinity: ListTileControlAffinity.leading),
              CheckboxListTile(value: _car, onChanged: (isApproved && !_editing) ? null : (v)=>setState(()=>_car=v??false), title: const Text('Car'), controlAffinity: ListTileControlAffinity.leading),
              CheckboxListTile(value: _three, onChanged: (isApproved && !_editing) ? null : (v)=>setState(()=>_three=v??false), title: const Text('Threewheeler'), controlAffinity: ListTileControlAffinity.leading),
              CheckboxListTile(value: _van, onChanged: (isApproved && !_editing) ? null : (v)=>setState(()=>_van=v??false), title: const Text('Van'), controlAffinity: ListTileControlAffinity.leading),
              const SizedBox(height: 8),
              if (!isApproved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Request approval'),
                  ),
                ),
              if (isApproved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _editing ? () async {
                      final ok = await _api.updateDeliveryProfile({
                        'name': _nameCtrl.text.trim(),
                        'contact': _phoneCtrl.text.trim(),
                        'nic': _nicCtrl.text.trim(),
                        'licenseNumber': _dlCtrl.text.trim(),
                        'vehicleNo': _vehicles.join(', '),
                      });
                      if (ok) {
                        setState(()=> _editing = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
                      }
                    } : null,
                    child: const Text('Save'),
                  ),
                ),
            ],
          ),
        );
          },
        ),
      ),
    );
  }
}


