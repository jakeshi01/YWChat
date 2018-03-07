//
//  CustomizeMessageViewModel.swift
//  YWChat
//
//  Created by leona on 2018/3/7.
//  Copyright © 2018年 Jake. All rights reserved.
//



let MessageTypeKey: String = "messageType"

enum CustomizeMessageType: String {
    
    case unknown = ""
    case A = "A"
    case B = "B"
    
}

class CustomizeMessageViewModel: YWBaseBubbleViewModel {

    open var content: [String: Any]?
    var messageType: CustomizeMessageType {
        guard let content = content,
            let typeStr = content[MessageTypeKey] as? String,
            let type = CustomizeMessageType.init(rawValue: typeStr) else {
            return .unknown
        }
        return type
    }

    convenience init(message: IYWMessage) {
        self.init()
        guard let bodyCustomize = message.messageBody as? YWMessageBodyCustomize, let data = bodyCustomize.content.data(using: String.Encoding.utf8) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else { return }
        content = json
    }

}


