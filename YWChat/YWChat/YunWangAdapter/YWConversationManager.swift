//
//  YWConversationManager.swift
//  YWChat
//
//  Created by leona on 2018/3/26.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

protocol YWConversationManagerDelegate {

    func showCustomizeMessage(with data: [String: Any]?) -> Bool
    func setMessageBubbleView(viewModel: CustomizeMessageViewModel) -> YWBaseBubbleChatView?
}



// MARK: - 聊天相关
class YWConversationManager: NSObject {
    
    //设置单例
    public static let shared = YWConversationManager.init()
    private override init() {}

    var delegate: YWConversationManagerDelegate?
    
    func getConversationController(with imKit: YWIMKit?, conversationId: String?, showCustomMessage: Bool = true) -> YWConversationViewController? {
        guard let imKit = imKit,
            let controller = imKit.makeConversationViewController(withConversationId: conversationId) else { return nil }
        if showCustomMessage {
            showCustomMessageInConversationViewController(controller)
        }
        return controller
    }
    
    func getConversationListController(with imKit: YWIMKit?) -> YWConversationListViewController? {
        guard let imKit = imKit, let controller = imKit.makeConversationListViewController() else { return nil }
        return controller
    }
    
    func sendMessage(with imKit: YWIMKit?, conversationId: String, content: String, progressBlock: ((CGFloat, String?) -> Void)?, errorBlock: ((Error?, String?) -> Void)?) {
        guard let imKit = YWLauncheManager.shared.imKit,
            let conversation = imKit.imCore.getConversationService().fetchConversation(byConversationId: conversationId) else { return }
        let body = YWMessageBodyText(messageText: content)
        conversation.asyncSend(body, progress: { (progress, messageId) in
            progressBlock?(progress, messageId)
        }) { (error, messageId) in
            errorBlock?(error, messageId)
        }
    }
    
    func sendCustomizeMessage(with imKit: YWIMKit?, conversationId: String, content: String, summary: String) {
        guard let imKit = YWLauncheManager.shared.imKit,
            let conversation = imKit.imCore.getConversationService().fetchConversation(byConversationId: conversationId) else { return }
        let customizeBody = YWMessageBodyCustomize(messageCustomizeContent: content, summary: summary)
        conversation.asyncSend(customizeBody, progress: nil, completion: nil)
    }
    
    /// 展示自定义消息
    private func showCustomMessageInConversationViewController(_ controller: YWConversationViewController) {
        controller.setHook4BubbleViewModel { [weak self] (message) -> YWBaseBubbleViewModel? in
            guard let showCustomizeMessage = self?.delegate?.showCustomizeMessage, let message = message else { return nil }
            let viewModel = CustomizeMessageViewModel(message: message)
            if showCustomizeMessage(viewModel.content) {
                return viewModel
            } else {
                return nil
            }
        }
        controller.setHook4BubbleView { [weak self] (message) -> YWBaseBubbleChatView? in
            guard let `self` = self, let viewModel = message as? CustomizeMessageViewModel else { return nil }
            return self.delegate?.setMessageBubbleView(viewModel: viewModel)
        }
    }
    
}

