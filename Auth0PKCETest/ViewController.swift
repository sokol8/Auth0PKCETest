//
//  ViewController.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-06.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import UIKit
import CocoaLumberjack
import WebKit

class ViewController: UIViewController {
    
    var authorizationWebView: WKWebView!
    var oauthSettings: OAuthClientSettings!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        runAuthenticationFlow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        DDLogDebug("WebView Strat to load")
//    }
//
//    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
//        DDLogDebug("WebView finish to load")
//    }

}

// MARK: WebView
extension ViewController {
    
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        authorizationWebView = WKWebView(frame: self.view.bounds, configuration: webConfiguration)
        authorizationWebView.navigationDelegate = self
        view = authorizationWebView
    }
    
    func loadWebView(withOAuthSettings settings: OAuthClientSettings) {
        if let request = authorizationURLRequest(withOAuthClientSettings: settings) {
            DDLogInfo("loading Web View with request: \(request)")
            authorizationWebView.load(request)
        }
    }
    
    func authorizationURLRequest(withOAuthClientSettings settings: OAuthClientSettings) -> URLRequest? {
        guard
            var components = URLComponents(string: settings.OAuthBaseURL)
            else {
                DDLogError("error forming URL from base URL '\(settings.OAuthBaseURL)'")
                return nil
        }
        
        components.path = settings.authorizationCodePath
        
        let audienceItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["audience"]!, value: settings.audience)
        let scopeItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["scope"]!, value: settings.scope)
        let responseTypeItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["responseType"]!, value: settings.responseType)
        let clientIdItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["clientId"]!, value: settings.clientId)
        let codeChallengeItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["codeChallenge"]!, value: settings.codeChallenge)
        let codeChallengeMethodItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["codeChallengeMethod"]!, value: settings.codeChallengeMethod)
        let redirectUrlItem = URLQueryItem(name: OAuthClientSettings.URLQueryItemKeysMapping["redirectUri"]!, value: settings.redirectUri)
        components.queryItems = [audienceItem, scopeItem, responseTypeItem, clientIdItem, codeChallengeItem, codeChallengeMethodItem, redirectUrlItem]
        
        if let url = components.url {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
            DDLogInfo("Authorization code URL Request: '\(request)'")
            return request
        } else {
            DDLogError("failed forming Authorization Code Request URL from OAuth settings: \(settings)")
            return nil
        }
    }
}


// MARK: Authentication flow
extension ViewController {
    
    func runAuthenticationFlow() {
        guard
            var settings = OAuthClientSettings(withBundle: Bundle.main, plistName: "Auth0Settings")
            else {
                DDLogError("Cannot read settings from Bundle");
                return
        }
        settings.codeVerifier = generateCodeVerifier()
        settings.codeChallenge = generateCodeChallenge(fromVerifier: settings.codeVerifier!)
        
        DDLogInfo("Settings: \(settings)")
        
        requestAuthorizationCode(withOAuthSettings: settings)
    }
    
    func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        let verifier = Data(bytes: buffer).pkceEncodedString()
        return verifier
    }
    
    func generateCodeChallenge(fromVerifier verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        
        var buffer = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &buffer)
        }
        
        let hash = Data(bytes: buffer)
        let challenge = hash.pkceEncodedString()
        return challenge
    }
    
    func requestAuthorizationCode(withOAuthSettings settings : OAuthClientSettings) {
        DDLogInfo("Starting Authorization Code request")
        loadWebView(withOAuthSettings: settings)
    }
    
    func isOAuthRedirectURL(_ url: URL) -> Bool {
        DDLogDebug("path: '\(url.absoluteURL)'")
        
        
        if url.absoluteString.hasPrefix()
        
        return true
    }
}

//MARK:- WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DDLogInfo("WebView Started loading")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DDLogInfo("WebView finished loading")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    
    func handleError(_ error: Error) {
        DDLogError("WebKit error: '\(error)'")
//        if let failingUrl = error.userInfo["NSErrorFailingURLStringKey"] as? String {
//
//            DDLogDebug("Failing URL: '\(failingUrl)'")
//        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        DDLogDebug("Did Recieve server redirect for Navigation Item: '\(navigation)'")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)
    {
        DDLogDebug("Decide policy for Navigation Item: '\(navigationAction)'")
        
        guard let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
        }
        
        if isOAuthRedirectURL(url) {
            DDLogDebug("last path component: '\(url.lastPathComponent)'")
            decisionHandler(.cancel)
            return
        }
        else {
            decisionHandler(.allow)
        }
    }
}

// MARK: Data extension for codes encoding
extension Data {
    func pkceEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

