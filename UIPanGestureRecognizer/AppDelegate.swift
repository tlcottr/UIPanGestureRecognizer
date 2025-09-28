//
//  AppDelegate.swift
//  PanPlayground
//
//  Created by Taylor Cottrell on 9/27/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Create a config named "Default" and attach our SceneDelegate explicitly
    let config = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    config.storyboard = nil   // ensure it's storyboard-free
    return config
  }
}
