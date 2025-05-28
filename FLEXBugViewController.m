//
//  FLEXBugViewController.m
//  FLEX
//
//  Bug调试功能实现
//

#import "FLEXBugViewController.h"
#import "FLEXNavigationController.h"
#import "FLEXAlert.h"
#import "FLEXManager.h"
#import "FLEXFileBrowserController.h"
#import "FLEXSystemLogViewController.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXPerformanceViewController.h"
#import "FLEXHierarchyTableViewController.h"
#import "FLEXAppInfoViewController.h"
#import "FLEXSystemAnalyzerViewController.h"

#import "FLEXUtility.h"
#import "FLEXColor.h"
#import "FLEXResources.h"

@interface FLEXBugViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray<NSDictionary *> *categories;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSDictionary *> *> *toolsByCategory;
@property (nonatomic, assign) BOOL isInCategory;
@property (nonatomic, strong) NSString *currentCategory;

@end

@implementation FLEXBugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"DoKit工具";
    self.isInCategory = NO;
    
    // 配置工具分类
    [self setupToolsData];
    
    // 初始化表格
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ToolCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.isInCategory) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
            target:self 
            action:@selector(dismissButtonTapped)];
    }
}

- (void)setupToolsData {
    // 常用工具 - 使用实际存在的控制器类
    NSArray *commonTools = @[
        @{@"title": @"App信息查看", @"detail": @"查看应用基本信息", @"class": @"FLEXAppInfoViewController"},
        @{@"title": @"沙盒浏览", @"detail": @"浏览应用沙盒文件", @"class": @"FLEXFileBrowserController"},
        @{@"title": @"H5任意门", @"detail": @"快速打开H5页面", @"action": @"showH5Door"},
        @{@"title": @"系统信息", @"detail": @"查看系统详细信息", @"class": @"FLEXSystemAnalyzerViewController"},
        @{@"title": @"清除本地数据", @"detail": @"清除应用本地存储", @"action": @"showClearCache"},
    ];
    
    // 性能检测 - 使用实际存在的控制器类
    NSArray *performanceTools = @[
        @{@"title": @"帧率检测", @"detail": @"监测应用FPS", @"action": @"showFPSMonitor"},
        @{@"title": @"CPU监控", @"detail": @"监测CPU使用情况", @"class": @"FLEXPerformanceViewController"},
        @{@"title": @"内存监控", @"detail": @"监测内存使用情况", @"action": @"showMemoryMonitor"},
        @{@"title": @"网络监控", @"detail": @"监测网络请求", @"class": @"FLEXNetworkMITMViewController"},
        @{@"title": @"卡顿检测", @"detail": @"检测UI卡顿", @"action": @"showLagMonitor"},
        @{@"title": @"系统日志", @"detail": @"查看系统日志", @"class": @"FLEXSystemLogViewController"},
    ];
    
    // 视觉工具 - 使用实际存在的控制器类
    NSArray *visualTools = @[
        @{@"title": @"颜色吸管", @"detail": @"获取屏幕上的颜色", @"action": @"showColorPicker"},
        @{@"title": @"组件检查", @"detail": @"检查UI组件", @"class": @"FLEXHierarchyTableViewController"},
        @{@"title": @"对齐标尺", @"detail": @"测量UI元素", @"action": @"showRuler"},
        @{@"title": @"元素边框", @"detail": @"显示视图边框", @"action": @"showViewBorder"},
        @{@"title": @"布局边界", @"detail": @"查看布局边界", @"action": @"showLayoutBounds"},
    ];
    
    // 设置分类数据
    self.categories = @[
        @{@"title": @"常用工具", @"image": @"hammer", @"key": @"common"},
        @{@"title": @"性能检测", @"image": @"gauge", @"key": @"performance"},
        @{@"title": @"视觉工具", @"image": @"eye", @"key": @"visual"}
    ];
    
    // 设置工具数据映射
    self.toolsByCategory = @{
        @"common": commonTools,
        @"performance": performanceTools,
        @"visual": visualTools
    };
}

