//
//  ViewController.swift
//  YWChat
//
//  Created by Jake on 2018/2/27.
//  Copyright © 2018年 Jake. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var unReadItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusChange(notification:)), name: .YWConnectionStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unReadChange(notification:)), name: .YWUnreadChanged, object: nil)
        title = YWLauncheManager.shared.statusName
        unReadItem.title = "\(YWLauncheManager.shared.unReadCount)未读"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - 登录相关
    @IBAction func login(_ sender: UIButton) {
        YWLauncheManager.shared.login(with: "visitor870", password: "taobao1234", successBlock: {
            print("成功")
        }) { (error) in
            print("失败")
        }
    }
    
    @IBAction func logout(_ sender: UIButton) {
        YWLauncheManager.shared.logout()
    }
    
    // MARK: - 聊天相关
    @IBAction func conversationList(_ sender: UIButton) {
        guard let conversationListController = YWLauncheManager.shared.getConversationListController(with: navigationController) else {
            print("未初始化")
            return
        }
        navigationController?.pushViewController(conversationListController, animated: true)
    }
    
    @IBAction func chat(_ sender: UIButton) {
        guard let conversationController = YWLauncheManager.shared.getConversationController(with: "iwangxinvisitor695", showCustomMessage: true) else { return }
        navigationController?.pushViewController(conversationController, animated: true)
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        guard let imKit = YWLauncheManager.shared.imKit,
            let conversation = imKit.imCore.getConversationService().fetchConversation(byConversationId: "iwangxinvisitor695") else { return }
        let body = YWMessageBodyText(messageText: "你好呀！我要删除")
        conversation.asyncSend(body, progress: { (progress, messageId) in
            print("进度:\(progress)")
        }) { (error, messageId) in
            if error == nil {
                print("发送成功")
            } else {
                print("发送失败")
            }
        }
    }
    
    @IBAction func sendCustomizeMessage(_ sender: UIButton) {
        guard let imKit = YWLauncheManager.shared.imKit,
            let conversation = imKit.imCore.getConversationService().fetchConversation(byConversationId: "iwangxinvisitor695") else { return }
        let customizeBody = YWMessageBodyCustomize(messageCustomizeContent: "{\"content\":\"wall\",\"age\":\"22\",\"type\":\"new\"}" , summary: "新的消息")
        conversation.asyncSend(customizeBody, progress: nil, completion: nil)
    }
    
    // MARK: - 测试
    @IBAction func test(_ sender: UIButton) {

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ViewController {
    
    @objc func statusChange(notification: Notification) {
        title = YWLauncheManager.shared.statusName
    }
    
    @objc func unReadChange(notification: Notification) {
        unReadItem.title = "\(YWLauncheManager.shared.unReadCount)未读"
    }

}
