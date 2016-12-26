//
//  LPWallpaperObserver.m
//  Menubar Toggle
//
//  Created by Игорь Савельев on 27/09/15.
//  Copyright © 2015 Leonspok. All rights reserved.
//

#import "LPWallpaperObserver.h"
#import "NSImage+Luminance.h"

@import AppKit;

NSString *const kThemeChangedToDarkNotification = @"ThemeChangedToDarkNotification";
NSString *const kThemeChangedToLightNotification = @"ThemeChangedToLightNotification";

static NSString *const kAutoSwithOSXThemeKey = @"autoSwithOSXTheme";
static NSString *const kImagesLuminanceInfoPlistFileName = @"imagesLuminance.plist";

@implementation LPWallpaperObserver {
    NSString *applicationSupportFolder;
    NSTimer *observingTimer;
}

+ (instancetype)sharedObserver {
    static LPWallpaperObserver *__sharedObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedObserver = [[LPWallpaperObserver alloc] init];
    });
    return __sharedObserver;
}

- (id)init {
    self = [super init];
    if (self) {
        [self updatePaths];
        
        if (self.autoSwithOSXTheme) {
            [self setAutoSwithOSXTheme:self.autoSwithOSXTheme];
        }
    }
    return self;
}

- (void)updatePaths {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    applicationSupportFolder = [[paths firstObject] stringByAppendingPathComponent:@"Menubar Toggle"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark Getters and Setters

- (BOOL)autoSwithOSXTheme {
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        return NO;
    }
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAutoSwithOSXThemeKey];
}

- (void)setAutoSwithOSXTheme:(BOOL)autoSwithOSXTheme {
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        autoSwithOSXTheme = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:autoSwithOSXTheme forKey:kAutoSwithOSXThemeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!autoSwithOSXTheme) {
        [self resetTheme];
        [observingTimer invalidate];
        observingTimer = nil;
    } else {
        [self setSuitableThemeIfNeeded];
        dispatch_async(dispatch_get_main_queue(), ^{
            observingTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(setSuitableThemeIfNeeded) userInfo:nil repeats:YES];
        });
    }
}

- (BOOL)isDarkModeEnabled {
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"get_theme" withExtension:@"txt"] error:nil];
	NSAppleEventDescriptor *dsc = [script executeAndReturnError:nil];
	return dsc.booleanValue;
}

- (void)resetTheme {
	[self setDarkTheme:NO];
}

#pragma mark Wallpapers Observing

- (BOOL)themeShouldBeDark {
    CGFloat averageLuminance = 0.0f;
    for (NSScreen *screen in [NSScreen screens]) {
        NSString *path = [[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:screen] path];
        averageLuminance += [self luminanceForImageWithPath:path];
    }
    if ([NSScreen screens].count > 0) {
        averageLuminance = averageLuminance/[NSScreen screens].count;
    }
    return averageLuminance < 0.375;
}

- (void)setDarkTheme:(BOOL)dark {
	NSString *scriptSource = [[NSString alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"change_theme" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil];
	scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"<mode>" withString:(dark? @"true" : @"false")];
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
	[script executeAndReturnError:nil];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (dark) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kThemeChangedToDarkNotification object:nil];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:kThemeChangedToLightNotification object:nil];
		}
	});
}

- (void)setSuitableThemeIfNeeded {
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL shouldBeDark = [self themeShouldBeDark];
        BOOL darkModeEnabled = [self isDarkModeEnabled];
        if (shouldBeDark != darkModeEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setDarkTheme:shouldBeDark];
            });
        }
    });
}

#pragma mark Images Managing

- (CGFloat)luminanceForImageWithPath:(NSString *)path {
    NSString *plistFilePath = [applicationSupportFolder stringByAppendingPathComponent:kImagesLuminanceInfoPlistFileName];
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFilePath];
    
    if ([info objectForKey:path]) {
        return [[info objectForKey:path] doubleValue];
    }
    
    if (!info) {
        info = [NSMutableDictionary dictionary];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
    if (image) {
        CGFloat luminance = image.luminance;
        [info setObject:@(luminance) forKey:path];
        [info writeToFile:plistFilePath atomically:YES];
        return luminance;
    } else {
        return 0.5f;
    }
}

@end
