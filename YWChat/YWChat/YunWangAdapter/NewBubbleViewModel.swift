//
//  NewBubbleViewModel.swift
//  YWChat
//
//  Created by leona on 2018/3/7.
//  Copyright © 2018年 Jake. All rights reserved.
//

import UIKit

class NewBubbleViewModel: YWBaseBubbleViewModel {

    var content: String = ""
    
    convenience init(message: IYWMessage) {
        self.init()
        guard let bodyCustomize = message.messageBody as? YWMessageBodyCustomize, let data = bodyCustomize.content.data(using: String.Encoding.utf8) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else { return }
        content = json?["content"] as? String ?? ""
    }

}
