import 'package:flutter/material.dart';
import '../cloud/cloud_service.dart';
import 'auth_page.dart';
import 'admin_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool owner = false;
  bool checkingOwner = false;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    if (!CloudService.signedIn) {
      if (mounted) setState(() => owner = false);
      return;
    }
    setState(() => checkingOwner = true);
    try {
      final value = await CloudService.isOwner();
      if (mounted) setState(() => owner = value);
    } catch (_) {
      if (mounted) setState(() => owner = false);
    } finally {
      if (mounted) setState(() => checkingOwner = false);
    }
  }

  Future<void> _openAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    await _loadOwner();
    if (mounted) setState(() {});
  }

  Future<void> _sync() async {
    try {
      await CloudService.pushLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت مزامنة بياناتك بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشلت المزامنة: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await CloudService.signOut();
    if (mounted) setState(() => owner = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = CloudService.user;
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (!CloudService.enabled)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'الخدمة السحابية غير مفعّلة في نسخة التطبيق الحالية. '
                  'سيظل التطبيق يعمل محليًا.',
                ),
              ),
            )
          else if (user == null) ...[
            const Icon(Icons.account_circle_outlined, size: 76),
            const SizedBox(height: 12),
            const Text(
              'أنت غير مسجل الدخول',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openAuth,
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول / إنشاء حساب'),
            ),
          ] else ...[
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.email ?? 'مستخدم'),
              subtitle: const Text('حساب سكينة السحابي'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _sync,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('مزامنة بياناتي الآن'),
            ),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
            if (checkingOwner)
              const Center(child: CircularProgressIndicator())
            else if (owner) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('لوحة المالك'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
