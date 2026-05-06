import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/checkin_provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_text_field.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final String eventId;
  const CheckinScreen({super.key, required this.eventId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) setState(() => _isOffline = result == ConnectivityResult.none);
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOffline = result == ConnectivityResult.none);
  }

  void _handleCheckIn(String id, String name) async {
    if (id.isEmpty && name.isEmpty) {
      _showSnackBar('Invalid participant ID or Name', isError: true);
      return;
    }
    
    final error = await ref.read(checkinProvider(widget.eventId).notifier).checkInParticipant(participantId: id, participantName: name);
    
    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _showSnackBar('✓ $name checked in successfully', isError: false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? AppColors.danger : AppColors.success),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
          ],
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? AppColors.danger : AppColors.success, width: 2),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final eventName = events.firstWhere((e) => e.id == widget.eventId, orElse: () => throw Exception('Not found')).name;

    return Scaffold(
      appBar: AppBar(
        title: Text(eventName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'SCANNER'),
                  Tab(text: 'MANUAL'),
                  Tab(text: 'GENERATE'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isOffline ? 40 : 0,
            width: double.infinity,
            color: AppColors.warning,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text('Offline · Saving locally', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _QRScannerTab(onScan: (id) => _handleCheckIn(id, 'Scanned User')),
                _ManualEntryTab(onSubmit: _handleCheckIn),
                const _GenerateQRTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QRScannerTab extends StatefulWidget {
  final Function(String) onScan;
  const _QRScannerTab({required this.onScan});

  @override
  State<_QRScannerTab> createState() => _QRScannerTabState();
}

class _QRScannerTabState extends State<_QRScannerTab> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      if (_isProcessing) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        setState(() => _isProcessing = true);
                        final value = barcodes.first.rawValue!;
                        final parts = value.split('|');
                        final id = parts[0];
                        widget.onScan(id);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _isProcessing = false);
                        });
                      }
                    },
                  ),
                  CustomPaint(painter: ScannerOverlayPainter()),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * 300 + 50,
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                          ),
                        ),
                      );
                    },
                  ),
                  if (_isProcessing)
                    Container(
                      color: AppColors.textPrimary.withOpacity(0.8),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
                            const SizedBox(height: 16),
                            Text('Processed', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('Align QR code to scan', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                Text('Position the QR code within the frame above', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final scanArea = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 250, height: 250);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    const length = 30.0;
    // Top Left
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft.translate(length, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft.translate(0, length), borderPaint);
    // Top Right
    canvas.drawLine(scanArea.topRight, scanArea.topRight.translate(-length, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight.translate(0, length), borderPaint);
    // Bottom Left
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft.translate(length, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft.translate(0, -length), borderPaint);
    // Bottom Right
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight.translate(-length, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight.translate(0, -length), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ManualEntryTab extends StatefulWidget {
  final Function(String, String) onSubmit;
  const _ManualEntryTab({required this.onSubmit});

  @override
  State<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends State<_ManualEntryTab> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AppTextField(
                    controller: _idController,
                    labelText: 'Participant ID (Optional)',
                    leadingIcon: const Icon(Icons.badge, color: AppColors.textSecondary),
                    isMono: true,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameController,
                    labelText: 'Participant Name',
                    leadingIcon: const Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              widget.onSubmit(_idController.text.trim(), _nameController.text.trim());
              _idController.clear();
              _nameController.clear();
            },
            child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _GenerateQRTab extends StatefulWidget {
  const _GenerateQRTab();

  @override
  State<_GenerateQRTab> createState() => _GenerateQRTabState();
}

class _GenerateQRTabState extends State<_GenerateQRTab> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  String? _qrData;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _generate() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required to generate QR')));
      return;
    }
    setState(() {
      _qrData = '${id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id}|$name';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AppTextField(
                    controller: _idController,
                    labelText: 'Participant ID (Optional)',
                    leadingIcon: const Icon(Icons.badge, color: AppColors.textSecondary),
                    isMono: true,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameController,
                    labelText: 'Participant Name',
                    leadingIcon: const Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (_qrData != null) ...[
            const SizedBox(height: 32),
            Center(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryDark),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Scan this code at the entrance', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ]
        ],
      ),
    );
  }
}
