import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:android_intent_plus/android_intent.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMKS Airlangga CBT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const KioskGuardian(),
    );
  }
}

class KioskGuardian extends StatefulWidget {
  const KioskGuardian({super.key});

  @override
  State<KioskGuardian> createState() => _KioskGuardianState();
}

class _KioskGuardianState extends State<KioskGuardian> {
  bool _isBypass = false; // Status Jalur Darurat

  void _activateBypass() {
    setState(() {
      _isBypass = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBypass) {
      return const ExamPage(isBypassMode: true);
    }

    return StreamBuilder<KioskMode>(
      stream: watchKioskMode(),
      builder: (context, snapshot) {
        final mode = snapshot.data;

        if (mode == null)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        if (mode == KioskMode.enabled) {
          return const ExamPage(isBypassMode: false);
        }

        return WarningPage(onBypass: _activateBypass);
      },
    );
  }
}

class WarningPage extends StatefulWidget {
  final VoidCallback onBypass;
  const WarningPage({super.key, required this.onBypass});

  @override
  State<WarningPage> createState() => _WarningPageState();
}

class _WarningPageState extends State<WarningPage> {
  String _brand = "";
  String _guideText = "Buka Pengaturan > Keamanan > Screen Pinning > ON";
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _detectDeviceBrand();
  }

