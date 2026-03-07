#include <Foundation/Foundation.h>
#include "general.h"


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


%hook YTDeviceAuthorizer


// youtube tries to register the device before using. This is useless to us since we are rewriting most of it. It would be best to eventually make this function never need to be called
// Actually, if i'm guessing correctly, this is how it does logged out personalized recommendations.
-(void)beginDeviceRegistration {
	id decryptedSecret = [%c(YTDeviceAuthorizer) decryptDeviceKey:@"ULxlVAAVMhZ2GeqZA/X1GgqEEIP1ibcd3S+42pkWfmk=" secret:[self valueForKey:l(@"secret")]];
    YTDeviceAuth *deviceAuth = [[%c(YTDeviceAuth) alloc] initWithDeviceId:@"dmVyeSBzZWN1cmUgaWQ=" deviceKey:decryptedSecret];
	[self setValue:[deviceAuth retain] forKey:l(@"deviceAuth")];
    if (deviceAuth)
    {
      [self saveRegistrationToStorage];
      [self performRequestQueueWithError:0];
      return;
    }
	[self performRequestQueueWithError:0]; // a3 in codebase but who's counting
}

%end