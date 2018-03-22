//
//  YunWangAdapter.swift
//  YWChat
//
//  Created by leona on 2018/3/22.
//  Copyright © 2018年 Jake. All rights reserved.
//

extension Notification.Name {
    static let YWConnectionStatusChanged = Notification.Name(rawValue: "YWConnectionStatusChanged")
    static let YWUnreadChanged = Notification.Name(rawValue: "YWUnreadChanged")
}

class YunWangAdapter: NSObject {
    
    public static let shared = YunWangAdapter.init()
    let manager = YWLauncheManager.shared
    
    // MARK: - 常用属性值
    var connectionStatus: YWIMConnectionStatus {
        return manager.lastConnectionStatus
    }
    var unReadCount: Int {
        return manager.unReadCount
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

    func Launching(with appKey: String,  debugPushCertName: String, releasePushCertName: String = "production") {
        manager.delegate = self
        manager.Launching(with: appKey, debugPushCertName: debugPushCertName, releasePushCertName: releasePushCertName)
    }

//    func send(customizeMessage: CustomizeMessageViewModel, by conversationId: String, summary: String) {
//        guard let imKit = YWLauncheManager.shared.imKit,
//            let conversation = imKit.imCore.getConversationService().fetchConversation(byConversationId: conversationId),
//            let content = customizeMessage.toJSONString() else { return }
//        let customizeBody = YWMessageBodyCustomize(messageCustomizeContent: content, summary: summary)
//        conversation.asyncSend(customizeBody, progress: nil, completion: nil)
//    }
}

// MARK: - 登录相关
extension YunWangAdapter {
    
    func login(with userId: String, password: String) {
        manager.login(with: userId, password: password, successBlock: {
            print("内部处理")
        }) { (error) in
            print("内部处理")
        }
    }
    
    func logout() {
        manager.logout()
    }
}

// MARK: - 自定义处理
extension YunWangAdapter: YWLauncheManagerDelegate {

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
                print(message.messageId)
            }
        })
    }
    
    func fetchProfile(for eServicePerson: YWPerson?) -> YWProfileItem {
        let item: YWProfileItem = YWProfileItem()
        item.person = eServicePerson
        item.displayName = eServicePerson?.personId
        item.avatar = #imageLiteral(resourceName: "meijiabang_icon")
        return item
    }
    

//    func customizeMessage(with type: String) -> CustomizeMessageViewModel.Type {
//        return CustomizeMessageViewModel.self
//    }
//
//    func indexNavigationBarDidClickVoiceButton() {
//
//    }
}


