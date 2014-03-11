//
//  Jeapie.h
//  Greenlamp
//
//  Created by Amoneron on 03.03.14.
//  Copyright (c) 2014 Alexander Murzanaev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Jeapie : NSObject

+(void)startSessionWithKey:(NSString *)key secret:(NSString *)secret launchOptions:(NSDictionary *)launchOptions;

+(void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

+(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;

+(void)tags:(NSArray *)tags;

+(void)addTag:(NSString *)tag;

+(void)removeTag:(NSString *)tag;

+(void)removeTags;

+(void)alias:(NSString *)alias;

@end
