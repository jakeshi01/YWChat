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
    private override init() {}
    let launcheManager = YWLauncheManager.shared
    let loginManager = YWLoginManager.shared
    let conversationManager = YWConversationManager.shared
    
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

    func Launching(with appKey: String,  debugPushCertName: String, releasePushCertName: String = "production") {
        launcheManager.delegate = self
        conversationManager.delegate = self
        launcheManager.Launching(with: appKey, debugPushCertName: debugPushCertName, releasePushCertName: releasePushCertName, successBlock: nil, failedBlock: nil)
    }
}

// MARK: - 登录相关
extension YunWangAdapter {
    
    func login(with userId: String, password: String) {
        loginManager.login(with: launcheManager.imKit, userId: userId, password: password, successBlock: {
            print("登录成功")
        }) { (error) in
            print("登录失败")
        }
    }
    
    func logout() {
        loginManager.logout(with: launcheManager.imKit)
    }
}


// MARK: - 聊天相关
extension YunWangAdapter {
    
    func getConversationController(conversationId: String?, showCustomMessage: Bool = true) -> YWConversationViewController? {
        return conversationManager.getConversationController(with: launcheManager.imKit, conversationId: conversationId, showCustomMessage: showCustomMessage)
    }

    func pushConversationListController(with navigationController: UINavigationController) {
        guard let controller = conversationManager.getConversationListController(with: launcheManager.imKit) else { return }
        controller.didSelectItemBlock = { [weak self] conversation in
            guard let `self` = self,
                let conversationController = self.conversationManager.getConversationController(with: self.launcheManager.imKit, conversationId: conversation?.conversationId) else { return }
            navigationController.pushViewController(conversationController, animated: true)
        }
        navigationController.pushViewController(controller, animated: true)
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

    func sendCustomizeMessage(by conversationId: String, message: BaseMessageModel, summary: String) {
        guard let content = message.toJSONString() else { return }
        conversationManager.sendCustomizeMessage(with: launcheManager.imKit, conversationId: conversationId, content: content, summary: summary)
    }
}

// MARK: - 自定义配置处理
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
}

// MARK: - 自定义消息处理
extension YunWangAdapter: YWConversationManagerDelegate {
    // MARK: - 自定义消息
    func showCustomizeMessage(with data: [String : Any]?) -> Bool {
        guard let data = data, let _ = data[MessageTypeKey] else { return false }
        return true
    }
    func setMessageBubbleView(viewModel: CustomizeMessageViewModel) -> YWBaseBubbleChatView? {
        guard let type = viewModel.messageType, let messageType = CustomizeMessageType(rawValue: type) else { return nil }
        switch messageType {
        case .A:
            return ABubbleChatView(message: viewModel)
        case .B:
            return BBubbleChatView(message: viewModel)
        }
    }
}