#pragma mark - Actions

- (void)dismissButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)backButtonTapped {
    self.isInCategory = NO;
    self.currentCategory = nil;
    self.title = @"DoKit工具";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self
        action:@selector(dismissButtonTapped)];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isInCategory) {
        NSArray *tools = self.toolsByCategory[self.currentCategory];
        return tools.count;
    }
    return self.categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ToolCell" forIndexPath:indexPath];
    
    if (self.isInCategory) {
        // 显示具体工具
        NSArray *tools = self.toolsByCategory[self.currentCategory];
        NSDictionary *tool = tools[indexPath.row];
        cell.textLabel.text = tool[@"title"];
        cell.detailTextLabel.text = tool[@"detail"];
    } else {
        // 显示分类
        NSDictionary *category = self.categories[indexPath.row];
        cell.textLabel.text = category[@"title"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu个工具", 
            (unsigned long)[self.toolsByCategory[category[@"key"]] count]];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.isInCategory) {
        // 在分类内部，选择具体工具
        NSArray *tools = self.toolsByCategory[self.currentCategory];
        NSDictionary *tool = tools[indexPath.row];
        
        if (tool[@"class"]) {
            Class toolClass = NSClassFromString(tool[@"class"]);
            if (toolClass) {
                id viewController = nil;
                
                // 特殊处理某些需要参数的控制器
                if ([tool[@"class"] isEqualToString:@"FLEXFileBrowserController"]) {
                    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
                    viewController = [[toolClass alloc] initWithPath:documentsPath];
                } else {
                    viewController = [[toolClass alloc] init];
                }
                
                if (viewController) {
                    [self.navigationController pushViewController:viewController animated:YES];
                }
            } else {
                [FLEXAlert showAlert:@"功能暂未实现" message:tool[@"title"] from:self];
            }
        } else if (tool[@"action"]) {
            // 使用 pragma 指令抑制 ARC 警告
            SEL action = NSSelectorFromString(tool[@"action"]);
            if ([self respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:action];
#pragma clang diagnostic pop
            } else {
                [FLEXAlert showAlert:@"功能暂未实现" message:tool[@"title"] from:self];
            }
        }
    } else {
        // 选择分类，进入分类详情
        NSDictionary *category = self.categories[indexPath.row];
        self.currentCategory = category[@"key"];
        self.isInCategory = YES;
        
        // 更新标题和导航
        self.title = category[@"title"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:@"返回"
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(backButtonTapped)];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Tool Actions

- (void)showH5Door {
    [FLEXAlert showAlert:@"H5任意门" message:@"H5任意门功能开发中..." from:self];
}

- (void)showClearCache {
    [FLEXAlert showAlert:@"清除缓存" message:@"清除缓存功能开发中..." from:self];
}

- (void)showFPSMonitor {
    [FLEXAlert showAlert:@"FPS监控" message:@"FPS监控功能开发中..." from:self];
}

- (void)showMemoryMonitor {
    [FLEXAlert showAlert:@"内存监控" message:@"内存监控功能开发中..." from:self];
}

- (void)showLagMonitor {
    [FLEXAlert showAlert:@"卡顿检测" message:@"卡顿检测功能开发中..." from:self];
}

- (void)showColorPicker {
    [FLEXAlert showAlert:@"颜色吸管" message:@"颜色吸管功能开发中..." from:self];
}

- (void)showRuler {
    [FLEXAlert showAlert:@"对齐标尺" message:@"对齐标尺功能开发中..." from:self];
}

- (void)showViewBorder {
    [FLEXAlert showAlert:@"元素边框" message:@"元素边框功能开发中..." from:self];
}

- (void)showLayoutBounds {
    [FLEXAlert showAlert:@"布局边界" message:@"布局边界功能开发中..." from:self];
}

@end