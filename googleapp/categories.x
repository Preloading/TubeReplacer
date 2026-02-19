#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"

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

@interface YTGuideFeedController (TubeReplacer)
-(void)addCategories;
-(void)addCategoryTerm:(NSString*)term defaultLabel:(NSString*)defaultLabel toArray:(NSMutableArray*)categories enabledByDefault:(BOOL)enabledByDefault;
@end

%hook YTGuideFeedController

%new
-(void)addCategoryTerm:(NSString*)term defaultLabel:(NSString*)defaultLabel toArray:(NSMutableArray*)categories enabledByDefault:(BOOL)enabledByDefault {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/dev.preloading.tubereplacer.preferences.plist"];
	NSArray *browsableCountries = @[@"ar", @"au", @"bd", @"be", @"bg", @"br", @"ca", @"cl", @"co", @"cz", @"de", @"dk", @"dz", @"ee", @"eg", @"es", @"et", @"fi", @"fr", @"gb", @"gr", @"hk", @"hr", @"hu", @"id", @"ie", @"il", @"in", @"ir", @"is", @"it", @"jo", @"jp", @"ke", @"kr", @"lt", @"lv", @"ma", @"mx", @"my", @"ng", @"nl", @"no", @"nz", @"ph", @"pk", @"pl", @"pt", @"ro", @"rs", @"ru", @"sa", @"se", @"sg", @"si", @"sk", @"th", @"tn", @"tr", @"tw", @"tz", @"ua", @"ug", @"us", @"vn", @"ye", @"za"];
	if (![preferences[[NSString stringWithFormat:@"%@BrowseId", term]] isEqualToString:@""] && (enabledByDefault || preferences[[NSString stringWithFormat:@"%@BrowseId", term]])) {
		if (preferences[[NSString stringWithFormat:@"%@Name", term]]) {
			if (!([preferences[[NSString stringWithFormat:@"%@Name", term]] isEqualToString:@""])) {
						[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:term label:preferences[[NSString stringWithFormat:@"%@Name", term]] browsableCountries:browsableCountries] autorelease]];
			}
		} else {
			[categories addObject:[[[%c(YTCategory) alloc] initWithTerm:term label:defaultLabel browsableCountries:browsableCountries] autorelease]];
		}
	}
}

%new
-(void)addCategories {
	NSMutableArray *categories = [NSMutableArray array];
	
	// TODO: The category fetching relies on the language being set correctly to have them all be translated correctly, we should move this 
	[self addCategoryTerm:@"Film"          defaultLabel:@"Film & Animation"      toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Autos"         defaultLabel:@"Autos & Vehicles"      toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Music"         defaultLabel:@"Music"                 toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Animals"       defaultLabel:@"Pets & Animals"        toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Sports"        defaultLabel:@"Sports"                toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Travel"        defaultLabel:@"Travel"                toArray:categories enabledByDefault:NO];
	[self addCategoryTerm:@"Games"         defaultLabel:@"Gaming"                toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Comedy"        defaultLabel:@"Comedy"                toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"People"        defaultLabel:@"People & Blogs"        toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"News"          defaultLabel:@"News & Politics"       toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Entertainment" defaultLabel:@"Entertainment"         toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Education"     defaultLabel:@"Education"             toArray:categories enabledByDefault:NO];
	[self addCategoryTerm:@"Howto"         defaultLabel:@"Howto & Style"         toArray:categories enabledByDefault:YES];
	[self addCategoryTerm:@"Nonprofit"     defaultLabel:@"Nonprofits & Activism" toArray:categories enabledByDefault:NO];
	[self addCategoryTerm:@"Tech"          defaultLabel:@"Science & Technology"  toArray:categories enabledByDefault:YES];

	[self handleEntries:categories];
	NSLog(@"categoriesCount_ = %@", [self valueForKey:@"categoriesCount_"]);
	
	NSLog(@"entryCount = %d", [self entryCount]);
}

// handles subscriptions & categories
- (void)updateViews:(id)a3 {
	

	YTUserAuthenticator *userAuthenticator = nil;
	if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
		YTServices *services = [self valueForKey:@"services_"];
		userAuthenticator = [services userAuthenticator];
	} else {
		userAuthenticator = [self valueForKey:@"userAuthenticator_"];
	}
	

	// might be GTMOAuth2Authentication, but ID is probably more reliable
	id authentication = [userAuthenticator authentication];
	// NSString *userLang = [%c(YTUtils) userLanguageCode];
	// YTGDataRequest *requestCategories = [%c(YTGDataRequest) requestForCategoriesWithLanguageCode:userLang];

	
	// todo: fuck with -[YTFeedController refresh] and get it to actually finish refreshing.
	[self reset];
	if ( authentication )
	{
		[self loadAccountThumbnail];

		if ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]) {
			YTGDataRequest *requestSubscriptions = [%c(YTGDataRequest) requestForMySubscriptionsWithAuth:authentication];
			[self makeRequest:requestSubscriptions serviceSelector:@selector(makeMySubscriptionsRequest:responseBlock:errorBlock:)]; // i'm hardcoding the categories so we shouldnt need them
		} else {
			// todo: [(YTGuideEntry*)[self valueForKey:@"accountEntry_"] setAccessibilityLabel:localizedStringForKey(@"guide.account_loggedin.access")];
			id requestSubscriptions = [(YTGDataRequestFactory*)[self valueForKey:@"GDataRequestFactory_"] requestForMySubscriptionsWithAuth:authentication];
			[self makeRequest:requestSubscriptions serviceSelector:@selector(makeMySubscriptionsRequest:responseBlock:errorBlock:)]; // i'm hardcoding the categories so we shouldnt need them
		}
		// [self makeRequest:requestSubscriptions serviceSelector:@selector(makeMySubscriptionsRequest:responseBlock:errorBlock:) extraRequest:requestCategories extraServiceSelector:@selector(makeCategoriesRequest:responseBlock:errorBlock:)];
	} else {
		[self addCategories];
	}
	// else
	// {
	// 	[self makeRequest:requestCategories serviceSelector:@selector(makeCategoriesRequest:responseBlock:errorBlock:)];
	// }

	// give hardcoded categories :3
	// NSLog(@"my country is %@", [%c(YTUtils) userCountryCode]);

	
}

-(void) handleEntries:(NSArray*)entries
{
	%orig;
	if ([entries[0] isKindOfClass:[%c(YTSubscription) class]]) {
		[self addCategories];
	}
}
%end