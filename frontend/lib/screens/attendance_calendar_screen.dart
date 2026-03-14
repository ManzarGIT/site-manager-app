import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceCalendarScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const AttendanceCalendarScreen(
      {super.key, required this.workerId, required this.workerName});

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  Map<String, String> _attendanceMap = {}; // date string -> status
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/attendance?workerId=${widget.workerId}'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> records = json.decode(response.body);
        final map = <String, String>{};
        for (final r in records) {
          final date = DateTime.parse(r['date']).toLocal();
          map[_dateKey(date)] = r['status'];
        }
        setState(() {
          _attendanceMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(DateTime date, String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final key = _dateKey(date);

    try {
      final response = await http.post(
        Uri.parse('${auth.baseUrl}/attendance/calendar'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'workerId': widget.workerId,
          'date': date.toIso8601String(),
          'status': status,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _attendanceMap[key] = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Marked $status for ${date.day}/${date.month}/${date.year}'),
            backgroundColor: _statusColor(status),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error marking attendance'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showDayDialog(DateTime date) {
    final key = _dateKey(date);
    final currentStatus = _attendanceMap[key];
    final now = DateTime.now();
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
    if (isFuture) return; // Can't mark future dates

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.day}/${date.month}/${date.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentStatus != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _statusColor(currentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(currentStatus),
                        color: _statusColor(currentStatus)),
                    const SizedBox(width: 8),
                    Text('Current: $currentStatus',
                        style: TextStyle(color: _statusColor(currentStatus))),
                  ],
                ),
              ),
            const Text('Mark attendance as:'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusButton('PRESENT', Colors.green, Icons.check_circle),
                _statusButton('ABSENT', Colors.red, Icons.cancel),
                _statusButton('HALF_DAY', Colors.orange, Icons.timelapse),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String status, Color color, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        final date = _selectedDate!;
        _markAttendance(date, status);
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(status.replaceAll('_', '\n'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  DateTime? _selectedDate;

  Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      case 'HALF_DAY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PRESENT':
        return Icons.check_circle;
      case 'ABSENT':
        return Icons.cancel;
      case 'HALF_DAY':
        return Icons.timelapse;
      default:
        return Icons.circle_outlined;
    }
  }

  List<DateTime> _getDaysInMonth() {
    final first = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final last = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  int get _totalPresent =>
      _attendanceMap.values.where((s) => s == 'PRESENT').length;
  int get _totalHalfDay =>
      _attendanceMap.values.where((s) => s == 'HALF_DAY').length;
  int get _totalAbsent =>
      _attendanceMap.values.where((s) => s == 'ABSENT').length;
  double get _totalDays => _totalPresent + (_totalHalfDay * 0.5);

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workerName} - Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month navigation
                Container(
                  color: Colors.deepOrange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month - 1);
                          });
                          _fetchAttendance();
                        },
                      ),
                      Text(
                        '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month + 1);
                          });
                          _fetchAttendance();
                        },
                      ),
                    ],
                  ),
                ),

                // Weekday headers
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(d,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            ))
                        .toList(),
                  ),
                ),

                // Calendar grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                    ),
                    itemCount: days.length + firstWeekday,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday) return const SizedBox();
                      final date = days[index - firstWeekday];
                      final key = _dateKey(date);
                      final status = _attendanceMap[key];
                      final isToday =
                          _dateKey(date) == _dateKey(DateTime.now());
                      final isFuture = date.isAfter(DateTime.now());

                      return GestureDetector(
                        onTap: () {
                          if (!isFuture) {
                            _selectedDate = date;
                            _showDayDialog(date);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: status != null
                                ? _statusColor(status)
                                : isToday
                                    ? Colors.deepOrange.withOpacity(0.3)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isToday
                                ? Border.all(color: Colors.deepOrange, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: status != null
                                    ? Colors.white
                                    : isFuture
                                        ? Colors.grey
                                        : null,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Legend
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legendItem(Colors.green, 'Present'),
                      _legendItem(Colors.orange, 'Half Day'),
                      _legendItem(Colors.red, 'Absent'),
                      _legendItem(Colors.grey.shade300, 'Not Marked'),
                    ],
                  ),
                ),

                // Summary
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text('Monthly Summary',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _summaryItem('Present', _totalPresent, Colors.green),
                          _summaryItem(
                              'Half Day', _totalHalfDay, Colors.orange),
                          _summaryItem('Absent', _totalAbsent, Colors.red),
                          _summaryItem('Total Days',
                              _totalDays.toStringAsFixed(1), Colors.deepOrange),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _summaryItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
