//
//  AppDelegate.swift
//  BlueCarApp
//
//  Created by adnan on 8/16/16.
//  Copyright © 2016 bluemix-mobile-devex. All rights reserved.
//

import UIKit
import BMSCore
import BMSPush
import BMSAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if let contents = NSBundle.mainBundle().pathForResource("BMSConfig", ofType: "plist"), dictionary = NSDictionary(contentsOfFile: contents) {
            let myBMSClient = BMSClient.sharedInstance
myBMSClient.initialize(bluemixRegion: BMSClient.REGION_US_SOUTH)
myBMSClient.defaultRequestTimeout = 10.0  // minutes
            
            // In this code example, Analytics is configured to record lifecycle events.
Analytics.initializeWithAppName(dictionary["appName"] as? String,
                                apiKey: dictionary["analyticsApiKey"] as? String,
                                deviceEvents: DeviceEvent.LIFECYCLE)

// Enable Logger (disabled by default), and set level to ERROR (DEBUG by default)
Logger.logStoreEnabled = true
Logger.logLevelFilter = LogLevel.Error

        }

        let notificationSettings = UIUserNotificationSettings(forTypes: [.Badge, .Alert, .Sound], categories: nil)
UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
UIApplication.sharedApplication().registerForRemoteNotifications()

        
        return true
    }
    
    func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){
        if let contents = NSBundle.mainBundle().pathForResource("BMSConfig", ofType: "plist"), dictionary = NSDictionary(contentsOfFile: contents) {
            let push = BMSPushClient.sharedInstance
            push.initializeWithAppGUID(dictionary["pushAppGuid"] as? String,
                                       clientSecret: dictionary["pushClientSecret"] as? String)

            // developers should put the user's id as the first argument
            push.registerWithDeviceToken(deviceToken, WithUserId: "USER_ID_HERE") { (response, statusCode, error) -> Void in
                if error.isEmpty {
                    print("Response during device registration : \(response)")
                    print("status code during device registration : \(statusCode)")
                } else {
                    print("Error during device registration \(error)")
                    print("Error during device registration \n  - status code: \(statusCode) \n  - Error: \(error) \n")
                }
            }
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        //UserInfo dictionary will contain data sent from the server

        let payLoad = ((((userInfo as NSDictionary).valueForKey("aps") as! NSDictionary).valueForKey("alert") as! NSDictionary).valueForKey("body") as! NSString)
        var userPayload = String();

        let additionalPayload = (userInfo as NSDictionary).valueForKey("payload")
        userPayload = additionalPayload!.description

        print("Recieved Push notifications message: " + (payLoad as String) + ", payload: " + (userPayload as String))
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

