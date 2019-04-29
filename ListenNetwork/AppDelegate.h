//
//  AppDelegate.h
//  网络监听
//
//  Created by lax on 2019/4/29.
//  Copyright © 2019 ColdChains. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//是否有网
@property (nonatomic, assign) BOOL hasNetwork;

+ (AppDelegate *)shared;

@end

