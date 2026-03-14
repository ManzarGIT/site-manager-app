import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'worker_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

  Future<void> _fetchSites() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/sites'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _sites = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Add Site ──────────────────────────────────────────────
  void _showAddSiteDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_business, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Add New Site'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
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
              if (nameController.text.isEmpty) return;
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final response = await http.post(
                Uri.parse('${auth.baseUrl}/sites'),
                headers: {
                  'Authorization': 'Bearer ${auth.token}',
                  'Content-Type': 'application/json'
                },
                body: json.encode({
                  'name': nameController.text,
                  'location': locationController.text,
                }),
              );
              if (mounted) Navigator.pop(context);
              if (response.statusCode == 201) {
                _fetchSites();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Site added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Site'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Site ─────────────────────────────────────────────
  void _showEditSiteDialog(dynamic site) {
    final nameController = TextEditingController(text: site['name']);
    final locationController =
        TextEditingController(text: site['location'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Site'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
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
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final response = await http.put(
                Uri.parse('${auth.baseUrl}/sites/${site['id']}'),
                headers: {
                  'Authorization': 'Bearer ${auth.token}',
                  'Content-Type': 'application/json'
                },
                body: json.encode({
                  'name': nameController.text,
                  'location': locationController.text,
                }),
              );
              if (mounted) Navigator.pop(context);
              if (response.statusCode == 200) {
                _fetchSites();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Site updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete Site (requires admin password) ─────────────────
  void _showDeleteSiteDialog(dynamic site) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Site', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        const Text('Warning!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are about to delete "${site['name']}". '
                      'This will permanently delete ALL workers, '
                      'attendance records and transactions for this site.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Enter admin password to confirm:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setDialogState(
                        () => obscurePassword = !obscurePassword),
                  ),
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
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter admin password'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final auth = Provider.of<AuthProvider>(context, listen: false);
                final response = await http.delete(
                  Uri.parse('${auth.baseUrl}/sites/${site['id']}'),
                  headers: {
                    'Authorization': 'Bearer ${auth.token}',
                    'Content-Type': 'application/json'
                  },
                  body: json.encode({
                    'adminPassword': passwordController.text,
                  }),
                );

                if (mounted) Navigator.pop(context);

                if (response.statusCode == 200) {
                  _fetchSites();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${site['name']} deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  final data = json.decode(response.body);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(data['message'] ?? 'Failed to delete site'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Site'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Site Options Menu ─────────────────────────────────────
  void _showSiteOptions(dynamic site, String userRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.business, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(site['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(site['location'] ?? 'No location',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.people, size: 18)),
              title: const Text('View Workers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerListScreen(
                        siteId: site['id'], siteName: site['name']),
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.edit, color: Colors.white, size: 18)),
              title: const Text('Edit Site Details'),
              onTap: () {
                Navigator.pop(context);
                _showEditSiteDialog(site);
              },
            ),
            if (userRole == 'ADMIN')
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete_forever,
                        color: Colors.white, size: 18)),
                title: const Text('Delete Site',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text('Requires admin password',
                    style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteSiteDialog(site);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final userRole = user?['role'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text('Confirm Logout'),
                    ],
                  ),
                  content: const Text(
                      'Are you sure you want to go to the Login Page?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        auth.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Yes, Logout'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade700,
                  Colors.deepOrange.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    (user?['name'] ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user?['name'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?['role'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_sites.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _sites.length == 1 ? 'Site' : 'Sites',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sites.isEmpty
                    ? const Center(child: Text('No sites found.'))
                    : ListView.builder(
                        itemCount: _sites.length,
                        itemBuilder: (context, index) {
                          final site = _sites[index];
                          final workerCount = site['_count']?['workers'] ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.deepOrange,
                                child:
                                    Icon(Icons.business, color: Colors.white),
                              ),
                              title: Text(site['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${site['location'] ?? 'No location'} • $workerCount Workers',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Options button
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    tooltip: 'Site Options',
                                    onPressed: () =>
                                        _showSiteOptions(site, userRole),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 14),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkerListScreen(
                                        siteId: site['id'],
                                        siteName: site['name']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: userRole == 'ADMIN' || userRole == 'MANAGER'
          ? FloatingActionButton(
              onPressed: _showAddSiteDialog,
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
