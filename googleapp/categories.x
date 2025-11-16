#include <Foundation/Foundation.h>
#include "appheaders.h"

// -[YTCategoryParser parseElement:error:]
// -[YTGuideFeedController handleEntries: is where categories are requested
//-[YTFeedController maybeMakeNextRequest]


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

// handles subscriptions & categories
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
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Film"   label:@"Film & Animation" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Sports" label:@"Sports" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Music"  label:@"Music" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];
	[categories addObject:[[%c(YTCategory) alloc] initWithTerm:@"Games"  label:@"Gaming" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]]];

	[self handleEntries:categories];
}

%end