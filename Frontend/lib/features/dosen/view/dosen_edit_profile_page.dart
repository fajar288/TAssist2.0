import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_snackbars.dart';
import '../data/dosen_service.dart';
import 'package:tassist/core/helpers/avatar_helper.dart';

class DosenEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialProfile; // Passing data profil dari dashboard saat dipanggil

  const DosenEditProfilePage({Key? key, required this.initialProfile}) : super(key: key);

  @override
  State<DosenEditProfilePage> createState() => _DosenEditProfilePageState();
}

class _DosenEditProfilePageState extends State<DosenEditProfilePage> {
  final DosenService _dosenService = DosenService();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _kuotaController;
  late TextEditingController _passwordController;
  late TextEditingController _passwordConfirmController;

  PlatformFile? _selectedPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile['nama'] ?? '');
    _emailController = TextEditingController(text: widget.initialProfile['email'] ?? '');
    _kuotaController = TextEditingController(text: widget.initialProfile['kuota_bimbingan']?.toString() ?? '0');
    _passwordController = TextEditingController();
    _passwordConfirmController = TextEditingController();

    // Listener untuk mengecek perubahan setiap kali user mengetik
    _nameController.addListener(_checkChanges);
    _kuotaController.addListener(_checkChanges);
    _passwordController.addListener(_checkChanges);
    _passwordConfirmController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _kuotaController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    setState(() {}); // Memicu rebuild untuk mengecek get hasChanges
  }

  // Logika mendeteksi perubahan
  bool get _hasChanges {
    final bool nameChanged = _nameController.text != (widget.initialProfile['nama'] ?? '');
    final bool kuotaChanged = _kuotaController.text != (widget.initialProfile['kuota_bimbingan']?.toString() ?? '0');
    final bool passwordFilled = _passwordController.text.isNotEmpty;
    final bool photoChanged = _selectedPhoto != null;

    return nameChanged || kuotaChanged || passwordFilled || photoChanged;
  }

  Future<void> _pickPhoto() async {
    // Sesuai aturan checkpoint 5 TAssist: pakai FilePicker.pickFiles dan withData: true
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true, 
    );

    if (result != null) {
      setState(() {
        _selectedPhoto = result.files.first;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges) return;

    if (_passwordController.text.isNotEmpty && _passwordController.text != _passwordConfirmController.text) {
      AppSnackBars.error(context, 'Konfirmasi password tidak cocok!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Buka komentar (uncomment) dan panggil _dosenService menggunakan avatarFile
      await _dosenService.updateProfile(
        nama: _nameController.text,
        kuotaBimbingan: _kuotaController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
        avatarFile: _selectedPhoto,
      );
      
      if (mounted) {
        AppSnackBars.success(context, 'Profil berhasil diperbarui');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.backgroundOf(context);
    final surface = AppTheme.surfaceOf(context);
    final border = AppTheme.cardBorderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return Scaffold(
      backgroundColor: bg, // Warna background soft
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Area Foto Profil
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: border,
                      shape: BoxShape.circle,
                      image: _selectedPhoto != null && _selectedPhoto!.bytes != null
                          ? DecorationImage(
                              image: MemoryImage(_selectedPhoto!.bytes!),
                              fit: BoxFit.cover,
                            )
                          : (widget.initialProfile['avatar'] != null)
                              ? DecorationImage(
                                  image: NetworkImage(
                                    AvatarHelper.getAvatarUrl(
                                      avatar: widget.initialProfile['avatar'],
                                    )
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (_selectedPhoto == null && widget.initialProfile['avatar'] == null)
                        ? Icon(Icons.person_outlined, size: 56, color: textMuted)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Semantics(
                      button: true,
                      label: 'Ubah foto profil',
                      child: Tooltip(
                        message: 'Ubah foto profil',
                        child: InkWell(
                          onTap: _pickPhoto,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: surface, width: 3),
                            ),
                            child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField('Nama Lengkap', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            
            // Email (Read Only)
            _buildTextField('Alamat Email', _emailController, Icons.email_outlined, isReadOnly: true),
            const SizedBox(height: 16),
            
            _buildTextField('Kuota Bimbingan', _kuotaController, Icons.people_outline, isNumeric: true),
            const SizedBox(height: 32),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ubah Password (Opsional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Password Baru', _passwordController, Icons.lock_outline, isPassword: true),
            const SizedBox(height: 16),
            _buildTextField('Konfirmasi Password Baru', _passwordConfirmController, Icons.lock_outline, isPassword: true),
            const SizedBox(height: 32),

            // Button Save
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges ? AppTheme.primary : textMuted,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false, bool isPassword = false, bool isNumeric = false}) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.cardBorderOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          obscureText: isPassword,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: isReadOnly ? textMuted : textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textMuted, size: 20),
            filled: true,
            fillColor: isReadOnly ? AppTheme.backgroundOf(context) : AppTheme.surfaceOf(context),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: AppTheme.primaryOf(context)),
            ),
          ),
        ),
      ],
    );
  }
}