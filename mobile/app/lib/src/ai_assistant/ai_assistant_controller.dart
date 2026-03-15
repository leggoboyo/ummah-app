import 'package:ai_assistant/ai_assistant.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import '../bootstrap/flutter_secure_value_store.dart';
import 'local_assistant_source_port.dart';

class AiAssistantController extends ChangeNotifier {
  AiAssistantController({
    AiAssistantRepository? repository,
    SecureValueStore? secureValueStore,
    AssistantSourcePort? sourcePort,
  })  : _repository = repository ??
            AiAssistantRepository(
              sourcePort: sourcePort ?? LocalAssistantSourcePort(),
            ),
        _secureValueStore = secureValueStore ?? FlutterSecureValueStore();

  static const String _apiKeyStorageKey = 'openai_api_key_v1';

  final AiAssistantRepository _repository;
  final SecureValueStore _secureValueStore;

  bool isReady = false;
  bool isWorking = false;
  bool apiKeyConfigured = false;
  String? errorMessage;
  String? statusMessage;
  AssistantResponse? latestResponse;
  AssistantMode selectedMode = AssistantMode.quran;

  String _preferredLanguageCode = 'en';

  Future<void> initialize({
    required String preferredLanguageCode,
  }) async {
    if (isReady || isWorking) {
      return;
    }

    isWorking = true;
    notifyListeners();
    try {
      _preferredLanguageCode = preferredLanguageCode;
      apiKeyConfigured = await _hasApiKey();
      statusMessage = apiKeyConfigured
          ? 'BYOK mode is ready. Your API key is stored in secure device storage.'
          : 'Add your OpenAI API key to enable BYOK mode.';
      isReady = true;
    } catch (error) {
      errorMessage = 'AI assistant failed to initialize: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  void selectMode(AssistantMode mode) {
    selectedMode = mode;
    errorMessage = null;
    statusMessage = null;
    notifyListeners();
  }

  Future<void> saveApiKey(String apiKey) async {
    final String trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      errorMessage = 'Enter an API key before saving.';
      notifyListeners();
      return;
    }

    isWorking = true;
    notifyListeners();
    try {
      await _secureValueStore.writeSecret(_apiKeyStorageKey, trimmed);
      apiKeyConfigured = true;
      errorMessage = null;
      statusMessage = 'Your OpenAI API key was saved in secure device storage.';
    } catch (error) {
      errorMessage = 'Failed to save the API key securely: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> clearApiKey() async {
    isWorking = true;
    notifyListeners();
    try {
      await _secureValueStore.removeSecret(_apiKeyStorageKey);
      apiKeyConfigured = false;
      statusMessage = 'The saved OpenAI API key was removed from this device.';
      errorMessage = null;
    } catch (error) {
      errorMessage = 'Failed to remove the saved API key: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> askQuestion(String question) async {
    final String trimmed = question.trim();
    if (trimmed.isEmpty) {
      errorMessage = 'Enter a question before asking the assistant.';
      notifyListeners();
      return;
    }

    isWorking = true;
    errorMessage = null;
    statusMessage = null;
    notifyListeners();

    try {
      final String? apiKey =
          await _secureValueStore.readSecret(_apiKeyStorageKey);
      latestResponse = await _repository.askQuestion(
        mode: selectedMode,
        question: trimmed,
        apiKey: apiKey ?? '',
        preferredLanguageCode: _preferredLanguageCode,
      );
      apiKeyConfigured = (apiKey ?? '').trim().isNotEmpty;
      statusMessage =
          'Answer generated from retrieved local sources and BYOK processing.';
    } catch (error) {
      errorMessage = '$error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> close() async {
    await _repository.dispose();
  }

  Future<bool> _hasApiKey() async {
    final String? value = await _secureValueStore.readSecret(_apiKeyStorageKey);
    return (value ?? '').trim().isNotEmpty;
  }
}
