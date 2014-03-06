jeapie-ios
==========

Jeapie sdk for ios

1. You must register in service Jeapie https://app.jeapie.com/register
2. Copy your app_key and app_secret in Settings -> Api keys
3. Copy files from folder "sdk" into your mobile project
4. Add a couple of lines in AppDelegate.m :

```objectivec
#import "AppDelegate.h"

//import jeapie sdk
#import "Jeapie.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //start jeapie
    [Jeapie startSessionWithKey:@"APP_KEY" secret:@"APP_SECRET" launchOptions:launchOptions];

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
