//
//  AFNetworkingManager.m
//  UnityCarDrive
//
//  Created by lax on 2019/4/11.
//  Copyright © 2019 TSingYan. All rights reserved.
//

#import "AFNetworkingManager.h"
#import "AFNetworking.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "AppDelegate.h"

typedef enum {
    RequestTypeGet,
    RequestTypePost
} RequestType;

@interface AFNetworkingManager()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation AFNetworkingManager

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [[AFHTTPSessionManager alloc] init];
        _sessionManager.requestSerializer.timeoutInterval = 30;
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript",@"text/plain", nil];
    }
    return _sessionManager;
}

+ (id)shared {
    static  dispatch_once_t once;
    static   id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

// 网络监听
+ (void)listenNetWorkingStatus {
    /* 函数调用返回的枚举值 */
    /**
     AFNetworkReachabilityStatusUnknown          = -1,  // 未知
     AFNetworkReachabilityStatusNotReachable     = 0,   // 无连接
     AFNetworkReachabilityStatusReachableViaWWAN = 1,   // 3G 花钱
     AFNetworkReachabilityStatusReachableViaWiFi = 2,   // 局域网络,
     */
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                [SVProgressHUD showSuccessWithStatus:@"未知网络"];
                [SVProgressHUD dismissWithDelay:2];
                break;
            case AFNetworkReachabilityStatusNotReachable:
                [SVProgressHUD showSuccessWithStatus:@"未连接网络"];
                [SVProgressHUD dismissWithDelay:2];
                AppDelegate.shared.hasNetwork = NO;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                if (!AppDelegate.shared.hasNetwork) {
                    AppDelegate.shared.hasNetwork = YES;
                    [SVProgressHUD showSuccessWithStatus:@"已连接蜂窝移动网络"];
                    [SVProgressHUD dismissWithDelay:2];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_GetNetwork" object:@"4G"];
                }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                if (!AppDelegate.shared.hasNetwork) {
                    AppDelegate.shared.hasNetwork = YES;
                    [SVProgressHUD showSuccessWithStatus:@"已连接WiFi"];
                    [SVProgressHUD dismissWithDelay:2];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_GetNetwork" object:@"WIFI"];
                }
                break;
            default:
                break;
        }
    }];
    
    /**
     * 由于检测网络有一定的延迟, 所以在启动APP的时候如果不设置网络的延迟, 直接调用[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus有可能得到的是status 返回的值是 AFNetworkReachabilityStatusUnknown;
     这个时候虽然有网, 但是也会因为网络的延迟, 直接做出错误的判断.
     一般建议设置延时调用 */
    /** 0.35秒后再执行surveyNetworkConcatenate:方法. */
    [self performSelector:@selector(startMonitoring) withObject:nil afterDelay:0.35f];
    
    //有网的时候默认启动提示已连接，设置这个第一次不会提示
    AppDelegate.shared.hasNetwork = YES;
}

+ (void)startMonitoring {
    /** 1. 开启监听 */
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)request:(RequestType)requestType
      urlString:(NSString *)urlString
      parameter:(NSDictionary *)param
        success:(void (^)(NSDictionary *))successBlock
        failure:(void (^)(NSError *))failureBlock {
    
    NSLog(@"\nurl = %@\n param = %@", urlString, param);
    
    void(^tempSuccessBlock)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonData) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"\nresult = %@", jsonString);
        }
        
        NSString *ret = responseObject[@"ret"];
        NSDictionary *result = responseObject[@"data"][@"Databody"];
        if (responseObject && ret && result) {
            if (ret.integerValue == 200) {
                successBlock(result);
            } else {
                [SVProgressHUD showErrorWithStatus:responseObject[@"msg"]];
                [SVProgressHUD dismissWithDelay:2];
                NSDictionary * userInfo = [NSDictionary dictionaryWithObject:responseObject[@"msg"] forKey:NSLocalizedDescriptionKey];
                error = [[NSError alloc] initWithDomain:@"An Error Has Occurred" code:ret.integerValue userInfo:userInfo];
                failureBlock(error);
            }
        } else {
            [SVProgressHUD showErrorWithStatus:@"数据解析失败"];
            [SVProgressHUD dismissWithDelay:2];
            NSDictionary * userInfo = [NSDictionary dictionaryWithObject:@"数据解析失败" forKey:NSLocalizedDescriptionKey];
            error = [[NSError alloc] initWithDomain:@"An Error Has Occurred" code:0 userInfo:userInfo];
            failureBlock(error);
        }
        [self hideActivityIndicator];
    };

    void(^tempFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"\ncode = %zd, error = %@", error.code, error.localizedDescription);
        if (AppDelegate.shared.hasNetwork == NO) {
            [SVProgressHUD showErrorWithStatus:@"未连接网络"];
            [SVProgressHUD dismissWithDelay:2];
        } else {
            [SVProgressHUD showErrorWithStatus:@"连接服务器失败"];
            [SVProgressHUD dismissWithDelay:2];
        }
        failureBlock(error);
        [self hideActivityIndicator];
    };

    [self showActivityIndicator];
    if (requestType == RequestTypeGet) {
        [self.sessionManager GET:urlString
                      parameters:param
                        progress:nil
                         success:tempSuccessBlock
                         failure:tempFailureBlock];
    } else {
        [self.sessionManager POST:urlString
                       parameters:param
                         progress:nil
                          success:tempSuccessBlock
                          failure:tempFailureBlock];
    }
    
}

- (void)showActivityIndicator {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)hideActivityIndicator {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)getRequest:(NSString *)urlString
         parameter:(NSDictionary *)param
           success:(void (^)(NSDictionary *))successBlock
           failure:(void (^)(NSError *))failureBlock {
    [self request:RequestTypeGet urlString:urlString
        parameter:param
          success:successBlock
          failure:failureBlock];
}

- (void)postRequest:(NSString *)urlString
          parameter:(NSDictionary *)param
            success:(void (^)(NSDictionary *))successBlock
            failure:(void (^)(NSError *))failureBlock {
    [self request:RequestTypePost
        urlString:urlString
        parameter:param
          success:successBlock
          failure:failureBlock];
}


@end
