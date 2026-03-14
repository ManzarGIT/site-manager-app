import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'attendance_calendar_screen.dart';
import 'finances_screen.dart';

class WorkerListScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const WorkerListScreen(
      {super.key, required this.siteId, required this.siteName});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  List<dynamic> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/workers?siteId=${widget.siteId}'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _workers = List<dynamic>.from(json.decode(response.body));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Payment type label & color ────────────────────────────
  String _paymentTypeLabel(String type) {
    switch (type) {
      case 'CONTRACT':
        return 'Contract';
      case 'PIECE_RATE':
        return 'Piece Rate';
      default:
        return 'Daily Wage';
    }
  }

  Color _paymentTypeColor(String type) {
    switch (type) {
      case 'CONTRACT':
        return Colors.purple;
      case 'PIECE_RATE':
        return Colors.teal;
      default:
        return Colors.deepOrange;
    }
  }

  IconData _paymentTypeIcon(String type) {
    switch (type) {
      case 'CONTRACT':
        return Icons.handshake;
      case 'PIECE_RATE':
        return Icons.straighten;
      default:
        return Icons.calendar_today;
    }
  }

  // ── Worker subtitle based on type ────────────────────────
  String _workerSubtitle(dynamic worker) {
    final type = worker['paymentType'] ?? 'DAILY_WAGE';
    switch (type) {
      case 'CONTRACT':
        return 'Contract: ₹${worker['contractAmount'] ?? 0} • ${worker['contractDescription'] ?? ''}';
      case 'PIECE_RATE':
        return '₹${worker['ratePerUnit'] ?? 0} per ${worker['unitDescription'] ?? 'unit'} • ${worker['taskDescription'] ?? ''}';
      default:
        return 'Wage: ₹${worker['wageRate']}/day • ${worker['phone'] ?? 'N/A'}';
    }
  }

  // ── Add Worker Dialog ─────────────────────────────────────
  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'DAILY_WAGE';

    // DAILY_WAGE
    final wageController = TextEditingController();
    // CONTRACT
    final contractDescController = TextEditingController();
    final contractAmountController = TextEditingController();
    // PIECE_RATE
    final taskDescController = TextEditingController();
    final unitDescController = TextEditingController();
    final ratePerUnitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Add New Worker'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic info
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Worker Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                // Payment Type selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Type *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      // Daily Wage
                      _paymentTypeOption(
                        setDialogState,
                        selectedType,
                        'DAILY_WAGE',
                        Icons.calendar_today,
                        Colors.deepOrange,
                        'Daily Wage Worker',
                        'Paid per day based on attendance',
                        (val) => setDialogState(() => selectedType = val),
                      ),
                      const SizedBox(height: 6),
                      // Contract
                      _paymentTypeOption(
                        setDialogState,
                        selectedType,
                        'CONTRACT',
                        Icons.handshake,
                        Colors.purple,
                        'Contract Worker',
                        'Fixed amount for a specific job',
                        (val) => setDialogState(() => selectedType = val),
                      ),
                      const SizedBox(height: 6),
                      // Piece Rate
                      _paymentTypeOption(
                        setDialogState,
                        selectedType,
                        'PIECE_RATE',
                        Icons.straighten,
                        Colors.teal,
                        'Piece-Rate Worker',
                        'Paid based on quantity of work done',
                        (val) => setDialogState(() => selectedType = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic fields based on type
                if (selectedType == 'DAILY_WAGE') ...[
                  TextField(
                    controller: wageController,
                    decoration: const InputDecoration(
                      labelText: 'Daily Wage Rate (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedType == 'CONTRACT') ...[
                  TextField(
                    controller: contractDescController,
                    decoration: const InputDecoration(
                      labelText: 'Work Description *',
                      hintText: 'e.g. House Plastering',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contractAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Total Contract Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedType == 'PIECE_RATE') ...[
                  TextField(
                    controller: taskDescController,
                    decoration: const InputDecoration(
                      labelText: 'Work Type / Task *',
                      hintText: 'e.g. Brick Laying',
                      prefixIcon: Icon(Icons.construction),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unitDescController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Definition *',
                      hintText: 'e.g. 1000 bricks',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ratePerUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Rate per Unit (₹) *',
                      hintText: 'e.g. 1000',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final body = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'siteId': widget.siteId,
                  'paymentType': selectedType,
                };
                if (selectedType == 'DAILY_WAGE') {
                  body['wageRate'] = wageController.text;
                } else if (selectedType == 'CONTRACT') {
                  body['contractDescription'] = contractDescController.text;
                  body['contractAmount'] = contractAmountController.text;
                } else if (selectedType == 'PIECE_RATE') {
                  body['taskDescription'] = taskDescController.text;
                  body['unitDescription'] = unitDescController.text;
                  body['ratePerUnit'] = ratePerUnitController.text;
                }

                final response = await http.post(
                  Uri.parse('${auth.baseUrl}/workers'),
                  headers: {
                    'Authorization': 'Bearer ${auth.token}',
                    'Content-Type': 'application/json'
                  },
                  body: json.encode(body),
                );
                if (mounted) Navigator.pop(context);
                if (response.statusCode == 201) {
                  _fetchWorkers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Worker added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Add Worker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTypeOption(
    StateSetter setDialogState,
    String selectedType,
    String value,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    Function(String) onSelect,
  ) {
    final isSelected = selectedType == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isSelected ? color : Colors.grey.shade200,
              child: Icon(icon,
                  size: 16, color: isSelected ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : null,
                          fontSize: 13)),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Edit Worker Dialog ────────────────────────────────────
  void _showEditWorkerDialog(dynamic worker) {
    final nameController = TextEditingController(text: worker['name']);
    final phoneController = TextEditingController(text: worker['phone'] ?? '');
    final type = worker['paymentType'] ?? 'DAILY_WAGE';

    final wageController =
        TextEditingController(text: worker['wageRate']?.toString() ?? '');
    final contractDescController =
        TextEditingController(text: worker['contractDescription'] ?? '');
    final contractAmountController =
        TextEditingController(text: worker['contractAmount']?.toString() ?? '');
    final taskDescController =
        TextEditingController(text: worker['taskDescription'] ?? '');
    final unitDescController =
        TextEditingController(text: worker['unitDescription'] ?? '');
    final ratePerUnitController =
        TextEditingController(text: worker['ratePerUnit']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Worker'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Worker Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 10),
              if (type == 'DAILY_WAGE')
                TextField(
                  controller: wageController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Wage Rate (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              if (type == 'CONTRACT') ...[
                TextField(
                  controller: contractDescController,
                  decoration: const InputDecoration(
                    labelText: 'Work Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contractAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Contract Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (type == 'PIECE_RATE') ...[
                TextField(
                  controller: taskDescController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: unitDescController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Definition',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ratePerUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Rate per Unit (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final body = {
                'name': nameController.text,
                'phone': phoneController.text,
                'paymentType': type,
                'wageRate': wageController.text,
                'contractDescription': contractDescController.text,
                'contractAmount': contractAmountController.text,
                'taskDescription': taskDescController.text,
                'unitDescription': unitDescController.text,
                'ratePerUnit': ratePerUnitController.text,
              };
              final response = await http.put(
                Uri.parse('${auth.baseUrl}/workers/${worker['id']}'),
                headers: {
                  'Authorization': 'Bearer ${auth.token}',
                  'Content-Type': 'application/json'
                },
                body: json.encode(body),
              );
              if (mounted) Navigator.pop(context);
              if (response.statusCode == 200) {
                _fetchWorkers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Worker updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.siteName} - Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AttendanceScannerScreenPlaceholder(
                        siteId: widget.siteId)),
              );
            },
            tooltip: 'Scan Attendance QR',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No workers found for this site.'),
                      const SizedBox(height: 8),
                      const Text('Tap + to add a worker',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _workers.length,
                  itemBuilder: (context, index) {
                    final worker = _workers[index];
                    final type = worker['paymentType'] ?? 'DAILY_WAGE';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _paymentTypeColor(type),
                          child: Text(
                            worker['name'].substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(worker['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _paymentTypeColor(type)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_paymentTypeIcon(type),
                                      size: 11, color: _paymentTypeColor(type)),
                                  const SizedBox(width: 3),
                                  Text(_paymentTypeLabel(type),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _paymentTypeColor(type),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(_workerSubtitle(worker),
                            style: const TextStyle(fontSize: 12)),
                        onTap: () => _showEditWorkerDialog(worker),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Show attendance only for DAILY_WAGE
                            if (type == 'DAILY_WAGE')
                              IconButton(
                                icon: const Icon(Icons.calendar_today,
                                    color: Colors.blue, size: 20),
                                tooltip: 'Attendance',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceCalendarScreen(
                                      workerId: worker['id'],
                                      workerName: worker['name'],
                                    ),
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.account_balance_wallet,
                                  color: Colors.green, size: 20),
                              tooltip: 'Wallet',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FinancesScreen(
                                    workerId: worker['id'],
                                    workerName: worker['name'],
                                    wageRate: (worker['wageRate'] as num?)
                                            ?.toDouble() ??
                                        0,
                                    paymentType: type,
                                    contractAmount:
                                        (worker['contractAmount'] as num?)
                                            ?.toDouble(),
                                    ratePerUnit: (worker['ratePerUnit'] as num?)
                                        ?.toDouble(),
                                    unitDescription: worker['unitDescription'],
                                    taskDescription: worker['taskDescription'],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: _showAddWorkerDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

// Placeholder for scanner (camera not supported in Chrome)
class AttendanceScannerScreenPlaceholder extends StatelessWidget {
  final String siteId;
  const AttendanceScannerScreenPlaceholder({super.key, required this.siteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('QR Scanner works on Android app only.',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Use the calendar for manual attendance.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
