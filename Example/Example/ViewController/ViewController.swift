//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/4/25.
//

import UIKit
import JavaScriptCore
import WebKit
import WWHUD
import WWNetworking
import WWEventSource
import WWSimpleAI_Ollama
import WWKeyboardShadowView
import WWExpandableTextView

// MARK: - ViewController
final class ViewController: UIViewController {
        
    @IBOutlet weak var myWebView: WKWebView!
    @IBOutlet weak var connentView: UIView!
    @IBOutlet weak var keyboardConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var keyboardShadowView: WWKeyboardShadowView!
    @IBOutlet weak var expandableTextView: WWExpandableTextView!
    
    private let urlString = "http://localhost:11434/api/generate"
    private let chatModel = "llama3.2"
    
    private var isDismiss = false
    private var responseString: String = ""
    private var aiTimestamp: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        expandableTextView.text = "我想了解iPhone X之後的各代發表日，請以表格表示，語言使用正體中文，謝謝…"
        expandableTextView.updateHeight()
    }
    
    @IBAction func generateLiveDemo(_ sender: UIButton) {
        generateLiveAction()
    }
}

// MARK: - WWEventSource.Delegate
extension ViewController: WWEventSource.Delegate {
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        sseStatusAction(eventSource: eventSource, result: result)
    }
    
    func serverSentEventsRawData(_ eventSource: WWEventSource, result: Result<WWEventSource.RawInformation, any Error>) {
        
        switch result {
        case .failure(let error): print(error)
        case .success(let rawInformation): sseRawString(eventSource: eventSource, rawInformation: rawInformation)
        }
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.EventValue) {
        print(eventValue)
    }
}

// MARK: - WWKeyboardShadowView.Delegate
extension ViewController: WWKeyboardShadowView.Delegate {
    
    func keyboardViewChange(_ view: WWKeyboardShadowView, status: WWKeyboardShadowView.DisplayStatus, information: WWKeyboardShadowView.KeyboardInformation, height: CGFloat) -> Bool {
        return true
    }
    
    func keyboardView(_ view: WWKeyboardShadowView, error: WWKeyboardShadowView.CustomError) {
        print(error)
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 初始化設定
    func initSetting() {
        initKeyboardShadowViewSetting()
        initExpandableTextViewSetting()
        initWebView()
    }
    
    /// 初始化鍵盤高度設定
    func initKeyboardShadowViewSetting() {
        keyboardConstraintHeight.constant = 0
        keyboardShadowView.configure(target: self, keyboardConstraintHeight: keyboardConstraintHeight)
        keyboardShadowView.register()
    }
    
    /// 初始化設定可變高度的TextView (最高3行)
    func initExpandableTextViewSetting() {
        expandableTextView.configure(lines: 3, gap: 21)
        expandableTextView.setting(font: .systemFont(ofSize: 20), textColor: .white, backgroundColor: .white.withAlphaComponent(0.2), borderWidth: 1, borderColor: .white)
    }
    
    /// 初始化WebView
    func initWebView() {
        
        _ = myWebView._loadFile(filename: "index.html")
        
        myWebView.backgroundColor = .clear
        myWebView.scrollView.backgroundColor = .clear
        myWebView.isOpaque = false
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 及時回應 (SSE)
    /// - Parameters:
    ///   - prompt: 提問文字
    func liveGenerate(prompt: String) {
        
        let json = """
        {
          "model": "\(chatModel)",
          "prompt": "\(prompt)",
          "stream": true
        }
        """
        
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .string(json))
    }
    
    /// 問問題 (執行SSE串流)
    func generateLiveAction() {
        
        let text = expandableTextView.text._removeWhitespacesAndNewlines()
        if (text.isEmpty) { return }
        
        generateLiveAction(webView: myWebView, text: text)
    }
    
    /// 顯示HUD
    func displayHUD() {
        WWHUD.shared.display()
    }
    
    /// 取消HUD
    func dismissHUD() {
        WWHUD.shared.dismiss()
    }
}

// MARK: - SSE (Server Sent Events - 單方向串流)
private extension ViewController {
    
    /// SSE狀態處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - result: Result<WWEventSource.Constant.ConnectionStatus, any Error>
    func sseStatusAction(eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        
        switch result {
        case .failure(let error):
            
            DispatchQueue.main.async { [unowned self] in
                dismissHUD()
                isDismiss = true
                responseString = ""
                print(error)
            }
            
        case .success(let status):
            
            switch status {
            case .connecting: isDismiss = false; DispatchQueue.main.async { self.expandableTextView.text = ""; self.expandableTextView.updateHeight() }
            case .open: if !isDismiss { DispatchQueue.main.async { [unowned self] in dismissHUD(); isDismiss = true }}
            case .closed: isDismiss = false; responseString = ""
            }
        }
    }
    
    /// SSE資訊處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - rawInformation: WWEventSource.RawInformation
    func sseRawString(eventSource: WWEventSource, rawInformation: WWEventSource.RawInformation) {
        
        defer {
            DispatchQueue.main.async { [unowned self] in
                refreashWebSlaveCell(with: myWebView, responseString: responseString)
            }
        }
        
        if rawInformation.response.statusCode != 200 {
            responseString = rawInformation.data._string() ?? "\(rawInformation.response.statusCode)"; return
        }
        
        guard let jsonObject = rawInformation.data._jsonObject() as? [String: Any],
              let _response = jsonObject["response"] as? String
        else {
            return
        }
        
        responseString += _response
        print(responseString)
    }
}

// MARK: - SSE for WKWebView (Server Sent Events - 單方向串流)
private extension ViewController {
    
    /// 顯示Markdown文字
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - responseString: String
    func refreashWebSlaveCell(with webView: WKWebView, responseString: String) {
        
        guard let base64Encoded = responseString._base64Encoded(),
              let aiTimestamp = aiTimestamp
        else {
            return
        }
        
        let jsCode = """
            window.displayMarkdown("\(base64Encoded)", \(aiTimestamp))
        """
        
        webView._evaluateJavaScript(script: jsCode) { result in
            
            switch result {
            case .failure(let error): print(error)
            case .success(let value): print(value ?? "")
            }
        }
    }
    
    /// 使用WKWebView去執行SSE問問題
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - text: String
    func generateLiveAction(webView: WKWebView, text: String) {
        
        appendRole(with: webView, role: "user", message: text) { _ in
            
            self.appendRole(with: webView, role: "bot", message: "") { dict in
                
                guard let aiTimestamp = dict["timestamp"] else { return }
                
                self.aiTimestamp = aiTimestamp
                self.liveGenerate(prompt: text)
            }
        }
    }
    
    /// 加上角色Cell
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - role: String
    ///   - message: String
    ///   - result: ([String: Int]) -> Void
    func appendRole(with webView: WKWebView, role: String, message: String = "",  result: @escaping (([String: Int]) -> Void)) {
                
        let jsCode = """
            window.appendRole("\(role)", "\(message)")
        """
        
        webView._evaluateJavaScript(script: jsCode) { _result_ in
            
            switch _result_ {
            case .failure(let error): print(error)
            case .success(let dict):
                guard let dict = dict as? [String: Int] else { return }
                return result(dict)
            }
        }
    }
}
