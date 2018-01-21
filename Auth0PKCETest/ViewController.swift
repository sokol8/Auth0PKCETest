//
//  ViewController.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-06.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import UIKit
import CocoaLumberjack
//import CommonCrypto

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        runAuthenticationFlow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


// MARK: Authentication flow
extension ViewController {
    
    func runAuthenticationFlow() {
        
        // Load settings from plist file
        guard
            var settings = OAuthClientSettings.loadFrom(bundle: Bundle.main, plistName: "Auth0Settings")
            else {
                DDLogError("Cannot read settings from Bundle");
                return
        }
        settings.codeVerifier = generateCodeVerifier()
        settings.codeChallenge = generateCodeChallenge(fromVerifier: settings.codeVerifier!)
        
        DDLogDebug("Settings: \(settings)")
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
}

extension Data {
    func pkceEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

