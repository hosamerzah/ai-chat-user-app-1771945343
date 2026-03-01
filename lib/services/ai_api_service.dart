import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ai_chat_user_app/services/remote_log_service.dart';

class AiApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getBakedInContext() async {
    try {
      return await rootBundle.loadString('assets/context_document.txt');
    } catch (e) {
      print("Could not load context document: $e");
      return "Default baked-in knowledge.";
    }
  }

  Future<Map<String, dynamic>?> getAiModelConfig(String modelId) async {
    try {
      final doc = await _firestore.collection('ai_models').doc(modelId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      print("Error fetching AI Model config: $e");
    }
    return null;
  }

  Future<int> getUserTokenBalance() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['tokenBalance'] ?? 0;
      }
    } catch (e) {
      print("Error fetching tokens: $e");
    }
    return 0;
  }

  Future<void> _deductToken(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        int currentBalance = doc.data()!['tokenBalance'] ?? 0;
        int newBalance = currentBalance - amount;
        await _firestore.collection('users').doc(user.uid).update({
          'tokenBalance': newBalance < 0 ? 0 : newBalance,
        });
      }
    } catch (e) {
      print("Error deducting token: $e");
    }
  }

  Future<String> chatWithAI(String modelId, String characterSystemPrompt, String userMessage) async {
    // 1. Check tokens
    final tokenBalance = await getUserTokenBalance();
    if (tokenBalance <= 0) {
      RemoteLogService.log(LogLevel.warning, "User attempted chat with zero tokens.");
      return "Error: Insufficient Tokens. Please upgrade your plan or purchase more via the Admin.";
    }

    // 2. Fetch Dynamic AI Model Config
    final modelConfig = await getAiModelConfig(modelId);
    if (modelConfig == null) {
      return "Error: AI Model configuration not found or inactive.";
    }

    final String apiKey = modelConfig['apiKey'] ?? '';
    final String provider = (modelConfig['provider'] ?? '').toString().toLowerCase();
    final String brainPrompt = modelConfig['systemPrompt'] ?? 'You are a helpful AI assistant.';
    
    if (apiKey.isEmpty) {
      RemoteLogService.log(LogLevel.error, "Missing API Key for model: $modelId", details: {'provider': provider});
      return "Error: The Admin has not configured an API key for this model.";
    }

    // 3. Prepare payload and Route
    final bakedText = await _getBakedInContext();
    final fullSystemPrompt = "$brainPrompt\n\nCharacter Role:\n$characterSystemPrompt\n\nContext:\n$bakedText";

    try {
      String responseText = "";

      if (provider == 'openai') {
        RemoteLogService.log(LogLevel.info, "Routing chat to OpenAI");
        responseText = await _callOpenAI(apiKey, fullSystemPrompt, userMessage);
      } else if (provider == 'gemini') {
        RemoteLogService.log(LogLevel.info, "Routing chat to Gemini");
        responseText = await _callGemini(apiKey, fullSystemPrompt, userMessage);
      } else {
        RemoteLogService.log(LogLevel.error, "Unsupported AI Provider: $provider");
        return "Error: Unsupported provider configured by Admin ($provider).";
      }

      // 4. Deduct token after successful reply
      await _deductToken(1); // Flat rate for now, could be dynamic later based on plan/model
      return responseText;
      
    } catch (e, stacktrace) {
      print("API Catch Error: $e");
      RemoteLogService.log(LogLevel.error, "AI API Request Failed", error: e, stackTrace: stacktrace);
      return "Connection Error: Could not reach the AI service.";
    }
  }

  Future<String> _callOpenAI(String apiKey, String systemPrompt, String userMessage) async {
    const apiUrl = "https://api.openai.com/v1/chat/completions";
    final payload = {
      "model": "gpt-3.5-turbo", 
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage}
      ],
      "max_tokens": 500,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      print("OpenAI Error: ${response.body}");
      throw Exception('OpenAI API returned ${response.statusCode}');
    }
  }

  Future<String> _callGemini(String apiKey, String systemPrompt, String userMessage) async {
    final apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey";
    
    final payload = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": "System Instructions: $systemPrompt\n\nUser: $userMessage"}
          ]
        }
      ],
      "generationConfig": {
        "maxOutputTokens": 500,
      }
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      print("Gemini Error: ${response.body}");
      throw Exception('Gemini API returned ${response.statusCode}');
    }
  }
}
