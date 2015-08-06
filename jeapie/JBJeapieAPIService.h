//
//  JBJeapieAPIService.h
//  Jeapiesdk
//
//  Created by Artem Shyianov on 7/20/15.
//  Copyright (c) 2015 Artem Shyianov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^JBInitializationHandler)(BOOL succses);

typedef void (^JBEventsHandler)(NSString *event, id json);

@interface JBJeapieAPIService : NSObject

- (void)pushOpen:(NSString *)pushId;
- (void)subscribe;
- (void)unsubscribe;
- (void)deliver:(NSString *)pushId;
- (void)setAlias:(NSString *)alias;
- (void)setPhone:(NSString *)phone;
- (void)setEmail:(NSString *)email;
- (void)addTag:(NSString *)tag;
- (void)setLocation:(NSArray *)coordinates;
- (void)removeTag:(NSString *)tag;
- (void)removeTags;

// Delegate
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)data;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

// Location
- (void)enableGeolocationWithInterval:(NSTimeInterval)interval;
- (void)disableGeolocation;

@property (nonatomic, copy) JBEventsHandler eventsHandler;
@property (nonatomic, copy) JBInitializationHandler initializationHandler;

+ (instancetype)sharedInstance;

@end
