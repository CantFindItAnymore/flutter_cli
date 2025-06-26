class BaseModel {
  String? code;
  String? message;
  String? error;
  dynamic data;

  BaseModel({
    this.code,
    this.message,
    this.error,
    this.data,
  });

  factory BaseModel.fromJson(Map<String, dynamic> json) => BaseModel(
        code: json['code']?.toString(),
        message: json['message']?.toString(),
        error: json['error']?.toString(),
        data: json['data'],
      );

  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (error != null) 'error': error,
        if (data != null) 'data': data,
      };
}
