class NewsModel {
  final int id;
  final String newsHeadlines;
  final String newsContent;
  final String newsCreatedDate;
  final String? newsImage;
  String newsStatus;

  NewsModel({
    required this.id,
    required this.newsHeadlines,
    required this.newsContent,
    required this.newsCreatedDate,
    this.newsImage,
    required this.newsStatus,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      newsHeadlines: json['news_headlines']?.toString() ?? '',
      newsContent: json['news_content']?.toString() ?? '',
      newsCreatedDate: json['news_created_date']?.toString() ?? '',
      newsImage: json['news_image']?.toString(),
      newsStatus: json['news_status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'news_headlines': newsHeadlines,
      'news_content': newsContent,
      'news_created_date': newsCreatedDate,
      'news_image': newsImage,
      'news_status': newsStatus,
    };
  }
}
