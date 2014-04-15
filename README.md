jeapie-ios
==========

#### Instructions for install Jeapie sdk

1. You must register in service Jeapie https://app.jeapie.com/register
2. Copy your app_key and app_secret from Settings -> Api keys
3. Copy files from folder "sdk" into your mobile project
4. Add a couple of lines in AppDelegate.m :

```objectivec
#import "AppDelegate.h"

//import jeapie sdk
#import "Jeapie.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //start jeapie with landings
    [Jeapie startSessionWithKey:@"APP_KEY"  secret:@"APP_SECRET" needLandings:YES launchOptions:launchOptions];
    
    //Enable Geolocation
    [Jeapie enableGeolocation];

    // enable push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(
        UIRemoteNotificationTypeBadge | 
        UIRemoteNotificationTypeSound | 
        UIRemoteNotificationTypeAlert
    )];
    
    return YES;
}

// register apns device token
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [Jeapie didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

// track push opens
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [Jeapie didReceiveRemoteNotification:userInfo];
}
```

#### Other commands
1) Set device alias
```objectivec
[Jeapie alias:@"test@jeapie.com"];
```
2) Set array of tags
```objectivec
NSArray *tagsArray = [NSArray arrayWithObjects:@"test", @"test2", @"apple", nil];
[Jeapie tags:tagsArray];
```
3) Add tag to set
```objectivec
[Jeapie addTag:@"new tag"];
```
4) Remove tag from set
```objectivec
[Jeapie removeTag:@"test2"];
```
5) Remove all tags
```objectivec
[Jeapie removeTags];
```
