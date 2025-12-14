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

	
	// todo: fuck with -[YTFeedController refresh] and get it to actually finish refreshing.
	[self reset];
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
	// NSLog(@"my country is %@", [%c(YTUtils) userCountryCode]);

	NSMutableArray *categories = [NSMutableArray array];
	
	// TODO: The category fetching relies on the language being set correctly to have them all be translated correctly, we should move this 
	// Also for my future knowlage, there are only 3 categories because fuckass youtube killed other categories
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Film"          label:@"Film & Animation" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Autos"         label:@"Autos & Vehicles" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Music"         label:@"Music" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Animals"       label:@"Pets & Animals" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Sports"        label:@"Sports" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	// [categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Travel"        label:@"Travel" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Games"         label:@"Gaming" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Comedy"        label:@"Comedy" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"People"        label:@"People & Blogs" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"News"          label:@"News & Politics" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Entertainment" label:@"Entertainment" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	// [categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Education"     label:@"Education" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Howto"         label:@"Howto & Style" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	// [categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Nonprofit"   label:@"Nonprofits & Activism" browsableCountries:@[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:@"Tech"          label:@"Science & Technology" browsableCountries:@[@"us", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"]] autorelease]];
	
	[self handleEntries:categories];
	NSLog(@"categoriesCount_ = %@", [self valueForKey:@"categoriesCount_"]);
	
	NSLog(@"entryCount = %d", [self entryCount]);
}
%end