#import "FLEXFileBrowserController+RuntimeBrowser.h"
#import "FLEXTableListViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXMachOClassBrowserViewController.h"
#import "FLEXWebViewController.h"
#import <dlfcn.h>

@implementation FLEXFileBrowserController (RuntimeBrowser)

- (void)analyzeMachOFile:(NSString *)path {
    const char *imagePath = path.UTF8String;
    void *handle = dlopen(imagePath, RTLD_LAZY | RTLD_NOLOAD);
    
    NSMutableArray *classNames = [NSMutableArray array];
    
    if (handle) {
        unsigned int count = 0;
        const char **classNamesC = objc_copyClassNamesForImage(imagePath, &count);
        
        for (unsigned int i = 0; i < count; i++) {
            NSString *className = @(classNamesC[i]);
            [classNames addObject:className];
        }
        
        free(classNamesC);
        dlclose(handle);
        
        // 使用 FLEXMachOClassBrowserViewController 显示类列表
        FLEXMachOClassBrowserViewController *tableVC = [[FLEXMachOClassBrowserViewController alloc] init];
        tableVC.title = [NSString stringWithFormat:@"%@ 中的类", [path lastPathComponent]];
        tableVC.classNames = [classNames sortedArrayUsingSelector:@selector(compare:)];
        tableVC.imagePath = path;
        [self.navigationController pushViewController:tableVC animated:YES];
    } else {
        UIAlertController *alert = [UIAlertController
                                   alertControllerWithTitle:@"无法加载"
                                   message:@"无法加载动态库或framework"
                                   preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)analyzePlistFile:(NSString *)path {
    NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfFile:path];
    if (plistContent) {
        UIViewController *explorerVC = [FLEXObjectExplorerFactory explorerViewControllerForObject:plistContent];
        explorerVC.title = [NSString stringWithFormat:@"%@ 内容", [path lastPathComponent]];
        [self.navigationController pushViewController:explorerVC animated:YES];
    } else {
        UIAlertController *alert = [UIAlertController
                                   alertControllerWithTitle:@"无法读取"
                                   message:@"无法读取 plist 文件内容"
                                   preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)previewTextFile:(NSString *)path {
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (content) {
        FLEXWebViewController *webVC = [[FLEXWebViewController alloc] initWithText:content];
        webVC.title = [path lastPathComponent];
        [self.navigationController pushViewController:webVC animated:YES];
    } else {
        UIAlertController *alert = [UIAlertController
                                   alertControllerWithTitle:@"无法读取"
                                   message:@"无法读取文本文件内容"
                                   preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)analyzeFileAtPath:(NSString *)path {
    NSString *extension = path.pathExtension.lowercaseString;
    
    if ([extension isEqualToString:@"dylib"] || [extension isEqualToString:@"framework"]) {
        [self analyzeMachOFile:path];
    } else if ([extension isEqualToString:@"plist"]) {
        [self analyzePlistFile:path];
    } else if ([@[@"h", @"m", @"mm", @"cpp", @"c", @"swift"] containsObject:extension]) {
        [self previewTextFile:path];
    } else {
        // 对于其他文件类型，显示一个提示
        UIAlertController *alert = [UIAlertController
                                   alertControllerWithTitle:@"文件类型"
                                   message:[NSString stringWithFormat:@"不支持分析 %@ 类型的文件", extension]
                                   preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end