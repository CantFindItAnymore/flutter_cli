import 'package:flutter/material.dart';
import 'package:flutter_cli/core/index.dart';

/// API统一响应格式
class ApiResponse<T> {
  final int code;
  final String? message;
  final T? data;

  ApiResponse({
    required this.code,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json,
      [T Function(dynamic)? fromJson]) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message']?.toString(),
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : json['data'] as T?,
    );
  }

  bool get isSuccess => code == 200;
}

/// Response统一处理回调
typedef OnResponseHandler = Future<String?> Function(
    ApiResponse<dynamic> response);

/// 请求处理拦截器
/// 如返回true则中断后面流程
typedef OnRequestHandler = Future<bool> Function(
    RequestOptions options, RequestInterceptorHandler handler);

typedef OnErrorHandler = Future<String?> Function(DioException err);

/// 网络请求服务
class Http extends GetxService {
  static const showLog = 'showLog';
  static const showError = 'showError';

  static Http get to => Get.find();

  late final Dio _dio;
  Dio get dio => _dio;

  // 取消请求token
  final CancelToken _cancelToken = CancelToken();

  /// 初始化
  /// [timeout] 请求超时时间
  Future<Http> init({int timeout = 30}) async {
    BaseOptions options = BaseOptions(
        connectTimeout: Duration(seconds: timeout),
        receiveTimeout: Duration(seconds: timeout),
        sendTimeout: Duration(seconds: timeout),
        contentType: 'application/json; charset=utf-8',
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
        });
    // 初始化dio
    _dio = Dio(options);
    // Log拦截器
    dio.interceptors.add(
      PrettyDioLogger(
        showRequest: false,
        showResponse: true,
        responseHeader: true,
        responseBody: true,
        showError: true,
        logPrint: Logger.network,
      ),
    );
    // 自定义添加拦截器
    _dio.interceptors.add(DioInterceptors());
    return this;
  }

  /// 设置BaseUrl
  void setBaseUrl(String baseUrl) {
    _dio.options = _dio.options.copyWith(baseUrl: baseUrl);
  }

  /// 取消网络请求
  void cancel([CancelToken? token]) {
    if (token != null) {
      token.cancel('cancel');
    } else {
      _cancelToken.cancel('cancel');
    }
  }

  /// 基础请求
  Future<ApiResponse?> request(
    String path, {
    Map<String, dynamic>? params,
    data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isFormData = false,
    bool showError = true,
  }) async {
    options ??= Options(method: 'get');
    if (isFormData) {
      options.contentType = 'multipart/form-data';
    }
    try {
      Response dioResponse = await _dio.request(path,
          data: data,
          queryParameters: params,
          cancelToken: cancelToken ?? _cancelToken,
          options: options,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress);

      // log('response: ${response.data.toString()}');

      // 无返回内容
      if (dioResponse.data == null) {
        Get.snackbar('error', 'Server error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackStyle: SnackStyle.FLOATING,
            snackPosition: SnackPosition.TOP);
        return ApiResponse.fromJson({
          'code': 500,
          'message': 'Server error',
          'data': null,
        });
      }

      ApiResponse response = ApiResponse.fromJson(dioResponse.data);

      /// 无效token
      if (response.code == 403) {
        log('invalid token');
        removeKey('token');
        clearAuthorization();
      } else if (response.code == 500 && showError == true) {
        Get.snackbar('error', 'Server error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackStyle: SnackStyle.FLOATING,
            snackPosition: SnackPosition.TOP);
      }

      return response;
    } on DioException catch (e) {
      log('[Api.request] DioException caught: url: ${e.requestOptions.path}, Message: ${e.message}');

      return null;
    }
  }

  /// GET请求
  Future<ApiResponse?> get(
    String path, {
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    bool showError = true,
  }) async {
    Options options = Options(method: 'get', headers: headers);
    return await request(
      path,
      options: options,
      params: params,
      cancelToken: cancelToken,
      showError: showError,
    );
  }

  /// POST请求
  Future<ApiResponse?> post(
    String path, {
    Map<String, dynamic>? params,
    data,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    bool isFormData = false,
    bool showError = true,
  }) async {
    Options options = Options(method: 'post', headers: headers);

    var formData = isFormData
        ? data is FormData
            ? data
            : FormData.fromMap(data)
        : data;

    return await request(
      path,
      options: options,
      params: params,
      data: formData,
      cancelToken: cancelToken,
      isFormData: isFormData,
      showError: showError,
    );
  }

  /// PUT请求
  Future<ApiResponse?> put(
    String path, {
    Map<String, dynamic>? params,
    data,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
  }) async {
    Options options = Options(method: 'put', headers: headers);
    return await request(
      path,
      options: options,
      params: params,
      data: data,
      cancelToken: cancelToken,
    );
  }

  /// DELETE请求
  Future<ApiResponse?> delete(
    String path, {
    Map<String, dynamic>? params,
    data,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
  }) async {
    Options options = Options(method: 'delete', headers: headers);
    return await request(
      path,
      options: options,
      params: params,
      data: data,
      cancelToken: cancelToken,
    );
  }

  String? _authorization;

  String? get authorization => _authorization;

  /// 设置授权(Token) 默认在开头添加Bearer
  /// [authorization] 授权Token
  void setAuthorization(String authorization, {bool addBearer = false}) {
    if (addBearer) {
      _authorization = 'Bearer $authorization';
    } else {
      _authorization = authorization;
    }
  }

  /// 清除授权
  void clearAuthorization() {
    _authorization = null;
  }

  OnResponseHandler? _onResponseHandler;

  OnResponseHandler? get onResponseHandler => _onResponseHandler;

  /// 设置响应拦截器
  void setOnResponseHandler(OnResponseHandler? handler) {
    _onResponseHandler = handler;
  }

  OnRequestHandler? _onRequestHandler;

  OnRequestHandler? get onRequestHandler => _onRequestHandler;

  /// 设置请求拦截器
  void setOnRequestHandler(OnRequestHandler? handler) {
    _onRequestHandler = handler;
  }

  OnErrorHandler? _onErrorHandler;

  OnErrorHandler? get onErrorHandler => _onErrorHandler;

  /// 设置错误拦截器
  void setOnErrorHandler(OnErrorHandler? handler) {
    _onErrorHandler = handler;
  }
}

