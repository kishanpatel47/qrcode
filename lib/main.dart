import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share/share.dart';
import 'dart:html' as html;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Drive QR Code Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _qrData = '';
  GlobalKey _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Drive QR Code Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Google Drive URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _qrData = _controller.text;
                });
              },
              child: Text('Generate QR Code'),
            ),
            SizedBox(height: 20),
            if (_qrData.isNotEmpty)
              RepaintBoundary(
                key: _qrKey,
                child: QrImageView(
                  data: _qrData,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            SizedBox(height: 20),
            if (_qrData.isNotEmpty) ...[
              ElevatedButton(
                onPressed: _shareQrCode,
                child: Text('Share QR Code'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _downloadQrCode,
                child: Text('Download QR Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _shareQrCode() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareFiles([file.path],
          text: 'Check out this QR code!',
          mimeTypes: ['image/png']); // Specify MIME type as PNG
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }

  Future<void> _downloadQrCode() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Convert Uint8List to base64
      String base64Image = base64Encode(pngBytes);

      // Create a download link
      final anchor = html.AnchorElement(
        href: 'data:application/octet-stream;base64,$base64Image',
      )
        ..setAttribute('download', 'qr_code.png')
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code downloaded'),
        ),
      );
    } catch (e) {
      print('Error downloading QR code: $e');
    }
  }
}
