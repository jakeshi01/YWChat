//
//  YWChat.swift
//  YWChat
//
//  Created by Jake on 2018/3/27.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let YWConnectionStatusChanged = Notification.Name(rawValue: "YWConnectionStatusChanged")
    static let YWUnreadChanged = Notification.Name(rawValue: "YWUnreadChanged")
}

protocol ReceiveMessageDelegate: class {
    func receiveMessage(message: IYWMessage)
}

class YWChat: NSObject {
    
    public static let shared = YWChat.init()
    private override init() {}
    
    private let launcheManager = YWLauncheManager.shared
    private let conversationManager = YWConversationManager.shared
    private var receiveMessageDelegateList = NSMutableArray()
    
    // MARK: - 常用属性值
    var connectionStatus: YWIMConnectionStatus {
        return launcheManager.lastConnectionStatus
    }
    
    var unReadCount: Int {
        return launcheManager.unReadCount
    }
    
    var statusName: String {
        switch connectionStatus {
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
    
}

// MARK: - 初始化、登录相关
extension YWChat {
    
    func setup(with appKey: String,
               debugPushCertName: String,
               releasePushCertName: String = "production",
               successBlock: (() -> Void)?,
               failedBlock: ((_ error: YWError?) -> Void)?)
    {
        launcheManager.delegate = self
        conversationManager.delegate = self
        launcheManager.Launching(with: appKey, debugPushCertName: debugPushCertName, releasePushCertName: releasePushCertName, successBlock:successBlock, failedBlock: failedBlock)
        
    }
    
    func login(with userId: String,
               password: String,
               successBlock: (() -> Void)?,
               failedBlock: ((_ error: YWError?) -> Void)?)
    {
        YWLoginManager.shared.login(with: launcheManager.imKit, userId: userId, password: password, successBlock: successBlock, failedBlock: failedBlock)
    }
    
    func logout() {
        YWLoginManager.shared.logout(with: launcheManager.imKit)
    }
    
}

// MARK: - 聊天相关
extension YWChat {
    
    //获取会话列表
    func getConversationListController(type: ConversationType, didSelectedConversationBlock: ((_  conversation: YWConversation?) -> Void)? = nil) -> YWConversationListViewController? {
        
        return conversationManager.getConversationListController(with: launcheManager.imKit, type: type, didSelectedConversationBlock: didSelectedConversationBlock)
        
    }
    
    //根据会话id获取对应会话
    @discardableResult
    func pushConversationController(in navgationController: UINavigationController, conversation: YWConversation, showCustomMessage: Bool) -> YWConversationViewController? {
        
        return conversationManager.pushConversationController(in: navgationController, imKit: launcheManager.imKit, conversation: conversation, showCustomMessage: showCustomMessage)
    }
    
    //打开单聊会话
    @discardableResult
    func pushP2PConversationController(in navgationController: UINavigationController, personId: String, showCustomMessage: Bool) -> YWConversationViewController? {
        
        return conversationManager.pushP2PConversationController(in: navgationController, imKit: launcheManager.imKit, personId: personId, showCustomMessage: showCustomMessage)
        
    }
    
    //根据tribeId打开群聊会话
    func getTribeConversationController(with tribeId: String, showCustomMessage: Bool, completionBlock: ((_ tribeController: YWConversationViewController?) -> Void)?) {
        
        conversationManager.getTribeConversationController(with: launcheManager.imKit, tribeId: tribeId, showCustomMessage: showCustomMessage, completionBlock: completionBlock)
    }
    
    func sendMessage(by conversationId: String, content: String) {
        conversationManager.sendMessage(with: launcheManager.imKit, conversationId: conversationId, content: content, progressBlock: { (progress, messageId) in
            print("进度:\(progress)")
        }) { (error, messageId) in
            if error == nil {
                print("发送成功")
            } else {
                print("发送失败")
            }
        }
    }
    
    func sendCustomizeMessage(by conversationId: String, message: [String: Any], summary: String) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: JSONSerialization.WritingOptions.init(rawValue: 0))
            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
                conversationManager.sendCustomizeMessage(with: launcheManager.imKit, conversationId: conversationId, content: JSONString, summary: summary)
            }
        } catch { }
    }
    
}

// MARK: - 方法
extension YWChat {
    
    func conversationUnread(by conversationId: String) -> Int {
        return launcheManager.conversationUnread(by: conversationId)
    }
    
}

// MARK: - 消息监听
extension YWChat {
    
    /// 监听接受消息，默认监听所有，可传conversationId限定监听范围
    open func listenReceiveMessage(delegete: ReceiveMessageDelegate) {
        receiveMessageDelegateList.add(delegete)
    }
    
    open func removeListen(delegete: ReceiveMessageDelegate) {
        receiveMessageDelegateList.remove(delegete)
    }
    
    private func distributeReceiveMessage(message: IYWMessage) {
        for delegate in receiveMessageDelegateList {
            (delegate as? ReceiveMessageDelegate)?.receiveMessage(message: message)
        }
    }
    
}

// MARK: - 自定义配置处理
extension YWChat: YWLauncheManagerDelegate {
    
    func connectionStatusChanged(status: YWIMConnectionStatus, error: Error?) {
        NotificationCenter.default.post(name: .YWConnectionStatusChanged, object: self, userInfo: ["status": status])
        // TODO: App自定义处理
        if (status == .forceLogout) || (status == .manualLogout) || (status == .autoConnectFailed) {
            // 手动登出、被踢、自动连接失败，都退出到登录页面
            print("退出登录")
        } else if status == .connected {
            print("需要监听消息")
        }
    }
    
    func conversationTotalUnreadChanged(unRead: Int) {
        NotificationCenter.default.post(name: .YWUnreadChanged, object: self, userInfo: ["count": unRead])
    }
    
    func openURL(urlString: String?, parentController: UIViewController?) {
        print("点击\(urlString ?? "")")
    }
    
    func receive(messages: Array<Any>?, isOffLine: Bool) {
        // 可以在此处根据需要播放提示音
        messages?.forEach({ (message) in
            if isOffLine {
                print("离线消息")
            } else {
                print("在线消息")
            }
            if let message = message as? IYWMessage {
                distributeReceiveMessage(message: message)
            }
        })
    }
    
    //    func fetchProfile(for eServicePerson: YWPerson?) -> YWProfileItem {
    //
    //    }
}

// MARK: - 自定义消息处理
extension YWChat: YWConversationManagerDelegate {
    
    // MARK: - 自定义消息
    func setBubbleViewModel(message: IYWMessage?) -> YWBaseBubbleViewModel? {
        return nil
    }
    
    func setMessageBubbleView(message: YWBaseBubbleViewModel?) -> YWBaseBubbleChatView? {
        return nil
    }
}

