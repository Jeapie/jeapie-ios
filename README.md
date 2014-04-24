jeapie-ios
==========

#### Instructions for install Jeapie sdk

1. You must register in service Jeapie https://app.jeapie.com/register
2. Copy your app_key and app_secret from Settings -> Api keys
3. Copy files from folder "sdk" into your mobile project
4. Add lib and frameworks to project (Project -> General -> Linked Frameworks and Libraries)
![alt text](http://content.screencast.com/users/skiff223/folders/Jing/media/53b6f32b-86fe-4830-bd1b-cdb63d9ba906/00000031.png "Linked Frameworks and Libraries")
4. Add "-ObjC" linker flag to "Other Linker Flags" in Build Settings
![alt text](http://content.screencast.com/users/skiff223/folders/Jing/media/4ed05e39-c539-4971-8c07-6bdda7d4d9b8/00000033.png "Other Linker Flags")
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

6.. For register in-app purchases

```objectivec
[Jeapie registerInAppPurchaseWithProduct:product];
```
or
```objectivec
[Jeapie registerInAppPurchaseWithIdentifier:identifier price:price currency:currency];
```

7.. For show landings

```objectivec
[Jeapie showLandingWithDelegate:<JeapieDelegate>];
```
8.. For show fixed landings

```objectivec
[Jeapie showFixedLanding:@"FIXED_LANDING_ID" withDelegate:<JeapieDelegate>];
```
(Detail in Jeapie docs)



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
