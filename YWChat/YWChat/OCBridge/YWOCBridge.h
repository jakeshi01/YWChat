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

+ (void)loginWithImKit:(YWIMKit *)imKit UserId:(NSString *)userId Password:(NSString *)password SuccessBlock:(void(^)(void))successBlock FailedBlock:(void (^)(NSError *))failedBlock;

+ (void) setConversationViewControllerViewWillApearBlock: (YWConversationViewController *)conversationViewController viewWillAppearBlock: (YWViewWillAppearBlock)block;

@end
