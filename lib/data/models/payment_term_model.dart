/// Model untuk satu termin/tahapan pembayaran dalam sebuah proyek konstruksi.
///
/// Status flow:
/// - 'pending'              → Kontraktor baru buat termin, client belum bayar
/// - 'waiting_confirmation' → Client klik "Sudah Membayar", kontraktor belum konfirmasi
/// - 'confirmed'            → Kontraktor konfirmasi pembayaran diterima, progres bisa dimulai
/// - 'progress_submitted'   → Kontraktor submit laporan progres, client belum review
/// - 'revision_requested'   → Client meminta perbaikan, kontraktor harus upload ulang
/// - 'completed'            → Client sudah menyetujui laporan progres, termin selesai
class PaymentTermModel {
  final String? id;
  final String projectId;
  final String bidId;
  final String vendorId;

  /// Nama termin, e.g. "DP Awal", "Termin 1", "Pelunasan"
  final String name;

  /// Persentase dari total harga deal (bid.price), e.g. 30 berarti 30%
  final double percentage;

  /// Nominal uang yang harus dibayar = bid.price * percentage / 100
  final double amount;

  /// 'pending' | 'waiting_confirmation' | 'confirmed' | 'progress_submitted' | 'revision_requested' | 'completed'
  final String status;

  /// Urutan termin (1, 2, 3, ...)
  final int orderIndex;

  /// Metode pembayaran yang dipilih client, e.g. 'bca', 'bni', 'mandiri', 'bri'
  final String? paymentMethod;

  /// Nomor virtual account yang ditampilkan ke client
  final String? virtualAccountNumber;

  /// Waktu client klik "Sudah Membayar"
  final DateTime? paidAt;

  /// Waktu kontraktor konfirmasi terima pembayaran
  final DateTime? confirmedAt;

  /// Catatan opsional dari kontraktor saat membuat termin
  final String? notes;

  final DateTime? createdAt;

  // ── Field Pelaporan Progres ──
  final String? progressDescription;
  final List<String>? progressImages;
  final String? progressPdfUrl;
  final DateTime? progressSubmittedAt;
  final DateTime? progressReviewedAt;

  // ── Field Revisi (baru) ──
  /// Catatan revisi dari client ketika mengajukan perubahan
  final String? revisionNotes;

  /// Waktu client mengajukan perubahan
  final DateTime? revisionRequestedAt;

  const PaymentTermModel({
    this.id,
    required this.projectId,
    required this.bidId,
    required this.vendorId,
    required this.name,
    required this.percentage,
    required this.amount,
    this.status = 'pending',
    required this.orderIndex,
    this.paymentMethod,
    this.virtualAccountNumber,
    this.paidAt,
    this.confirmedAt,
    this.notes,
    this.createdAt,
    this.progressDescription,
    this.progressImages,
    this.progressPdfUrl,
    this.progressSubmittedAt,
    this.progressReviewedAt,
    this.revisionNotes,
    this.revisionRequestedAt,
  });

  // ──────────────────────────────────────────
  // fromJson: dari response Supabase
  // ──────────────────────────────────────────
  factory PaymentTermModel.fromJson(Map<String, dynamic> json) {
    List<String>? imagesList;
    if (json['progress_images'] != null) {
      imagesList = List<String>.from(json['progress_images'] as List);
    }

    return PaymentTermModel(
      id: json['id'] as String?,
      projectId: json['project_id'] as String? ?? '',
      bidId: json['bid_id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      orderIndex: json['order_index'] as int? ?? 1,
      paymentMethod: json['payment_method'] as String?,
      virtualAccountNumber: json['virtual_account_number'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      progressDescription: json['progress_description'] as String?,
      progressImages: imagesList,
      progressPdfUrl: json['progress_pdf_url'] as String?,
      progressSubmittedAt: json['progress_submitted_at'] != null
          ? DateTime.tryParse(json['progress_submitted_at'] as String)
          : null,
      progressReviewedAt: json['progress_reviewed_at'] != null
          ? DateTime.tryParse(json['progress_reviewed_at'] as String)
          : null,
      revisionNotes: json['revision_notes'] as String?,
      revisionRequestedAt: json['revision_requested_at'] != null
          ? DateTime.tryParse(json['revision_requested_at'] as String)
          : null,
    );
  }

  // ──────────────────────────────────────────
  // toJson: untuk insert/update ke Supabase
  // ──────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'bid_id': bidId,
      'vendor_id': vendorId,
      'name': name,
      'percentage': percentage,
      'amount': amount,
      'status': status,
      'order_index': orderIndex,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (virtualAccountNumber != null)
        'virtual_account_number': virtualAccountNumber,
      if (notes != null) 'notes': notes,
      if (progressDescription != null) 'progress_description': progressDescription,
      if (progressImages != null) 'progress_images': progressImages,
      if (progressPdfUrl != null) 'progress_pdf_url': progressPdfUrl,
      if (progressSubmittedAt != null)
        'progress_submitted_at': progressSubmittedAt!.toIso8601String(),
      if (progressReviewedAt != null)
        'progress_reviewed_at': progressReviewedAt!.toIso8601String(),
      if (revisionNotes != null) 'revision_notes': revisionNotes,
      if (revisionRequestedAt != null)
        'revision_requested_at': revisionRequestedAt!.toIso8601String(),
    };
  }

  PaymentTermModel copyWith({
    String? id,
    String? projectId,
    String? bidId,
    String? vendorId,
    String? name,
    double? percentage,
    double? amount,
    String? status,
    int? orderIndex,
    String? paymentMethod,
    String? virtualAccountNumber,
    DateTime? paidAt,
    DateTime? confirmedAt,
    String? notes,
    DateTime? createdAt,
    String? progressDescription,
    List<String>? progressImages,
    String? progressPdfUrl,
    DateTime? progressSubmittedAt,
    DateTime? progressReviewedAt,
    String? revisionNotes,
    DateTime? revisionRequestedAt,
  }) {
    return PaymentTermModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      bidId: bidId ?? this.bidId,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
      paidAt: paidAt ?? this.paidAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      progressDescription: progressDescription ?? this.progressDescription,
      progressImages: progressImages ?? this.progressImages,
      progressPdfUrl: progressPdfUrl ?? this.progressPdfUrl,
      progressSubmittedAt: progressSubmittedAt ?? this.progressSubmittedAt,
      progressReviewedAt: progressReviewedAt ?? this.progressReviewedAt,
      revisionNotes: revisionNotes ?? this.revisionNotes,
      revisionRequestedAt: revisionRequestedAt ?? this.revisionRequestedAt,
    );
  }

  // ──────────────────────────────────────────
  // Status Helpers
  // ──────────────────────────────────────────

  /// Termin belum dibayar sama sekali
  bool get isPending => status == 'pending';

  /// Client sudah klaim bayar, kontraktor belum konfirmasi
  bool get isWaitingConfirmation => status == 'waiting_confirmation';

  /// Kontraktor konfirmasi pembayaran diterima
  bool get isConfirmed => status == 'confirmed';

  /// Kontraktor sudah kirim laporan progres, menunggu tinjauan client
  bool get isProgressSubmitted => status == 'progress_submitted';

  /// Client meminta perbaikan, kontraktor harus upload ulang
  bool get isRevisionRequested => status == 'revision_requested';

  /// Client sudah menyetujui laporan progres → termin selesai
  bool get isCompleted => status == 'completed';

  /// Helper: apakah pembayaran sudah diterima (confirmed atau lebih lanjut)
  bool get isPaymentReceived =>
      isConfirmed ||
      isProgressSubmitted ||
      isRevisionRequested ||
      isCompleted;
}
