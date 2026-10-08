//
//  JapaneseWebSupport.swift
//  hello
//

import Foundation
import WebKit

/// Makes a `WKWebView` present itself as Japanese:
/// - `fetch` and `XMLHttpRequest` send `Accept-Language` (main-frame navigations get it
///   from `InAppWebViewModel`),
/// - `navigator.language(s)` report Japanese,
/// - CJK text falls back to Hiragino. WebKit on the iOS Simulator draws CJK text set in
///   `system-ui` / `-apple-system` (Bootstrap's default font stack) as missing-glyph boxes.
enum JapaneseWebSupport {
    static let acceptLanguage = "ja"
    static let navigatorLanguages = ["ja-JP", "ja"]

    static func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let contentController = configuration.userContentController
        contentController.addUserScript(
            WKUserScript(source: languageScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )
        contentController.addUserScript(
            WKUserScript(source: fontScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )
        return configuration
    }

    static func localized(_ request: URLRequest) -> URLRequest {
        var request = request
        request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
        return request
    }

    private static var languageScript: String {
        let languagesJSON = "[" + navigatorLanguages.map { "\"\($0)\"" }.joined(separator: ",") + "]"
        return """
        (() => {
          const acceptLanguage = "\(acceptLanguage)";
          const languages = \(languagesJSON);
          try {
            Object.defineProperty(Navigator.prototype, "language", { get: () => languages[0], configurable: true });
            Object.defineProperty(Navigator.prototype, "languages", { get: () => languages.slice(), configurable: true });
          } catch (e) {}

          const isAcceptLanguage = (name) => String(name).toLowerCase() === "accept-language";
          const setHeader = XMLHttpRequest.prototype.setRequestHeader;
          XMLHttpRequest.prototype.setRequestHeader = function (name, value) {
            if (isAcceptLanguage(name)) { this.__hasAcceptLanguage = true; }
            return setHeader.call(this, name, value);
          };
          const send = XMLHttpRequest.prototype.send;
          XMLHttpRequest.prototype.send = function (...args) {
            if (!this.__hasAcceptLanguage) {
              try { setHeader.call(this, "Accept-Language", acceptLanguage); } catch (e) {}
            }
            return send.apply(this, args);
          };

          const originalFetch = window.fetch;
          window.fetch = function (input, init) {
            const headers = new Headers(
              (init && init.headers) || (input instanceof Request ? input.headers : undefined)
            );
            if (!headers.has("Accept-Language")) { headers.set("Accept-Language", acceptLanguage); }
            return originalFetch.call(this, input, Object.assign({}, init, { headers }));
          };
        })();
        """
    }

    private static let fontScript = """
        (() => {
          const ranges = "U+3000-303F, U+3040-30FF, U+31F0-31FF, U+3400-4DBF, U+4E00-9FFF, U+F900-FAFF, U+FF00-FFEF";
          const css = `
            @font-face {
              font-family: "AppJapaneseFallback";
              src: local("HiraginoSans-W3"), local("HiraKakuProN-W3");
              font-weight: 100 500;
              unicode-range: ${ranges};
            }
            @font-face {
              font-family: "AppJapaneseFallback";
              src: local("HiraginoSans-W6"), local("HiraKakuProN-W6");
              font-weight: 600 900;
              unicode-range: ${ranges};
            }
            :root {
              --bs-font-sans-serif: "AppJapaneseFallback", system-ui, -apple-system, "Hiragino Sans", sans-serif !important;
              --bs-body-font-family: var(--bs-font-sans-serif) !important;
            }
            body { font-family: "AppJapaneseFallback", system-ui, -apple-system, "Hiragino Sans", sans-serif; }
          `;
          const style = document.createElement("style");
          style.textContent = css;
          (document.head || document.documentElement).appendChild(style);
        })();
        """
}
