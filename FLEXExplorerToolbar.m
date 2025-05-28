//
//  FLEXExplorerToolbar.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXExplorerToolbar.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

// 添加常量定义
static const CGFloat kDragHandleHeight = 10.0;

@interface FLEXExplorerToolbar ()

@property (nonatomic, readwrite) FLEXExplorerToolbarItem *globalsItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *hierarchyItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *selectItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *recentItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *moveItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *closeItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *bugItem;
@property (nonatomic, readwrite) UIView *dragHandle;

@property (nonatomic) UIImageView *dragHandleImageView;

@property (nonatomic) UIView *selectedViewDescriptionContainer;
@property (nonatomic) UIView *selectedViewDescriptionSafeAreaContainer;
@property (nonatomic) UIView *selectedViewColorIndicator;
@property (nonatomic) UILabel *selectedViewDescriptionLabel;

@property (nonatomic,readwrite) UIView *backgroundView;

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [FLEXColor secondaryBackgroundColorWithAlpha:0.95];
        self.layer.borderColor = [FLEXColor tertiaryBackgroundColor].CGColor;
        self.layer.borderWidth = 1.0;
        
        self.dragHandle = [UIView new];
        self.dragHandle.backgroundColor = [FLEXColor tertiaryBackgroundColor];
        [self addSubview:self.dragHandle];

        // 初始化现有按钮（保持不变）
        self.selectItem    = [FLEXExplorerToolbarItem itemWithTitle:@"选择" image:FLEXResources.selectIcon];
        self.hierarchyItem = [FLEXExplorerToolbarItem itemWithTitle:@"视图" image:FLEXResources.hierarchyIcon];
        self.globalsItem   = [FLEXExplorerToolbarItem itemWithTitle:@"菜单" image:FLEXResources.globalsIcon];
        self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"最近" image:FLEXResources.recentIcon];
        self.moveItem      = [FLEXExplorerToolbarItem itemWithTitle:@"移动" image:FLEXResources.moveIcon sibling:self.recentItem];
        self.bugItem       = [FLEXExplorerToolbarItem itemWithTitle:@"调试" image:FLEXResources.bugIcon];
        self.closeItem     = [FLEXExplorerToolbarItem itemWithTitle:@"关闭" image:FLEXResources.closeIcon];
        
        
        // Selected view box //
        
        self.selectedViewDescriptionContainer = [UIView new];
        self.selectedViewDescriptionContainer.backgroundColor = [FLEXColor tertiaryBackgroundColorWithAlpha:0.95];
        self.selectedViewDescriptionContainer.hidden = YES;
        [self addSubview:self.selectedViewDescriptionContainer];

        self.selectedViewDescriptionSafeAreaContainer = [UIView new];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = UIColor.clearColor;
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionSafeAreaContainer];
        
        self.selectedViewColorIndicator = [UIView new];
        self.selectedViewColorIndicator.backgroundColor = UIColor.redColor;
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];
        
        self.selectedViewDescriptionLabel = [UILabel new];
        self.selectedViewDescriptionLabel.backgroundColor = UIColor.clearColor;
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];
        
        // toolbarItems
        self.toolbarItems = @[_globalsItem, _hierarchyItem, _selectItem, _moveItem, _closeItem];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    const CGFloat kPadding = 10.0;
    const CGFloat kButtonSize = 44.0;
    const CGFloat kMiddleSpace = 8.0;
    const CGSize size = self.bounds.size;
    
    // 获取safeArea区域
    CGRect safeArea = [self safeArea];
    
    // 拖拽手柄
    CGFloat dragHandleWidth = size.width * 0.2;
    self.dragHandle.frame = CGRectMake(
        size.width / 2.0 - dragHandleWidth / 2.0,
        0,
        dragHandleWidth,
        kDragHandleHeight
    );
    
    // 左侧按钮
    self.selectItem.frame = CGRectMake(
        kPadding, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    self.hierarchyItem.frame = CGRectMake(
        CGRectGetMaxX(self.selectItem.frame) + kMiddleSpace, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    
    // 右侧按钮，从右向左布局
    self.closeItem.frame = CGRectMake(
        size.width - kPadding - kButtonSize, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    self.globalsItem.frame = CGRectMake(
        CGRectGetMinX(self.closeItem.frame) - kButtonSize - kMiddleSpace, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    
    // Bug按钮 - 放在globalsItem左侧
    self.bugItem.frame = CGRectMake(
        CGRectGetMinX(self.globalsItem.frame) - kButtonSize - kMiddleSpace, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    
    // 调整其他按钮位置
    self.moveItem.frame = CGRectMake(
        CGRectGetMinX(self.bugItem.frame) - kButtonSize - kMiddleSpace, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    self.recentItem.frame = CGRectMake(
        CGRectGetMinX(self.moveItem.frame) - kButtonSize - kMiddleSpace, 
        kDragHandleHeight + kPadding, 
        kButtonSize, 
        kButtonSize
    );
    
    // 确保Bug按钮被添加到视图中
    if (self.bugItem.superview == nil) {
        [self addSubview:self.bugItem];
    }
    
    // 所选视图描述区域的布局
    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];
    
    CGRect descriptionContainerFrame = CGRectZero;
    descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds);
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.x = CGRectGetMinX(self.bounds);
    descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
    self.selectedViewDescriptionContainer.frame = descriptionContainerFrame;

    CGRect descriptionSafeAreaContainerFrame = CGRectZero;
    descriptionSafeAreaContainerFrame.size.width = CGRectGetWidth(safeArea);
    descriptionSafeAreaContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionSafeAreaContainerFrame.origin.x = CGRectGetMinX(safeArea);
    descriptionSafeAreaContainerFrame.origin.y = CGRectGetMinY(safeArea);
    self.selectedViewDescriptionSafeAreaContainer.frame = descriptionSafeAreaContainerFrame;

    // Selected View Color
    CGRect selectedViewColorFrame = CGRectZero;
    selectedViewColorFrame.size.width = kSelectedViewColorDiameter;
    selectedViewColorFrame.size.height = kSelectedViewColorDiameter;
    selectedViewColorFrame.origin.x = kHorizontalPadding;
    selectedViewColorFrame.origin.y = FLEXFloor((kDescriptionContainerHeight - kSelectedViewColorDiameter) / 2.0);
    self.selectedViewColorIndicator.frame = selectedViewColorFrame;
    self.selectedViewColorIndicator.layer.cornerRadius = ceil(selectedViewColorFrame.size.height / 2.0);
    
    // Selected View Description
    CGRect descriptionLabelFrame = CGRectZero;
    CGFloat descriptionOriginX = CGRectGetMaxX(selectedViewColorFrame) + kHorizontalPadding;
    descriptionLabelFrame.size.height = kDescriptionLabelHeight;
    descriptionLabelFrame.origin.x = descriptionOriginX;
    descriptionLabelFrame.origin.y = kDescriptionVerticalPadding;
    descriptionLabelFrame.size.width = CGRectGetMaxX(self.selectedViewDescriptionContainer.bounds) - kHorizontalPadding - descriptionOriginX;
    self.selectedViewDescriptionLabel.frame = descriptionLabelFrame;
}


#pragma mark - Setter Overrides

- (void)setToolbarItems:(NSArray<FLEXExplorerToolbarItem *> *)toolbarItems {
    if (_toolbarItems == toolbarItems) {
        return;
    }
    
    // Remove old toolbar items, if any
    for (FLEXExplorerToolbarItem *item in _toolbarItems) {
        [item.currentItem removeFromSuperview];
    }
    
    // Trim to 5 items if necessary
    if (toolbarItems.count > 5) {
        toolbarItems = [toolbarItems subarrayWithRange:NSMakeRange(0, 5)];
    }

    for (FLEXExplorerToolbarItem *item in toolbarItems) {
        [self addSubview:item.currentItem];
    }

    _toolbarItems = toolbarItems.copy;

    // Lay out new items
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedViewOverlayColor:(UIColor *)selectedViewOverlayColor {
    if (![_selectedViewOverlayColor isEqual:selectedViewOverlayColor]) {
        _selectedViewOverlayColor = selectedViewOverlayColor;
        self.selectedViewColorIndicator.backgroundColor = selectedViewOverlayColor;
    }
}

- (void)setSelectedViewDescription:(NSString *)selectedViewDescription {
    if (![_selectedViewDescription isEqual:selectedViewDescription]) {
        _selectedViewDescription = selectedViewDescription;
        self.selectedViewDescriptionLabel.text = selectedViewDescription;
        BOOL showDescription = selectedViewDescription.length > 0;
        self.selectedViewDescriptionContainer.hidden = !showDescription;
    }
}


#pragma mark - Sizing Convenience Methods

+ (UIFont *)descriptionLabelFont {
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)toolbarItemHeight {
    return 44.0;
}

+ (CGFloat)dragHandleWidth {
    return FLEXResources.dragHandle.size.width;
}

+ (CGFloat)descriptionLabelHeight {
    return ceil([[self descriptionLabelFont] lineHeight]);
}

+ (CGFloat)descriptionVerticalPadding {
    return 2.0;
}

+ (CGFloat)descriptionContainerHeight {
    return [self descriptionVerticalPadding] * 2.0 + [self descriptionLabelHeight];
}

+ (CGFloat)selectedViewColorIndicatorDiameter {
    return ceil([self descriptionLabelHeight] / 2.0);
}

+ (CGFloat)horizontalPadding {
    return 11.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = 0.0;
    height += [[self class] toolbarItemHeight];
    height += [[self class] descriptionContainerHeight];
    return CGSizeMake(size.width, height);
}

- (CGRect)safeArea {
    CGRect safeArea = self.bounds;
    if (@available(iOS 11.0, *)) {
        safeArea = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
    }

    return safeArea;
}

@end
