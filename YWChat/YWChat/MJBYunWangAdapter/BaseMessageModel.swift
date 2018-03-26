//
//  BaseMessageModel.swift
//  YWChat
//
//  Created by leona on 2018/3/22.
//  Copyright © 2018年 Jake. All rights reserved.
//



enum CustomizeMessageType: String {
    
    case A = "自定义A消息"
    case B = "自定义B消息"
}


import ObjectMapper

class BaseMessageModel: Mappable {
    
    var messageType: String?
    
    init() {}
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        messageType <- map["messageType"]
    }
}


class BModel: BaseMessageModel {
    
    var b: String = ""
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        b <- map["b"]
    }
}
