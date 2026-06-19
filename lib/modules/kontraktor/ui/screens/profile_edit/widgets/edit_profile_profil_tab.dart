import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class EditProfileProfilTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController companyCtrl;
  final TextEditingController nibCtrl;
  final TextEditingController npwpCtrl;
  final File? avatarFile;
  final String? currentAvatarUrl;
  final VoidCallback onPickAvatar;

  const EditProfileProfilTab({
    super.key,
    required this.nameCtrl,
    required this.companyCtrl,
    required this.nibCtrl,
    required this.npwpCtrl,
    required this.avatarFile,
    required this.currentAvatarUrl,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Center Avatar with camera icon
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: onPickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.cardCream,
                          backgroundImage: avatarFile != null
                              ? FileImage(avatarFile!)
                              : (currentAvatarUrl != null &&
                                      currentAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(currentAvatarUrl!)
                                      as ImageProvider
                                  : null,
                          child: (avatarFile == null &&
                                  (currentAvatarUrl == null ||
                                      currentAvatarUrl!.isEmpty))
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 48,
                                )
                              : null,
                        ),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 14,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('Nama Lengkap'),
          _buildTextField(nameCtrl, 'Masukkan nama lengkap'),
          const SizedBox(height: 16),
          _buildLabel('Nama Perusahaan'),
          _buildTextField(companyCtrl, 'Masukkan nama perusahaan/vendor'),
          const SizedBox(height: 16),
          _buildLabel('Nomor Induk Berusaha (NIB)'),
          _buildTextField(
            nibCtrl,
            'Masukkan 13 digit NIB',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildLabel('Nomor Pokok Wajib Pajak (NPWP)'),
          _buildTextField(npwpCtrl, 'Masukkan NPWP perusahaan'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
