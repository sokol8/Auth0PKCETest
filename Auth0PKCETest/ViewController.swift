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
import SafariServices

class ViewController: UIViewController {
    
    let settingsPlistName = "Auth0SettingsTestApp"
    
    var oauthSettings: OAuthClientSettings!
    var authorizationWebView: WKWebView!
    var safariViewController: SFSafariViewController!
    var authSafariSession: SFAuthenticationSession!
    
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

// MARK: WebView
extension ViewController {
    
    func loadSafariWebView(withOAuthSettings settings: OAuthClientSettings) {
        
        guard let url = authorizationURL(withOAuthSettings: settings)
            else {
                DDLogError("Failed forming Authorization URL with settings: \(settings)")
                return
        }
        
        safariViewController = SFSafariViewController(url: url)
        safariViewController.delegate = self
        
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    // NOTE: SFAuthenticationSession doesn't properly work with Auth0. Raises error "Safari cannot open the page because the address is invalid"
    // Errors is raised disregarding of whether we pass nil or valid redirectUri to callbackURLScheme
    func loadSafariAuthenticationSession(withOAuthSettings settings: OAuthClientSettings) {
        guard let url = authorizationURL(withOAuthSettings: settings)
            else {
                DDLogError("Failed forming Authorization URL with settings: \(settings)")
                return
        }
        
        authSafariSession = SFAuthenticationSession(url: url, callbackURLScheme: "om.works.Auth0PKCETest" )
        { (callBackURL:URL?, error:Error?) in
            guard error == nil
                else {
                    DDLogError("Authentication error: '\(error)'")
                    return
            }
            DDLogDebug("got callBackURL: '\(callBackURL)'")
            
            self.startAccessTokenRequest(url: callBackURL)
        }
        
        let startStatus = authSafariSession.start()
        DDLogInfo("Auth Session started: \(startStatus)")
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
    
    func logLine(_ line: String) {
        DispatchQueue.main.async {
            //self.logTextView.text.appendingFormat("\(line)\n")
            self.logTextView.text = self.logTextView.text + "\(line)\n"
        }
    }
    
    func clearLog() {
        DispatchQueue.main.async {
            self.logTextView.text = ""
        }
    }
}


// MARK: Authentication flow
extension ViewController {
    
    func runAuthenticationFlow() {
        
        clearCookies()
        
        guard let settings = OAuthClientSettings(withBundle: Bundle.main, plistName: settingsPlistName)
            else {
                DDLogError("Cannot read settings from Bundle. Bailing out from Authentication flow");
                return
        }
        oauthSettings = settings
        
        guard let codeVerifier = generateCodeVerifier()
            else {
                DDLogError("Failed to generate CodeVerifier. Bailing out from Authentication flow")
                return
        }
        oauthSettings.codeVerifier = codeVerifier
        
        guard let codeChallenge = generateCodeChallenge(fromVerifier: oauthSettings.codeVerifier!)
            else {
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
        
        guard errorCode == errSecSuccess
            else {
                DDLogError("Failed generating random bytes with error '\(errorCode)'")
                return nil
        }
        
        let verifier = Data(bytes: buffer).pkceEncodedString()
        return verifier
    }
    
    func generateCodeChallenge(fromVerifier verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8)
            else {
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
        //loadSafariWebView(withOAuthSettings: settings)
        //loadWKWebView(withOAuthSettings: settings)
    }
    
    func authorizationURL(withOAuthSettings settings: OAuthClientSettings) -> URL? {
        guard var components = URLComponents(string: settings.OAuthBaseURL)
            else {
                DDLogError("error forming URL from base URL '\(settings.OAuthBaseURL)'")
                return nil
        }
        
        components.path = settings.authorizationCodePath
        components.queryItems = settings.authorizationRequestURLQueryItems
        
        return components.url
    }
    
    func authorizationURLRequest(withOAuthSettings settings: OAuthClientSettings) -> URLRequest? {
        if let url = authorizationURL(withOAuthSettings: settings) {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
            DDLogInfo("Authorization code URL Request: '\(request)'")
            return request
        } else {
            DDLogError("failed forming Authorization Code Request URL from OAuth settings: \(settings)")
            return nil
        }
    }
    
    func isOAuthRedirectURL(_ url: URL) -> Bool {
        if let range = url.absoluteString.range(of: oauthSettings.redirectUri, options: .caseInsensitive) {
            return (0 == range.lowerBound.encodedOffset)
        } else {
            return false
        }
    }
    
    func callbackCode(fromURL url: URL) -> String? {
        guard let urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: false )
            else {
                DDLogError("Failed initialising URLComponents with URL: '\(url)'")
                return nil
        }
        
        if let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                
                if queryItem.name == OAuthClientSettings.URLQueryItemKeys.authorizationCode.rawValue {
                   return queryItem.value
                }
            }
        }
        else {
            DDLogError("Empty query items of URL components: '\(urlComponents)'")
            return nil
        }
        
        return nil
    }
    
