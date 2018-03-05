//
//  YWLauncheManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/1.
//  Copyright © 2018年 Jake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WXOpenIMSDKFMWK/YWFMWK.h>
#import <WXOUIModule/YWUIFMWK.h>

@interface YWOCBridge : NSObject

+ (NSInteger)registerAppKey: (NSString *)key;
+ (void)configImKit: (YWIMKit *)imKit;
+ (void)handleAPNSPush:(YWIMKit *)imKit description: (NSString*)description;

@end
