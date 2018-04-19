//
//  YWLoginManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/25.
//  Copyright © 2018年 Jake. All rights reserved.
//

import Foundation

let YWUidKey: String = "YW_uid"
let YWPasswordKey: String = "YW_password"
let RepeatCount: Int = 3   //失败重试次数
let MessageLimit: UInt = 15  //单页加载聊天消息数

enum YWError: Int, Swift.Error, LocalizedError {
    case launcheError = 60001
    case loginFailure = 60002
    case userAccountError = 60003
    
    var errorDescription: String? {
        switch self {
        case .launcheError:
            return "初始化失败"
        case .loginFailure:
            return "登录失败"
        case .userAccountError:
            return "账户或密码错误"
        }
    }
}

class YWLoginManager: NSObject {
    //设置单例
    public static let shared = YWLoginManager.init()
    private override init() {}
    
    //登录状态查询
    var isLogined: Bool {
        get{
            guard let imKit = YWLauncheManager.shared.imKit else {
                return false
            }
            return imKit.imCore.getLoginService().isCurrentLogined
        }
    }
    
    var ywUid: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: YWUidKey)
            UserDefaults.standard.synchronize()
        }
        get {
            return UserDefaults.standard.string(forKey: YWUidKey)
        }
    }
    
    var ywPassword: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: YWPasswordKey)
            UserDefaults.standard.synchronize()
        }
        get {
            return UserDefaults.standard.string(forKey:YWPasswordKey)
        }
    }
    
}

// MARK: - Interface
extension YWLoginManager {
    
    //云旺用户登录，失败自动尝试，失败3次后抛出失败。账号密码为空直接抛出错误
    func login(with imKit: YWIMKit?,
               userId: String,
               password: String,
               successBlock: (() -> Void)?,
               failedBlock: ((_ error: YWError?) -> Void)?)
    {
        guard userId.count > 0, password.count > 0 else {
            failedBlock?(YWError.userAccountError)
            return
        }
        var retryCount: Int = 0
        func retryLogin() {
            guard retryCount < RepeatCount else {
                failedBlock?(YWError.loginFailure)
                return
            }
            YWOCBridge.login(with: imKit, userId: userId, password: password, successBlock: { [weak self] in
                successBlock?()
                guard let `self` = self else { return }
                self.ywUid = userId
                self.ywPassword = password
            }) { _ in
                retryCount += 1
                retryLogin()
            }
        }
        retryLogin()
    }
    
    func logout(with imKit: YWIMKit?)
    {
        guard let imKit = imKit else { return }
        imKit.imCore.getLoginService().asyncLogout(completionBlock: nil)
    }
    
    func clearYWUserAccount()
    {
        UserDefaults.standard.removeObject(forKey: YWUidKey)
        UserDefaults.standard.removeObject(forKey: YWPasswordKey)
    }
    
}
