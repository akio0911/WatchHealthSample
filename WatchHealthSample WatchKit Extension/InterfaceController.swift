//
//  InterfaceController.swift
//  WatchHealthSample WatchKit Extension
//
//  Created by akio0911 on 2015/10/11.
//  Copyright © 2015年 akio0911. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import ClockKit
import WatchConnectivity

class InterfaceController: WKInterfaceController {

    @IBOutlet var label: WKInterfaceLabel!
    
    let healthStore = HKHealthStore()
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        WKInterfaceDevice.currentDevice().playHaptic(.Success) // FIXME: 後で消す
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            label.setText("not available")
            return
        }
        label.setText("available")
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        for complication in complicationServer.activeComplications {
            complicationServer.reloadTimelineForComplication(complication)
        }
        
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
        
        if WCSession.defaultSession().reachable {
            print("reachable")
            
            let message = ["From":"Watch", "To":"Phone"]
            WCSession.defaultSession().sendMessage(message,
                replyHandler: { (dic:[String : AnyObject]) -> Void in
                    print("Watch : success : dic = \(dic)")
                    self.label.setText("dic = \(dic)")
                },
                errorHandler: { (error:NSError) -> Void in
                    print("Watch : error : \(error.localizedDescription)")
                }
            )
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

extension InterfaceController
{
    var kiloGramUnit: HKUnit {
        return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)
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
    
    func executeQuery() {
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
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.label.setText("\(btResults)")
                })
                
                btResults.forEach{ result in
                    print(
                        result.weight,
                        result.date.descriptionWithLocale(nil),
                        result.date.descriptionWithLocale(NSLocale.currentLocale()),
                        separator: " , ")
                }
            default:
                fatalError("responseObj and error are invalid.")
            }
        }
        
        healthStore.executeQuery(findAllQuery)
    }
}

extension InterfaceController : WCSessionDelegate {
    
}
