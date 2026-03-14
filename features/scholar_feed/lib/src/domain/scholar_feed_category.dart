enum ScholarFeedCategory {
  all,
  books,
  articles,
  audios,
  videos;

  String get slug {
    switch (this) {
      case ScholarFeedCategory.all:
        return 'all';
      case ScholarFeedCategory.books:
        return 'books';
      case ScholarFeedCategory.articles:
        return 'articles';
      case ScholarFeedCategory.audios:
        return 'audios';
      case ScholarFeedCategory.videos:
        return 'videos';
    }
  }

  String get label {
    switch (this) {
      case ScholarFeedCategory.all:
        return 'All items';
      case ScholarFeedCategory.books:
        return 'Books';
      case ScholarFeedCategory.articles:
        return 'Articles';
      case ScholarFeedCategory.audios:
        return 'Audios';
      case ScholarFeedCategory.videos:
        return 'Videos';
    }
  }
}
