//
//  ContentView.swift
//  WebViewConsumer
//
//  Created by Javier Ferri de Dios on 2/5/23.
//

import SwiftUI
import WebKit

struct ContentView: View {
    private let urlString = "file:///Users/javiferrid/Desktop/test.html"
    private let css = """
        html, body {
          overflow-x: hidden;
        }

        body {
          background-color: #333333;
          line-height: 1.5;
          color: white;
          padding: 10;
          font-weight: 600;
          font-family: -apple-system;
        }
    """
    var body: some View {
        VStack {
            WebView(url: URL(string: urlString)!, css: css)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct WebView: UIViewRepresentable {
    var url: URL
    var css: String
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var webView: WKWebView?
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
        }
        
        // receive message from wkwebview
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            print(message.body)
            let date = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.messageToWebview(msg: "hello, I got your messsage: \(message.body) at \(date)")
            }
        }
        
        func messageToWebview(msg: String) {
            self.webView?.evaluateJavaScript("webkit.messageHandlers.bridge.onMessage('\(msg)')")
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let cssString = css.components(separatedBy: .newlines).joined()
        let javaScript = """
           var element = document.createElement('style');
           element.innerHTML = '\(cssString)';
           document.head.appendChild(element);
        """
        let userScript = WKUserScript(source: javaScript,
                                      injectionTime: .atDocumentEnd,
                                      forMainFrameOnly: true)
    
        let coordinator = makeCoordinator()
        let userContentController = WKUserContentController()
        userContentController.add(coordinator, name: "bridge")
        userContentController.addUserScript(userScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        let _wkWV = WKWebView(frame: CGRect.zero, configuration: configuration)
        _wkWV.navigationDelegate = coordinator

        return _wkWV
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
