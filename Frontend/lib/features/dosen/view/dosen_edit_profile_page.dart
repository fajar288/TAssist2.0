import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/dosen_service.dart';
import 'package:produk/core/helpers/avatar_helper.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna background soft
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Sesuai navBlue TAssist
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                      color: const Color(0xFFE2E8F0),
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
                        ? const Icon(Icons.person, size: 60, color: Color(0xFF94A3B8))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
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
            _buildTextField('Email Address', _emailController, Icons.email_outlined, isReadOnly: true),
            const SizedBox(height: 16),
            
            _buildTextField('Kuota Bimbingan', _kuotaController, Icons.people_outline, isNumeric: true),
            const SizedBox(height: 32),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ubah Password (Opsional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Password Baru', _passwordController, Icons.lock_outline, isPassword: true),
            const SizedBox(height: 16),
            _buildTextField('Konfirmasi Password Baru', _passwordConfirmController, Icons.lock_outline, isPassword: true),
            const SizedBox(height: 40),

            // Button Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false, bool isPassword = false, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          obscureText: isPassword,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: isReadOnly ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF1F5F9) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
            ),
          ),
        ),
      ],
    );
  }
}