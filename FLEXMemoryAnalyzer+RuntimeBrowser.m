#import "FLEXMemoryAnalyzer+RuntimeBrowser.h"
#import "FLEXRuntimeClient+RuntimeBrowser.h"  // 添加这行导入
#import "FLEXRuntimeClient.h"
#import <mach/mach.h>
#import <malloc/malloc.h>
#import <objc/runtime.h>

@implementation FLEXMemoryAnalyzer (RuntimeBrowser)

- (NSDictionary *)getDetailedHeapSnapshot {
    NSMutableDictionary *snapshot = [NSMutableDictionary dictionary];
    
    // 获取内存使用统计
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    snapshot[@"residentSize"] = @(info.resident_size);
    snapshot[@"virtualSize"] = @(info.virtual_size);
    
    // 获取内存区域信息
    snapshot[@"memoryZones"] = [self getMemoryZoneInfo];
    
    // 获取类实例分布
    snapshot[@"instanceDistribution"] = [self getClassInstanceDistribution];
    
    // 检测可能的内存泄漏
    snapshot[@"potentialLeaks"] = [self findMemoryLeaks];
    
    // 获取 malloc 统计信息
    malloc_statistics_t stats;
    malloc_zone_statistics(NULL, &stats);
    
    snapshot[@"mallocStats"] = @{
        @"blocksInUse": @(stats.blocks_in_use),
        @"sizeInUse": @(stats.size_in_use),
        @"maxSizeInUse": @(stats.max_size_in_use),
        @"sizeAllocated": @(stats.size_allocated)
    };
    
    return snapshot;
}

- (NSArray *)getMemoryZoneInfo {
    NSMutableArray *zones = [NSMutableArray array];
    
    vm_address_t *zone_addresses = NULL;
    unsigned int zone_count = 0;
    
    kern_return_t kr = malloc_get_all_zones(mach_task_self(), NULL, &zone_addresses, &zone_count);
    
    if (kr == KERN_SUCCESS) {
        for (unsigned int i = 0; i < zone_count; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zone_addresses[i];
            if (zone && zone->zone_name) {
                malloc_statistics_t stats;
                malloc_zone_statistics(zone, &stats);
                
                [zones addObject:@{
                    @"name": @(zone->zone_name),
                    @"blocksInUse": @(stats.blocks_in_use),
                    @"sizeInUse": @(stats.size_in_use),
                    @"sizeAllocated": @(stats.size_allocated)
                }];
            }
        }
    }
    
    return zones;
}

- (NSDictionary *)getClassInstanceDistribution {
    NSMutableDictionary *distribution = [NSMutableDictionary dictionary];
    
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        // 获取实例数量（简化版本）
        NSUInteger instanceCount = [self getInstanceCountForClass:cls];
        if (instanceCount > 0) {
            distribution[className] = @{
                @"count": @(instanceCount),
                @"instanceSize": @(class_getInstanceSize(cls))
            };
        }
    }
    
    free(classes);
    return distribution;
}

- (NSArray *)findMemoryLeaks {
    NSMutableArray *leaks = [NSMutableArray array];
    
    // 简化的内存泄漏检测
    
    // 检查常见的泄漏模式
    
    // 1. 检查循环引用
    NSArray *suspiciousClasses = @[@"UIViewController", @"UIView", @"NSTimer", @"NSURLSessionTask"];
    
    for (NSString *className in suspiciousClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            NSUInteger count = [self getInstanceCountForClass:cls];
            if (count > 100) { // 阈值检测
                [leaks addObject:@{
                    @"type": @"过多实例",
                    @"className": className,
                    @"count": @(count),
                    @"severity": @"warning"
                }];
            }
        }
    }
    
    // 2. 检查 NSTimer 是否未失效
    Class timerClass = NSClassFromString(@"NSTimer");
    if (timerClass) {
        // 使用 FLEXRuntimeClient 的扩展方法来获取实例
        FLEXRuntimeClient *runtime = [FLEXRuntimeClient runtime];
        NSArray *timers = [runtime getAllInstancesOfClass:timerClass];
        for (NSTimer *timer in timers) {
            if ([timer isValid]) {
                [leaks addObject:@{
                    @"type": @"未失效的NSTimer",
                    @"className": @"NSTimer",
                    @"description": @"可能导致内存泄漏",
                    @"severity": @"high"
                }];
                break; // 只报告一次
            }
        }
    }
    
    return leaks;
}

@end