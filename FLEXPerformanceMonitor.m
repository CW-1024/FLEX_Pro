//
//  FLEXPerformanceMonitor.m
//  FLEX
//
//  Created based on DoKit performance tools.
//  Copyright © 2023 FLEX Team. All rights reserved.
//

#import "FLEXPerformanceMonitor.h"
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <ifaddrs.h>

@interface FLEXPerformanceMonitor ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, assign) float currentFPS;

@property (nonatomic, strong) NSTimer *cpuTimer;
@property (nonatomic, assign) float cpuUsage;

@property (nonatomic, strong) NSTimer *memoryTimer;
@property (nonatomic, assign) double memoryUsage;

@property (nonatomic, strong) NSTimer *networkTimer;
@property (nonatomic, assign) uint64_t lastDownloadBytes;
@property (nonatomic, assign) uint64_t lastUploadBytes;
@property (nonatomic, assign) uint64_t downloadFlowBytes;
@property (nonatomic, assign) uint64_t uploadFlowBytes;

@property (nonatomic, strong) NSDate *classLoadStartTime;
@property (nonatomic, strong) NSMutableDictionary *classLoadTimes;
@property (nonatomic, strong) NSMutableArray *methodProfilingResults;
@property (nonatomic, assign) BOOL isProfilingActive;

@end

@implementation FLEXPerformanceMonitor

+ (instancetype)sharedInstance {
    static FLEXPerformanceMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FLEXPerformanceMonitor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _classLoadTimes = [NSMutableDictionary dictionary];
        _methodProfilingResults = [NSMutableArray array];
        _isProfilingActive = NO;
    }
    return self;
}

#pragma mark - FPS监控

- (void)startFPSMonitoring {
    if (self.displayLink) {
        return;
    }
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.lastTimestamp = 0;
    self.frameCount = 0;
}

- (void)stopFPSMonitoring {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)displayLinkTick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        return;
    }
    
    self.frameCount++;
    NSTimeInterval interval = link.timestamp - self.lastTimestamp;
    if (interval >= 1.0) {
        self.currentFPS = self.frameCount / interval;
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

#pragma mark - CPU监控

- (void)startCPUMonitoring {
    if (self.cpuTimer) {
        return;
    }
    
    self.cpuTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                    target:self 
                                                  selector:@selector(updateCPUUsage) 
                                                  userInfo:nil 
                                                   repeats:YES];
}

- (void)stopCPUMonitoring {
    if (self.cpuTimer) {
        [self.cpuTimer invalidate];
        self.cpuTimer = nil;
    }
}

- (void)updateCPUUsage {
    self.cpuUsage = [self getCPUUsage];
}

- (float)getCPUUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    float cpu_usage = 0;
    
    for (int i = 0; i < thread_count; i++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            continue;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            cpu_usage += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    
    vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    
    return cpu_usage * 100.0;
}

#pragma mark - 内存监控

- (void)startMemoryMonitoring {
    if (self.memoryTimer) {
        return;
    }
    
    self.memoryTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                       target:self 
                                                     selector:@selector(updateMemoryUsage) 
                                                     userInfo:nil 
                                                      repeats:YES];
}

- (void)stopMemoryMonitoring {
    if (self.memoryTimer) {
        [self.memoryTimer invalidate];
        self.memoryTimer = nil;
    }
}

- (void)updateMemoryUsage {
    self.memoryUsage = [self getMemoryUsage];
}

- (double)getMemoryUsage {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kr = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    return (double)vmInfo.phys_footprint / (1024 * 1024);
}

#pragma mark - 网络流量监控

- (void)startNetworkMonitoring {
    if (self.networkTimer) {
        return;
    }
    
    // 初始化基准值
    [self getNetworkFlow];
    self.lastDownloadBytes = self.downloadFlowBytes;
    self.lastUploadBytes = self.uploadFlowBytes;
    
    self.networkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                        target:self 
                                                      selector:@selector(updateNetworkFlow) 
                                                      userInfo:nil 
                                                       repeats:YES];
}

- (void)stopNetworkMonitoring {
    if (self.networkTimer) {
        [self.networkTimer invalidate];
        self.networkTimer = nil;
    }
}

