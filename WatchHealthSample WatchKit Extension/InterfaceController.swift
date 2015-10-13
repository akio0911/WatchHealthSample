//
//  InterfaceController.swift
//  WatchHealthSample WatchKit Extension
//
//  Created by akio0911 on 2015/10/11.
//  Copyright © 2015年 akio0911. All rights reserved.
//

import WatchKit
import Foundation
import ClockKit
import WatchConnectivity

class InterfaceController: WKInterfaceController {

    @IBOutlet var label: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        WKInterfaceDevice.currentDevice().playHaptic(.Success) // FIXME: 後で消す
        
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

extension InterfaceController : WCSessionDelegate {
    
}
