//
//  ViewController+WKNavigationDelegate.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-31.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation
import WebKit
import CocoaLumberjack

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
