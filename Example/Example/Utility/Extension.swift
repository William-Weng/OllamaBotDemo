//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2025/4/25.
//

import UIKit
import WebKit

// MARK: - Sequence (function)
extension Sequence {
    
    /// Array => JSON Data => Base64String
    /// - Parameters:
    ///   - writingOptions: JSONSerialization.WritingOptions
    ///   - base64EncodingOptions: Data.Base64EncodingOptions
    /// - Returns: String?
    func _base64JSONDataString(writingOptions: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(), base64EncodingOptions: Data.Base64EncodingOptions = []) -> String? {
        return _jsonData(options: writingOptions)?._base64String(options: base64EncodingOptions)
    }
}

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
    
    /// 將轉成Base64的JSONObject轉回來 - "WzEsMiwzXQ==" => [1, 2, 3]
    /// - Parameters:
    ///   - encoding: String.Encoding
    ///   - isLossyConversion: Bool
    ///   - options: JSONSerialization.ReadingOptions
    /// - Returns: T?
    func _base64JSONObjectDecode<T>(using encoding: String.Encoding = .utf8, isLossyConversion: Bool = false, options: JSONSerialization.ReadingOptions = .allowFragments) -> T? {
        
        guard let data = _data(using: encoding, isLossyConversion: isLossyConversion),
              let jsonObject = Data(base64Encoded: data)?._jsonObject(options: options)
        else {
            return nil
        }
        
        return jsonObject as? T
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
