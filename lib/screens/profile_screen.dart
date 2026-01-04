import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _gradeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
    _gradeController = TextEditingController(text: user?.grade ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      await context.read<AuthProvider>().updateProfile(
            displayName: _nameController.text.trim(),
            department: _departmentController.text.trim(),
            grade: _gradeController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            )
          else
            IconButton(
              onPressed: () {
                setState(() => _isEditing = false);
                // Reset controllers
                final user = context.read<AuthProvider>().userModel;
                _nameController.text = user?.displayName ?? '';
                _departmentController.text = user?.department ?? '';
                _gradeController.text = user?.grade ?? '';
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.userModel;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profil Fotoğrafı
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: user?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildInitials(user.displayName),
                              ),
                            )
                          : _buildInitials(user?.displayName),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: Colors.white,
                            onPressed: () {
                              // Storage aktif olduğunda çalışacak
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Firebase Storage aktif değil'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email (düzenlenemez)
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                if (_isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Bölüm',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gradeController,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf',
                      hintText: 'Örn: 2. Sınıf',
                      prefixIcon: Icon(Icons.grade_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kaydet'),
                  ),
                ] else ...[
                  // Görüntüleme modu
                  _buildInfoTile(
                    icon: Icons.person,
                    label: 'Ad Soyad',
                    value: user?.displayName ?? 'Belirtilmemiş',
                  ),
                  _buildInfoTile(
                    icon: Icons.school,
                    label: 'Bölüm',
                    value: user?.department ?? 'Belirtilmemiş',
                  ),
                  _buildInfoTile(
                    icon: Icons.grade,
                    label: 'Sınıf',
                    value: user?.grade ?? 'Belirtilmemiş',
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Çıkış Yap
                OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitials(String? name) {
    final initials = name != null && name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';
    return Text(
      initials.toUpperCase(),
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
