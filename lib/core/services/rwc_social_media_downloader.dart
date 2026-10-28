import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'rwc_scraper_service.dart';

class SocialMediaImageInfo {
  final String idListingImage;
  final String imageUrl;

  const SocialMediaImageInfo({
    required this.idListingImage,
    required this.imageUrl,
  });
}

class RwcSocialMediaDownloader {
  static const String _baseUrl = 'https://raywhitecipete.net';
  static const String _defaultEmail = 'sosmedrwc@gmail.com';
  static const String _defaultPassword = r'sosial123$';

  static final RwcSocialMediaDownloader _instance =
      RwcSocialMediaDownloader._internal();
  factory RwcSocialMediaDownloader() => _instance;
  RwcSocialMediaDownloader._internal();

  String _cookies = '';

  void _updateCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      final parts = setCookie
          .split(RegExp(r',(?=\s*[A-Za-z0-9_\-]+=)'))
          .map((c) => c.split(';').first.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        final existing = _cookies
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        for (final p in parts) {
          final key = p.split('=').first;
          existing.removeWhere((e) => e.startsWith('$key='));
          existing.add(p);
        }
        _cookies = existing.join('; ');
      }
    }
  }

  /// Logs in to https://raywhitecipete.net/SocialMedia
  Future<bool> login({
    String email = _defaultEmail,
    String password = _defaultPassword,
  }) async {
    final client = http.Client();
    try {
      // 1. GET login page to grab anti-forgery token & session cookie
      final getRes = await client.get(
        Uri.parse('$_baseUrl/SocialMedia/Account/Login'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      ).timeout(const Duration(seconds: 15));
      _updateCookies(getRes);

      String token = '';
      final tokenMatch = RegExp(
        r'''name=["']__RequestVerificationToken["'][^>]+value=["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(getRes.body);
      if (tokenMatch != null) {
        token = tokenMatch.group(1) ?? '';
      }

      // 2. POST credentials
      final bodyFields = <String, String>{
        'Email': email,
        'Username': email,
        'Password': password,
        if (token.isNotEmpty) '__RequestVerificationToken': token,
      };

      final req = http.Request(
        'POST',
        Uri.parse('$_baseUrl/SocialMedia/Account/Login'),
      )
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
        ..headers['User-Agent'] =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15'
        ..headers['Cookie'] = _cookies
        ..bodyFields = bodyFields;

      final streamed =
          await client.send(req).timeout(const Duration(seconds: 15));
      final postRes = await http.Response.fromStream(streamed);
      _updateCookies(postRes);

      return postRes.statusCode == 302 ||
          postRes.statusCode == 200 ||
          _cookies.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Fetches social media image IDs for a listing
  Future<List<SocialMediaImageInfo>> getListingImages(String idListing) async {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    if (cleanId.isEmpty) return [];

    if (_cookies.isEmpty) {
      await login();
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/SocialMedia/Home/GetListingImageByIdListing?id=$cleanId',
      );
      final response = await http.get(
        url,
        headers: {
          'Cookie': _cookies,
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('[') || body.startsWith('{')) {
          final decoded = json.decode(body);
          final list = decoded is List
              ? decoded
              : (decoded is Map
                  ? (decoded['data'] ?? decoded['images'] ?? []) as List
                  : []);
          final result = <SocialMediaImageInfo>[];
          for (final item in list) {
            if (item is Map) {
              final imgId = (item['IdListingImage'] ??
                      item['idlistingimage'] ??
                      item['Id'] ??
                      item['id'] ??
                      '')
                  .toString();
              var imgUrl = (item['ImageUrl'] ??
                      item['Url'] ??
                      item['FilePath'] ??
                      item['Path'] ??
                      '')
                  .toString();
              if (imgUrl.startsWith('/')) {
                imgUrl = '$_baseUrl$imgUrl';
              }
              if (imgId.isNotEmpty) {
                result.add(SocialMediaImageInfo(
                  idListingImage: imgId,
                  imageUrl: imgUrl,
                ));
              }
            }
          }
          if (result.isNotEmpty) return result;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Downloads RWC Design 3 image bytes for a single listing image ID or fallback URL
  Future<Uint8List?> downloadDesign3ImageBytes({
    required String idListing,
    required String headline,
    String? idListingImage,
    String? fallbackImageUrl,
  }) async {
    if (_cookies.isEmpty) {
      await login();
    }

    if (idListingImage != null && idListingImage.isNotEmpty) {
      try {
        final encodedHeadline = Uri.encodeComponent(headline.toUpperCase());
        final url = Uri.parse(
          '$_baseUrl/SocialMedia/Home/DownloadListingSocialMediaV3?idlistingimage=$idListingImage&headline1=$encodedHeadline&headline2=',
        );
        final res = await http.get(
          url,
          headers: {'Cookie': _cookies},
        ).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200 &&
            res.bodyBytes.length > 1000 &&
            !(res.headers['content-type'] ?? '').contains('text/html')) {
          return res.bodyBytes;
        }
      } catch (_) {}
    }

    if (fallbackImageUrl != null && fallbackImageUrl.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse(fallbackImageUrl))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Downloads all Design 3 images for a listing and saves them to temporary files for sharing
  Future<List<File>> downloadDesign3FilesForListing({
    required String idListing,
    required String headline,
    List<String> fallbackGalleryUrls = const [],
    void Function(int current, int total)? onProgress,
  }) async {
    final cleanId = RwcScraperService.extractCleanId(idListing);
    final smImages = await getListingImages(cleanId);
    final savedFiles = <File>[];
    final tempDir = await getTemporaryDirectory();

    final total = smImages.isNotEmpty
        ? smImages.length
        : (fallbackGalleryUrls.isNotEmpty ? fallbackGalleryUrls.length : 0);

    if (smImages.isNotEmpty) {
      for (var i = 0; i < smImages.length; i++) {
        onProgress?.call(i + 1, total);
        final info = smImages[i];
        final bytes = await downloadDesign3ImageBytes(
          idListing: cleanId,
          headline: headline,
          idListingImage: info.idListingImage,
          fallbackImageUrl: info.imageUrl.isNotEmpty
              ? info.imageUrl
              : (i < fallbackGalleryUrls.length ? fallbackGalleryUrls[i] : null),
        );
        if (bytes != null) {
          final file =
              File('${tempDir.path}/RWC_Design3_${cleanId}_${i + 1}.jpg');
          await file.writeAsBytes(bytes);
          savedFiles.add(file);
        }
      }
    } else if (fallbackGalleryUrls.isNotEmpty) {
      for (var i = 0; i < fallbackGalleryUrls.length; i++) {
        onProgress?.call(i + 1, total);
        final bytes = await downloadDesign3ImageBytes(
          idListing: cleanId,
          headline: headline,
          fallbackImageUrl: fallbackGalleryUrls[i],
        );
        if (bytes != null) {
          final file =
              File('${tempDir.path}/RWC_Design3_${cleanId}_${i + 1}.jpg');
          await file.writeAsBytes(bytes);
          savedFiles.add(file);
        }
      }
    }

    return savedFiles;
  }

  /// Generates a 3:4 Portrait HD Newsletter PDF matching Android's NewsletterDownloader.kt
  Future<File?> generateNewsletterPdf({
    required String titleText,
    required String coverImageUrl,
    required List<MapEntry<String, String>> listingIdAndTitles,
    Map<String, String> fallbackPrimaryImages = const {},
    void Function(String status, double progress)? onProgress,
  }) async {
    final doc = pw.Document();
    // 3:4 Portrait HD (1080 x 1440 pt)
    const pageFormat = PdfPageFormat(1080, 1440, marginAll: 0);

    onProgress?.call('Mengunduh foto cover newsletter...', 0.1);
    Uint8List? coverBytes;
    if (coverImageUrl.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse(coverImageUrl))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          coverBytes = res.bodyBytes;
        }
      } catch (_) {}
    }

    // 1. Cover Page
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              if (coverBytes != null)
                pw.Image(
                  pw.MemoryImage(coverBytes),
                  fit: pw.BoxFit.cover,
                )
              else
                pw.Container(color: PdfColor.fromHex('#0F1523')),
              // Dark gradient overlay at bottom & top
              pw.Positioned(
                left: 60,
                right: 60,
                bottom: 90,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 42,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(24),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'RAY WHITE CIPETE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#D9A700'),
                          letterSpacing: 3,
                        ),
                      ),
                      pw.SizedBox(height: 14),
                      pw.Text(
                        titleText.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 44,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#111827'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 2. Listing Pages with clickable UrlLink to https://raywhitecipete.net/ListingView/Detail/<id>
    for (var i = 0; i < listingIdAndTitles.length; i++) {
      final entry = listingIdAndTitles[i];
      final cleanId = RwcScraperService.extractCleanId(entry.key);
      final headline = entry.value.isNotEmpty ? entry.value : 'LISTING #$cleanId';
      final progress = 0.2 + (0.75 * ((i + 1) / listingIdAndTitles.length));
      onProgress?.call(
        'Memproses listing #$cleanId (${i + 1}/${listingIdAndTitles.length})...',
        progress,
      );

      final smImages = await getListingImages(cleanId);
      final firstIdImg =
          smImages.isNotEmpty ? smImages.first.idListingImage : null;
      final fallbackUrl = fallbackPrimaryImages[cleanId] ??
          (smImages.isNotEmpty ? smImages.first.imageUrl : null);

      final imgBytes = await downloadDesign3ImageBytes(
        idListing: cleanId,
        headline: headline,
        idListingImage: firstIdImg,
        fallbackImageUrl: fallbackUrl,
      );

      final detailUrl = 'https://raywhitecipete.net/ListingView/Detail/$cleanId';

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.UrlLink(
              destination: detailUrl,
              child: pw.Stack(
                fit: pw.StackFit.expand,
                children: [
                  if (imgBytes != null)
                    pw.Image(
                      pw.MemoryImage(imgBytes),
                      fit: pw.BoxFit.cover,
                    )
                  else
                    pw.Container(
                      color: PdfColor.fromHex('#121824'),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'LISTING #$cleanId\n$headline',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 38,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  pw.Positioned(
                    right: 36,
                    bottom: 36,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#0F1523'),
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: pw.Text(
                        'KLIK DETAIL WEB #$cleanId',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#FFE600'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    onProgress?.call('Menyimpan dokumen PDF...', 0.98);
    final pdfBytes = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final safeName = titleText
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final file = File('${tempDir.path}/Newsletter_$safeName.pdf');
    await file.writeAsBytes(pdfBytes);
    onProgress?.call('Selesai!', 1.0);
    return file;
  }
}
