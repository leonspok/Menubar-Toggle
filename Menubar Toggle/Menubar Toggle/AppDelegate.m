//
//  AppDelegate.m
//  Menubar Toggle
//
//  Created by Игорь Савельев on 27/09/15.
//  Copyright © 2015 Leonspok. All rights reserved.
//

#import "AppDelegate.h"
#import "LPWallpaperObserver.h"

@interface AppDelegate ()
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *enabledItem;
@property (weak) IBOutlet NSMenuItem *startAtLoginItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.title = @"";
    _statusItem.toolTip = @"Menubar Toggle";
    _statusItem.menu = self.menu;
    
    if ([[LPWallpaperObserver sharedObserver] isDarkModeEnabled]) {
        [self setMenuBarDarkThemeLogo];
    } else {
        [self setMenuBarLightThemeLogo];
    }
    
    [self.enabledItem setState:[LPWallpaperObserver sharedObserver].autoSwithOSXTheme? NSOnState : NSOffState];
    [self.startAtLoginItem setState:[self willStartAtLogin]? NSOnState : NSOffState];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setMenuBarDarkThemeLogo) name:kThemeChangedToDarkNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setMenuBarLightThemeLogo) name:kThemeChangedToLightNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)setMenuBarDarkThemeLogo {
    NSImage *menuBarLogo = [NSImage imageNamed:@"menubarLogoDarkThemeEnabled"];
    [menuBarLogo setTemplate:YES];
    _statusItem.image = menuBarLogo;
}

- (void)setMenuBarLightThemeLogo {
    NSImage *menuBarLogo = [NSImage imageNamed:@"menubarLogoLightThemeEnabled"];
    [menuBarLogo setTemplate:YES];
    _statusItem.image = menuBarLogo;
}

- (IBAction)toggleEnabled:(id)sender {
    [[LPWallpaperObserver sharedObserver] setAutoSwithOSXTheme:![LPWallpaperObserver sharedObserver].autoSwithOSXTheme];
    [self.enabledItem setState:[LPWallpaperObserver sharedObserver].autoSwithOSXTheme? NSOnState : NSOffState];
}

- (BOOL)willStartAtLogin {
    BOOL foundIt = NO;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = (__bridge NSArray *)(LSSharedFileListCopySnapshot(loginItems, &seed));
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            NSURL *URL = (__bridge NSURL *)(LSSharedFileListItemCopyResolvedURL(item, resolutionFlags, NULL));
            foundIt = [URL isEqual:[[NSBundle mainBundle] bundleURL]];
            if (foundIt) {
                break;
            }
        }
        CFRelease(loginItems);
    }
    return foundIt;
}

- (IBAction)toggleStartAtLogin:(id)sender {
    LSSharedFileListItemRef existingItem = NULL;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = (__bridge NSArray *)(LSSharedFileListCopySnapshot(loginItems, &seed));
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            NSURL *URL = (__bridge NSURL *)(LSSharedFileListItemCopyResolvedURL(item, resolutionFlags, NULL));
            BOOL foundIt = [URL isEqual:[[NSBundle mainBundle] bundleURL]];
            if (foundIt) {
                existingItem = item;
                break;
            }
        }
        
        if (existingItem != NULL) {
            LSSharedFileListItemRemove(loginItems, existingItem);
        } else {
            LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
                                          NULL, NULL, (__bridge CFURLRef)[[NSBundle mainBundle] bundleURL], NULL, NULL);
        }
        
        CFRelease(loginItems);
    }
    
    [self.startAtLoginItem setState:[self willStartAtLogin]? NSOnState : NSOffState];
}

@end
