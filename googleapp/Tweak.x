#include <Foundation/Foundation.h>
#import <execinfo.h>

/// First Use Registration

@interface YTDeviceAuth : NSObject
{
    NSString *deviceId_;
    NSData *deviceKey_;
}
- (id)initWithDeviceId:(id)fp8 deviceKey:(id)fp12;
@end


@interface YTDeviceAuthorizer : NSObject
{
    NSMutableArray *requestQueue_;
    NSString *developerKey_;
    YTDeviceAuth *deviceAuth_;
    NSString *secret_;
    NSUserDefaults *storage_;
    NSString *uniqueInstallationID_;
}
- (void)saveRegistrationToStorage;
- (void)performRequestQueueWithError:(id)fp8;
+ (id)decryptDeviceKey:(id)fp8 secret:(id)fp12;
@end


// Debugging tools :TM:
static void *StackTrace(NSString* forThing) {
	void *callstack[128];
	int frames = backtrace(callstack, 128);
	char **symbols = backtrace_symbols(callstack, frames);
	NSMutableString *callstackString = [NSMutableString stringWithFormat:@"[Debugging] Callstack for %@:\n", forThing];
	for (int i = 1; i < frames; i++) {
		[callstackString appendFormat:@"%s\n", symbols[i]];
	}
	NSLog(@"%@", callstackString);
	
	free(symbols);
	return 0;
}

%hook YTDeviceAuthorizer


// youtube tries to register the device before using. This is useless to us since we are rewriting most of it. It would be best to eventually make this function never need to be called
// Actually, if i'm guessing correctly, this is how it does logged out personalized recommendations.1
-(void)beginDeviceRegistration {
	id decryptedSecret = [%c(YTDeviceAuthorizer) decryptDeviceKey:@"ULxlVAAVMhZ2GeqZA/X1GgqEEIP1ibcd3S+42pkWfmk=" secret:[self valueForKey:@"secret_"]];
    YTDeviceAuth *deviceAuth = [[%c(YTDeviceAuth) alloc] initWithDeviceId:@"dmVyeSBzZWN1cmUgaWQ=" deviceKey:decryptedSecret];
	[self setValue:[deviceAuth retain] forKey:@"deviceAuth_"];
    if (deviceAuth)
    {
      [self saveRegistrationToStorage];
      [self performRequestQueueWithError:0];
      return;
    }
	[self performRequestQueueWithError:0]; // a3 in codebase but who's counting
}

%end


/// feeds

%hook YTGDataRequest

+ (id)requestForChannelsWithStandardFeed:(int)fp8 {
	NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
	return %orig;
}

+ (id)requestWithURL:(id)fp8 {
	%log;
	StackTrace(@"requestWithURL");
	return %orig;
}


// called by -[YTGuideFeedController updateViews]
+ (id)requestForCategoriesWithLanguageCode:(id)fp8 {
	%log;


	return %orig;
}


%end

%hook YTGDataService

struct BlockLiteral {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    void *descriptor;
};

- (void)makeCategoriesRequest:(id)arg1 responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    struct BlockLiteral *blk = (__bridge struct BlockLiteral *)responseBlock;
    NSLog(@"[BLOCK] invoke = %p, descriptor = %p", blk->invoke, blk->descriptor);
    %orig;
}

%end

// -[YTCategoryParser parseElement:error:]
// -[YTGuideFeedController handleEntries: is where categories are requested
//-[YTFeedController maybeMakeNextRequest]

%hook YTCategoryParser
- (id)parseElement:(id)fp8 error:(id *)fp12 {
	%log;
	StackTrace(@"YTCategoryParser");
	return %orig;
}

%end


// %hook YTFeedController

// - (void)addEntriesFromArray:(NSArray *)newEntries
// {
//     for (id entry in newEntries) {
//         // Skip duplicates
//         // if ([self.uniqueEntries containsObject:entry]) {
//         //     continue;
//         // }
        
// 		NSLog(@"entry -> %@", entry);
//         // New entry - add it to our data structures
//         // NSNumber *newIndex = @(self.entries.count);
//         // [self.indices setObject:newIndex forKey:entry];
//         // [self.entries addObject:entry];
//         // [self.uniqueEntries addObject:entry];
//     }

// 	return %orig;
    
//     // [self.feedView reload];
// }
// %end

// TO LOOK AT
// -[YTVideoParser parseElement:error:]



@interface YTUserAuthenticator: NSObject
- (id)authentication;
@end

@interface YTServices : NSObject
- (id)userAuthenticator;
@end

@interface YTFeedController : NSObject
- (void)makeRequest:(id)fp8 serviceSelector:(SEL)fp12 extraRequest:(id)fp16 extraServiceSelector:(SEL)fp20;
- (void)makeRequest:(id)fp8 serviceSelector:(SEL)fp12;
@end

@interface YTGuideFeedController: YTFeedController
- (void)loadAccountThumbnail;
- (void)handleEntries:(id)fp8;

@end 

@interface YTUtils
+ (id)userLanguageCode;
+ (id)userCountryCode;
@end

@interface YTGDataRequest
+ (id)requestForCategoriesWithLanguageCode:(id)fp8;
+ (id)requestForMySubscriptionsWithAuth:(id)fp8;
@end

@interface YTCategory : NSObject
{
    NSString *term_;
    NSString *label_;
    NSSet *browsableCountries_;
}

- (id)browsableCountries;
- (id)label;
- (id)term;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (id)initWithTerm:(id)fp8 label:(id)fp12 browsableCountries:(id)fp16;

@end

%hook YTGuideFeedController

- (void)updateViews:(id)a3 {
	YTServices *services = [self valueForKey:@"services_"];
    YTUserAuthenticator *userAuthenticator = [services userAuthenticator];

	// might be GTMOAuth2Authentication, but ID is probably more reliable
	id authentication = [userAuthenticator authentication];
	// NSString *userLang = [%c(YTUtils) userLanguageCode];
	// YTGDataRequest *requestCategories = [%c(YTGDataRequest) requestForCategoriesWithLanguageCode:userLang];

	if ( authentication )
	{
		[self loadAccountThumbnail];
		YTGDataRequest *requestSubscriptions = [%c(YTGDataRequest) requestForMySubscriptionsWithAuth:authentication];
		// [self makeRequest:requestSubscriptions serviceSelector:@selector(makeMySubscriptionsRequest:responseBlock:errorBlock:) extraRequest:requestCategories extraServiceSelector:@selector(makeCategoriesRequest:responseBlock:errorBlock:)];
		[self makeRequest:requestSubscriptions serviceSelector:@selector(makeMySubscriptionsRequest:responseBlock:errorBlock:)]; // i'm hardcoding the categories so we shouldnt need them
	}
	// else
	// {
	// 	[self makeRequest:requestCategories serviceSelector:@selector(makeCategoriesRequest:responseBlock:errorBlock:)];
	// }

	// give hardcoded categories :3
	NSLog(@"my country is %@", [%c(YTUtils) userCountryCode]);
	NSMutableArray *categories = [NSMutableArray array];

	// TODO: The category fetching relies on the language being set correctly to have them all be translated correctly, we should move this 
	// Also for my future knowlage, there are only 3 categories because fuckass youtube killed other categories
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Film" label:@"Film & Animation" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Music" label:@"Music" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Games" label:@"Gaming" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];

	[self handleEntries:categories];
}

%end

