//
//  NewBubbleChatView.swift
//  YWChat
//
//  Created by leona on 2018/3/7.
//  Copyright © 2018年 Jake. All rights reserved.
//

import UIKit

class NewBubbleChatView: YWBaseBubbleChatView {

    private let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    private var model: NewBubbleViewModel?
    
    convenience init(viewModel: NewBubbleViewModel) {
        
        self.init()
        self.model = viewModel

        label.backgroundColor = .yellow
        label.text = model?.content
        addSubview(label)
    }
    
    override func getBubbleSize() -> CGSize {
        return CGSize(width: 80, height: 80)
    }

    override func updateConstraints() {
        super.updateConstraints()
    }
    
    override func viewModelClassName() -> String {
        return "NewBubbleChatView"
    }

}
