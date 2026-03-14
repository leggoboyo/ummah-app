import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/fiqh_knowledge_pack.dart';

abstract interface class FiqhKnowledgeDataSource {
  Future<FiqhKnowledgePack> loadPack();
}

class FiqhAssetDataSource implements FiqhKnowledgeDataSource {
  const FiqhAssetDataSource({
    this.assetPath = 'packages/fiqh/assets/fiqh_knowledge_v1.json',
  });

  final String assetPath;

  @override
  Future<FiqhKnowledgePack> loadPack() async {
    final String raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return FiqhKnowledgePack.fromJson(json);
  }
}
