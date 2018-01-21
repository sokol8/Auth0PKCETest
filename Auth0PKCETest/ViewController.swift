//
//  ViewController.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-06.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import UIKit
import CocoaLumberjack

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
    
    func runAuthenticationFlow() {
        var settings = OAuthClientSettings.loadFrom(bundle: Bundle.main, plistName: "Auth0Settings")
        
        DDLogDebug("Settings: \(settings ?? nil)")
        
        //print("Settings: \(settings)")
    }

}

