//
//  AppDelegate.swift
//  Example
//
//  Created by William.Weng on 2025/4/25.
//

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window?.overrideUserInterfaceStyle = .dark
        return true
    }
}

