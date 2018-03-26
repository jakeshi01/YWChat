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
        title = YunWangAdapter.shared.statusName
        unReadItem.title = "\(YunWangAdapter.shared.unReadCount)未读"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - 登录相关
    @IBAction func login(_ sender: UIButton) {
        YunWangAdapter.shared.login(with: "visitor870", password: "taobao1234")
    }
    
    @IBAction func logout(_ sender: UIButton) {
        YunWangAdapter.shared.logout()
    }
    
    // MARK: - 聊天相关
    @IBAction func conversationList(_ sender: UIButton) {
        guard let navigationController = navigationController else { return }
        YunWangAdapter.shared.pushConversationListController(with: navigationController)
    }
    
    @IBAction func chat(_ sender: UIButton) {
        guard let conversationController = YunWangAdapter.shared.getConversationController(conversationId: "iwangxinvisitor696") else { return }
        navigationController?.pushViewController(conversationController, animated: true)
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        YunWangAdapter.shared.sendMessage(by: "iwangxinvisitor695", content: "发一个普通的消息")
    }
    
    @IBAction func sendCustomizeMessage(_ sender: UIButton) {
        let a = BModel()
        a.messageType = CustomizeMessageType.A.rawValue
        YunWangAdapter.shared.sendCustomizeMessage(by: "iwangxinvisitor695", message: a, summary: "自定义消息A")
    }
    
    // MARK: - 测试
    @IBAction func test(_ sender: UIButton) {
        let b = BModel()
        b.messageType = CustomizeMessageType.B.rawValue
        YunWangAdapter.shared.sendCustomizeMessage(by: "iwangxinvisitor695", message: b, summary: "自定义消息B")
        
    
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ViewController {
    
    @objc func statusChange(notification: Notification) {
        title = YunWangAdapter.shared.statusName
    }
    
    @objc func unReadChange(notification: Notification) {
        unReadItem.title = "\(YunWangAdapter.shared.unReadCount)未读"
    }

}
