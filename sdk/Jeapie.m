//
//  Jeapie.m
//  Greenlamp
//
//  Created by Amoneron on 03.03.14.
//  Copyright (c) 2014 Alexander Murzanaev. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error Jeapie should be compiled with ARC enabled.
#endif

#import "Jeapie.h"

#define VERSION_MAJOR   1
#define VERSION_MINOR   0

#define SEND_INTERVAL   60

#define JPLog(_MESSAGE_) [Jeapie JPLog:_MESSAGE_]

static NSString *key_ = nil;
static NSString *secret_ = nil;
static NSString *server_ = @"http://%@:%@@app.jeapie.com:1337/api/v1/mobile/track?data=%@";
static NSMutableArray *queue_ = nil;
static NSString *uuid_ = nil;
static NSTimer *autoSendTimer_ = nil;
static NSDate *sessionStart_ = nil;
static UIBackgroundTaskIdentifier backgroundTaskIdentifier_;

@interface NSData (Base64)

- (NSString *)base64EncodedString;

@end

@interface JPRequest : NSObject {
    
    NSMutableData *_receivedData;
    id _target;
    SEL _action;
    NSURLConnection *_connection;
    
}

@property (strong, nonatomic) NSMutableURLRequest *urlRequest;
@property (strong, nonatomic) NSMutableArray *postParams;

+(id)requestWithURL:(NSString *)url post:(NSDictionary *)post target:(id)target action:(SEL)action;

-(id)initWithURL:(NSString *)url post:(NSDictionary *)post target:(id)target action:(SEL)action;

-(void)cancel;

@end

@interface Jeapie () {
    
}

@end

@implementation Jeapie

+(void)JPLog:(NSString *)message
{
    NSLog(@"Jeapie v.%d.%d: %@", VERSION_MAJOR, VERSION_MINOR, message);
}

+(void)startSessionWithKey:(NSString *)key secret:(NSString *)secret launchOptions:(NSDictionary *)launchOptions
{
    // check for correct values
    if (key == nil || key.length < 10 || secret == nil || secret.length < 10) {
        JPLog(@"Incorrect key or secret.");
        return;
    }
    
    key_ = key;
    secret_ = secret;
    uuid_ = [Jeapie obtainUUID];
    
    // init queue
    queue_ = [[NSMutableArray alloc] init];
    [Jeapie pullQueue];
    
    // register events
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // remote notifications
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo)
        [Jeapie didReceiveRemoteNotification:userInfo];
    
    JPLog(@"Session started.");
}

+(void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSDictionary *m_id = [userInfo objectForKey:@"m_id"];
    if (m_id != nil)
        [Jeapie addEntity:@{ @"type" : @"push", @"m_id" : m_id, @"time" : [Jeapie currentTime] }];
}

+(NSString *)currentTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    [Jeapie addEntity:@{ @"token" : token }];
}

+(NSString *)obtainUUID
{
    NSString *identifier = nil;
    
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        identifier = [uuid UUIDString];
    }
    
    if (identifier == nil && NSClassFromString(@"UIDevice"))
        identifier = [[UIDevice currentDevice].identifierForVendor UUIDString];
    
    if (identifier == nil) {
        // try to load saved identifier
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"jeapie_v_%d_%d_uuid.plist", VERSION_MAJOR, VERSION_MINOR]];
        NSMutableDictionary *identifierDictionary = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            @try {
                identifierDictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            }
            @catch (NSException *exception) {
                JPLog(@"Pulling identifier error.");
            }
        }
        if (identifierDictionary)
            identifier = identifierDictionary[@"uuid"];
        else {
            identifier = [[NSUUID UUID] UUIDString];
            // save it to file
            identifierDictionary = [[NSMutableDictionary alloc] init];
            [identifierDictionary setObject:identifier forKey:@"uuid"];
            if (![NSKeyedArchiver archiveRootObject:identifierDictionary toFile:filePath]) {
                JPLog(@"Pushing identifier error.");
            }
        }
    }
    
    return identifier;
}

+(void)tags:(NSArray *)tags
{
    [Jeapie addEntity:@{ @"tags" : tags }];
}

+(void)addTag:(NSString *)tag
{
    [Jeapie addEntity:@{ @"add_tag": tag}];
}

+(void)removeTag:(NSString *)tag
{
    [Jeapie addEntity:@{ @"remove_tag": tag}];
}

+(void)removeTags
{
    [Jeapie addEntity:@{ @"remove_tags": @"true"}];
}

+(void)alias:(NSString *)alias
{
    [Jeapie addEntity:@{ @"alias": alias}];
}

#pragma mark - System notifications

