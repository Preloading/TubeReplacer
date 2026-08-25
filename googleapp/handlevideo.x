// Handles stream selection & dealing with the finicky SABR stream

// formats
// 1 = 360p (fallback)
// 2 = TubeRepair/Custom
// 4 = HLS
// 5 = SABR

#include <Foundation/Foundation.h>
#include "appheaders.h"
#include "general.h"
#include "common/SABR/TRSabrStream.h"

%hook YTStream


+(YTStream*)selectStreamForVideo:(YTVideo*)video onWiFi:(BOOL)onWifi {
    NSArray<YTStream*> *streams = [video streams];
    
    // return the stream with the highest number lol
    YTStream *selectedStream = nil;
    
    for (YTStream *stream in streams) {
        if ([stream format] == 5) {
            // sabr case
            TRSabrStream *sabrStream = (TRSabrStream*)stream;
            if ([sabrStream isStreamBad])
                continue;
        }
        if ([stream format] == 2)
            return stream; // if they are using custom, **we use custom**
        if ([stream format] > [selectedStream format])
            selectedStream = stream;
    }

    return selectedStream;

}

+(YTStream*)selectStreamForVideo:(YTVideo*)video onWiFi:(BOOL)onWifi devicePrivileges:(id)devicePrivileges {
    NSArray<YTStream*> *streams = [video streams];
    
    // return the stream with the highest number lol
    YTStream *selectedStream = nil;
    
    for (YTStream *stream in streams) {
        if ([stream format] == 5) {
            // sabr case
            TRSabrStream *sabrStream = (TRSabrStream*)stream;
            if ([sabrStream isStreamBad])
                continue;
        }
        if ([stream format] == 2)
            return stream; // if they are using custom, **we use custom**
        if ([stream format] > [selectedStream format])
            selectedStream = stream;
    }

    NSLog(@"selected new stream -> %@", selectedStream);
    return selectedStream;

}

// 1.2.1 - 1.3.0
+(YTStream*)selectStreamForVideo:(YTVideo*)video maxQualityStreamFormat:(int)maxQualityStreamFormat onWiFi:(BOOL)onWifi devicePrivileges:(id)devicePrivileges CPN:(NSString*)cpn {
    NSArray<YTStream*> *streams = [video streams];
    
    // return the stream with the highest number lol
    YTStream *selectedStream = nil;
    
    for (YTStream *stream in streams) {
        if ([stream format] == 5) {
            // sabr case
            TRSabrStream *sabrStream = (TRSabrStream*)stream;
            if ([sabrStream isStreamBad])
                continue;
        }
        if ([stream format] == 2)
            return stream; // if they are using custom, **we use custom**
        if ([stream format] > [selectedStream format])
            selectedStream = stream;
    }

    NSLog(@"selected new stream -> %@", selectedStream);
    return selectedStream;

}

%end

%hook YTPlayerController

