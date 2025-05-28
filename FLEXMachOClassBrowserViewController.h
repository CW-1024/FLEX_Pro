#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMachOClassBrowserViewController : UITableViewController

@property (nonatomic, copy) NSArray<NSString *> *classNames;
@property (nonatomic, copy) NSString *imagePath;

@end

NS_ASSUME_NONNULL_END