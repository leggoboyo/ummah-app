import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../domain/scholar_feed_item.dart';
import '../domain/scholar_feed_source.dart';

class IslamHouseRssDataSource {
  IslamHouseRssDataSource({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<List<ScholarFeedItem>> fetchFeed(ScholarFeedSource source) async {
    final http.Response response = await _httpClient.get(
      Uri.parse(source.feedUrl),
      headers: const <String, String>{
        'Accept': 'application/rss+xml, application/xml, text/xml',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load ${source.providerName} feed: HTTP ${response.statusCode}',
      );
    }

    final XmlDocument document = XmlDocument.parse(response.body);
    final Iterable<XmlElement> itemElements = document.findAllElements('item');
    final List<ScholarFeedItem> items = <ScholarFeedItem>[];

    for (final XmlElement item in itemElements) {
      final String link = _elementText(item, 'link');
      final String guid = _elementText(item, 'guid');
      final String title = _elementText(item, 'title');
      final String description = _elementText(item, 'description');
      final String pubDateRaw = _elementText(item, 'pubDate');
      final String? imageUrl = _mediaContentUrl(item);

      if (link.isEmpty && guid.isEmpty && title.isEmpty) {
        continue;
      }

      items.add(
        ScholarFeedItem(
          id: guid.isNotEmpty ? '${source.id}:$guid' : '${source.id}:$link',
          sourceId: source.id,
          sourceTitle: source.title,
          providerName: source.providerName,
          title: title,
          summary: description,
          url: link,
          languageCode: source.languageCode,
          categoryLabel: source.category.label,
          publishedAt: _parsePubDate(pubDateRaw),
          imageUrl: imageUrl,
        ),
      );
    }

    return items;
  }

  void dispose() {
    _httpClient.close();
  }

  String _elementText(XmlElement parent, String name) {
    final Iterable<XmlElement> elements = parent.findElements(name);
    if (elements.isEmpty) {
      return '';
    }
    return elements.first.innerText.trim();
  }

  String? _mediaContentUrl(XmlElement item) {
    final Iterable<XmlElement> mediaElements =
        item.findElements('media:content');
    for (final XmlElement element in mediaElements) {
      final String? url = element.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    for (final XmlElement element in item.descendantElements) {
      if (element.name.qualified == 'media:content') {
        final String? url = element.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  DateTime? _parsePubDate(String value) {
    if (value.isEmpty) {
      return null;
    }

    final List<String> attempts = <String>[
      value,
      value.replaceAll(' ,', ','),
    ];

    for (final String candidate in attempts) {
      try {
        return HttpDate.parse(candidate);
      } on FormatException {
        // Fall back to generic parsing below for non-RFC date strings.
      }
      final DateTime? generic = DateTime.tryParse(candidate);
      if (generic != null) {
        return generic;
      }
    }
    return null;
  }
}
