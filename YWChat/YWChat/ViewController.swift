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
        title = YWChat.shared.statusName
        unReadItem.title = "\(YWChat.shared.unReadCount)未读"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - 登录相关
    @IBAction func login(_ sender: UIButton) {
        YWChat.shared.login(with: "visitor870", password: "taobao1234", successBlock: nil, failedBlock: nil)
    }
    
    @IBAction func logout(_ sender: UIButton) {
        YWChat.shared.logout()
    }
    
    // MARK: - 聊天相关
    @IBAction func conversationList(_ sender: UIButton) {
        
        guard let navigationController = navigationController else { return }
        let vc = YWChat.shared.getConversationListController(type: .all)
        navigationController.pushViewController(vc!, animated: true)
    }
    
    @IBAction func chat(_ sender: UIButton) {
        guard let imKit = YWLauncheManager.shared.imKit,
            let conversation = YWP2PConversation.fetchConversation(byConversationId: "iwangxinvisitor695", creatIfNotExist: true, baseContext: imKit.imCore),
            let controller = imKit.makeConversationViewController(withConversationId: conversation.conversationId) else { return }
        //        if showCustomMessage {
        //            showCustomMessageInConversationViewController(controller)
        //        }
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        YWChat.shared.sendMessage(by: "iwangxinvisitor695", content: "发一个普通的消息")
    }
    
    @IBAction func sendCustomizeMessage(_ sender: UIButton) {
        let a: [String: Any] = ["messageType": "哈哈", "aaa": "你好"]
        YWChat.shared.sendCustomizeMessage(by: "iwangxinvisitor695", message: a, summary: "自定义消息A")
    }
    
    // MARK: - 测试
    @IBAction func test(_ sender: UIButton) {
//        let b = BModel()
//        b.messageType = CustomizeMessageType.B.rawValue
//        YunWangAdapter.shared.sendCustomizeMessage(by: "iwangxinvisitor695", message: b, summary: "自定义消息B")
        
    
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension ViewController {
    
    @objc func statusChange(notification: Notification) {
        title = YWChat.shared.statusName
    }
    
    @objc func unReadChange(notification: Notification) {
        unReadItem.title = "\(YWChat.shared.unReadCount)未读"
    }

}
