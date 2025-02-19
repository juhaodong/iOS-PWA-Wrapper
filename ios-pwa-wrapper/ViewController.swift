//
//  ViewController.swift
//  ios-pwa-wrapper
//
//  Created by Martin Kainzbauer on 25/10/2017.
//  Copyright © 2017 Martin Kainzbauer. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var offlineView: UIView!
    @IBOutlet weak var offlineIcon: UIImageView!
    @IBOutlet weak var offlineButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!


    // MARK: Globals
    var webView: WKWebView!
    var tempView: WKWebView!
    var progressBar: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = appTitle
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            //检查设置中的图标是否与app图标一致
            self.setIcon()
            
            //使用UserDefaults来判断程序是否第一次启动
            self.firstLaunchCheckIcon()

        }
        
        setupApp()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // reload page from offline screen
    @IBAction func onOfflineButtonClick(_ sender: Any) {
        offlineView.isHidden = true
        webViewContainer.isHidden = false
        loadAppUrl()
    }

    // Observers for updating UI
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if (keyPath == #keyPath(WKWebView.isLoading)) {
            // show activity indicator

            /*
            // this causes troubles when swiping back and forward.
            // having this disabled means that the activity view is only shown on the startup of the app.
            // ...which is fair enough.
            if (webView.isLoading) {
                activityIndicatorView.isHidden = false
                activityIndicator.startAnimating()
            }
            */
        }
        if (keyPath == #keyPath(WKWebView.estimatedProgress)) {
            progressBar.progress = Float(webView.estimatedProgress)
        }
    }

    // Initialize WKWebView
    func setupWebView() {
        // set up webview
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: webViewContainer.frame.width, height: webViewContainer.frame.height))
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webViewContainer.addSubview(webView)

        // settings
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.preferences.javaScriptEnabled = true
        if #available(iOS 10.0, *) {
            webView.configuration.ignoresViewportScaleLimits = false
        }
        webView.customUserAgent = "Mozilla/5.0 (Linux; Android 4.1.1; Galaxy Nexus Build/JRO03C) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.166 Mobile Safari/535.19";

        // bounces
        webView.scrollView.bounces = enableBounceWhenScrolling

        // init observers
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: NSKeyValueObservingOptions.new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: NSKeyValueObservingOptions.new, context: nil)
    }

    // Initialize UI elements
    // call after WebView has been initialized
    func setupUI() {
        // leftButton.isEnabled = false

        // progress bar
        progressBar = UIProgressView(frame: CGRect(x: 0, y: 0, width: webViewContainer.frame.width, height: 40))
        progressBar.autoresizingMask = [.flexibleWidth]
        progressBar.progress = 0.0
        progressBar.tintColor = progressBarColor
        webView.addSubview(progressBar)

        // activity indicator
        activityIndicator.color = activityIndicatorColor
        activityIndicator.startAnimating()

        // offline container
        offlineIcon.tintColor = offlineIconColor
        offlineButton.tintColor = buttonColor
        offlineView.isHidden = true

        // setup navigation bar
        if (forceLargeTitle) {
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.always
            }
        }
        if (useLightStatusBarStyle) {
            self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        }
        self.navigationController?.navigationBar.isHidden = true


        /// create callback for device rotation
        let deviceRotationCallback: (Notification) -> Void = { _ in
            // this fires BEFORE the UI is updated, so we check for the opposite orientation,
            // if it's not the initial setup
        }
        /// listen for device rotation
        NotificationCenter.default.addObserver(forName: .UIDeviceOrientationDidChange, object: nil, queue: .main, using: deviceRotationCallback)

        /*
        // @DEBUG: test offline view
        offlineView.isHidden = false
        webViewContainer.isHidden = true
        */
    }

    // load startpage
    func loadAppUrl() {
        let urlRequest = URLRequest(url: webAppUrl!)
        webView.load(urlRequest)
    }

    // Initialize App and start loading
    func setupApp() {
        setupWebView()
        setupUI()
        loadAppUrl()
    }

    // Cleanup
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
    }

    // Helper method to determine wide screen width
    func isWideScreen() -> Bool {
        // this considers device orientation too.
        if (UIScreen.main.bounds.width >= wideScreenMinWidth) {
            return true
        } else {
            return false
        }
    }
    
    func firstLaunchCheckIcon() {
        let userDefault = UserDefaults.standard
        let isNotFitst = userDefault.bool(forKey: "firstLaunch")
        NSLog(String(isNotFitst))
        if(!isNotFitst){
            userDefault.set(true, forKey: "firstLaunch")
            NSLog("is first launching")
            let chooseIcon = bottomAlert()
            NSLog(chooseIcon)
        }
    }
    
    func setIcon() {
        let userDefault = UserDefaults.standard
        let icon = userDefault.object(forKey: "chooseIcon")
        
        let icon_name = String(describing: icon)
                
        switch(icon_name) {
            case "Optional(AD)" :
                changeAppIconWithName(iconName: nil)
                break
            case "Optional(T4)" :
                changeAppIconWithName(iconName: "Icon_T4")
                break
            case "Optional(CB)" :
                changeAppIconWithName(iconName: "Icon_CB")
                break
            case "Optional(TM)" :
                changeAppIconWithName(iconName: "Icon_TM")
                break
            default:
                print(icon_name)
//                changeAppIconWithName(iconName: nil)
        }
        
    }
    
    func changeAppIconWithName(iconName: String?) {
        if UIApplication.shared.supportsAlternateIcons {
            print("change to " + (iconName ?? "nil"))
            let currentIconName = UIApplication.shared.alternateIconName ?? nil
            
            //当现icon不是选中icon时切换为选中icon
            if(iconName != currentIconName) {
                UIApplication.shared.setAlternateIconName(iconName) { error in
                    print(error ?? "no error")
                }
                let userDefault = UserDefaults.standard
                var icon = userDefault.object(forKey: "chooseIcon")
                
                var icon_name = String(describing: icon)
                NSLog(icon_name)
                userDefault.set(iconName,forKey: "chooseIcon")
                
                icon = userDefault.object(forKey: "chooseIcon")
                
                icon_name = String(describing: icon)
                NSLog(icon_name)
            }
        }
    }


    // change Icon Button
    @IBOutlet weak var toggleIconBtn: UIButton!

    @IBAction func triggerIcon(_ sender: Any) {
//        print(UIApplication.shared.alternateIconName ?? "alternateIconName")
//        print("========================================")

//        bottomAlert()
    }


    //切换图标按钮
    func bottomAlert() -> String {
        var res = String()
        let alertController = UIAlertController(title: NSLocalizedString("切换图标", comment: ""),
                message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: ""), style: .cancel, handler: nil)

        let originalIcon = UIAlertAction(title: NSLocalizedString("原始图标", comment: ""), style: .default, handler: { [self]
            action in
            print("切换为原始图标")
            changeAppIconWithName(iconName: nil)
            res = "AD"
        })
        let t4Icon = UIAlertAction(title: NSLocalizedString("T4", comment: ""), style: .default, handler: { [self]
            action in
            print("切换为T4图标")
            changeAppIconWithName(iconName: "Icon_T4")
            res = "T4"
        })
        let comebuyIcon = UIAlertAction(title: NSLocalizedString("ComeBuy", comment: ""), style: .default, handler: { [self]
            action in
            print("切换为ComeBuy图标")
            changeAppIconWithName(iconName: "Icon_CB")
            res = "CB"
        })
        let teeamoIcon = UIAlertAction(title: NSLocalizedString("Teeamo", comment: ""), style: .default, handler: { [self]
            action in
            print("切换为茶伴图标")
            changeAppIconWithName(iconName: "Icon_TM")
            res = "TM"
        })
        alertController.addAction(cancelAction)
        alertController.addAction(t4Icon)
        alertController.addAction(comebuyIcon)
        alertController.addAction(teeamoIcon)
        alertController.addAction(originalIcon)
        self.present(alertController, animated: true, completion: nil)
        return res
    }

}

