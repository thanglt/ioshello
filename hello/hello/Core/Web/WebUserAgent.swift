//
//  WebUserAgent.swift
//  hello
//

import Foundation

enum WebUserAgent {
    /// Prepended to WebKit's default User-Agent, e.g. `ios:hello:1.0`.
    static func prefix(bundle: Bundle = .main) -> String {
        let info = bundle.infoDictionary ?? [:]
        let appName = info["CFBundleDisplayName"] as? String
            ?? info["CFBundleName"] as? String
            ?? ""
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        return "ios:\(appName):\(version)"
    }
}
