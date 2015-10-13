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
import WatchConnectivity

class ComplicationController: NSObject, CLKComplicationDataSource {
    
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
                    
                    guard let weight = dic["KiloGram"] as? NSNumber else {
                        handler(nil)
                        return
                    }
                    
                    print("weight = \(weight)")
                    print("weight.dynamicType = \(weight.dynamicType)")
                    
                    self.settingComplication(complication, weight: weight.doubleValue, withHandler: handler)
                },
                errorHandler: { (error:NSError) -> Void in
                    print("Watch : error : \(error.localizedDescription)")
                }
            )
        }

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
}

extension ComplicationController : WCSessionDelegate {
    
}
