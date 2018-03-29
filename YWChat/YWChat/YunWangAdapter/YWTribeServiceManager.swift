//
//  YWTribeServiceManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/22.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

protocol YWTribeServiceManagerDelegate: class {
    
    func joinTribeAndFetchConversation(isSuccessed: Bool)
    func loadMoreMessage(messages: [IYWMessage], profiles: [String: (avatar: String, name: String)])
    func receivedNewMessage(messages: [IYWMessage], profiles: [String: (avatar: String, name: String)])
    func loadNoMoreMessage()
}

class YWTribeServiceManager {
    
    weak var delegate: YWTribeServiceManagerDelegate?
    private(set) var tribe: YWTribe?
    private let tribeId: String
    private let tribeService: IYWTribeService? = YWLauncheManager.shared.imKit?.imCore.getTribeService()
    private let contactService: YWContactManager = YWContactManager.shared
    private var conversation: YWTribeConversation?
    
    init(tribeId: String) {
        self.tribeId = tribeId
        joinTribe { [weak self] isSuccess in
            guard let `self` = self else { return }
            if !isSuccess {
                self.delegate?.joinTribeAndFetchConversation(isSuccessed: false)
            } else {
                self.getCurrentTribe()
            }
            
        }
        
    }

}

// MARK: - interface
extension YWTribeServiceManager {
    
    func loadMoreMessage() {
        
        guard let currentConversation = conversation else { return }
        let preCount = currentConversation.countOfFetchedObjects
        currentConversation.loadMoreMessages(MessageLimit, completion: { [weak self] existMore in
            
            guard let `self` = self else { return }
            guard existMore else {
                self.delegate?.loadNoMoreMessage()
                return
            }
            
            let newCount = currentConversation.countOfFetchedObjects - preCount
            guard newCount > 0, let messages = currentConversation.fetchedObjects as? [IYWMessage] else {
                self.listenOnNewMessage()
                return
            }
            let loadMessages: [IYWMessage] = messages.prefix(Int(newCount)).sorted(by: { $0.time.timeIntervalSince($1.time) < 0 })
            self.dealMessageWithProfilePromise(messages: loadMessages, isNewMessages: true)
        })
        
    }
    
    func sendTextMessage(content: String, progressBlock: ((CGFloat, String?) -> Void)?, errorBlock: ((Error?, String?) -> Void)?) {
        guard let currentConversation = conversation, let body = YWMessageBodyText(messageText: content) else { return }
        currentConversation.asyncSend(body, progress: { (progress, messageId) in
            progressBlock?(progress, messageId)
        }) { (error, messageId) in
            errorBlock?(error, messageId)
        }
    }
}

private extension YWTribeServiceManager {
    
    func joinTribe(completion:((_ isSuccess: Bool) -> Void)?){
        
        tribeService?.joinTribe(tribeId, completion: { (tribeId, error) in
            if let error = error as NSError?, error.code == YWTribeErrorCode.memberDumplicated.rawValue {
                completion?(true)
            } else if error == nil {
                completion?(true)
            } else {
                completion?(false)
            }
        })
        
    }
    
    func getCurrentTribe() {
        
        tribeService?.requestTribe(fromServer: tribeId, completion: { [weak self] (tribe, _) in
            guard let `self` = self else { return }
            self.tribe = tribe
            self.disableTribeMessagePush()
            self.getCurrentConversationAndLoadMessage()
        })
    }
    
    func disableTribeMessagePush() {
        YWLauncheManager.shared.imKit?.imCore.getSettingService().asyncSetMessageReceive(.receiveButNoAlert, for: tribe, completion: nil)
    }
    
    func getCurrentConversationAndLoadMessage() {
        
        guard let imkit = YWLauncheManager.shared.imKit else {
            self.delegate?.joinTribeAndFetchConversation(isSuccessed: false)
            return
        }
        conversation = YWTribeConversation.fetch(by: tribe, createIfNotExist: true, baseContext: imkit.imCore)
        
        guard let currentConversation = conversation else {
            self.delegate?.joinTribeAndFetchConversation(isSuccessed: false)
            return
        }
        self.delegate?.joinTribeAndFetchConversation(isSuccessed: true)
        
        let preCount = currentConversation.countOfFetchedObjects
        currentConversation.loadMoreMessages(MessageLimit, completion: { [weak self] existMore in
            
            guard let `self` = self else { return }
            guard existMore else {
                self.delegate?.loadNoMoreMessage()
                return
            }
            
            let newCount = currentConversation.countOfFetchedObjects - preCount
            guard newCount > 0, let messages = currentConversation.fetchedObjects as? [IYWMessage] else {
                self.listenOnNewMessage()
                return
            }
            let loadMessages: [IYWMessage] = messages.prefix(Int(newCount)).sorted(by: { $0.time.timeIntervalSince($1.time) < 0 })
            self.dealMessageWithProfilePromise(messages: loadMessages, isNewMessages: true)
        })
          
    }
    
    func listenOnNewMessage() {
        
        conversation?.setOnNewMessageBlockV2({ [weak self] (messages, _) in
            
            guard let `self` = self, let messages = messages as? [IYWMessage] else { return }
            self.dealMessageWithProfilePromise(messages: messages, isNewMessages: true)
            
        })
        
    }
    
    func dealMessageWithProfilePromise(messages: [IYWMessage], isNewMessages: Bool) {
    
        guard let tribe = self.tribe else {
            return
        }
        let persons: [YWPerson] = messages.flatMap({$0.messageFromPerson})
        
        contactService.loadProfiles(for: persons, tribe: tribe) { [weak self] profiles in
            guard let `self` = self else { return }
            var items: [String: (avatar: String, name: String)] = [:]
            profiles?.forEach({ profile in
                items[profile.person.personId] = (avatar: profile.avatarUrl, name: profile.displayName)
            })
            if isNewMessages {
                self.delegate?.receivedNewMessage(messages: messages, profiles: items)
            } else {
                self.delegate?.loadMoreMessage(messages: messages, profiles: items)
                self.listenOnNewMessage()
            }
        }
        
    }

}

