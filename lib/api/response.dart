class Response {

  Status? _status;
  final Map<String, String> _headers = {};
  final Map<String, String> _body = {};
  final Map _response = {};
  int statusCode = 0;

  Map<String, String> get header => _headers;
  Map<String, String> get body   => _body;
  Map get response => _response;
  Status? get status => _status;

}

enum Status {
  defaultError,
  authError,
  internetError,
  serverError
}

