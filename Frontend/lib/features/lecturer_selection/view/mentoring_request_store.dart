import 'package:flutter/foundation.dart';

class MentoringRequestStore {
  // Daftar request yang dikirim mahasiswa
  static final ValueNotifier<List<RequestedLecturer>> requests =
      ValueNotifier<List<RequestedLecturer>>([]);

  // Status apakah bimbingan sudah disetujui dosen
  static final ValueNotifier<bool> isApproved = ValueNotifier<bool>(false);

  static void request(RequestedLecturer lecturer) {
    if (!isRequested(lecturer.id)) {
      requests.value = [...requests.value, lecturer];
    }
  }

  static void cancel(String lecturerId) {
    requests.value = requests.value.where((r) => r.id != lecturerId).toList();
  }

  static bool isRequested(String lecturerId) {
    return requests.value.any((r) => r.id == lecturerId);
  }

  // Fungsi untuk dosen menyetujui bimbingan
  static void approve() {
    isApproved.value = true;
  }
}

class RequestedLecturer {
  const RequestedLecturer({
    required this.id,
    required this.name,
    required this.major,
    required this.imageUrl,
    required this.nid,
    required this.guidanceQuotaLeft,
  });

  final String id;
  final String name;
  final String major;
  final String imageUrl;
  final String nid;
  final int guidanceQuotaLeft;
}