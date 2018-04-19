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
        func load(messages: [IYWMessage], profiles: [String: (avatar: String, name: String)])
        func received(message:IYWMessage, disPlayName: String?)
        func loadNoMoreMessage()
        func someoneDidJoin(userName: String?)
    }
    
    extension YWTribeServiceManagerDelegate {
        
        func joinTribeAndFetchConversation(isSuccessed: Bool) {}
        func load(messages: [IYWMessage], profiles: [String: (avatar: String, name: String)]) {}
        func received(message:IYWMessage, disPlayName: String?) {}
        func loadNoMoreMessage() {}
        func someoneDidJoin(userName: String?) {}
        
    }
    
    
    
    class YWTribeServiceManager: CustomStringConvertible {
        
        weak var delegate: YWTribeServiceManagerDelegate?
        private(set) var tribe: YWTribe?
        private let tribeId: String
        private let tribeService: IYWTribeService? = YWLauncheManager.shared.imKit?.imCore.getTribeService()
        private let contactService: YWContactManager = YWContactManager.shared
        private var conversation: YWTribeConversation?
        
        var description: String {
            return "tribeId = \(tribeId)"
        }
        
        init(tribeId: String, shouldLoadHistory: Bool) {
            self.tribeId = tribeId
            joinTribe { [weak self] isSuccess in
                guard let `self` = self else { return }
                if !isSuccess {
                    self.delegate?.joinTribeAndFetchConversation(isSuccessed: false)
                } else {
                    self.getCurrentTribe(shouldLoadHistory: shouldLoadHistory)
                    self.listenToMemberJoin()
                }
                
            }
            
        }
        
        deinit {
            
            tribeService?.removeMemberDidJoinBlock(forKey: description)
            tribeService?.exit(fromTribe: tribeId, completion: nil)
        }
        
    }
    
    // MARK: - interface]
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
                self.loadMessages(with: loadMessages)
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
        
        func sendCustomizeMessage(message: String) {
            
            guard let currentConversation = conversation else { return }
            
            let customizeBody = YWMessageBodyCustomize(messageCustomizeContent: message, summary: "", isTransparent: true)
            currentConversation.asyncSend(customizeBody, progress: nil, completion: nil)
            
        }
        
        func getPersonDisplayName(_ person: YWPerson, completionBlock:((_ displayName: String?) -> Void)? ) {
            
            guard let ywIMKit = YWLauncheManager.shared.imKit else {
                completionBlock?(nil)
                return
            }
            
            let contactService = ywIMKit.imCore.getContactService()
            
            if let item = contactService?.getProfileFor?(person, with: nil) {
                
                completionBlock?(item.displayName)
                
            } else {
                
                contactService?.asyncGetProfileFromServer?(for: person, with: nil, withProgress: nil, andCompletionBlock: { (isSuccess, item) in
                    completionBlock?(item?.displayName)
                })
                
            }
            
        }
        
        func isTribeMessage(_ message: IYWMessage) -> Bool {
            
            guard let currentConversation = conversation else {
                return false
            }
            
            return currentConversation.conversationId == message.conversationId
            
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
        
        func getCurrentTribe(shouldLoadHistory: Bool) {
            
            if let tribe = YWLauncheManager.shared.imKit?.imCore.getTribeService().fetchTribe(tribeId) {
                
                self.tribe = tribe
                self.disableTribeMessagePush()
                self.getCurrentConversationAndLoadMessage(needLoadMessage: shouldLoadHistory)
                
            } else {
                
                tribeService?.requestTribe(fromServer: tribeId, completion: { [weak self] (tribe, _) in
                    guard let `self` = self else { return }
                    self.tribe = tribe
                    self.disableTribeMessagePush()
                    self.getCurrentConversationAndLoadMessage(needLoadMessage: shouldLoadHistory)
                })
                
            }
            
        }
        
        func disableTribeMessagePush() {
            YWLauncheManager.shared.imKit?.imCore.getSettingService().asyncSetMessageReceive(.receiveButNoAlert, for: tribe, completion: nil)
        }
        
        func getCurrentConversationAndLoadMessage(needLoadMessage: Bool) {
            
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
            
            guard needLoadMessage else { return }
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
                self.loadMessages(with: loadMessages)
            })
            
        }
        
        func listenOnNewMessage() {
            
            conversation?.setOnNewMessageBlockV2({ [weak self] (messages, _) in
                
                guard let `self` = self, let messages = messages as? [IYWMessage] else { return }
                self.loadMessages(with: messages)
                
            })
            
        }
        
        func loadMessages(with messages: [IYWMessage]) {
            
            guard let tribe = self.tribe else {
                return
            }
            let persons: [YWPerson] = messages.compactMap({$0.messageFromPerson})
            
            contactService.loadProfiles(for: persons, tribe: tribe) { [weak self] profiles in
                guard let `self` = self else { return }
                var items: [String: (avatar: String, name: String)] = [:]
                profiles?.forEach({ profile in
                    items[profile.person.personId] = (avatar: profile.avatarUrl, name: profile.displayName)
                })
                self.delegate?.load(messages: messages, profiles: items)
            }
            
        }
        
        func receiveMessage(with message: IYWMessage, completionBlock: ((_ displayName: String?) -> Void)?) {
            
            getPersonDisplayName(message.messageFromPerson) { [weak self] displayName in
                
                guard let  `self` = self else { return }
                self.delegate?.received(message: message, disPlayName: displayName)
                completionBlock?(displayName)
                
            }
            
        }
        
        func listenToMemberJoin() {
            
            YWLauncheManager.shared.imKit?.imCore.getTribeService().addMemberDidJoin({ [weak self] (userInfo) in
                
                guard let `self` = self,
                    let aTribeId = userInfo?[YWTribeServiceKeyTribeId] as? String,
                    aTribeId == self.tribeId,
                    let person = userInfo?[YWTribeServiceKeyPerson] as? YWPerson
                    else { return }
                
                self.getPersonDisplayName(person, completionBlock: { displayName in
                    self.delegate?.someoneDidJoin(userName: displayName)
                })
                
                
                }, forKey: self.description, of: YWBlockPriority.developer)
            
        }
        
    }
    
