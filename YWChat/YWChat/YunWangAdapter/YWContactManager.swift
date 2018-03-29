//
//  YWContactManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/22.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

class YWContactManager: NSObject {
    
    public static let shared = YWContactManager.init()
    private override init() {}
    
    private let contactService = YWLauncheManager.shared.imKit?.imCore.getContactService()
    
    func loadProfile(for person: YWPerson, tribe: YWTribe, completionBlock: ((_ profile:YWProfileItem?) -> Void)?) {
        
        guard let sercvice = contactService else {
            completionBlock?(nil)
            return
        }
        
        let profile: YWProfileItem? = sercvice.getProfileFor?(person, with: tribe)
        
        if let _ = profile {
            
            completionBlock?(profile)
       
        } else {
            
            sercvice.asyncGetProfileFromServer?(for: person, with: tribe, withProgress: nil, andCompletionBlock: { (_, profile) in
                completionBlock?(profile)
            })
        }
        
    }
    
    func loadProfiles(for persons: [YWPerson], tribe: YWTribe, completionBlock: ((_ profiles: [YWProfileItem]?) -> Void)?) {
        
        guard let sercvice = contactService else {
            completionBlock?(nil)
            return
        }
        
        let secondsPerDay: TimeInterval = 24*60*60;
        sercvice.getProfileForPersons?(persons, with: tribe, expireInterval: secondsPerDay, withProgress: nil, andCompletionBlock: { (_, profiles) in
            guard let items = profiles as? [YWProfileItem] else {
                completionBlock?(nil)
                return
            }
            completionBlock?(items)
        })
    }
    
}
