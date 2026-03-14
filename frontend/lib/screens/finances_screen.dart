import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FinancesScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String paymentType;
  final double wageRate;
  final double? contractAmount;
  final double? ratePerUnit;
  final String? unitDescription;
  final String? taskDescription;

  const FinancesScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    this.paymentType = 'DAILY_WAGE',
    this.wageRate = 0,
    this.contractAmount,
    this.ratePerUnit,
    this.unitDescription,
    this.taskDescription,
  });

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  List<dynamic> _transactions = <dynamic>[];
  List<dynamic> _attendance = <dynamic>[];
  List<dynamic> _workProgress = <dynamic>[];
  bool _isLoading = true;
  final _rupeeFormat = NumberFormat('#,##,###', 'en_IN');

  // ── Computed values ───────────────────────────────────────
  double get _totalEarned {
    switch (widget.paymentType) {
      case 'CONTRACT':
        return widget.contractAmount ?? 0;
      case 'PIECE_RATE':
        final totalQty = _workProgress.fold<double>(
            0, (sum, p) => sum + (p['quantity'] as num).toDouble());
        return totalQty * (widget.ratePerUnit ?? 0);
      default: // DAILY_WAGE
        double days = 0;
        for (final a in _attendance) {
          if (a['status'] == 'PRESENT') days += 1;
          if (a['status'] == 'HALF_DAY') days += 0.5;
        }
        return days * widget.wageRate;
    }
  }

  double get _totalAdvance => _transactions
      .where((t) => t['type'] == 'ADVANCE')
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get _totalPaid => _transactions
      .where((t) => t['type'] == 'PAYMENT')
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get _remainingBalance => _totalEarned - _totalAdvance - _totalPaid;

  double get _totalAttendanceDays {
    double days = 0;
    for (final a in _attendance) {
      if (a['status'] == 'PRESENT') days += 1;
      if (a['status'] == 'HALF_DAY') days += 0.5;
    }
    return days;
  }

  double get _totalWorkQty => _workProgress.fold<double>(
      0, (sum, p) => sum + (p['quantity'] as num).toDouble());

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchTransactions(),
      if (widget.paymentType == 'DAILY_WAGE') _fetchAttendance(),
      if (widget.paymentType == 'PIECE_RATE') _fetchWorkProgress(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchTransactions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/transactions/worker/${widget.workerId}'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200 && mounted) {
        setState(() =>
            _transactions = List<dynamic>.from(json.decode(response.body)));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _fetchAttendance() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/attendance?workerId=${widget.workerId}'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200 && mounted) {
        setState(
            () => _attendance = List<dynamic>.from(json.decode(response.body)));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _fetchWorkProgress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/workers/progress/${widget.workerId}'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200 && mounted) {
        setState(() =>
            _workProgress = List<dynamic>.from(json.decode(response.body)));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ── Add Work Progress (PIECE_RATE only) ──────────────────
  void _showAddProgressDialog() {
    final quantityController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_chart, color: Colors.teal),
            const SizedBox(width: 8),
            Text('Record Work - ${widget.taskDescription ?? 'Progress'}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rate: ₹${_rupeeFormat.format(widget.ratePerUnit ?? 0)} per ${widget.unitDescription ?? 'unit'}\n'
                'Total completed so far: ${_rupeeFormat.format(_totalWorkQty)} ${widget.unitDescription ?? 'units'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity Completed',
                hintText: 'e.g. 1000',
                suffixText: widget.unitDescription ?? 'units',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.straighten),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (quantityController.text.isEmpty) return;
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final response = await http.post(
                Uri.parse('${auth.baseUrl}/workers/progress'),
                headers: {
                  'Authorization': 'Bearer ${auth.token}',
                  'Content-Type': 'application/json'
                },
                body: json.encode({
                  'workerId': widget.workerId,
                  'quantity': double.tryParse(quantityController.text) ?? 0,
                  'description': descController.text,
                }),
              );
              if (mounted) Navigator.pop(context);
              if (response.statusCode == 201) {
                _loadAllData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Work progress recorded!'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Record Payment Dialog ─────────────────────────────────
  void _showRecordPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'PAYMENT';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Record Payment'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Total Earned',
                          '₹${_rupeeFormat.format(_totalEarned)}', Colors.blue),
                      _summaryRow(
                          'Advance Given',
                          '- ₹${_rupeeFormat.format(_totalAdvance)}',
                          Colors.red),
                      _summaryRow(
                          'Already Paid',
                          '- ₹${_rupeeFormat.format(_totalPaid)}',
                          Colors.green),
                      const Divider(),
                      _summaryRow(
                        'Remaining Due',
                        '₹${_rupeeFormat.format(_remainingBalance)}',
                        _remainingBalance > 0
                            ? Colors.deepOrange
                            : Colors.green,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '⚠️ Payment is made externally (UPI/Cash). Record here only.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Entry Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'PAYMENT', child: Text('💰 Payment Record')),
                    DropdownMenuItem(
                        value: 'ADVANCE', child: Text('⏩ Advance Given')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 10),
                if (amountController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance after this:',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          '₹${_rupeeFormat.format(_remainingBalance - (double.tryParse(amountController.text) ?? 0))}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (e.g. Paid via UPI)',
                    border: OutlineInputBorder(),
                  ),
                ),
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
                if (amountController.text.isEmpty) return;
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final response = await http.post(
                  Uri.parse('${auth.baseUrl}/transactions'),
                  headers: {
                    'Authorization': 'Bearer ${auth.token}',
                    'Content-Type': 'application/json'
                  },
                  body: json.encode({
                    'workerId': widget.workerId,
                    'type': selectedType,
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'notes': notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  }),
                );
                if (mounted) Navigator.pop(context);
                if (response.statusCode == 200 || response.statusCode == 201) {
                  _loadAllData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment recorded!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Record'),
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

  Widget _summaryRow(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (widget.paymentType) {
      case 'CONTRACT':
        return Colors.purple;
      case 'PIECE_RATE':
        return Colors.teal;
      default:
        return Colors.deepOrange;
    }
  }

  String get _typeLabel {
    switch (widget.paymentType) {
      case 'CONTRACT':
        return 'Contract Worker';
      case 'PIECE_RATE':
        return 'Piece-Rate Worker';
      default:
        return 'Daily Wage Worker';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.paymentType == 'PIECE_RATE' ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.workerName} - Wallet'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _loadAllData),
          ],
          bottom: widget.paymentType == 'PIECE_RATE'
              ? const TabBar(tabs: [
                  Tab(
                      text: 'Wallet',
                      icon: Icon(Icons.account_balance_wallet, size: 18)),
                  Tab(
                      text: 'Work Progress',
                      icon: Icon(Icons.bar_chart, size: 18)),
                ])
              : null,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : widget.paymentType == 'PIECE_RATE'
                ? TabBarView(children: [
                    _buildWalletTab(),
                    _buildProgressTab(),
                  ])
                : _buildWalletTab(),
        floatingActionButton: widget.paymentType == 'PIECE_RATE'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'progress',
                    onPressed: _showAddProgressDialog,
                    backgroundColor: Colors.teal,
                    mini: true,
                    child: const Icon(Icons.add_chart, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'payment',
                    onPressed: _showRecordPaymentDialog,
                    backgroundColor: Colors.deepOrange,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Record Payment',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            : FloatingActionButton.extended(
                onPressed: _showRecordPaymentDialog,
                backgroundColor: Colors.deepOrange,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Record Payment',
                    style: TextStyle(color: Colors.white)),
              ),
      ),
    );
  }

  Widget _buildWalletTab() {
    return Column(
      children: [
        // Wallet card
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _typeColor.withValues(alpha: 0.9),
                _typeColor.withValues(alpha: 0.6)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _typeColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_typeLabel,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    widget.paymentType == 'DAILY_WAGE'
                        ? '${_totalAttendanceDays.toStringAsFixed(1)} days'
                        : widget.paymentType == 'PIECE_RATE'
                            ? '${_rupeeFormat.format(_totalWorkQty)} ${widget.unitDescription ?? 'units'}'
                            : 'Fixed Contract',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining Balance',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  Text(
                    '₹${_rupeeFormat.format(_remainingBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white30, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _walletStat(
                      'Total Earned',
                      '₹${_rupeeFormat.format(_totalEarned)}',
                      Colors.lightBlueAccent),
                  _walletStat(
                      'Advance',
                      '₹${_rupeeFormat.format(_totalAdvance)}',
                      Colors.redAccent.shade100),
                  _walletStat('Paid', '₹${_rupeeFormat.format(_totalPaid)}',
                      Colors.greenAccent),
                ],
              ),
            ],
          ),
        ),

        // Transactions list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('Payment Records',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('${_transactions.length} records',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('No payments recorded yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final t = _transactions[index];
                    final date = DateTime.parse(t['date']);
                    final type = t['type'] as String;
                    final amount = (t['amount'] as num).toDouble();
                    Color tColor = type == 'PAYMENT'
                        ? Colors.green
                        : type == 'ADVANCE'
                            ? Colors.red
                            : Colors.blue;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tColor.withValues(alpha: 0.15),
                          child: Icon(
                            type == 'PAYMENT'
                                ? Icons.check_circle
                                : type == 'ADVANCE'
                                    ? Icons.money_off
                                    : Icons.work,
                            color: tColor,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type == 'PAYMENT'
                                  ? 'Payment Recorded'
                                  : type == 'ADVANCE'
                                      ? 'Advance Given'
                                      : 'Wage',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('₹${_rupeeFormat.format(amount)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: tColor)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(date),
                                style: const TextStyle(fontSize: 12)),
                            if (t['notes'] != null &&
                                t['notes'].toString().isNotEmpty)
                              Text('📝 ${t['notes']}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    return Column(
      children: [
        // Progress summary
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(_rupeeFormat.format(_totalWorkQty),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                  Text(widget.unitDescription ?? 'Units',
                      style: const TextStyle(fontSize: 12)),
                  const Text('Completed',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Column(
                children: [
                  Text(
                    '₹${_rupeeFormat.format(_totalEarned)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const Text('Work Value', style: TextStyle(fontSize: 12)),
                  const Text('Earned',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Column(
                children: [
                  Text(
                    '₹${_rupeeFormat.format(_remainingBalance)}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _remainingBalance >= 0
                            ? Colors.deepOrange
                            : Colors.green),
                  ),
                  const Text('Balance', style: TextStyle(fontSize: 12)),
                  Text(
                    _remainingBalance >= 0 ? 'Remaining' : 'Overpaid',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('Work Progress Entries',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('${_workProgress.length} entries',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),

        Expanded(
          child: _workProgress.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('No work progress recorded yet'),
                      const SizedBox(height: 4),
                      const Text('Tap the teal + button to add',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: _workProgress.length,
                  itemBuilder: (context, index) {
                    final p = _workProgress[index];
                    final date = DateTime.parse(p['date']);
                    final qty = (p['quantity'] as num).toDouble();
                    final value = qty * (widget.ratePerUnit ?? 0);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(Icons.construction,
                              color: Colors.teal),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_rupeeFormat.format(qty)} ${widget.unitDescription ?? 'units'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('₹${_rupeeFormat.format(value)}',
                                style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(date),
                                style: const TextStyle(fontSize: 12)),
                            if (p['description'] != null &&
                                p['description'].toString().isNotEmpty)
                              Text('📝 ${p['description']}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _walletStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
