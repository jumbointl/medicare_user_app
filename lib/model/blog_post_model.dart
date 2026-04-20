class BlogPostModel{
  int? id;
  String? image;
  String? title;
  String? description;
  String? content;
  String? catTitle;
  List? author;


  BlogPostModel({
    this.id,
    this.title,
    this.image,
    this.description,
    this.author,
    this.catTitle,
    this.content
  });

  factory BlogPostModel.fromJson(Map<String,dynamic> json){
    return BlogPostModel(
      id: json['id'],
      image: json['image'],
      title: json['title'],
      description: json['description'],
      author: json['author'],
      catTitle: json['cat_title'],
      content: json['content'],

    );
  }

}