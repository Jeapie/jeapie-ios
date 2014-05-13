jeapie-ios
==========

> <b>WARNING!</b> Jeapie sdk is only for <b>iOs version 6+</b>

#### Installation instructions for Jeapie sdk

> Please, before you install sdk make sure that you are familiar with documentation about iPhone push notifications:
>  [Apple Push Notification Service] (https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ApplePushService.html)
>
> Also you need to understand the basics of <b>Objective-c</b> programming language and <b>iPhone</b> mobile development

---

#### First part (Get push notification certificates)
* You have to visit in Developer center [Certificates, Identifiers & Profiles] (https://developer.apple.com/account/ios/certificate/certificateList.action) and create certificates
* Convert your certificates to *.pem formats

#### Second part (Create account in Jeapie)

* You should register in Jeapie service  https://app.jeapie.com/register
* Copy your <b>APP_KEY</b> and <b>APP_SECRET</b> from Settings -> Api keys (In Jeapie Dashboard)
* Copy sdk dir from github to your iPhone project
* In Jeapie dashboard -> Settings -> Push settings you need uploud your certificates

> <b>Warning!</b> If you create in Jeapie dashboard app with <b>"development"</b> <i>production status</i> you have to upload <b>test</b> push notifications certificate.<br>
> If you create in Jeapie dashboard app with <b>"production"</b> <i>production status</i> you have to upload   <b>producation</b> push notifications certificate.
>
> Otherwise, push notifications will not be sent


#### Third part (Setting Jeapie in iPhone project)


* Add lib and frameworks to project (Project -> General -> Linked Frameworks and Libraries)
![alt text](http://content.screencast.com/users/skiff223/folders/Jing/media/53b6f32b-86fe-4830-bd1b-cdb63d9ba906/00000031.png "Linked Frameworks and Libraries")
* Add "-ObjC" linker flag to "Other Linker Flags" in Build Settings
![alt text](http://content.screencast.com/users/skiff223/folders/Jing/media/4ed05e39-c539-4971-8c07-6bdda7d4d9b8/00000033.png "Other Linker Flags")
* Add a couple of lines in AppDelegate.m :

```objectivec
#import "AppDelegate.h"

//import jeapie sdk
#import "Jeapie.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init Jeapie
    // Replace APP_KEY, APP_SECRET on your value
    [Jeapie startSessionWithKey:@"APP_KEY"  secret:@"APP_SECRET" needLandings:YES launchOptions:launchOptions];
    
    //Enable indexing Geolocation (works only if your have geolocation permissions!)
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

* For register in-app purchases

```objectivec
[Jeapie registerInAppPurchaseWithProduct:product];
```
or
```objectivec
[Jeapie registerInAppPurchaseWithIdentifier:identifier price:price currency:currency];
```

* For show landings (in development)

```objectivec
[Jeapie showLandingWithDelegate:<JeapieDelegate>];
```
* For show fixed landings (in development

```objectivec
[Jeapie showFixedLanding:@"FIXED_LANDING_ID" withDelegate:<JeapieDelegate>];
```


#### Other commands
* Set device alias
```objectivec
[Jeapie alias:@"test@jeapie.com"];
```
* Set array of tags
```objectivec
NSArray *tagsArray = [NSArray arrayWithObjects:@"test", @"test2", @"apple", nil];
[Jeapie tags:tagsArray];
```
* Add tag to set
```objectivec
[Jeapie addTag:@"new tag"];
```
* Remove tag from set
```objectivec
[Jeapie removeTag:@"test2"];
```
* Remove all tags
```objectivec
[Jeapie removeTags];
```