  Future<void> _detectDeviceBrand() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _brand = androidInfo.manufacturer.toLowerCase();
        _setGuideText(_brand);
      });
    }
  }

  void _setGuideText(String brand) {
    if (brand.contains('oppo') || brand.contains('realme')) {
      _guideText =
          "1. Pengaturan > Kata Sandi & Keamanan > Keamanan Sistem\n2. Cari 'Penyematan Layar' -> ON\n3. WAJIB Matikan Gesture Usap, ganti ke Tombol Navigasi.";
    } else if (brand.contains('vivo')) {
      _guideText =
          "1. Pengaturan > Keamanan & Privasi > More Security Settings\n2. Aktifkan 'Penyematan Layar'.\n3. Gunakan Tombol Navigasi Biasa.";
    } else if (brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco')) {
      _guideText =
          "1. Setelan > Sandi & Keamanan > Privasi > Penyematan Layar.\n2. Matikan Fullscreen Gesture.";
    } else if (brand.contains('samsung')) {
      _guideText =
          "1. Pengaturan > Biometrik & Keamanan > Pengaturan Keamanan Lainnya > Sematkan Jendela.";
    }
  }

  Future<void> _openSecuritySettings() async {
    const intent = AndroidIntent(action: 'android.settings.SECURITY_SETTINGS');
    await intent.launch();
  }

  // DIALOG RAHASIA KHUSUS GURU
  Future<void> _showEmergencyDialog() async {
    final TextEditingController passController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Mode Darurat (Guru Only)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Gunakan ini HANYA jika HP siswa tidak support Screen Pinning.\n\nSiswa akan kena AUTO-RELOAD jika mencoba keluar aplikasi.",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Pengawas",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // --- SETTING PASSWORD GURU DI SINI ---
                if (passController.text == "jujur2025") {
                  Navigator.pop(context);
                  widget.onBypass(); // Aktifkan Bypass
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password Salah!")),
                  );
                }
              },
              child: const Text(
                "Masuk Paksa",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 70, color: Colors.red),
              const SizedBox(height: 15),
              const Text(
                "MODE UJIAN BELUM AKTIF",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "HP Terdeteksi: ${_brand.toUpperCase()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Text(
                        "PANDUAN AKTIVASI:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text(
                        _guideText,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text("Buka Pengaturan"),
                        onPressed: _openSecuritySettings,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text("SAYA SUDAH ATUR, MULAI UJIAN"),
                onPressed: () async {
                  try {
                    setState(() => _errorMessage = "");
                    await startKioskMode();
                  } catch (e) {
                    setState(
                      () => _errorMessage =
                          "Gagal Mengunci. Cek Panduan di atas.",
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
              // TOMBOL RAHASIA
              TextButton(
                onPressed: _showEmergencyDialog,
                child: const Text(
                  "HP Tidak Support? Klik di sini",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. EXAM PAGE (WEBVIEW + ANTI CURANG)
// ==========================================
class ExamPage extends StatefulWidget {
  final bool isBypassMode;
  const ExamPage({super.key, this.isBypassMode = false});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;

  // --- GANTI IP SERVER DI SINI ---
  final String _examUrl = "https://ujian.smkairlanggabpn.sch.id/";
  // ------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Pantau aplikasi
    _initSecurity();
    _initWebView();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.isBypassMode) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        debugPrint("KECURANGAN TERDETEKSI: RELOAD PAKSA");
        _controller.reload(); // Hukuman: Refresh Halaman

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ANDA KELUAR APLIKASI! Halaman dimuat ulang."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _initSecurity() async {
    WakelockPlus.enable();
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.preventScreenshotOn();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
            // Tampilkan Notifikasi Error Merah
            if (error.errorCode < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 10),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Gagal Terhubung!",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${error.description}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Text(
                        "Matikan Data Seluler, Pakai WiFi Sekolah.",
                        style: TextStyle(fontSize: 10, color: Colors.yellow),
                      ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'COBA LAGI',
                    textColor: Colors.white,
                    onPressed: () => _controller.reload(),
                  ),
                ),
              );
            }
          },
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36 ExamSkarla",
      )
      ..loadRequest(Uri.parse(_examUrl));
  }

  Future<void> _exitApp() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar Ujian?'),
          content: const Text(
            'Pastikan Anda sudah LOGOUT dan mengirim jawaban.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await stopKioskMode();
                await ScreenProtector.preventScreenshotOff();
                SystemNavigator.pop();
              },
              child: const Text(
                'KELUAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,

        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SMKS Airlangga",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.isBypassMode
                    ? "MODE DARURAT (UNPINNED)"
                    : "CBT Online v2.1.9",
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isBypassMode
                      ? Colors.yellowAccent
                      : Colors.white70,
                ),
              ),
            ],
          ),
          actions: [
            const ExamStatusBar(),
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.redAccent,
              ),
              onPressed: _exitApp,
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
              gestureRecognizers: Set()
                ..add(
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                )
                ..add(
                  Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                ),
            ),
            if (_isLoading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class ExamStatusBar extends StatefulWidget {
  const ExamStatusBar({super.key});
  @override
  State<ExamStatusBar> createState() => _ExamStatusBarState();
}

class _ExamStatusBarState extends State<ExamStatusBar> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  String _timeString = "";
  bool _isConnected = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initBattery();
    _checkConnectivity();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _getTime(),
    );
  }

  void _initBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    if (mounted)
      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });

    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final l = await _battery.batteryLevel;
      if (mounted)
        setState(() {
          _batteryState = state;
          _batteryLevel = l;
        });
    });
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    if (mounted)
      setState(
        () => _timeString =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      );
  }

  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      bool hasInternet =
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
      if (mounted) setState(() => _isConnected = hasInternet);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getBatteryColor() {
    if (_batteryState == BatteryState.charging) return Colors.greenAccent;
    if (_batteryLevel <= 20) return Colors.redAccent;
    return Colors.white;
  }

  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging)
      return Icons.battery_charging_full;
    if (_batteryLevel <= 20) return Icons.battery_alert;
    return Icons.battery_full;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(_timeString, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Icon(
          _isConnected ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: _isConnected ? Colors.white : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          "$_batteryLevel%",
          style: TextStyle(
            fontSize: 12,
            color: _getBatteryColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Icon(_getBatteryIcon(), size: 18, color: _getBatteryColor()),
        const SizedBox(width: 5),
      ],
    );
  }
}