    @discardableResult
    func startAccessTokenRequest(url: URL?) -> Bool {
        
        if let callBackURL = url {
            if isOAuthRedirectURL(callBackURL) {
                oauthSettings.authorizationCode = callbackCode(fromURL: callBackURL)
                DDLogDebug("Recieved Authorization Code: '\(oauthSettings.authorizationCode!)'")
                
                self.logLine("--------------------")
                self.logLine("Recieved Authorization Code: \(oauthSettings.authorizationCode!)")
                self.logLine("--------------------")
                
                requestAccessToken(withOAuthSettings: oauthSettings)
                return true
            }
        }
        return false
    }
    
    func requestAccessToken(withOAuthSettings settings : OAuthClientSettings) {
        
        guard let urlRequest = accessTokenURLRequest(withOAuthSettings: settings)
            else {
                DDLogError("Failed creating URL Request with settings: '\(settings)'")
                return
        }
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                DDLogError("Authentication Token request error '\(error!)'")
            }
            else {
                
                DDLogDebug("Authentication Token response '\(response!)'")
                DDLogDebug("Access Token Data: \(data)")
                
                guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                    else {
                        DDLogError("error serializing JSON into Data");
                        return
                }
                
                DDLogDebug("Access Token Response JSON: '\(json)'")
                
                self.logLine("--------------------")
                self.logLine("Access Token Response")
                self.logLine("--------------------")
                if let jsonDict = json {
                    for (key, value) in jsonDict {
                        self.logLine("'\(key) : '\(value)'")
                    }
                }
            }
        })
        dataTask.resume()
    }
    
    func accessTokenURLRequest(withOAuthSettings settings: OAuthClientSettings) -> URLRequest? {
        guard var components = URLComponents(string: settings.OAuthBaseURL)
            else {
                DDLogError("error forming URL from base URL: '\(settings.OAuthBaseURL)'")
                return nil
        }
        components.path = settings.accessTokenPath
        
        guard let url = components.url
            else {
                DDLogError("error getting URL out of components: '\(components)'")
                return nil
        }
        
        DDLogDebug("Access Token Request Dictionary: '\(settings.accessTokenRequestParameters)'")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: settings.accessTokenRequestParameters, options: [])
            else {
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

//MARK:- WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    
    // TODO:
    // ADD support for Code=-1001 "The request timed out."
    //  ADD support for Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
    func handleError(_ error: Error) {
        DDLogError("WebKit error: '\(error)'")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)
    {
        DDLogDebug("Decide policy for Navigation Item: '\(navigationAction)'")
        
        guard let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
        }
        DDLogDebug("\n\nNavigation URL: '\(url)'\n\n")
        
        
        //TODO: add support for error 'om.works.auth0pkcetest://mc-test.auth0.com/ios/om.works.Auth0PKCETest/callback?error=access_denied&error_description=Service%20not%20found%3A%20https%3A%2F%2Fapi-dev.metaboliccompass.com'
        // TO REPERODUCE - set audience to 'api-dev.metaboliccompass.com' with MC-TEST client
        
        let status = startAccessTokenRequest(url: url)
        
        if status {
            decisionHandler(.cancel)
        }
        else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - SFSafariViewControllerDelegate
extension ViewController : SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool){
        DDLogInfo("completed initial load of \(controller)")
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        DDLogInfo("user closed Safari View Controller")
    }
}
