import SwiftUI
import WebKit

struct WebView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // Configuración de la WebView
        let webConfiguration = WKWebViewConfiguration()
        
        // iOS 14+: Usar WKWebpagePreferences.allowsContentJavaScript en lugar de javaScriptEnabled
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        webConfiguration.defaultWebpagePreferences = preferences
        
        // Permitir comunicación entre el HTML y Swift
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "callbackHandler")
        webConfiguration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        
        // Cargar el HTML
        let htmlString = """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Document Autocapture JS</title>
            <script type="module" crossorigin src="./assets/js/autocapture.min.js"></script>
          </head>
          <body>
            <div>
              <div id="autocapture_documents"></div>
            </div>
            <script type="module">
              window.addEventListener("message", function (event) {
                let image = event.data.image;
                let error = event.data.error;

                if (image) {
                  console.log(image);
                  window.webkit.messageHandlers.callbackHandler.postMessage(image);
                }

                if (error) {
                  const getError = { name: error.name, message: error.message };
                  console.log(getError);
                  window.webkit.messageHandlers.callbackHandler.postMessage(JSON.stringify(getError));
                }
              });
            </script>
          </body>
        </html>
        """

        webView.loadHTMLString(htmlString, baseURL: nil)
        
        viewController.view = webView
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No es necesario actualizar nada en este caso
    }
    
    // Configurar el Coordinador para manejar mensajes de JS
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "callbackHandler" {
                if let messageBody = message.body as? String {
                    print("Mensaje recibido desde JS: \(messageBody)")
                }
            }
        }
    }
}