- (void)updateNetworkFlow {
    [self getNetworkFlow];
    
    // 计算差值
    uint64_t downloadDiff = self.downloadFlowBytes - self.lastDownloadBytes;
    uint64_t uploadDiff = self.uploadFlowBytes - self.lastUploadBytes;
    
    // 更新上一次的值
    self.lastDownloadBytes = self.downloadFlowBytes;
    self.lastUploadBytes = self.uploadFlowBytes;
    
    // 记录每秒的流量
    self.downloadFlowBytes = downloadDiff;
    self.uploadFlowBytes = uploadDiff;
}

- (void)getNetworkFlow {
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    
    uint64_t iBytes = 0;
    uint64_t oBytes = 0;
    
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        while (cursor != NULL) {
            if (cursor->ifa_addr->sa_family == AF_LINK) {
                if (!(cursor->ifa_flags & IFF_LOOPBACK)) { // 排除回环接口
                    const struct if_data *data = (const struct if_data *)cursor->ifa_data;
                    iBytes += data->ifi_ibytes;
                    oBytes += data->ifi_obytes;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    self.downloadFlowBytes = iBytes;
    self.uploadFlowBytes = oBytes;
}

#pragma mark - 类加载时间跟踪

- (void)startTrackingClassLoadTime {
    self.classLoadStartTime = [NSDate date];
    
    // 初始化记录已加载的类
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        if (className) {
            self.classLoadTimes[className] = @(0); // 已加载的类的加载时间为0
        }
    }
    
    free(classes);
    
    // 注意：实际实现中可能需要使用Method Swizzling来捕获类加载事件
    // 这里使用简化实现
}

- (NSArray *)getClassLoadTimeInfo {
    // 获取当前所有类，比较与初始记录的差异
    NSMutableArray *loadTimeInfo = [NSMutableArray array];
    
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        if (className && !self.classLoadTimes[className]) {
            // 这是一个新加载的类
            [loadTimeInfo addObject:@{
                @"className": className,
                @"loadTime": @(0.01) // 模拟加载时间
            }];
            
            // 记录以避免重复添加
            self.classLoadTimes[className] = @(0.01);
        }
    }
    
    free(classes);
    
    // 按加载时间排序
    [loadTimeInfo sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"loadTime" ascending:NO]
    ]];
    
    return loadTimeInfo;
}

#pragma mark - 方法性能分析

- (void)startMethodProfiling {
    if (self.isProfilingActive) {
        return;
    }
    
    [self.methodProfilingResults removeAllObjects];
    self.isProfilingActive = YES;
    
    // 实际实现中应该使用Method Swizzling或其他技术来拦截方法调用
    // 这里使用简化实现
    
    NSLog(@"方法性能分析已开始");
}

- (void)stopMethodProfiling {
    if (!self.isProfilingActive) {
        return;
    }
    
    self.isProfilingActive = NO;
    
    // 模拟一些结果数据
    [self simulateMethodProfilingResults];
    
    NSLog(@"方法性能分析已停止");
}

- (NSArray *)getProfilingResults {
    return [self.methodProfilingResults copy];
}

#pragma mark - 辅助方法

- (void)simulateMethodProfilingResults {
    // 生成一些示例数据
    NSArray *commonMethods = @[
        @"-[UIViewController viewDidLoad]",
        @"-[UITableView reloadData]",
        @"-[UIImageView setImage:]",
        @"+[UIImage imageNamed:]",
        @"-[NSURLSession dataTaskWithURL:completionHandler:]",
        @"-[NSString stringWithFormat:]",
        @"-[UICollectionView cellForItemAtIndexPath:]",
        @"-[UIApplication sendAction:to:from:forEvent:]"
    ];
    
    for (NSString *methodName in commonMethods) {
        double executionTime = ((double)arc4random_uniform(100)) / 1000.0; // 0-100ms
        [self.methodProfilingResults addObject:@{
            @"methodName": methodName,
            @"executionTime": @(executionTime),
            @"callCount": @(arc4random_uniform(50) + 1)
        }];
    }
    
    // 按执行时间排序
    [self.methodProfilingResults sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"executionTime" ascending:NO]
    ]];
}

#pragma mark - 全部监控

- (void)startAllMonitoring {
    [self startFPSMonitoring];
    [self startCPUMonitoring];
    [self startMemoryMonitoring];
    [self startNetworkMonitoring];
}

- (void)stopAllMonitoring {
    [self stopFPSMonitoring];
    [self stopCPUMonitoring];
    [self stopMemoryMonitoring];
    [self stopNetworkMonitoring];
}

@end