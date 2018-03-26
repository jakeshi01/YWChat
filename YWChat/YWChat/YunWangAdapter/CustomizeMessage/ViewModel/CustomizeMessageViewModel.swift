//
//  CustomizeMessageViewModel.swift
//  YWChat
//
//  Created by leona on 2018/3/7.
//  Copyright © 2018年 Jake. All rights reserved.
//

class CustomizeMessageViewModel: YWBaseBubbleViewModel {

    open var content: [String: Any]?
    var messageType: String? {
        guard let content = content, let type = content[MessageTypeKey] as? String else { return nil }
        return type
    }

    convenience init(message: IYWMessage) {
        self.init()
        guard let bodyCustomize = message.messageBody as? YWMessageBodyCustomize, let data = bodyCustomize.content.data(using: String.Encoding.utf8) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else { return }
        content = json
    }

}


