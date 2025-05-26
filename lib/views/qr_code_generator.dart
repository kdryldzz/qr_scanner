import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class QRCodeGenerator extends StatefulWidget {
  final String? initialData;
  const QRCodeGenerator({super.key, this.initialData});

  @override
  _QRCodeGeneratorState createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  String qrData = "";
  bool showQR = false;
  final GlobalKey qrKey = GlobalKey();
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      setState(() {
        qrData = widget.initialData!;
        textController.text = widget.initialData!;
        showQR = true;
      });
    }
  }

  Future<void> _saveToHistory(String qrData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> generatedHistory = prefs.getStringList('generated_qr_history') ?? [];
    
    if (!generatedHistory.contains(qrData)) {
      if (generatedHistory.length >= 50) {
        generatedHistory.removeLast();
      }
      generatedHistory.insert(0, qrData);
      await prefs.setStringList('generated_qr_history', generatedHistory);
    }
  }

  Future<void> _captureAndSavePng() async {
    try {
      final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      
      // Harici depolama dizinini al
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Depolama dizini bulunamadı');
      }
      
      // Downloads klasörüne git (Android için)
      final downloadsPath = directory.path.replaceAll('/Android/data/com.example.qr_scanner/files', '/Download');
      final fileName = 'QR_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '$downloadsPath/$fileName';
      
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('QR kod başarıyla indirildi!'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod kaydedilirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareQrCode() async {
    try {
      final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'QR Code for: $qrData',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod paylaşılırken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 10,left: 10,right: 10,bottom: 10),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text(
                "Generate QR Code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter URL or text",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    qrData = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: () {
                  if (qrData.isNotEmpty) {
                    setState(() {
                      showQR = true;
                    });
                    _saveToHistory(qrData);
                  }
                },
                icon: const Icon(Icons.qr_code),
                label: const Text("Generate QR Code"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: const Color.fromARGB(255, 11, 56, 93),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  height: 250,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(showQR ? 1 : 0.1),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(showQR ? 0.2 : 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: showQR
                      ? SizedBox(
                          height: 200,
                          width: 200,
                          child: Center(
                            // QR kodu oluşturma
                        child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                      ))
                      : const SizedBox(
                          height: 200,
                          width: 200,
                          child: Center(
                            child: Icon(
                              Icons.qr_code_2,
                              size: 80,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              if (showQR) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _captureAndSavePng,
                    icon: const Icon(Icons.download),
                    label: const Text("Save"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.green.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      iconColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _shareQrCode,
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.blue.shade900.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      iconColor: Colors.white,
                    ),
                  ),
                ],
              ),
              ],
          ),
        ),
      ),
    );
  }
}