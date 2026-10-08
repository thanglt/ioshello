//
//  OrderHistoryViewModel.swift
//  hello
//

import Foundation
import Observation

@Observable
final class OrderHistoryViewModel {
    static let defaultURL = URL(
        string: "https://active.amanotesunny.com/customer/views/shopping/default/order-history?mode=orderHistory&shoppingMode=TAKE_OUT&accountId=40a0ced1-8340-4277-8aa2-36e471df5f57&retailerId=91a74429-bce0-4211-96c7-4bc2dd8ff5ec&_top=1"
    )

    let url: URL?
    /// Prepended to WebKit's default User-Agent, e.g. `ios:hello:1.0`.
    let userAgentPrefix: String
    var isShowingWebView = false

    var canOpen: Bool { url != nil }

    var request: URLRequest? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.setValue(JapaneseWebSupport.acceptLanguage, forHTTPHeaderField: "Accept-Language")
        return request
    }

    init(url: URL? = OrderHistoryViewModel.defaultURL, bundle: Bundle = .main) {
        self.url = url
        self.userAgentPrefix = Self.makeUserAgentPrefix(bundle: bundle)
    }

    func openTapped() {
        guard canOpen else { return }
        isShowingWebView = true
    }

    private static func makeUserAgentPrefix(bundle: Bundle) -> String {
        let info = bundle.infoDictionary ?? [:]
        let appName = info["CFBundleDisplayName"] as? String
            ?? info["CFBundleName"] as? String
            ?? ""
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        return "ios:\(appName):\(version)"
    }
}
