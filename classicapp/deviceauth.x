#import <Foundation/Foundation.h>

@interface YTDeviceAuthenticator : NSObject {
	double _timeTokenGranted;
}

-(void)_loadStatusChanged;
-(void)_connectionDidEnd;
-(void)_succeeded;

@end

%hook YTDeviceAuthenticator

// still sends the auth request, but this ignores whatever it says, and sets the proper stuff. Idk why it didn't work when I did this on the thing that actually sends the request.
- (void)connectionDidFinishLoading:(id)connection
{
	[self setValue:@"token" forKey:@"_token"];
    [self setValue:@([NSDate timeIntervalSinceReferenceDate]) forKey:@"_timeTokenGranted"];

    [self _connectionDidEnd];
	[self _succeeded];
        
}

%end