-(void)setAndPlayVideoStream:(YTStream *)stream
{
    BOOL version10 = ([version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"]);

    YTPlayer *player = [self valueForKey:l(@"player")];
    
    // deal with SABR
    if ([stream format] == 5) {
        TRSabrStream *sabrStream = (TRSabrStream*)stream;
        NSLog(@"d");
        sabrStream.currentPlayerTimeFunction = ^double{
            return [player currentMediaTime];
        };

        sabrStream.reloadPlayerFunction = ^{
            [self reloadPlayerStream];
        };

        if (version10) {
            sabrStream.authentication = [[(YTServices*)[self valueForKey:l(@"services")] userAuthenticator] authentication];
        } else {
            sabrStream.authentication = [[(YTPlayerServices*)[self valueForKey:l(@"playerServices")] userAuth] authentication];
        }

        [sabrStream start];
    }
    
    return %orig;
}


-(MLRemoteStream*)remoteStreamFromYTStream:(YTStream*)stream withURL:(NSURL*)url {
    if ([stream format] == 5) {
        return (MLRemoteStream*)stream;
    }
    return %orig;
}

-(void)dealloc {
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    if ([(YTStream*)[self valueForKey:l(@"videoStream")] format] == 5) {
      // sabr
        [[[self valueForKey:l(@"videoStream")] URL] release];
    }
    return %orig;
}

%new
-(void)reloadPlayerStream
{
    BOOL version10 = [version() isEqualToString:@"1.0.0"] || [version() isEqualToString:@"1.0.1"];
    if (!version10)
      [self saveMediaTime];
    YTStream *selectedStream = nil;
    if ([version() isEqualToString:@"1.2.1"] || [version() isEqualToString:@"1.3.0"])
        selectedStream = [self selectStreamForVideo:[self valueForKey:l(@"video")] maxQualityStreamFormat:9999 devicePrivileges:[self valueForKey:l(@"privileges")] CPN:[self valueForKey:l(@"videoCPN")]];
    else if ([version() isEqualToString:@"1.1.0"])
        selectedStream = [self selectStreamForVideo:[self valueForKey:l(@"video")] devicePrivileges:nil];
    else
        selectedStream = [self selectStreamForVideo:[self valueForKey:l(@"video")]];

    // [self setValue:@(1) forKey:l(@"startPlayback")];
    if (version10) {
        [self setAndPlayVideoStream:selectedStream];
    } else {
        if ( selectedStream != nil)
        {
            if (![selectedStream isEqual:(YTStream*)[self valueForKey:l(@"videoStream")]])
            {
                NSLog(@"switching streams to -> %@", selectedStream);
                [(YTStream*)[self valueForKey:l(@"videoStream")] autorelease];
                [self setValue:[selectedStream retain] forKey:l(@"videoStream")];
            }
        }
        NSLog(@"video stream -> %@", [self valueForKey:l(@"videoStream")]);
        [self setAndPlayVideoStream:[self valueForKey:l(@"videoStream")]];
    }
}

// -(void)appDidBecomeActive {
//   NSLog(@"We have awaken from a slumber, reloading things......");
//     [self reloadPlayerStream];
//     %orig;
// }

%end

%hook MLPassThroughProxy

-(MLRemoteStream*)selectStream {
    NSArray<YTStream*> *streams = [(MLStreamManifest*)[self valueForKey:l(@"streamManifest")] remoteStreams];
    
    // return the stream with the highest number lol
    MLRemoteStream *selectedStream = nil;
    
    for (MLRemoteStream *stream in streams) {
        if ([stream format] == 5) {
            // sabr case
            TRSabrStream *sabrStream = (TRSabrStream*)stream;
            if ([sabrStream isStreamBad])
                continue;
        }
        if ([stream format] == 2)
            return stream; // if they are using custom, **we use custom**
        if ([stream format] > [selectedStream format])
            selectedStream = stream;
    }

    NSLog(@"selected new stream -> %@", selectedStream);
    return selectedStream;
}

%end

// %hook YTPlayerScreenController
  
// -(void)destroyLocalPlayerController
// {
//   NSLog(@"destroy aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
//   %orig;
// }


// %end

// %hook YTWatchViewController_iPhone 

// -(void)viewDidUnload {
//     NSLog(@"dealloc aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
// }

// %end

// %hook YTVideoViewController_iPhone 

%hook YTWatchViewController_iPhone
 

// - (id)retain {
//     id result = %orig;

//     NSLog(@"[DEBUG] RETAIN %@ count=%lu",
//           self, (unsigned long)[(NSObject*)self retainCount]);

//     NSLog(@"%@", [NSThread callStackSymbols]);

//     return result;
// }

// - (void)release {
//     NSLog(@"[DEBUG] RELEASE %@ count=%lu",
//           self, (unsigned long)[(NSObject*)self retainCount] - 1);

//     %orig;
// }

// -(void)viewDidUnload {
//     NSLog(@"dealloc aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
// }


// - (id)alloc {
//     NSLog(@"[DEBUG] alloc %@", [NSThread callStackSymbols]);
//     return %orig;
// }


// - (void)dealloc {
//     NSLog(@"[DEBUG] DEALLOC %@", self);
//     %orig;
// }
// - (void)viewWillDisappear:(BOOL)animated {
//     %orig;
//     [%c(YTNotificationCenter) removeRequestPortraitUIObserver:self];
//     [%c(YTNotificationCenter) removeReleasePortraitUIObserver:self];
// }

// - (void)viewWillAppear:(BOOL)animated {
//     %orig;
//     [%c(YTNotificationCenter) addRequestPortraitUIObserver:self selector:@selector(requestPortraitOrientation:)];
//     [%c(YTNotificationCenter) addReleasePortraitUIObserver:self selector:@selector(releasePortraitOrientation:)];

// }

-(id)initWithVideoID:(id)videoId source:(int)source services:(id)services navigation:(id)navigation
{
    return %orig;
}

%end

// %hook YTNavigation_iPhone
  
// -(void)back
// {
//     UINavigationController *navigationController = [self valueForKey:l(@"navigationController")];
//   NSLog(@"nav controller -> %@", navigationController);
//     NSLog(@"nav controllers -> %@", [navigationController viewControllers]);
//   return %orig;
// }

// - (void)pushViewController:(id)vc fromView:(id)view {
//     NSLog(@"[DEBUG] pushViewController:fromView: vc=%p view=%p stack=%@", vc, view, [NSThread callStackSymbols]);
//     %orig;
// }

// %end