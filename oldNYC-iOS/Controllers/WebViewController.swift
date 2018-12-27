//
//  WebViewController.swift
//  oldNYC-iOS
//
//  Created by Orian Breaux and Christina Leuci.
//  Copyright © 2016 OldNYC. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let url = URL(string: "https://docs.google.com/forms/d/16ryWDwz6W0jKRGtF6BOcebfvWCdA_Yn-c-vB6y3WqUw/viewform") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
