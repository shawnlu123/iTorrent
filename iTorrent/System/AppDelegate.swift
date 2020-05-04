//
//  AppDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit
import UserNotifications

import Firebase
import GoogleMobileAds

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    static var backgrounded = false
    var openedByFile = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        MSAppCenter.start("381c5088-264f-4ea2-b145-498a2ce15a06", withServices: [
            MSAnalytics.self,
            MSCrashes.self
        ])
        
        PatreonAPI.configure()
        
        DispatchQueue.global(qos: .utility).async {
            sleep(1)
            if !self.openedByFile {
                FullscreenAd.shared.load()
            }
        }

        Core.configure()

        if #available(iOS 13.0, *) {
            Themes.shared.currentUserTheme = window?.traitCollection.userInterfaceStyle.rawValue
        }

        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
            splitViewController.preferredDisplayMode = .allVisible
        }

        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                print("Granted: " + String(granted))
            }
            center.removeAllDeliveredNotifications()
            center.delegate = self
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
            UIApplication.shared.cancelAllLocalNotifications()
        }

        if UserPreferences.ftpKey {
            Core.shared.startFileSharing()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Path: " + url.path)
        if url.absoluteString.hasPrefix("magnet:") {
            Core.shared.addMagnet(url.absoluteString)
        } else {
            openedByFile = true
            Core.shared.addTorrentFromFile(url)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        Core.shared.saveTorrents(filesStatesOnly: BackgroundTask.startBackground())
        AppDelegate.backgrounded = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } else {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        BackgroundTask.stopBackgroundTask()
        TorrentSdk.resumeToApp()
        AppDelegate.backgrounded = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Core.shared.saveTorrents()
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        let primaryNav = primaryViewController as? UINavigationController
        let secondNav = secondaryViewController as? UINavigationController
        if secondNav != nil {
            var viewControllers: [UIViewController] = []
            viewControllers += (primaryNav?.viewControllers)!
            viewControllers += (secondNav?.viewControllers)!
            primaryNav?.viewControllers = viewControllers
            primaryNav?.isToolbarHidden = false
        }
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let nav = primaryViewController as? UINavigationController {
            if nav.topViewController is PreferencesController ||
                nav.topViewController is SettingsSortingController ||
                nav.topViewController is PreferencesWebDavController ||
                nav.topViewController is PatreonViewController {
                return Utils.createEmptyViewController()
            }
        }

        let controllers = splitViewController.viewControllers
        if let navController = controllers[controllers.count - 1] as? UINavigationController {
            var viewControllers: [UIViewController] = []
            while !(navController.topViewController is TorrentListController),
                !(navController.topViewController is PreferencesController) {
                let view = navController.topViewController
                navController.popViewController(animated: false)
                viewControllers.append(view!)
            }
            viewControllers.reverse()

            if viewControllers.count == 0 {
                return Utils.createEmptyViewController()
            }

            let theme = Themes.current

            let detailNavController = splitViewController.storyboard?.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            detailNavController.viewControllers = viewControllers
            detailNavController.setToolbarHidden(false, animated: false)
            detailNavController.navigationBar.barStyle = theme.barStyle
            detailNavController.toolbar.barStyle = theme.barStyle
            detailNavController.navigationBar.tintColor = navController.navigationBar.tintColor
            detailNavController.toolbar.tintColor = navController.navigationBar.tintColor

            return detailNavController
        }
        return nil
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let hash = response.notification.request.content.userInfo["hash"] as? String {
            if Core.shared.state != .InProgress {
                DispatchQueue.global(qos: .background).async {
                    while Core.shared.state != .InProgress {
                        sleep(1)
                    }
                    DispatchQueue.main.async {
                        self.openTorrentDetailsViewController(withHash: hash, sender: self)
                    }
                }
            } else {
                openTorrentDetailsViewController(withHash: hash, sender: self)
            }
        }
        completionHandler()
    }

    func openTorrentDetailsViewController(withHash hash: String, sender: Any) {
        if let splitViewController = UIApplication.shared.keyWindow?.rootViewController as? UISplitViewController,
            let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Detail") as? TorrentDetailsController {
            viewController.managerHash = hash
            if !splitViewController.isCollapsed {
                if splitViewController.viewControllers.count > 1,
                    let nvc = splitViewController.viewControllers[1] as? UINavigationController {
                    nvc.show(viewController, sender: sender)
                } else {
                    let navController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                    navController.viewControllers.append(viewController)
                    navController.isToolbarHidden = false
                    splitViewController.showDetailViewController(navController, sender: sender)
                }
            } else {
                splitViewController.showDetailViewController(viewController, sender: sender)
            }
        }
    }
}
