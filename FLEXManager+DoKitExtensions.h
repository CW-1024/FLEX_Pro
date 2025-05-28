//
//  FLEXManager+DoKitExtensions.h
//  FLEX
//
//  DoKit 功能增强扩展
//

#import "FLEXManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (DoKitExtensions)

/// 注册所有 DoKit 增强功能
- (void)registerDoKitEnhancements;

/// 性能监控相关
- (void)registerPerformanceMonitoring;

/// 网络调试相关
- (void)registerNetworkDebugging;

/// UI 调试相关
- (void)registerUIDebugging;

/// 内存调试相关
- (void)registerMemoryDebugging;

@end

NS_ASSUME_NONNULL_END