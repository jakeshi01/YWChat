//
//  YWLauncheManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/1.
//  Copyright © 2018年 Jake. All rights reserved.
//

extension Notification.Name {
    static let YWConnectionStatusChanged = Notification.Name(rawValue: "ConnectionStatusChanged")
    static let YWUnreadChanged = Notification.Name(rawValue: "UnreadChanged")
}

@objc class YWLauncheManager: NSObject {
    
    public static let shared = YWLauncheManager.init()
    private(set) var lastConnectionStatus: YWIMConnectionStatus = .disconnected
    private override init() {}
    
    var imKit: YWIMKit?
    
    var unReadCount: Int {
        guard let imKit = imKit else { return 0 }
        return Int(imKit.imCore.getConversationService().countOfUnreadMessages)
    }
    
    var statusName: String {
        switch lastConnectionStatus {
        case .autoConnectFailed:
            return "自动连接失败"
        case .connected:
            return "连接成功"
        case .connecting:
            return "连接中"
        case .disconnected:
            return "断开连接"
        case .forceLogout:
            return "被踢"
        case .manualDisconnected:
            return "主动断开连接"
        case .manualLogined:
            return "主动登录成功"
        case .manualLogout:
            return "主动登出"
        case .reconnected:
            return "重连成功"
        }
    }
    
    var conversationListController: YWConversationListViewController? {
        guard let imKit = imKit else { return nil }
        return imKit.makeConversationListViewController()
    }
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
            
            listenConnectionStatus()
            listenUnreadChanged()
            setAudioCategory()
            setEServiceProfile()
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
    
    /// 监听连接状态
    func listenConnectionStatus() {
        guard let imKit = imKit else { return }
        imKit.imCore.getLoginService().addConnectionStatusChangedBlock({ [weak self] (status, error) in
            guard let `self` = self else { return }
            self.lastConnectionStatus = status
            NotificationCenter.default.post(name: .YWConnectionStatusChanged, object: self, userInfo: ["status": status])
            if (status == .forceLogout) || (status == .manualLogout) || (status == .autoConnectFailed) {
                // 手动登出、被踢、自动连接失败，都退出到登录页面
                print("退出登录")
            } else if status == .connected {
                print("需要监听消息")
            }
            }, forKey: description, of: .developer)
    }
    
    /// 监听未读数
    func listenUnreadChanged() {
        guard let imKit = imKit else { return }
        imKit.imCore.getConversationService().addConversationTotalUnreadChangedBlock({ (unRead) in
            NotificationCenter.default.post(name: .YWUnreadChanged, object: self, userInfo: ["count": unRead])
        }, forKey: description, of: .developer)
    }
    
    /// 设置语音播放模式
    func setAudioCategory() {
        guard let imKit = imKit else { return }
        imKit.audioSessionCategory = AVAudioSessionCategoryPlayback
    }
    
    /// 设置客服头像和昵称
    func setEServiceProfile() {
        guard let imKit = imKit else { return }
        imKit.fetchProfileForEServiceBlock = { person, progressBlock, completionBlock in
            let item: YWProfileItem = YWProfileItem()
            item.person = person
            item.displayName = person?.personId
            item.avatar = #imageLiteral(resourceName: "meijiabang_icon")
            completionBlock?(true, item)
        }
    }

}

// MARK: - 登录相关
extension YWLauncheManager {

    func login(with userId: String, password: String, successBlock: (() -> Void)?, failedBlock: ((_ error: Error?) -> Void)?) {
        guard let imKit = imKit else {
            failedBlock?(nil)
            return
        }
        YWOCBridge.login(with: imKit, userId: userId, password: password, successBlock: {
            successBlock?()
        }) { (error) in
            failedBlock?(error)
        }
    }
    
    func logout() {
        guard let imKit = imKit else { return }
        imKit.imCore.getLoginService().asyncLogout(completionBlock: nil)
    }

}

