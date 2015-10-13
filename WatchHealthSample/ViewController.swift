//
//  ViewController.swift
//  WatchHealthSample
//
//  Created by akio0911 on 2015/10/11.
//  Copyright © 2015年 akio0911. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    let kiloGramUnit: HKUnit = HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)
    
    let healthStore = HKHealthStore()
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Configure interface objects here.
        
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
                    self.executeQuery()
                default:
                    fatalError("success and error are invalid.")
                }
            }
        case .SharingAuthorized:
            self.executeQuery()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    typealias FindHealthValueCompletion = (HKSampleQuery, [HKSample]?, NSError?) -> Void
    
    func makeSampleQuery(type type: HKQuantityType, completion: FindHealthValueCompletion) -> HKSampleQuery {
        guard let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            fatalError("bodyMassTypeが作成できない")
        }
        let endKey = HKSampleSortIdentifierEndDate
        let endDate = NSSortDescriptor(key: endKey, ascending: false)
        
        return HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [endDate], resultsHandler: completion)
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
                    self.label.text = "Count : \(btResults.count)"
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

