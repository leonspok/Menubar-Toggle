//
//  LPWallpaperObserver.h
//  Menubar Toggle
//
//  Created by Игорь Савельев on 27/09/15.
//  Copyright © 2015 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kThemeChangedToDarkNotification;
extern NSString *const kThemeChangedToLightNotification;

@interface LPWallpaperObserver : NSObject

@property (nonatomic, assign) BOOL autoSwithOSXTheme;
@property (nonatomic, assign, readonly, getter=isDarkModeEnabled) BOOL darkModeEnabled;

+ (instancetype)sharedObserver;

- (void)setSuitableThemeIfNeeded;
- (void)resetTheme;

@end
