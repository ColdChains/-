//
//  AFNetworkingManager.h
//  UnityCarDrive
//
//  Created by lax on 2019/4/11.
//  Copyright © 2019 TSingYan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFNetworkingManager : NSObject

+ (instancetype)shared;

// 监听网络状态
+ (void)listenNetWorkingStatus;

- (void)getRequest:(NSString *)urlString
         parameter:(NSDictionary *)param
           success:(void(^)(NSDictionary *result))successBlock
           failure:(void(^)(NSError *error))failureBlock;

- (void)postRequest:(NSString *)urlString
         parameter:(NSDictionary *)param
           success:(void(^)(NSDictionary *result))successBlock
           failure:(void(^)(NSError *error))failureBlock;

// 状态栏加载提示
- (void)showActivityIndicator;
- (void)hideActivityIndicator;

@end
