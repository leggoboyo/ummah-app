import 'package:core/core.dart';
import 'package:http/http.dart' as http;
import 'package:scholar_feed/scholar_feed.dart';
import 'package:test/test.dart';

void main() {
  test('parses IslamHouse RSS items into feed metadata', () async {
    final IslamHouseRssDataSource dataSource = IslamHouseRssDataSource(
      httpClient: _FakeHttpClient(
        {
          'https://islamhouse.com/RSS/IslamHouse-all-EN-EN.xml': _sampleFeedXml,
        },
      ),
    );

    final List<ScholarFeedItem> items = await dataSource.fetchFeed(
      const ScholarFeedSource(
        id: 'islamhouse_en_all',
        providerKey: 'islamhouse_rss',
        providerName: 'IslamHouse',
        title: 'IslamHouse English: All items',
        description: 'Test source',
        languageCode: 'en',
        category: ScholarFeedCategory.all,
        feedUrl: 'https://islamhouse.com/RSS/IslamHouse-all-EN-EN.xml',
        siteUrl: 'https://islamhouse.com/en/',
      ),
    );

    expect(items, hasLength(2));
    expect(items.first.title, 'Summary of Taraweeh Rulings');
    expect(items.first.url, 'https://islamhouse.com/en/books/2843564/');
  });

  test('repository persists followed sources and cached items locally',
      () async {
    final _InMemoryKeyValueStore store = _InMemoryKeyValueStore();
    final ScholarFeedRepository repository = ScholarFeedRepository(
      keyValueStore: store,
      dataSource: IslamHouseRssDataSource(
        httpClient: _FakeHttpClient(
          {
            'https://islamhouse.com/RSS/IslamHouse-all-EN-EN.xml':
                _sampleFeedXml,
          },
        ),
      ),
      availableSources: const <ScholarFeedSource>[
        ScholarFeedSource(
          id: 'islamhouse_en_all',
          providerKey: 'islamhouse_rss',
          providerName: 'IslamHouse',
          title: 'IslamHouse English: All items',
          description: 'Test source',
          languageCode: 'en',
          category: ScholarFeedCategory.all,
          feedUrl: 'https://islamhouse.com/RSS/IslamHouse-all-EN-EN.xml',
          siteUrl: 'https://islamhouse.com/en/',
        ),
      ],
    );

    await repository.setSourceFollowed(
      sourceId: 'islamhouse_en_all',
      isFollowed: true,
    );
    final ScholarFeedSyncResult refreshed =
        await repository.refreshFollowedSources();
    final ScholarFeedSyncResult cached = await repository.getCachedFeed();

    expect(refreshed.items, isNotEmpty);
    expect(cached.items.first.title, 'Summary of Taraweeh Rulings');
    expect(cached.followedSourceIds, contains('islamhouse_en_all'));
  });
}

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<String?> readString(String key) async => _storage[key];

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _storage[key] = value;
  }
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.responses);

  final Map<String, String> responses;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String? body = responses[request.url.toString()];
    if (body == null) {
      return http.StreamedResponse(
        Stream<List<int>>.value('not found'.codeUnits),
        404,
      );
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(body.codeUnits),
      200,
      headers: const <String, String>{
        'content-type': 'text/xml; charset=UTF-8',
      },
    );
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final String? body = responses[url.toString()];
    if (body == null) {
      return http.Response('not found', 404);
    }
    return http.Response(
      body,
      200,
      headers: const <String, String>{
        'content-type': 'text/xml; charset=UTF-8',
      },
    );
  }
}

const String _sampleFeedXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title><![CDATA[islamhouse.com :: All items :: English ]]></title>
    <item>
      <title><![CDATA[Summary of Taraweeh Rulings]]></title>
      <description><![CDATA[Summary of Taraweeh Rulings]]></description>
      <link><![CDATA[https://islamhouse.com/en/books/2843564/]]></link>
      <pubDate>Fri, 13 Mar 2026 00:00:00 GMT</pubDate>
      <guid isPermaLink="true"><![CDATA[/en/books/2843564/]]></guid>
      <media:content url="https://islamhouse.com/assets/images/videos-placeholder.png" type="image/jpeg" medium="image" />
    </item>
    <item>
      <title><![CDATA[RAMADANIYAT - thirty Lessons in Ramadan]]></title>
      <description><![CDATA[RAMADANIYAT - thirty Lessons in Ramadan]]></description>
      <link><![CDATA[https://islamhouse.com/en/books/2843530/]]></link>
      <pubDate>Thu, 12 Mar 2026 00:00:00 GMT</pubDate>
      <guid isPermaLink="true"><![CDATA[/en/books/2843530/]]></guid>
      <media:content url="https://islamhouse.com/assets/images/videos-placeholder.png" type="image/jpeg" medium="image" />
    </item>
  </channel>
</rss>
''';