// WebView Event Listeners
extension ViewController: WKNavigationDelegate {
    // didFinish
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // set title
        if (changeAppTitleToPageTitle) {
            navigationItem.title = webView.title
        }
        // hide progress bar after initial load
        progressBar.isHidden = true
        // hide activity indicator
        activityIndicatorView.isHidden = true
        activityIndicator.stopAnimating()

    }

    // didFailProvisionalNavigation
    // == we are offline / page not available
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        // show offline screen
//        offlineView.isHidden = false
//        webViewContainer.isHidden = true
    }


    // restrict navigation to target host, open external links in 3rd party apps
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let requestUrl = navigationAction.request.url {
            if let scheme = requestUrl.scheme {
                print(scheme)
                if (scheme != "http" && scheme != "https") {
                    print("I should Open")
                    decisionHandler(.cancel)
                    if (UIApplication.shared.canOpenURL(requestUrl)) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(requestUrl)
                        } else {
                            // Fallback on earlier versions
                            UIApplication.shared.openURL(requestUrl)
                        }
                    }
                } else {
                    print("I should Allow")
                    decisionHandler(.allow)
                }
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }

}

// WebView additional handlers
extension ViewController: WKUIDelegate {
    // handle links opening in new tabs
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            webView.load(navigationAction.request)
        }
        return nil
    }


//    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//
//        if let requestUrl = navigationResponse.response.url {
//
//            let param = requestUrl.relativeString
//
//            if ( param == "http://v2.aaden.online/login" ) {
//                    print("--------------------------------")
//                    toggleIconBtn.isHidden = false
//                } else {
//                    print("+++++++++++++++++++++++++++++++++")
//                    toggleIconBtn.isHidden = true
//                }
//            print(requestUrl.relativeString as Any)
//
//        }
//
//        decisionHandler(.allow)
//    }
}
