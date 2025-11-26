import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
// import 'package:platform/platform.dart'; // Bawaan android_intent biasanya butuh ini, tapi opsional

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

// 1. GATEKEEPER
class KioskGuardian extends StatelessWidget {
  const KioskGuardian({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KioskMode>(
      stream: watchKioskMode(),
      builder: (context, snapshot) {
        final mode = snapshot.data;
        if (mode == null)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        if (mode == KioskMode.enabled) return const ExamPage();
        return const WarningPage();
      },
    );
  }
}

class WarningPage extends StatefulWidget {
  const WarningPage({super.key});

  @override
  State<WarningPage> createState() => _WarningPageState();
}

class _WarningPageState extends State<WarningPage> {
  String _brand = "";
  String _guideText =
      "Buka Pengaturan > Keamanan > Screen Pinning > ON"; // Default
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _detectDeviceBrand();
  }

  Future<void> _detectDeviceBrand() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    setState(() {
      _brand = androidInfo.manufacturer.toLowerCase();
      _setGuideText(_brand);
    });
  }

  void _setGuideText(String brand) {
    if (brand.contains('oppo') || brand.contains('realme')) {
      _guideText =
          "1. Buka Pengaturan > Kata Sandi & Keamanan\n2. Pilih 'Keamanan Sistem' / 'More Security'\n3. Cari 'Penyematan Layar' (Screen Pinning) -> ON\n4. WAJIB Matikan Gesture Usap, ganti ke Tombol Navigasi.";
    } else if (brand.contains('vivo')) {
      _guideText =
          "1. Buka Pengaturan > Keamanan & Privasi\n2. Pilih 'More Security Settings'\n3. Aktifkan 'Penyematan Layar' (Screen Pinning).\n4. Gunakan Tombol Navigasi Biasa.";
    } else if (brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco')) {
      _guideText =
          "1. Buka Setelan > Sandi & Keamanan > Privasi\n2. Cari 'Penyematan Layar'.\n3. Jika pakai Fullscreen Gesture, matikan dulu.";
    } else if (brand.contains('infinix') || brand.contains('tecno')) {
      _guideText =
          "1. Buka Pengaturan > Keamanan\n2. Cari 'Penyematan Layar' di paling bawah.";
    } else if (brand.contains('samsung')) {
      _guideText =
          "1. Buka Pengaturan > Biometrik & Keamanan > Pengaturan Keamanan Lainnya\n2. Aktifkan 'Sematkan Jendela'.";
    }
  }

  Future<void> _openSecuritySettings() async {
    const intent = AndroidIntent(action: 'android.settings.SECURITY_SETTINGS');
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    String displayBrand = _brand.toUpperCase();

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
                  "HP Terdeteksi: $displayBrand",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Text(
                        "CARA MENGATASI:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text(
                        _guideText,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 15),
                      // TOMBOL PINTAS KE SETTING
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text("Buka Pengaturan Keamanan"),
                        onPressed: _openSecuritySettings,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ERROR MESSAGE (Kalau masih gagal)
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
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text("SAYA SUDAH ATUR, MULAI UJIAN"),
                onPressed: () async {
                  try {
                    setState(() => _errorMessage = "");
                    await startKioskMode();
                  } catch (e) {
                    setState(() {
                      _errorMessage =
                          "Masih Gagal. Pastikan 'Screen Pinning' sudah ON dan JANGAN pakai Gesture Usap.";
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});
  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  // GANTI URL DI SINI
  final String _examUrl = "https://ujian.smkairlanggabpn.sch.id";

  @override
  void initState() {
    super.initState();
    _initSecurity();
    _initWebView();
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
          onWebResourceError: (error) {},
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
          content: const Text('Pastikan sudah LOGOUT.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'KELUAR',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                await stopKioskMode();
                await ScreenProtector.preventScreenshotOff();
                SystemNavigator.pop();
              },
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
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SMKS Airlangga",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text("CBT Online v2.1.5", style: TextStyle(fontSize: 12)),
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
            WebViewWidget(controller: _controller),
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
  String _timeString = "";
  bool _isConnected = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getBattery();
    _checkConnectivity();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _getTime(),
    );
  }

  void _getBattery() async {
    final level = await _battery.batteryLevel;
    setState(() => _batteryLevel = level);
    _battery.onBatteryStateChanged.listen((state) async {
      final l = await _battery.batteryLevel;
      setState(() => _batteryLevel = l);
    });
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    if (mounted) setState(() => _timeString = formattedTime);
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
        Text("$_batteryLevel%", style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Icon(
          _batteryLevel > 20 ? Icons.battery_full : Icons.battery_alert,
          size: 18,
          color: _batteryLevel > 20 ? Colors.white : Colors.red,
        ),
        const SizedBox(width: 5),
      ],
    );
  }
}
