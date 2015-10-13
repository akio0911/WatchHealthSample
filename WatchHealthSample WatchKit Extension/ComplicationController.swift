//
//  ComplicationController.swift
//  WatchHealthSample
//
//  Created by akio0911 on 2015/10/11.
//  Copyright © 2015年 akio0911. All rights reserved.
//

import ClockKit
import HealthKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let healthStore = HKHealthStore()
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.None])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        
        print("getCurrentTimelineEntryForComplication")
        
        WKInterfaceDevice.currentDevice().playHaptic(.Success) // FIXME: 後で消す
        
        // 体重情報の型を生成する
        guard let btType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) else
        {
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
                    self.executeQuery(complication, withHandler: handler)
                default:
                    fatalError("success and error are invalid.")
                }
            }
        case .SharingAuthorized:
            self.executeQuery(complication, withHandler: handler)
        }

    }
    
    // 体重の単位を生成する。単位はkg
    let btUnit: HKUnit = HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)

    func executeQuery(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        print("executeQuery")
        
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
                    return
                }
                
                guard let quantitySample = quantitySamples.first else {
                    return
                }
                
                print("quantitySample.endDate = \(quantitySample.endDate)")
                
                // HealthStoreで使用していた型から体温の値へと復元する
                let btResults : [(weight:Double, date:NSDate)] = quantitySamples.map { sample in
                    return (
                        sample.quantity.doubleValueForUnit(self.btUnit),
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
                
                let weight = quantitySample.quantity.doubleValueForUnit(self.btUnit)
                self.settingComplication(complication, weight: weight, withHandler: handler)
            default:
                fatalError("responseObj and error are invalid.")
            }
        }
        
        healthStore.executeQuery(findAllQuery)
    }
    
    func settingComplication(complication: CLKComplication, weight:Double, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        
        let weightString = NSString(format: "%.1f", weight) as String
        
        print("weightString = \(weightString)")
        
        let template: CLKComplicationTemplate
        switch complication.family {
        case .ModularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallSimpleText()
            modularSmall.textProvider = CLKSimpleTextProvider(text: weightString)
            template = modularSmall
        case .ModularLarge:
            let modularLarge = CLKComplicationTemplateModularLargeTallBody()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: "Weight")
            modularLarge.bodyTextProvider   = CLKSimpleTextProvider(text: "\(weightString)kg")
            template = modularLarge
            
        case .UtilitarianSmall:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: "\(weightString)kg")
            utilitarianSmall.imageProvider = nil
            template = utilitarianSmall
            
        case .UtilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: "Weight : \(weightString)kg")
            utilitarianLarge.imageProvider = nil
            template = utilitarianLarge
            
        case .CircularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallRingText()
            circularSmall.textProvider = CLKSimpleTextProvider(text: weightString)
            circularSmall.fillFraction = 0.7
            circularSmall.ringStyle = CLKComplicationRingStyle.Closed
            template = circularSmall
            
        }
        
        let timelineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
        handler(timelineEntry)
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
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        
        // Update hourly
        handler(NSDate(timeIntervalSinceNow: 60*60))
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        
        switch complication.family {
        case .ModularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: "--")
            handler(template)
        case .ModularLarge:
            let template = CLKComplicationTemplateModularLargeTallBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Weight")
            template.bodyTextProvider   = CLKSimpleTextProvider(text: "--.-kg")
            handler(template)
        case .UtilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: "--.-kg")
            template.imageProvider = nil
            handler(template)
        case .UtilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "Weight : --.-kg")
            template.imageProvider = nil
            handler(template)
        case .CircularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "--")
            template.fillFraction = 0.7
            template.ringStyle = CLKComplicationRingStyle.Closed
            handler(template)
        }
    }
    
    func makeFutureDateWithDay(day:Int) -> NSDate? {
        let cal = NSCalendar.currentCalendar()
        let components = cal.components([.Year, .Month, .Day], fromDate: NSDate())
        components.day += day
        return cal.dateFromComponents(components)
    }
}
