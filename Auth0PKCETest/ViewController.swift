//
//  ViewController.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-06.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import CocoaLumberjack

class ViewController: UIViewController {
    
    let kSettingsPlistName = "Auth0SettingsTestApp"
    
    var oauthSettings: OAuthClientSettings!
    var authSafariSession: SFAuthenticationSession!
    
    var authorizationWebView: WKWebView!
    var safariViewController: SFSafariViewController!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogDebug("self view: \(view)")
    }

    @IBAction func loginAction(_ sender: Any) {
        clearLog()
        runAuthenticationFlow()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// MARK: - WebView
extension ViewController {
    
    func loadSafariAuthenticationSession(withOAuthSettings settings: OAuthClientSettings) {
        guard let url = authorizationURL(withOAuthSettings: settings) else {
            DDLogError("Failed forming Authorization URL with settings: \(settings)")
            return
        }
        
        DDLogDebug("Loading Authorization url: '\(url)'")
        authSafariSession = SFAuthenticationSession(url: url, callbackURLScheme: Bundle.main.bundleIdentifier)
        { [weak self] (callBackURL: URL?, error: Error?) in
            guard error == nil else {
                DDLogError("Authentication error: '\(error!)'")
                return
            }
            
            guard let url = callBackURL else {
                DDLogError("Empty Redirect URL received")
                return
            }
            
            DDLogDebug("Recieved callBackURL: '\(url)'")
            self?.startAccessTokenRequest(url: url)
        }
        
        let startStatus = authSafariSession.start()
        DDLogInfo("Auth Session started: \(startStatus)")
    }
    
    func loadSafariWebView(withOAuthSettings settings: OAuthClientSettings) {
        
        guard let url = authorizationURL(withOAuthSettings: settings) else {
            DDLogError("Failed forming Authorization URL with settings: \(settings)")
            return
        }
        
        safariViewController = SFSafariViewController(url: url)
        safariViewController.delegate = self
        
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    func setupWKWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        authorizationWebView = WKWebView(frame: self.view.bounds, configuration: webConfiguration)
        authorizationWebView.navigationDelegate = self
        view = authorizationWebView
    }
    
    func loadWKWebView(withOAuthSettings settings: OAuthClientSettings) {
        setupWKWebView()
        
        if let request = authorizationURLRequest(withOAuthSettings: settings) {
            DDLogInfo("loading Web View with request: \(request)")
            authorizationWebView.load(request)
        }
    }
}

// MARK: - WebView
extension ViewController {
    func logLine(_ line: String) {
        DispatchQueue.main.async {
            self.logTextView.text = self.logTextView.text + "\(line)\n"
        }
    }
    
    func clearLog() {
        DispatchQueue.main.async {
            self.logTextView.text = ""
        }
    }
}

// MARK: - Authentication flow
extension ViewController {
    
    func runAuthenticationFlow() {
        guard let settings = OAuthClientSettings(withBundle: Bundle.main, plistName: kSettingsPlistName) else {
            DDLogError("Cannot read settings from Bundle. Bailing out from Authentication flow");
            return
        }
        oauthSettings = settings
        
        guard let codeVerifier = generateCodeVerifier() else {
            DDLogError("Failed to generate CodeVerifier. Bailing out from Authentication flow")
            return
        }
        oauthSettings.codeVerifier = codeVerifier
        
        guard let codeChallenge = generateCodeChallenge(fromVerifier: oauthSettings.codeVerifier!) else {
            DDLogError("Failed to generate CodeChallenge. Bailing out from Authentication flow")
            return
        }
        oauthSettings.codeChallenge = codeChallenge
        DDLogInfo("Settings: \(oauthSettings)")
        
        requestAuthorizationCode(withOAuthSettings: oauthSettings)
    }
    
    func clearCookies() {
        let cookieJar = HTTPCookieStorage.shared
        
        DDLogInfo("cleaning Cookies")
        
        for cookie in cookieJar.cookies! {
            DDLogDebug(cookie.name+"="+cookie.value)
            cookieJar.deleteCookie(cookie)
        }
        
        DDLogInfo("finished cleaning Cookies")
    }
    
    func generateCodeVerifier() -> String? {
        var buffer = [UInt8](repeating: 0, count: 32)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        
        guard errorCode == errSecSuccess else {
            DDLogError("Failed generating random bytes with error '\(errorCode)'")
            return nil
        }
        
        let verifier = Data(bytes: buffer).pkceEncodedString()
        return verifier
    }
    
    func generateCodeChallenge(fromVerifier verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else {
            DDLogError("Cannot get data out of verifier: '\(verifier)'")
            return nil
        }
        
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
        loadSafariAuthenticationSession(withOAuthSettings: settings)
    }
    
    func authorizationURL(withOAuthSettings settings: OAuthClientSettings) -> URL? {
        guard var components = URLComponents(string: settings.OAuthBaseURL) else {
            DDLogError("error forming URL from base URL '\(settings.OAuthBaseURL)'")
            return nil
        }
        
        components.path = settings.authorizationCodePath
        components.queryItems = settings.authorizationRequestURLQueryItems
        
        return components.url
    }
    
    func authorizationURLRequest(withOAuthSettings settings: OAuthClientSettings) -> URLRequest? {
        guard let url = authorizationURL(withOAuthSettings: settings) else {
            DDLogError("failed forming Authorization Code Request URL from OAuth settings: \(settings)")
            return nil
        }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        DDLogInfo("Authorization code URL Request: '\(request)'")
        return request
    }
    
    func isOAuthRedirectURL(_ url: URL) -> Bool {
        if let range = url.absoluteString.range(of: oauthSettings.redirectUri, options: .caseInsensitive) {
            return (0 == range.lowerBound.encodedOffset)
        } else {
            return false
        }
    }
    
    func callbackCode(fromURL url: URL) -> String? {
        guard let urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: false) else {
                DDLogError("Failed initialising URLComponents with URL: '\(url)'")
                return nil
        }
        
        guard let queryItems = urlComponents.queryItems else {
            DDLogError("Empty query items of URL components: '\(urlComponents)'")
            return nil
        }

        for queryItem in queryItems {
            if queryItem.name == OAuthClientSettings.URLQueryItemKeys.authorizationCode.rawValue {
               return queryItem.value
            }
        }
        
        return nil
    }
    
    @discardableResult
    func startAccessTokenRequest(url: URL) -> Bool {
        
        guard isOAuthRedirectURL(url) else {
            DDLogError("Improper Redirect URL recieved: \(url)")
            return false
        }
        
        oauthSettings.authorizationCode = callbackCode(fromURL: url)
        DDLogDebug("Recieved Authorization Code: '\(oauthSettings.authorizationCode!)'")
        
        self.logLine("--------------------")
        self.logLine("Recieved Authorization Code: \(oauthSettings.authorizationCode!)")
        self.logLine("--------------------")
        
        // Postpone Requesting Access Token to verify Auth0 race condition assumption
        let when = DispatchTime.now() + 0
        DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
            self?.requestAccessToken(withOAuthSettings: (self?.oauthSettings)!)
        }
        
        return true
    }
    
    func requestAccessToken(withOAuthSettings settings : OAuthClientSettings) {
        
        guard let urlRequest = accessTokenURLRequest(withOAuthSettings: settings) else {
                DDLogError("Failed creating URL Request with settings: '\(settings)'")
                return
        }
        
        DDLogDebug("Requesting access Token with url: '\(urlRequest.url!)'")
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: urlRequest, completionHandler: {
            [weak self] (responseData, response, error) -> Void in
            
            guard error == nil else {
                DDLogError("Authentication Token request error '\(error!)'")
                return
            }
                
            DDLogDebug("Authentication Token response '\(response!)'")
            guard let data = responseData else {
                DDLogError("Authentication Token response contained no Data")
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DDLogError("error serializing JSON into Data");
                return
            }
            
            DDLogDebug("Access Token Response JSON: '\(json!)'")
            self?.logJSONResponse(json)
            
        })
        dataTask.resume()
    }
    
    func logJSONResponse(_ json: [String: Any]?) {
        self.logLine("--------------------")
        self.logLine("Access Token Response")
        self.logLine("--------------------")
        if let jsonDict = json {
            for (key, value) in jsonDict {
                self.logLine("'\(key) : '\(value)'")
            }
        }
    }
    
    func accessTokenURLRequest(withOAuthSettings settings: OAuthClientSettings) -> URLRequest? {
        guard var components = URLComponents(string: settings.OAuthBaseURL) else {
            DDLogError("error forming URL from base URL: '\(settings.OAuthBaseURL)'")
            return nil
        }
        components.path = settings.accessTokenPath
        
        guard let url = components.url else {
            DDLogError("error getting URL out of components: '\(components)'")
            return nil
        }
        
        DDLogDebug("Access Token Request Dictionary: '\(settings.accessTokenRequestParameters)'")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: settings.accessTokenRequestParameters, options: []) else {
            DDLogError("Error serializing setitngs into JSON")
            return nil
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["content-type": "application/json"]
        request.httpBody = httpBody
        
        DDLogDebug("Access Token URL Request: '\(request)'")
        
        return request
    }
    
}

