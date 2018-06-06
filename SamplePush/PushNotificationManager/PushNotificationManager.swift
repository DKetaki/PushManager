//
//  PushNotificationClass.swift
//  SamplePush
//
//  Created by Ketaki Damale on 18/04/18.
//  Copyright © 2018 Ketaki Damale. All rights reserved.
//

import UIKit
import UserNotifications

//MARK: Push Notification Manager
class PushManager:NSObject
{
    //:Class Variable Declaration:
    public var token:String? = nil
    public var isGranted:Bool = false
    static let shared = PushManager()
    var objRegisterCompletion : registerCompletion!
    var objReceiveCompletion : receiveCompletion!
    
    private override init() { }
    //:Typlealias
    typealias registerCompletion = (_ result: String?, _ error: Error? , _ isgranted: Bool?) -> Void
    typealias receiveCompletion = ([AnyHashable : Any]) -> Void
    
    //:init overloading:
    func setPushNotification(application: UIApplication,block:@escaping registerCompletion)
    {
        if #available(iOS 10, *)
        {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            { (granted, error) in
                guard error == nil else
                {
                   //:Delgate call:
                    DispatchQueue.main.async
                    {
                      //  self.delegate?.applicationdidDeniedPermission(application)
                        block(nil,error,false)
                    }
                    return
                }
                self.isGranted = granted
                if granted
                {
                    //:Application register for Push Notification:
                    DispatchQueue.main.async
                    {
                        application.registerForRemoteNotifications()
                         self.objRegisterCompletion = block
                    }
                }
                else
                {
                  //:Delgate call:
                    DispatchQueue.main.async
                    {
                       // self.delegate?.applicationdidDeniedPermission(application)
                        block(nil,nil,false)
                    }
                    return
                }
            }
        }
        else
        {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
             self.objRegisterCompletion = block
        }
       
    }
    func subscribe(completion:@escaping receiveCompletion)
    {
        self.objReceiveCompletion = completion
    }

}
extension PushManager
{
    func ApplicationDidRegisterWithdeviceToken(_ application:UIApplication,deviceToken:Data)
    {
        token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
         self.objRegisterCompletion(token!,nil,true)
    }
    func ApplicationdidFailedForRemoteNotification(_ application: UIApplication, error: Error)
    {
        self.objRegisterCompletion(nil,error,false)
    }
    func ApplicationReceivedRemoteNotification(_ application: UIApplication?,data: [AnyHashable : Any])
    {
        self.objReceiveCompletion(data)
    }
    
}
extension AppDelegate
{
    //Degelate call
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        PushManager.shared.ApplicationDidRegisterWithdeviceToken(application, deviceToken: deviceToken)
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        PushManager.shared.ApplicationdidFailedForRemoteNotification(application, error: error)
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any])
    {
        PushManager.shared.ApplicationReceivedRemoteNotification(application,data: data)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void)
    {
        PushManager.shared.ApplicationReceivedRemoteNotification(nil,data: notification.request.content.userInfo)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        PushManager.shared.ApplicationReceivedRemoteNotification(nil,data: response.notification.request.content.userInfo)
    }
}

