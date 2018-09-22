//
//  AppDelegate.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import Firebase
import SafariServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()

        window?.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        window?.backgroundColor = UIColor.white
        
        if #available(iOS 11, *) {
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        }
        
        // Starting with 1.1 we only use the `keys4` and `strokes2` keyboard layouts
        if UserPreferences.shared.keyboardLayout != .keys4 &&
            UserPreferences.shared.keyboardLayout != .strokes2 &&
            UserPreferences.shared.keyboardLayout != .msr {
            UserPreferences.shared.keyboardLayout = .strokes2
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if !UserDefaults.standard.bool(forKey: Constants.tutorialShownKey) {
            showTutorial()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    private func showTutorial() {
        let alertController = UIAlertController(title: NSLocalizedString("SwipeSpeak Tutorial", comment: ""),
                                                message: NSLocalizedString("Do you want to view a tutorial about how to use the app?\nYou can always view it from the app settings.", comment: ""),
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("Show", comment: ""), style: .default, handler: { (_) in
            UserDefaults.standard.set(true, forKey: Constants.tutorialShownKey)
            self.window?.rootViewController?.present(SFSafariViewController(url: Constants.tutorialURL), animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("Later", comment: ""), style: .default, handler: { (_) in
        }))
        
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (_) in
            UserDefaults.standard.set(true, forKey: Constants.tutorialShownKey)
            self.window?.rootViewController?.present(SFSafariViewController(url: Constants.tutorialURL), animated: true, completion: nil)
        }))
        
        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

}
