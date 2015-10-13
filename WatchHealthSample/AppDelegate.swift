//
//  AppDelegate.swift
//  WatchHealthSample
//
//  Created by akio0911 on 2015/10/11.
//  Copyright © 2015年 akio0911. All rights reserved.
//

import UIKit
import WatchConnectivity
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let healthStore = HKHealthStore()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
        
        return true
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

extension AppDelegate : WCSessionDelegate {
    typealias ReplyHandler = ([String : AnyObject]) -> Void
    
    var kiloGramUnit: HKUnit {
        return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ReplyHandler) {
        print("didReceiveMessage")
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            print("not available")
            return
        }
        print("available")
        
        guard let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            print("Failed to create HKObjectType")
            return
        }
        
        switch healthStore.authorizationStatusForType(bodyMassType) {
        case .NotDetermined, .SharingDenied:
            let types = Set([bodyMassType])
            healthStore.requestAuthorizationToShareTypes(nil, readTypes: types){ success, error in
                
                switch (success, error) {
                case (false, let err?):
                    print(err.description)
                case (true , _):
                    print("取得可能")
                    self.executeQuery(replyHandler)
                default:
                    fatalError("success and error are invalid.")
                }
            }
        case .SharingAuthorized:
            self.executeQuery(replyHandler)
        }
    }
    
    typealias FindHealthValueCompletion = (HKSampleQuery, [HKSample]?, NSError?) -> Void
    
    func makeSampleQuery(type type: HKQuantityType, completion: FindHealthValueCompletion) -> HKSampleQuery {
        guard let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            fatalError("bodyMassTypeが作成できない")
        }
        let endKey = HKSampleSortIdentifierEndDate
        let endDate = NSSortDescriptor(key: endKey, ascending: false)
        
        return HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 7, sortDescriptors: [endDate], resultsHandler: completion)
    }
    
    func executeQuery(replyHandler : ReplyHandler) {
        guard let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            return
        }
        
        let findAllQuery = makeSampleQuery(type: bodyMassType){
            query, responseObj, error in
            
            switch (responseObj, error) {
            case (_, let err?):
                print(err.description)
            case (let samples?, nil):
                print("samples : \(samples)")
                
                guard let quantitySamples = samples as? [HKQuantitySample] else
                {
                    break
                }
                
                let btResults : [(weight:Double, date:NSDate)] = quantitySamples.map { sample in
                    return (
                        sample.quantity.doubleValueForUnit(self.kiloGramUnit),
                        sample.endDate
                    )
                }
                
                print("btResults : \(btResults)")
                
                btResults.forEach{ result in
                    print(
                        result.weight,
                        result.date.descriptionWithLocale(nil),
                        result.date.descriptionWithLocale(NSLocale.currentLocale()),
                        separator: " , ")
                }
                
                let reply : [String : AnyObject]
                if let quantitySample = quantitySamples.first {
                    reply = ["KiloGram" : quantitySample.quantity.doubleValueForUnit(self.kiloGramUnit)]
                }else{
                    reply = ["Status":"Error"]
                }
                replyHandler(reply)
                
            default:
                fatalError("responseObj and error are invalid.")
            }
        }
        
        healthStore.executeQuery(findAllQuery)
    }
}