/// 拦截器
class DioInterceptors extends QueuedInterceptor {
  @override
  void onRequest(options, handler) async {
    OnRequestHandler? onRequestHandler = Http.to.onRequestHandler;
    if (onRequestHandler != null) {
      if (await onRequestHandler(options, handler)) {
        return;
      }
    }

    String? authorization = Http.to.authorization;
    if (authorization.isNotEmptyOrNull) {
      if (!options.headers.containsKey('token')) {
        options.headers.addAll({'token': authorization});
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(response, handler) async {
    OnResponseHandler? onResponseHandler = Http.to.onResponseHandler;
    if (onResponseHandler != null) {
      ApiResponse apiResponse = ApiResponse.fromJson(response.data);
      String? msg = await onResponseHandler(apiResponse);
      if (msg != null) {
        handler.reject(
          DioException(
            type: DioExceptionType.badResponse,
            message: msg.isEmpty ? 'Server error' : msg,
            requestOptions: response.requestOptions,
            response: response,
            error: null,
          ),
        );
        return;
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    String? errorMessage;
    OnErrorHandler? onErrorHandler = Http.to.onErrorHandler;
    if (onErrorHandler != null) {
      errorMessage = await onErrorHandler(err);
    }
    if (errorMessage.isEmptyOrNull) {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server connection timeout';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Server connection failed';
          break;
        case DioExceptionType.badCertificate:
          errorMessage = 'Invalid certificate';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled';
          break;
        case DioExceptionType.unknown:
          if (await isNetworkAvailable()) {
            errorMessage = 'Server connection failed';
          } else {
            errorMessage = 'No network connection';
          }
          break;
        case DioExceptionType.badResponse:
          int? statusCode = err.response?.statusCode;
          if (statusCode != null) {
            errorMessage = 'Server error: $statusCode';
          }
          break;
      }
    }
    handler.reject(
      DioException(
        type: err.type,
        message: errorMessage,
        requestOptions: err.requestOptions,
        response: err.response,
        error: null,
      ),
    );
  }
}
