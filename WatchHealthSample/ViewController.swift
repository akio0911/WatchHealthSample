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

    // 体重の単位を生成する。単位はkg
    let btUnit: HKUnit = HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Configure interface objects here.
        
        let healthStore = HKHealthStore()
        
        // 体重情報の型を生成する
        guard let btType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            print("Failed to create HKObjectType")
            return
        }
        
        switch healthStore.authorizationStatusForType(btType) {
        case .NotDetermined, .SharingDenied:
            // 体重型のデータをHealthStoreから取得するために、ユーザーへ許可を求めます。
            // 許可されたデータのみ、アプリケーションからHealthStoreへ読み込みする権限が与えられます。
            // ヘルスケアの[ソース]タブ画面がモーダルで表示されます。
            // 第1引数に指定したNSSet!型のshareTypesの書き込み許可を求めます。
            // 第2引数に指定したNSSet!型のreadTypesの読み込み許可を求めます。
            
            let types = Set([btType])
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
        // 体重情報の型を生成する
        guard let btType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            fatalError("btTypeが作成できない")
        }
        let endKey = HKSampleSortIdentifierEndDate
        let endDate = NSSortDescriptor(key: endKey, ascending: false)
        
        return HKSampleQuery(sampleType: btType, predicate: nil, limit: 1, sortDescriptors: [endDate], resultsHandler: completion)
    }
    
    func executeQuery() {
        guard let btType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
            return
        }
        
        // HealthStoreのデータを全件取得するHKSampleQueryを返却
        let findAllQuery = makeSampleQuery(type: btType){
            query, responseObj, error in
            
            switch (responseObj, error) {
            case (_, let err?):
                print(err.description)
            case (let samples?, nil):
                // 取得した結果がresponseObjに格納されている。
                // アプリで使用する場合、[AnyObject]!型のresponseObjを必要な型にキャストする必要がある
                
                guard let quantitySamples = samples as? [HKQuantitySample] else
                {
                    break
                }
                
                // HealthStoreで使用していた型から体温の値へと復元する
                let btResults : [(weight:Double, date:NSDate)] = quantitySamples.map { sample in
                    return (
                        sample.quantity.doubleValueForUnit(self.btUnit),
                        sample.endDate
                    )
                }
                
                print("btResults : \(btResults)")
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.label.text = "\(btResults)"
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
        
        let healthStore = HKHealthStore()
        
        healthStore.executeQuery(findAllQuery)
    }
}

