//
//  Jeapie.h
//  Jeapie
//
//  Created by Amoneron on 03.03.14.
//  Copyright (c) 2014 Alexander Murzanaev. All rights reserved.
//

// These frameworks should be added to project
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <StoreKit/StoreKit.h>

#pragma mark - Jeapie Delegate Protocol

@protocol JeapieDelegate <NSObject>

@optional

-(void)landingDidAppear;
/**
 Returns some data if the link tapped by user contains it. Returns nil otherwise.
 */
-(void)landingDidClose:(NSDictionary *)landingData;

@end


#pragma mark - Jeapie

@interface Jeapie : NSObject <UIWebViewDelegate, CLLocationManagerDelegate>

// Itegration methods

/**
 Initialize Jeapie by invoking this from AppDelegate's application:didFinishLaunchingWithOptions:
 @param key
        Key provided by Jeapie.
 @param secret
        Secret value provided by Jeapie.
 @param needLandings
        Set to YES if you indent to use landings in your app (really cool stuff!).
 @param launchOptions
        Pass didFinishLaunchingWithOptions: param.
 */
+(void)startSessionWithKey:(NSString *)key secret:(NSString *)secret needLandings:(BOOL)needLandings launchOptions:(NSDictionary *)launchOptions;

+(void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

+(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;


// Events

+(void)tags:(NSArray *)tags;

+(void)addTag:(NSString *)tag;

+(void)removeTag:(NSString *)tag;

+(void)removeTags;

+(void)alias:(NSString *)alias;

+(void)registerInAppPurchaseWithProduct:(SKProduct *)product;

+(void)registerInAppPurchaseWithIdentifier:(NSString *)identifier price:(float)price currency:(NSString *)currency;


// Landings

+(BOOL)hasLandings;

+(void)showLandingWithDelegate:(id <JeapieDelegate>)delegate;

+(NSUInteger)fixedLandingsCount;

+(NSArray *)fixedLandingsIdentifiers;

+(void)showFixedLanding:(NSString *)identifier withDelegate:(id <JeapieDelegate>)delegate;


// Other stuff

/**
 Enables geolocation tracking. It works if geolocation service is explicitly allowed for this application by user only.
 */
+(void)enableGeolocation;

+(void)resetBadge;

@end


