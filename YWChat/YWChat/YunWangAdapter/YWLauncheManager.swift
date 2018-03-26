//
//  YWLauncheManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/1.
//  Copyright © 2018年 Jake. All rights reserved.
//

let MessageTypeKey: String = "messageType"

@objc protocol YWLauncheManagerDelegate {
    
    /// 连接状态改变
    @objc optional func connectionStatusChanged(status: YWIMConnectionStatus, error: Error?)
    /// 未读数改变
    @objc optional func conversationTotalUnreadChanged(unRead: Int)
    /// 聊天中点击URL
    @objc optional func openURL(urlString: String?, parentController: UIViewController?)
    /// 接收信息
    @objc optional func receive(messages: Array<Any>?, isOffLine: Bool)
    /// 配置客服信息
    @objc optional func fetchProfile(for eServicePerson: YWPerson?) -> YWProfileItem
}


@objc class YWLauncheManager: NSObject {
    
    public static let shared = YWLauncheManager.init()
    private(set) var lastConnectionStatus: YWIMConnectionStatus = .disconnected
    private override init() {}
    
    var customizeMessageList: [(type: String, viewModelClass: AnyClass, viewClass: YWBaseBubbleChatView.Type)] = [("类型A", BModel.self, YWBaseBubbleChatView.self)]
    var imKit: YWIMKit?
    var delegate: YWLauncheManagerDelegate?
    
    var unReadCount: Int {
        guard let imKit = imKit else { return 0 }
        return Int(imKit.imCore.getConversationService().countOfUnreadMessages)
    }
}

extension YWLauncheManager {
    
    func Launching(with appKey: String,
                        debugPushCertName: String,
                        releasePushCertName: String = "production",
                        successBlock: (() -> Void)?,
                        failedBlock: ((_ error: YWError?) -> Void)?)
    {
        var retryCount: Int = 0
        
        func retryInitialization() {
            guard retryCount < repeatCount else {
                failedBlock?(YWError.launcheError)
                return
            }
            
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
                listenOnClickUrl()
                listenNewMessage()
                setAudioCategory()
                setEServiceProfile()
                successBlock?()
            } else {
                retryCount += 1
                retryInitialization()
            }
        }
        
        retryInitialization()
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
            self.delegate?.connectionStatusChanged?(status: status, error: error)
        }, forKey: description, of: .developer)
    }
    
    /// 监听未读数
    func listenUnreadChanged() {
        
        guard let imKit = imKit else { return }
        imKit.imCore.getConversationService().addConversationTotalUnreadChangedBlock({ [weak self] (unRead) in
            guard let `self` = self else { return }
            self.delegate?.conversationTotalUnreadChanged?(unRead: Int(unRead))
        }, forKey: description, of: .developer)
    }
    
    /// 监听链接点击事件
    func listenOnClickUrl() {
        
        guard let imKit = imKit else { return }
        imKit.setOpenURLBlock({ [weak self] (urlString, controller) in
            guard let `self` = self else { return }
            self.delegate?.openURL?(urlString: urlString, parentController: controller)
        }, allowedURLTypes: nil)
    }
    
    /// 监听新消息
    func listenNewMessage() {
        
        guard let imKit = imKit else { return }
        imKit.imCore.getConversationService().add(onNewMessageBlockV2: { [weak self] (messages, isOffLine) in
            guard let `self` = self else { return }
            self.delegate?.receive?(messages: messages, isOffLine: isOffLine)
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
            let item = self.delegate?.fetchProfile?(for: person)
            completionBlock?(true, item)
        }
    }

}
