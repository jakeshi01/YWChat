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

enum ConversationType: Int {
    case p2p = 0      //单聊
    case tribe = 1    //群聊
    case all = 2
}

// MARK: - 聊天相关
class YWConversationManager: NSObject {
    
    //设置单例
    public static let shared = YWConversationManager.init()
    private override init() {}

    var delegate: YWConversationManagerDelegate?
    
}

// MARK: - 会话
extension YWConversationManager {
    
    //获取会话列表
    func getConversationListController(with imKit: YWIMKit?, type: ConversationType) -> YWConversationListViewController? {
        
        guard let imKit = imKit, let controller = imKit.makeConversationListViewController() else { return nil }
        
        switch type {
        case .all:
            controller.heightForRowBlock = { tableView, indexPath, conversation in
                return YWConversationListCellDefaultHeight
            }
        case .p2p:
            controller.heightForRowBlock = { tableView, indexPath, conversation in
                guard let conversation = conversation as? YWP2PConversation else {return 0}
                if !conversation.person.isEHelperPerson() {
                    return YWConversationListCellDefaultHeight
                }
                return 0
            }
        case .tribe :
            controller.heightForRowBlock = { tableView, indexPath, conversation in
                guard let _ = conversation as? YWTribeConversation else {return 0}
                return YWConversationListCellDefaultHeight
            }
        }
        
        return controller
    }
    
    
    //根据会话id获取对应会话
    @discardableResult
    func pushConversationController(in navgationController: UINavigationController, imKit: YWIMKit?, conversation: YWConversation, showCustomMessage: Bool) -> YWConversationViewController? {
        
        let conversationViewController: YWConversationViewController? = navgationController.viewControllers.filter { controller -> Bool in
            
            if controller.isKind(of: YWConversationViewController.self) {
                return (controller as! YWConversationViewController).conversation.conversationId == conversation.conversationId
            }
            return false
            
        }.first as? YWConversationViewController
        
        if let existConversationViewController = conversationViewController {
            
            navgationController.popToViewController(existConversationViewController, animated: true)
            navgationController.setNavigationBarHidden(false, animated: false)
            
            return existConversationViewController
            
        } else {
            
            var realConversation = conversation
            switch conversation.conversationType {
            case .P2P:
                realConversation = YWP2PConversation.fetch(by: (conversation as! YWP2PConversation).person, creatIfNotExist: true, baseContext: imKit?.imCore)
            case .tribe:
                realConversation = YWTribeConversation.fetch(by: (conversation as! YWTribeConversation).tribe, createIfNotExist: true, baseContext: imKit?.imCore)
            case .custom, .unsupported:
                break
            }
            
            guard let newConversationViewController = imKit?.makeConversationViewController(withConversationId: realConversation.conversationId) else { return nil }
            
            YWOCBridge.setConversationViewControllerViewWillApearBlock(newConversationViewController, viewWillAppear: { [weak self] animate in
                guard let `self` = self else { return }
                navgationController.setNavigationBarHidden(false, animated: animate)
                navgationController.pushViewController(newConversationViewController, animated: true)
                if showCustomMessage {
                    self.showCustomMessageInConversationViewController(newConversationViewController)
                }
            })
            
            return newConversationViewController
        }
        
    }
    
    //打开单聊会话
    @discardableResult
    func pushP2PConversationController(in navgationController: UINavigationController, imKit: YWIMKit?, personId: String, showCustomMessage: Bool) -> YWConversationViewController? {
        
        guard let imKit = imKit,
              let person = YWPerson(personId: personId),
              let conversation = YWP2PConversation.fetch(by: person, creatIfNotExist: true, baseContext: imKit.imCore),
              let controller = self.pushConversationController(in: navgationController, imKit: imKit, conversation: conversation, showCustomMessage: showCustomMessage)
        else { return nil }
        return controller
    }
    
    //根据tribeId打开群聊会话
    func getTribeConversationController(with imKit: YWIMKit?, tribeId: String, showCustomMessage: Bool, completionBlock: ((_ tribeController: YWConversationViewController?) -> Void)?) {
        
        guard let imKit = imKit else {
            completionBlock?(nil)
            return
        }

        getTribe(with: tribeId, imKit: imKit) { [weak self] tribe in
            
            guard let `self` = self,
                  let tribe = tribe,
                  let controller = imKit.makeConversationViewController(with: tribe)
            else {
                completionBlock?(nil)
                return
            }
    
            if showCustomMessage {
                self.showCustomMessageInConversationViewController(controller)
            }
            completionBlock?(controller)
        }
        
    }

    
}

// MARK: - 消息
extension YWConversationManager {

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

private extension YWConversationManager {
    
    func getTribe(with tribeId: String, imKit: YWIMKit, completionBlock: ((_ tribe: YWTribe?) -> Void)?) {
        
        let tribe: YWTribe? = imKit.imCore.getTribeService().fetchTribe(tribeId)
        
        guard let _ = tribe else {
            imKit.imCore.getTribeService().requestTribe(fromServer: tribeId, completion: { (tribe, _) in
                completionBlock?(tribe)
            })
            return
        }
        
        completionBlock?(tribe)
    }
    
}