+(void)applicationDidBecomeActive:(NSNotification *)notification
{
    [Jeapie startAutoSendTimer];
    sessionStart_ = [NSDate date];
    
    // open event
    [Jeapie addEntity:@{ @"type" : @"open", @"time" : [Jeapie currentTime] }];
}

+(void)applicationWillResignActive:(NSNotification *)notification
{
    [Jeapie stopAutoSendTimer];
    if (sessionStart_ != nil) {
        [Jeapie addEntity:@{ @"session" : [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:sessionStart_]] }];
        sessionStart_ = nil;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Jeapie pushQueue];
    });
}

+(void)applicationDidEnterBackground:(NSNotificationCenter *)notification
{
    backgroundTaskIdentifier_ = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier_];
        backgroundTaskIdentifier_ = UIBackgroundTaskInvalid;
    }];
    
    [Jeapie sendQueue];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Jeapie pushQueue];
    });
}

+(void)applicationWillTerminate:(NSNotification *)notification
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Jeapie pushQueue];
    });
}

#pragma mark - Queue management

+(NSString *)queueFilePath
{
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"jeapie_v_%d_%d.plist", VERSION_MAJOR, VERSION_MINOR]];
}

+(void)pullQueue
{
    NSString *filePath = [Jeapie queueFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        @try {
            queue_ = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        }
        @catch (NSException *exception) {
            JPLog(@"Pulling queue error.");
        }
    }
}

+(void)pushQueue
{
    if (![NSKeyedArchiver archiveRootObject:queue_ toFile:[Jeapie queueFilePath]]) {
        JPLog(@"Pushing queue error.");
    }
}

+(void)addEntity:(NSDictionary *)entity
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:entity];
    [dictionary setObject:uuid_ forKey:@"uuid"];
    [queue_ addObject:[dictionary dictionaryWithValuesForKeys:[dictionary allKeys]]];
}

+(void)clearQueue
{
    [queue_ removeAllObjects];
    [Jeapie pushQueue];
}

#pragma mark - Sending

+(void)startAutoSendTimer
{
    [Jeapie stopAutoSendTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        autoSendTimer_ = [NSTimer scheduledTimerWithTimeInterval:SEND_INTERVAL target:self selector:@selector(sendQueue) userInfo:nil repeats:YES];
    });
}

+(void)stopAutoSendTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (autoSendTimer_) [autoSendTimer_ invalidate];
        autoSendTimer_ = nil;
    });
}

+(void)sendQueue
{
    // deviceInfo
    NSMutableDictionary *deviceInfo = [[NSMutableDictionary alloc] init];
    UIDevice *device = [UIDevice currentDevice];
    [deviceInfo setObject:uuid_ forKey:@"uuid"];
    [deviceInfo setObject:[NSString stringWithFormat:@"%d.%d", VERSION_MAJOR, VERSION_MINOR] forKey:@"lib_version"];
    [deviceInfo setValue:[device systemVersion] forKey:@"os_version"];
    [deviceInfo setValue:@"iOS" forKey:@"os"];
    [deviceInfo setValue:@"Apple" forKey:@"manufacturer"];
    [deviceInfo setValue:[device model] forKey:@"model"];
    //    [deviceInfo setValue:[device localizedModel] forKey:@"mp_device_model"];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    [deviceInfo setValue:[NSNumber numberWithFloat:screenRect.size.height] forKey:@"screen_height"];
    [deviceInfo setValue:[NSNumber numberWithFloat:screenRect.size.width] forKey:@"screen_width"];
    
    // prepare JSON
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:queue_];
    [array insertObject:deviceInfo atIndex:0];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
    
    // check
    if (jsonData == nil) {
        JPLog(@"Error JSON encoding.");
        return;
    }
    
    // convert to base64 & send
    NSString *requestURL = [NSString stringWithFormat:server_, key_, secret_, [jsonData base64EncodedString]];
    
    [JPRequest requestWithURL:requestURL post:nil target:self action:@selector(dataDidSend:)];
}

+(void)dataDidSend:(NSString *)response
{
    NSLog(@"Data did send: %@", response);
    // clear data
    [Jeapie clearQueue];
}


@end






#pragma mark - JPRequest class

@implementation JPRequest

+(id)requestWithURL:(NSString *)url post:(NSDictionary *)post target:(id)target action:(SEL)action
{
    return [[JPRequest alloc] initWithURL:url post:post target:target action:action];
}

