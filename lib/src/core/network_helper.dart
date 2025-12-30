import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Network işlemleri için helper sınıfı
/// Timeout, retry ve error handling sağlar
class NetworkHelper {
  /// Supabase query'lerini timeout ve retry ile çalıştırır
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation().timeout(timeout);
      } on TimeoutException {
        if (attempts == maxRetries) {
          throw Exception('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
        }
      } on PostgrestException catch (e) {
        if (attempts == maxRetries) {
          throw Exception('Veritabanı hatası: ${e.message}');
        }
      } catch (e) {
        if (attempts == maxRetries) {
          throw Exception('Bağlantı hatası: $e');
        }
      }
      
      attempts++;
      if (attempts <= maxRetries) {
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    throw Exception('İstek başarısız oldu.');
  }

  /// Network bağlantısını kontrol eder
  static Future<bool> checkConnection() async {
    try {
      final client = Supabase.instance.client;
      await client.from('restaurants').select('id').limit(1).timeout(
        const Duration(seconds: 5),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

