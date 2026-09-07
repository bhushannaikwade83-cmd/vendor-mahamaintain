import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../models/job_models.dart';
import '../repositories/jobs_repository.dart';
import '../state/partner_app_state.dart';
import 'app_toast.dart';
import 'job_card.dart';
import '../utils/error_messages.dart';

void openJobDetailsSheet(BuildContext hostContext, int jobId) {
  showModalBottomSheet(
    context: hostContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => JobDetailsSheet(jobId: jobId, hostContext: hostContext),
  );
}

class JobDetailsSheet extends StatefulWidget {
  final int jobId;
  final BuildContext hostContext;
  const JobDetailsSheet({required this.jobId, required this.hostContext, Key? key}) : super(key: key);

  @override
  State<JobDetailsSheet> createState() => _JobDetailsSheetState();
}

class _JobDetailsSheetState extends State<JobDetailsSheet> {
  final _otpController = TextEditingController();
  final _picker = ImagePicker();
  File? _capturedAfterPhoto;
  bool _busy = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _accept() async {
    setState(() => _busy = true);
    final job = partnerAppState.jobById(widget.jobId);
    try {
      await partnerAppState.acceptJob(widget.jobId);
      if (!mounted) return;
      Navigator.pop(context);
      showAppToast(widget.hostContext, 'Job accepted! ${job?.customer ?? ''} • ${job?.service ?? ''}',
          type: ToastType.success);
    } on JobActionException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(widget.hostContext, friendlyErrorMessage(e), type: ToastType.error);
    }
  }

  void _reject() async {
    setState(() => _busy = true);
    try {
      await partnerAppState.rejectJob(widget.jobId);
      if (!mounted) return;
      Navigator.pop(context);
      showAppToast(widget.hostContext, 'Job rejected', type: ToastType.info);
    } on JobActionException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(widget.hostContext, friendlyErrorMessage(e), type: ToastType.error);
    }
  }

  void _navigate() {
    final job = partnerAppState.jobById(widget.jobId);
    if (job == null) return;
    showAppToast(widget.hostContext, 'Opening Google Maps navigation to ${job.customer}...', type: ToastType.info);
  }

  void _startJob() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    setState(() => _busy = true);
    try {
      await partnerAppState.startJob(widget.jobId, beforePhoto: photo != null ? File(photo.path) : null);
      if (!mounted) return;
      Navigator.pop(context);
      showAppToast(widget.hostContext, 'Job started', type: ToastType.success);
    } on JobActionException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(widget.hostContext, friendlyErrorMessage(e), type: ToastType.error);
    }
  }

  Future<void> _captureAfterPhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return;
    setState(() => _capturedAfterPhoto = File(photo.path));
  }

  void _completeJob() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      showAppToast(widget.hostContext, 'Please enter a valid 6-digit OTP', type: ToastType.error);
      return;
    }
    final job = partnerAppState.jobById(widget.jobId);
    if (job == null) return;
    setState(() => _busy = true);
    try {
      final amount = await partnerAppState.completeJob(widget.jobId, otp, afterPhoto: _capturedAfterPhoto);
      if (!mounted) return;
      Navigator.pop(context);
      showAppToast(widget.hostContext, 'Job completed! ₹$amount added to your wallet', type: ToastType.success);
      Future.delayed(const Duration(milliseconds: 900), () {
        showRatingPromptToast(
          widget.hostContext,
          customerFirstName: job.customer.split(' ').first,
          onRate: (r) => partnerAppState.rateJob(widget.jobId, r),
        );
      });
    } on JobActionException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(widget.hostContext, friendlyErrorMessage(e), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: partnerAppState,
      builder: (context, _) {
        final job = partnerAppState.jobById(widget.jobId);
        if (job == null) return const SizedBox.shrink();

        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                                  children: [
                                    TextSpan(text: job.service),
                                    TextSpan(
                                      text: '  • ${job.type}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal, fontSize: 12, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('${job.time} • ${job.distance}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER',
                              style: TextStyle(fontSize: 11, letterSpacing: 1, color: kSlateText)),
                          const SizedBox(height: 4),
                          Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kEmeraldBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, size: 12, color: kEmerald),
                                    const SizedBox(width: 6),
                                    Text(job.phone,
                                        style: const TextStyle(color: kEmerald, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  showAppToast(widget.hostContext, 'Address copied to clipboard', type: ToastType.success);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy, size: 11, color: Colors.black54),
                                      SizedBox(width: 5),
                                      Text('Copy Address',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: kSlateBorder),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Service Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(job.address, style: const TextStyle(color: kSlateText, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ESTIMATED DURATION', style: TextStyle(fontSize: 10, color: kSlateText)),
                                    Text(job.duration, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PAYMENT MODE', style: TextStyle(fontSize: 10, color: kSlateText)),
                                    Text('${job.paymentMode} • ₹${job.amount}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (job.notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('NOTES FROM CUSTOMER', style: TextStyle(fontSize: 10, color: kSlateText)),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEFCE8),
                                border: Border.all(color: const Color(0xFFFEF3C7)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(job.notes, style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                          if (job.status == JobStatus.inProgress || job.status == JobStatus.completed) ...[
                            const SizedBox(height: 16),
                            const Text('JOB PROOF', style: TextStyle(fontSize: 11, letterSpacing: 1, color: kSlateText)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                    child: _photoBox('BEFORE', Icons.camera_alt, AppTheme.saffron, job.beforePhoto,
                                        localFile: null, job: job)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _photoBox('AFTER', Icons.camera_alt, kEmerald, job.afterPhoto,
                                        localFile: _capturedAfterPhoto, job: job)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: kSlateBorder)),
                    ),
                    child: _buildActions(job),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _photoBox(String label, IconData icon, Color color, String? url,
      {required File? localFile, required Job job}) {
    // BEFORE is captured once, when the job is started - it isn't editable
    // here. AFTER can be captured (and re-captured) while the job is in
    // progress, then submitted together with the completion OTP.
    final canCapture = label == 'AFTER' && job.status == JobStatus.inProgress;
    Widget content;
    if (localFile != null) {
      content = ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(localFile, fit: BoxFit.cover));
    } else if (url != null) {
      content = ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.cover));
    } else {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          canCapture ? 'Tap to capture' : 'No photo',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: canCapture
              ? InkWell(onTap: _captureAfterPhoto, borderRadius: BorderRadius.circular(16), child: content)
              : content,
        ),
      ],
    );
  }

  Widget _buildActions(Job job) {
    switch (job.status) {
      case JobStatus.newJob:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _reject,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Reject', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : _accept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Accept Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      case JobStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.saffron.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(Icons.directions, color: AppTheme.saffron, size: 18),
                label: Text('Navigate', style: TextStyle(color: AppTheme.saffron, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : _startJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Start Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      case JobStatus.inProgress:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Enter Customer OTP to Complete',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kSlateText)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '6-digit OTP',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: kEmerald)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _completeJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('✓ Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Ask the customer to read out the code sent to them once the job is done.',
                style: TextStyle(fontSize: 10, color: kSlateText)),
          ],
        );
      case JobStatus.completed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: kEmeraldBg, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: kEmerald, size: 16),
                  SizedBox(width: 6),
                  Text('Job Completed Successfully',
                      style: TextStyle(color: kEmerald, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            if (job.rating != null) ...[
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Customer rated you ',
                  style: const TextStyle(fontSize: 12),
                  children: [
                    TextSpan(
                        text: '${job.rating} ★',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      case JobStatus.cancelled:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('This job was cancelled by the customer.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
        );
    }
  }
}
