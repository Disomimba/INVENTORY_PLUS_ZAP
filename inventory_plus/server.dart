import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart'; // <--- Added this import

// 1. Your security middleware
Middleware securityHeadersMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      return response.change(headers: {
        ...response.headers,
        'X-Frame-Options': 'SAMEORIGIN',
        'Content-Security-Policy': "frame-ancestors 'self';",
      });
    };
  };
}

void main() async {
  // 2. Set up the handler to serve your compiled Flutter web files
  // 'build/web' is the default folder where Flutter puts your compiled web app
  final _myAppHandler = createStaticHandler('build/web', defaultDocument: 'index.html');

  // 3. Build the pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequests()) 
      .addMiddleware(securityHeadersMiddleware()) // <--- Injected Security Layer
      .addHandler(_myAppHandler); // Serves the Flutter app

  // 4. Start the server
  final server = await io.serve(handler, 'localhost', 51328); 
  print('Server running on port ${server.port}');
}