//
//  YWLauncheManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/1.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

@objc class YWLauncheManager: NSObject {
    
    public static let shared = YWLauncheManager.init()
    private override init() {}
    
    var imKit: YWIMKit?
    
}

extension YWLauncheManager {
    
    func Launching(with appKey: String,  debugPushCertName: String, releasePushCertName: String = "production") {
        
        if Initialization(with: appKey) {
            #if DEBUG
                YWAPI.sharedInstance().getGlobalLogService().needCloseDiag = false
                YWAPI.sharedInstance().getGlobalPushService().setXPushCertName(debugPushCertName)
            #else
                YWAPI.sharedInstance().getGlobalLogService().needCloseDiag = true
                YWAPI.sharedInstance().getGlobalPushService().setXPushCertName(releasePushCertName)
            #endif
            YWOCBridge.handleAPNSPush(imKit, description: description)
            setAvatarStyle()
        } else {
            print("初始化失败")
        }
        
    }
    
}

private extension YWLauncheManager {
    
    func Initialization(with appKey: String) -> Bool {

        let error: Int = YWOCBridge.registerAppKey(appKey)
        
        if error != 0 && error == YWSdkInitErrorCode.alreadyInited.rawValue {
            //初始化失败
            return false
        } else if error == 0 {
            // 首次初始化成功, 获取一个IMKit并持有
            imKit = YWAPI.sharedInstance().fetchIMKitForOpenIM()
            YWOCBridge.configImKit(imKit)
        }
        
        return  true
    }
    
    func setAvatarStyle() {
        imKit?.avatarImageViewCornerRadius = 4.0
        imKit?.avatarImageViewContentMode = .scaleAspectFit
    }

}

