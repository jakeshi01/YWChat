//
//  BBubbleChatView.swift
//  YWChat
//
//  Created by leona on 2018/3/7.
//  Copyright © 2018年 Jake. All rights reserved.
//

import UIKit

class BBubbleChatView: YWBaseBubbleChatView {

    private let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
    private(set) var message: CustomizeMessageViewModel?
    
    convenience init(message: CustomizeMessageViewModel) {
        
        self.init()
        self.message = message
        
        label.backgroundColor = .red
        label.text = "我是\(message.messageType ?? ""))"
        addSubview(label)
    }
    
    override func getBubbleSize() -> CGSize {
        return CGSize(width: 200, height: 80)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    override func viewModelClassName() -> String {
        return "CustomizeMessageViewModel"
    }

}