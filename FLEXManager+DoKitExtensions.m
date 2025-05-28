//
//  FLEXManager+DoKitExtensions.m
//  FLEX
//
//  DoKit 功能增强扩展实现
//

#import "FLEXManager+DoKitExtensions.h"
#import "FLEXManager+Extensibility.h"
#import "FLEXBugViewController.h"
#import "FLEXPerformanceViewController.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXNetworkWeakViewController.h"
#import "FLEXVisualToolsViewController.h"

@implementation FLEXManager (DoKitExtensions)

- (void)registerDoKitEnhancements {
    [self registerPerformanceMonitoring];
    [self registerNetworkDebugging];
    [self registerUIDebugging];
    [self registerMemoryDebugging];
    [self registerBugDebugging];
}

// 添加category参数的注册方法
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock category:(NSString *)category {
    // 临时忽略category参数，使用基础方法
    [self registerGlobalEntryWithName:entryName objectFutureBlock:objectFutureBlock];
}

- (void)registerPerformanceMonitoring {
    // CPU 监控
    [self registerGlobalEntryWithName:@"CPU 监控"
                   objectFutureBlock:^id{
                       return [[FLEXPerformanceViewController alloc] init];
                   }];
    
    // 内存监控
    [self registerGlobalEntryWithName:@"内存监控"
                   viewControllerFutureBlock:^UIViewController *{
                       return [[FLEXPerformanceViewController alloc] init];
                   }];
}

- (void)registerNetworkDebugging {
    // 网络监控
    [self registerGlobalEntryWithName:@"网络监控"
                   viewControllerFutureBlock:^UIViewController *{
                       return [[FLEXNetworkMITMViewController alloc] init];
                   }];
    
    // 弱网测试
    [self registerGlobalEntryWithName:@"弱网测试"
                   viewControllerFutureBlock:^UIViewController *{
                       return [[FLEXNetworkWeakViewController alloc] init];
                   }];
}

- (void)registerUIDebugging {
    // 视觉工具
    [self registerGlobalEntryWithName:@"视觉工具"
                   viewControllerFutureBlock:^UIViewController *{
                       return [[FLEXVisualToolsViewController alloc] init];
                   }];
}

- (void)registerMemoryDebugging {
    // 内存泄漏检测
    [self registerGlobalEntryWithName:@"内存泄漏检测"
                   viewControllerFutureBlock:^UIViewController *{
                       // 返回一个临时的替代实现
                       return [[FLEXPerformanceViewController alloc] init];
                   }];
}

- (void)registerBugDebugging {
    // 注册Bug调试工具入口
    [self registerGlobalEntryWithName:@"DoKit工具箱"
                   viewControllerFutureBlock:^UIViewController *{
                       return [[FLEXBugViewController alloc] init];
                   }];
}

@end