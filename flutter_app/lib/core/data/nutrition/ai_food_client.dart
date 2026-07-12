import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:noop/core/state/prefs.dart';

/// One item the AI identified in a food photo.
class AiFoodItem {
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  const AiFoodItem({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory AiFoodItem.fromJson(Map<String, dynamic> j) => AiFoodItem(
        name: (j['name'] ?? '').toString(),
        grams: _num(j['grams']),
        kcal: _num(j['kcal']),
        protein: _num(j['protein']),
        carbs: _num(j['carbs']),
        fat: _num(j['fat']),
      );
}

/// The AI's estimate for a whole food photo.
class AiFoodEstimate {
  final String dish;
  final List<AiFoodItem> items;
  final double totalKcal;
  final double confidence; // 0..1
  const AiFoodEstimate({
    required this.dish,
    required this.items,
    required this.totalKcal,
    required this.confidence,
  });

  factory AiFoodEstimate.fromJson(Map<String, dynamic> j) => AiFoodEstimate(
        dish: (j['dish'] ?? 'unknown').toString(),
        items: [
          for (final it in (j['items'] as List? ?? const []))
            AiFoodItem.fromJson(Map<String, dynamic>.from(it as Map)),
        ],
        totalKcal: _num(j['total_kcal']),
        confidence: _num(j['confidence']).clamp(0.0, 1.0),
      );
}

/// Why an estimate failed, so the UI can tell the user what to do.
enum AiFoodError { noKey, http, badResponse, timeout }

class AiFoodException implements Exception {
  final AiFoodError kind;
  final String message;
  const AiFoodException(this.kind, this.message);
  @override
  String toString() => 'AiFoodException($kind): $message';
}

/// Bring-your-own-key food-photo → nutrition estimator over any OpenAI-compatible
/// `/chat/completions` vision endpoint (OpenAI or xAI Grok). The key is the
/// user's; the request goes device→provider directly over TLS. Cost control:
/// ONE call per explicit user action, no auto-retry, a hard `max_tokens` cap,
/// and `detail: low` + client-side downscaling by the caller. The key and the
/// raw response are never logged.
class AiFoodClient {
  AiFoodClient._();

  static const _systemPrompt =
      'You are a nutrition estimator. Given a photo of food, identify the dish '
      'and its component items and estimate nutrition. Respond with ONLY a '
      'single JSON object and no other text, matching exactly this schema:\n'
      '{"dish": string, "items": [{"name": string, "grams": number, "kcal": '
      'number, "protein": number, "carbs": number, "fat": number}], '
      '"total_kcal": number, "confidence": number}\n'
      'Rules: grams is the estimated edible weight of that item. protein, carbs '
      'and fat are in grams. total_kcal must equal the sum of the items\' kcal. '
      'confidence is a number from 0 to 1 reflecting how certain you are, given '
      'image clarity and portion ambiguity. Use metric grams and integer-ish '
      'kcal. If the image contains no food, return {"dish":"unknown","items":'
      '[],"total_kcal":0,"confidence":0}. Do not add comments, explanations, or '
      'trailing text outside the JSON.';

  static const _userPrompt =
      'Estimate the nutrition of the food shown in this image. Assume a single '
      'serving as pictured. If no size reference is visible, estimate portion '
      'sizes from typical plating and standard serving sizes.';

  /// Estimate nutrition from a (already downscaled) JPEG. [jpegBytes] should be
  /// a modest image (≈768 px longest side, q≈70) — the caller owns downscaling.
  /// Throws [AiFoodException] on any failure so the UI can react precisely.
  static Future<AiFoodEstimate> estimate(Uint8List jpegBytes) async {
    final prefs = Prefs.instance;
    final key = prefs.aiApiKey;
    if (key == null || key.isEmpty) {
      throw const AiFoodException(
          AiFoodError.noKey, 'No AI key set. Add one in Settings.');
    }
    final b64 = base64Encode(jpegBytes);
    final uri = Uri.parse('${prefs.aiBaseUrl}/chat/completions');
    final body = jsonEncode({
      'model': prefs.aiModel,
      'response_format': {'type': 'json_object'},
      'temperature': 0.2,
      'max_tokens': 700,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _userPrompt},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$b64',
                'detail': 'low',
              },
            },
          ],
        },
      ],
    });

    http.Response res;
    try {
      res = await http
          .post(uri,
              headers: {
                'Authorization': 'Bearer $key',
                'Content-Type': 'application/json',
              },
              body: body)
          .timeout(const Duration(seconds: 30));
    } on Exception {
      throw const AiFoodException(AiFoodError.timeout, 'The request timed out.');
    }

    if (res.statusCode != 200) {
      // Never surface res.body verbatim (it can echo the key/headers on some
      // proxies); report only the status.
      throw AiFoodException(
          AiFoodError.http, 'AI request failed (HTTP ${res.statusCode}).');
    }

    try {
      final envelope = jsonDecode(res.body) as Map<String, dynamic>;
      final content =
          envelope['choices'][0]['message']['content'] as String; // JSON string
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return AiFoodEstimate.fromJson(parsed);
    } catch (_) {
      throw const AiFoodException(
          AiFoodError.badResponse, 'The AI returned an unreadable response.');
    }
  }
}

double _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
