//
//  WebView.swift
//  SampleWebView
//
//  Created by wastecross on 7/11/24.
//

// import AVFoundation
import Foundation
import SwiftUI
import WebKit

/**
TO DO: validate permissions
func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    case .denied, .restricted:
        completion(false)
    @unknown default:
        completion(false)
    }
}
*/

func getUrlSdk(completion: @escaping (Result<String, Error>) -> Void) {
    // URL obtenida de
    
    // URL para obtener la url donde se subiran los archivos
    let postURL = URL(string: "https://veridocid.azure-api.net/api/id/v3/urlSdk")!

    // Crear el body del request, onlyCapture indica que solo se tomaran las fotos
    // y se regresaran en un post message.
    let parameters: [String: Bool] = [
        "onlyCapture": true,
    ]

    // Convertir el body a JSON data
    let jsonData = try! JSONSerialization.data(withJSONObject: parameters, options: [])

    // Crear el request
    var request = URLRequest(url: postURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("sk_test_FqUVwaeqFm8YrC8i9WUgOKl5PsGuR0+qrZ7YLVz3/l8=", forHTTPHeaderField: "x-api-key")
    request.httpBody = jsonData

    // Crear la tarea de URLSession
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error: \(error?.localizedDescription ?? "No data")")
            return
        }
        
        // Manejar la respuesta del servidor
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        
        // Convertir la respuesta a texto
        if let responseString = String(data: data, encoding: .utf8) {
            completion(.success(responseString))
        } else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse response"])))
        }
    }
    // Ejecutar tarea
    task.resume()
}

struct WebView: UIViewRepresentable {

    // -------------------------------------- Código del cliente
    var wkWebView: WKWebView!
    var bundle: Bundle {
        return Bundle.main
    }

    var scriptString: String {
        if let path = bundle.path(forResource: "autocapture.min", ofType: "js") {
            do {
                return try String(contentsOfFile: path)
            } catch  {
                return ""
            }
        } else {
            return ""
        }
    }

    func wkWebViewSetup() {
        let config = WKWebViewConfiguration()
        let js = scriptString
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        config.userContentController.add(self, name: "message")

        let sourceLogHandler = "function captureLog(msg) { window.webkit.messageHandlers.longHandler.postMessage(msg); } window.console.log = captureLog;"
        let scriptLogHandler = WKUserScript(source: sourceLogHandler, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(scriptLogHandler)
        config.userContentController.add(self, name: "longHandler")

        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.allowsInlineMediaPlayback = true
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        wkWebView.backgroundColor = .black
        wkWebView = WKWebView(frame: view.bounds, configuration: config)
    }

    func loadHTML() {
        let nameHTML = "veridoc"
        if let pathHTML = bundle.path(forResource: nameHTML, ofType: "html") {
            let url = URL(fileURLWithPath: pathHTML)
            wkWebView.loadFileURL(url, allowingReadAccessTo: url)
        }
    }

    // -------------------------------------- Código del cliente

    func makeUIView(context: Context) -> some UIView {
        // Iniciar variable donde se declarara la url para comenzar el proceso de captura
        var urlSdk = ""
        
        getUrlSdk() { result in
            switch result {
                case .success(let responseText):
                    print("Response: \(responseText)")
                    urlSdk = responseText
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
            }
        }
        
        let prefs = WKPreferences()
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.defaultWebpagePreferences = pagePrefs

        let webView = WKWebView(frame: .zero, configuration: config)
        let url = URL(string: urlSdk)

        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url!))
        
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

