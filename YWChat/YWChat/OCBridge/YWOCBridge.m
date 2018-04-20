//
//  YWLauncheManager.swift
//  YWChat
//
//  Created by Jake on 2018/3/1.
//  Copyright © 2018年 Jake. All rights reserved.
//


#import "YWOCBridge.h"

@interface YWOCBridge ()


@end

@implementation YWOCBridge

+ (NSInteger)registerAppKey: (NSString *)key {
    NSError *error = nil;
    [[YWAPI sharedInstance] setEnvironment:YWEnvironmentRelease];
    [[YWAPI sharedInstance] syncInitWithOwnAppKey:key getError:&error];
    return error.code;
}

+ (void)configImKit: (YWIMKit *)imKit {
    [[imKit.IMCore getContactService] setEnableContactOnlineStatus:YES];
}

+ (void)handleAPNSPush:(YWIMKit *)imKit description: (NSString*)description {

    [[[YWAPI sharedInstance] getGlobalPushService] addHandlePushBlockV4:^(NSDictionary *aResult, BOOL *aShouldStop) {
        
        BOOL isLaunching = [aResult[YWPushHandleResultKeyIsLaunching] boolValue];
        UIApplicationState state = [aResult[YWPushHandleResultKeyApplicationState] integerValue];
        NSString *conversationId = aResult[YWPushHandleResultKeyConversationId];
        Class conversationClass = aResult[YWPushHandleResultKeyConversationClass];
        
        if (conversationId.length <= 0) {
            return;
        }
        
        if (conversationClass == NULL) {
            return;
        }
        
        if (isLaunching) {
            // 用户划开Push导致app启动
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /// 说明已经预登录成功
                YWConversation *conversation = nil;
                if (conversationClass == [YWP2PConversation class]) {
                    conversation = [YWP2PConversation fetchConversationByConversationId:conversationId creatIfNotExist:YES baseContext:imKit.IMCore];
                }
                if (conversation) {
                    if ([[(YWP2PConversation *)conversation person] isEHelperPerson]) {
                        //todo 通过推送进入客服

                    } else {
                        //todo 通过推送进入普通聊天，项目中目前只有招聘会使用
                    }
                }
            });
            
        } else {
            // app已经启动时处理Push
            if (state == UIApplicationStateInactive) {
                /// 说明已经预登录成功
                YWConversation *conversation = nil;
                if (conversationClass == [YWP2PConversation class]) {
                    //todo 通过推送进入单聊

                }
                if (conversation) {

                    if ([[(YWP2PConversation *)conversation person] isEHelperPerson]) {
                        //todo 通过推送进入客服
                    } else {
                        //todo 通过推送进入普通聊天，项目中目前只有招聘会使用
                    }
                    
                }
            }
        }
    } forKey:description ofPriority:YWBlockPriorityDeveloper];
}

+ (void)loginWithImKit:(YWIMKit *)imKit UserId:(NSString *)userId Password:(NSString *)password SuccessBlock:(void(^)(void))successBlock FailedBlock:(void (^)(NSError *))failedBlock
{
    // 登录之前，先告诉IM如何获取登录信息。
    // 当IM向服务器发起登录请求之前，会调用这个block，来获取用户名和密码信息。
    [[imKit.IMCore getLoginService] setFetchLoginInfoBlock:^(YWFetchLoginInfoCompletionBlock  _Nonnull aCompletionBlock) {
        aCompletionBlock(YES, userId, password, nil, nil);
    }];
    
    // 发起登录
    [[imKit.IMCore getLoginService] asyncLoginWithCompletionBlock:^(NSError *aError, NSDictionary *aResult) {
        if (aError.code == 0 || [[imKit.IMCore getLoginService] isCurrentLogined]) {
            // 登录成功
            if (successBlock) {
                successBlock();
            }
        } else {
            if (failedBlock) {
                failedBlock(aError);
            }
        }
    }];
}

@end



