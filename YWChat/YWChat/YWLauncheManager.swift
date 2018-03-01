//
//  YWLauncheManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/1.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

class YWLauncheManager: NSObject {
    
    static let shared = YWLauncheManager.init()
    private override init() {}
    
    var imKit: YWIMKit!
    private let appkey: String = "23271397"
    
}

extension YWLauncheManager {
    
    func Launching(with PushCertName: String) {
        try? YWAPI.sharedInstance().syncInit(withOwnAppKey: appkey)
        #if DEBUG
            YWAPI.sharedInstance().getGlobalLogService().needCloseDiag = false
            YWAPI.sharedInstance().getGlobalPushService().setXPushCertName(PushCertName)
        #else
            YWAPI.sharedInstance().getGlobalLogService().needCloseDiag = true
            YWAPI.sharedInstance().getGlobalPushService().setXPushCertName("production")
        #endif
    }
}