-(id)initWithURL:(NSString *)url post:(NSDictionary *)post target:(id)target action:(SEL)action
{
    if ((self = [super init])) {
        
        _postParams = nil;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20 /* seconds */];
        if (post) {
            [request setHTTPMethod:@"POST"];
            self.postParams = [[NSMutableArray alloc] init];
            NSArray *keys = [post allKeys];
            for (NSString *key in keys)
                [self.postParams addObject:[NSString stringWithFormat:@"%@=%@", key, [post objectForKey:key]]];
            [request setHTTPBody:[[_postParams componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        self.urlRequest = request;
        
        // create the connection with the request
        // and start loading the data
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (_connection) {
            _receivedData = [[NSMutableData alloc] init];
            _target = target;
            _action = action;
        }
        else {
            _receivedData = nil;
            self = nil;
        }
    }
    return self;
}

// to ignore cache
-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

// working with https
-(BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    [_receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // just do nothing, data won't be cleared
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (_target && _action && [_target respondsToSelector:_action]) {
        NSString *string = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_action withObject:string];
#pragma clang diagnostic pop
    }
}

-(void)cancel
{
    [_connection cancel];
}

@end






#pragma mark - NSData + base64 category

//
// Mapping from 6 bit pattern to ASCII character.
//
static unsigned char base64EncodeLookup[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

//
// Fundamental sizes of the binary and base64 encode/decode units in bytes
//
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

char *Base64Encode(const void *buffer, size_t length, bool separateLines, size_t *outputLength)
{
	const unsigned char *inputBuffer = (const unsigned char *)buffer;
    
#define MAX_NUM_PADDING_CHARS 2
#define OUTPUT_LINE_LENGTH 64
#define INPUT_LINE_LENGTH ((OUTPUT_LINE_LENGTH / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE)
#define CR_LF_SIZE 2
    
	//
	// Byte accurate calculation of final buffer size
	//
	size_t outputBufferSize =
    ((length / BINARY_UNIT_SIZE)
     + ((length % BINARY_UNIT_SIZE) ? 1 : 0))
    * BASE64_UNIT_SIZE;
	if (separateLines) {
		outputBufferSize +=
        (outputBufferSize / OUTPUT_LINE_LENGTH) * CR_LF_SIZE;
	}
    
	//
	// Include space for a terminating zero
	//
	outputBufferSize += 1;
    
	//
	// Allocate the output buffer
	//
	char *outputBuffer = (char *)malloc(outputBufferSize);
	if (!outputBuffer) {
		return NULL;
	}
    
	size_t i = 0;
	size_t j = 0;
	const size_t lineLength = separateLines ? INPUT_LINE_LENGTH : length;
	size_t lineEnd = lineLength;
    
	while (true)
	{
		if (lineEnd > length) {
			lineEnd = length;
		}
        
		for (; i + BINARY_UNIT_SIZE - 1 < lineEnd; i += BINARY_UNIT_SIZE) {
			//
			// Inner loop: turn 48 bytes into 64 base64 characters
			//
			outputBuffer[j++] = (char)base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
			outputBuffer[j++] = (char)base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                                         | ((inputBuffer[i + 1] & 0xF0) >> 4)];
			outputBuffer[j++] = (char)base64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)
                                                         | ((inputBuffer[i + 2] & 0xC0) >> 6)];
			outputBuffer[j++] = (char)base64EncodeLookup[inputBuffer[i + 2] & 0x3F];
		}
        
		if (lineEnd == length) {
			break;
		}
        
		//
		// Add the newline
		//
		outputBuffer[j++] = '\r';
		outputBuffer[j++] = '\n';
		lineEnd += lineLength;
	}
    
	if (i + 1 < length) {
		//
		// Handle the single '=' case
		//
		outputBuffer[j++] = (char)base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = (char)base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                                     | ((inputBuffer[i + 1] & 0xF0) >> 4)];
		outputBuffer[j++] = (char)base64EncodeLookup[(inputBuffer[i + 1] & 0x0F) << 2];
		outputBuffer[j++] =	'=';
	}
	else if (i < length) {
		//
		// Handle the double '=' case
		//
		outputBuffer[j++] = (char)base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = (char)base64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
		outputBuffer[j++] = '=';
		outputBuffer[j++] = '=';
	}
	outputBuffer[j] = 0;
    
	//
	// Set the output length and return the buffer
	//
	if (outputLength) {
		*outputLength = j;
	}
	return outputBuffer;
}

@implementation NSData (Base64)

- (NSString *)base64EncodedString
{
	size_t outputLength = 0;
	char *outputBuffer =
    Base64Encode([self bytes], [self length], false, &outputLength);
    
	NSString *result = [[NSString alloc] initWithBytes:outputBuffer length:outputLength encoding:NSASCIIStringEncoding];
	free(outputBuffer);
	return result;
}

@end
