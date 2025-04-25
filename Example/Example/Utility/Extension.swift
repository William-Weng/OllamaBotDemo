//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2025/4/25.
//

import UIKit
import WebKit

// MARK: - String (function)
extension String {
    
    /// 去除空白及換行字元
    /// - Returns: Self
    func _removeWhitespacesAndNewlines() -> Self { return trimmingCharacters(in: .whitespacesAndNewlines) }
    
    /// 文字 => Base64文字
    /// => Hello World -> SGVsbG8gV29ybGQ=
    /// - Parameter options: Data.Base64EncodingOptions
    /// - Returns: String?
    func _base64Encoded(options: Data.Base64EncodingOptions = []) -> String? {
        return data(using: .utf8)?._base64String()
    }
}

// MARK: - Data (function)
extension Data {
    
    /// [Data => Base64文字](https://zh.wikipedia.org/zh-tw/Base64)
    /// - Parameter options: Base64EncodingOptions
    /// - Returns: Base64EncodingOptions
    func _base64String(options: Base64EncodingOptions = []) -> String {
        return self.base64EncodedString(options: options)
    }
}

// MARK: - WKWebView
extension WKWebView {
    
    /// 載入本機HTML檔案
    /// - Parameters:
    ///   - filename: HTML檔案名稱
    ///   - bundle: Bundle位置
    ///   - directory: 資料夾位置
    ///   - readAccessURL: 允許讀取的資料夾位置
    /// - Returns: Result<WKNavigation?, Error>
    func _loadFile(filename: String, bundle: Bundle? = nil, inSubDirectory directory: String? = nil, allowingReadAccessTo readAccessURL: URL? = nil) -> WKNavigation? {
        
        guard let url = (bundle ?? .main).url(forResource: filename, withExtension: nil, subdirectory: directory) else { return nil }
        
        let readAccessURL: URL = readAccessURL ?? url.deletingLastPathComponent()
        
        return loadFileURL(url, allowingReadAccessTo: readAccessURL)
    }
    
    /// [執行JavaScript](https://andyu.me/2020/07/17/js-iife/)
    /// - Parameters:
    ///   - script: [JavaScript文字](https://lance.coderbridge.io/2020/08/05/why-use-IIFE/)
    ///   - result: Result<Any?, Error>
    func _evaluateJavaScript(script: String?, result: @escaping (Result<Any?, Error>) -> Void) {
        
        guard let script = script else { return }
        
        evaluateJavaScript(script) { data, error in
            if let error = error { result(.failure(error)); return }
            result(.success(data))
        }
    }
}
