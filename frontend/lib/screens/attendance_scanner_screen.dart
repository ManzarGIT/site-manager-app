import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceScannerScreen extends StatefulWidget {
  final String siteId;
  const AttendanceScannerScreen({super.key, required this.siteId});

  @override
  State<StatefulWidget> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  String? result;
  bool _isProcessing = false;

  Future<void> _markAttendance(String workerId, String action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse('${auth.baseUrl}/attendance'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'workerId': workerId,
          'siteId': widget.siteId,
          'action': action, // 'CHECK_IN' or 'CHECK_OUT'
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Successfully marked $action'),
                backgroundColor: Colors.green),
          );
        } else {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data['message'] ?? 'Error marking attendance'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Network error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Worker QR')),
      body: Column(
        children: <Widget>[
          Expanded(
              flex: 4,
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (!_isProcessing && barcode.rawValue != null) {
                      setState(() {
                        result = barcode.rawValue;
                      });
                    }
                  }
                },
              )),
          Expanded(
            flex: 1,
            child: Center(
              child: (_isProcessing)
                  ? const CircularProgressIndicator()
                  : (result != null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Worker QR Detected',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      _markAttendance(result!, 'CHECK_IN'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('CHECK IN',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _markAttendance(result!, 'CHECK_OUT'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange),
                                  child: const Text('CHECK OUT',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        )
                      : const Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }
}
