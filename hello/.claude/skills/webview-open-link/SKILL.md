---
name: webview-open-link
description: Add a screen with a button that opens a URL in an in-app WKWebView (Japanese Accept-Language, ios:<app>:<version> User-Agent prefix, Japanese font fix, page back button via window.ReactNativeWebView bridge, no app nav bar). Use when the user asks to open a link / web page / webview from a button or screen.
---

# Open a link in an in-app WKWebView

Verified on iOS 26 Simulator (iPhone 17 Pro) in this project. Reference sources live in
`templates/` next to this file and, in this repo, in `hello/Core/Web/` and
`hello/Features/OrderHistory/`.

## What the result does
- Screen with an **Open** button → pushes a full-screen `WKWebView` (not Safari, not SwiftUI `WebView`/`WebPage`).
- App navigation bar hidden on the web screen: no white back button, no reload button. The page's own header is the only chrome.
- Headers on every main-frame navigation + every `fetch`/`XMLHttpRequest`: `Accept-Language: ja`.
- `navigator.language` = `ja-JP`, `navigator.languages` = `["ja-JP","ja"]`.
- `User-Agent: ios:<CFBundleDisplayName|CFBundleName>:<CFBundleShortVersionString> <WebKit default UA>`.
- Japanese text renders correctly (no `?` boxes) on the Simulator.
- Page sends `window.ReactNativeWebView.postMessage(JSON.stringify({command: 'back'}))` → web view closes and the main screen shows again.

## Steps
1. **Shared web layer** — if `hello/Core/Web/` does not exist yet, copy `templates/Core/Web/*.swift` there (the `hello/` folder is file-system-synchronized; never edit `project.pbxproj`):
   - `WKWebViewContainer.swift` — `UIViewRepresentable` hosting a `WKWebView` owned by the view model.
   - `JapaneseWebSupport.swift` — `WKWebViewConfiguration` with two `.atDocumentStart` user scripts (language + font) and `localized(_ request:)` that sets `Accept-Language`.
   - `WebBridge.swift` — injects `window.ReactNativeWebView`, parses `{"command": ...}` into `WebBridge.Command`, logs unknown commands with `Logger` (category `WebBridge`).
   - `InAppWebViewModel.swift` — `@Observable final class …: NSObject`, owns the `WKWebView`, `WKNavigationDelegate`, KVO for `isLoading`/`estimatedProgress`, `isCloseRequested`.
   - `InAppWebView.swift` — the screen: `.toolbar(.hidden, for: .navigationBar)`, `.ignoresSafeArea(edges: .bottom)`, linear progress overlay, `dismiss()` on `isCloseRequested`.
   If it already exists, reuse it — do not duplicate.
2. **Feature screen** — follow the `new-feature` skill layout (`Features/<Name>/{Views,ViewModels}`), modelled on `templates/Features/OrderHistory/`:
   - View model: `static let defaultURL = URL(string: "…")` (optional, never force-unwrap), `userAgentPrefix` built from `Bundle`, `request: URLRequest?` with `Accept-Language`, `isShowingWebView`, `openTapped()`.
   - View: `NavigationStack` + `Button("Open", action: viewModel.openTapped)` + `.navigationDestination(isPresented:)` → `InAppWebView(request:userAgentPrefix:)`.
   - Add every UI string to `hello/Localizable.xcstrings`. Every view gets a `#Preview`.
   - Make the screen reachable (e.g. root in `helloApp.swift`) only if the user wants that; say what you changed.
3. **New bridge commands** — add a `case` to `WebBridge.Command` (+ its name in `init(_:)`) and handle it in `InAppWebViewModel.handle(_:)`.
4. **Build** with the CLAUDE.md command; zero errors and zero new warnings.
5. **Verify on the Simulator** (attach the panel first), see below.

## Why it is built this way (gotchas found the hard way)
- **`?` boxes instead of Japanese**: the server is fine (`lang="ja"`, `Content-Language: ja-JP`). WebKit on the iOS Simulator renders CJK text in `system-ui` / `-apple-system` (Bootstrap's default stack) as missing glyphs, even in Safari; `sans-serif` and `Hiragino Sans` work. Fix = an `@font-face` named `AppJapaneseFallback` from `local("HiraginoSans-W3")`/`W6` limited by `unicode-range` to CJK, put first in `--bs-font-sans-serif` / `--bs-body-font-family` (with `!important`) and `body`. Latin text keeps the system font; on devices it matches what iOS uses anyway.
- **`Accept-Language` on `URLRequest` only covers that one request.** Link taps/redirects lose it → `decidePolicyFor` cancels main-frame GETs lacking the header and re-loads them with it (skip `.backForward`, `.reload`, POST/body, non-http(s), and fragment-only `#…` changes, otherwise `href="#"` reloads the page). `fetch`/XHR are patched in JS. Images/CSS/JS sub-resources still send the system language — WebKit gives no hook for those.
- **User-Agent prefix**: read the default with `evaluateJavaScript("navigator.userAgent")` before the first load, then set `customUserAgent = "<prefix> <default>"`. `applicationNameForUserAgent` can only append.
- **Back button**: pages with `_top` in the URL call `reactMsgBackToApp()` → `window.ReactNativeWebView.postMessage(JSON.stringify({command:'back'}))` (built for a React Native host). We provide that object at document start and forward to a `WKScriptMessageHandler`.
- **Retain cycles**: `WKUserContentController` retains its handlers → use the `WebBridgeMessageHandler` proxy with a `[weak self]` closure; `navigationDelegate` is weak already.
- **Swift 6 / concurrency**: everything is MainActor by default. KVO change handlers are not actor-isolated → wrap updates in `MainActor.assumeIsolated` (WKWebView KVO fires on main). Do not add `@preconcurrency`/`@unchecked Sendable`.
- **`MemberImportVisibility`**: files using `Logger` interpolation must `import OSLog`; files using WebKit types must `import WebKit`.
- Hiding the nav bar removes the app's back button; the page's back button (bridge) is then the way out. Mention this to the user; offer a fallback close button if the page can fail to load.
- iOS 26 SwiftUI `WebView`/`WebPage` was tried first and dropped at the user's request: it has no hook for `window.open`, and the user wants `WKWebView`.
- The URL in this project contains `accountId`/`retailerId`; flag hard-coded per-account IDs and offer moving them to an uncommitted `.xcconfig`.

## Verify
1. Real page: build, `launch` the `.app` on the Simulator, tap **Open**, screenshot → Japanese text readable, no app nav bar, bottom of the page reaches the screen edge. Tap the page's `<` → main screen again.
2. Headers: run `python3 -I .claude/skills/webview-open-link/scripts/echo_headers.py <scratchpad>/headers.log` in the background, temporarily point `defaultURL` at `http://localhost:8765/test` (ATS allows localhost), build, open it, tap `next page`, `fragment`, `bridge back`, then read the log. Expect `AL=ja` and `UA=ios:hello:<version> Mozilla/…` on `/test`, `/api/fetch`, `/api/xhr`, `/next`; no second `/test` after `fragment`; the bridge button closes the screen.
3. **Restore the real URL** (keep a backup copy before editing; `grep` for it afterwards), stop the server, rebuild, relaunch.
