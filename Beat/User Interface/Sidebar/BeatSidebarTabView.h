//
//  BeatSidebarTabView.h
//  Beat
//
//  Created by Lauri-Matti Parppei on 22.10.2021.
//  Copyright © 2021 KAPITAN!. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BeatReloadableView <NSObject>
- (void)reload;
@end

@interface BeatSidebarTabView : NSTabViewItem
@property (nonatomic, weak) IBOutlet id reloadableView;
@end

NS_ASSUME_NONNULL_END