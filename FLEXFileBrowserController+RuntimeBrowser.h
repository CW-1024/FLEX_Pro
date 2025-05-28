#import "FLEXFileBrowserController.h"

@interface FLEXFileBrowserController (RuntimeBrowser)

// 移植文件分析功能
- (void)analyzeMachOFile:(NSString *)path;
- (void)analyzePlistFile:(NSString *)path;
- (void)previewTextFile:(NSString *)path;
- (void)analyzeFileAtPath:(NSString *)path;

@end