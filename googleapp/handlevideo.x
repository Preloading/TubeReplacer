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
        NSLog(@"format -> %i", [stream format]);
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
    NSLog(@"streams to select from -> %@", streams);

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

// 2.0.0
%hook YTPBStreamingData

+(YTPBStreamingData *)streamingDataWithStreams:(NSArray<YTStream *>*)streams
{
    NSMutableArray *newStreams = [[NSMutableArray alloc] initWithCapacity:streams.count];
    for (YTStream *stream in streams) {
        if ([stream format] == 5)
            continue;
        [newStreams addObject:stream];
    }

    return %orig(newStreams);
}

%end

// 1.4.0 only
%hook YTPlayerController
-(void)loadPlayerWithStreamManifest:(MLStreamManifest*)streamManifest deviceCapabilities:(id)deviceCapabilities airPlayAllowed:(BOOL)airPlayAllowed  {
    if (objc_getAssociatedObject(streamManifest, "sabrHackApplied") == NULL) {
        YTPlayerServices *playerServices = [self valueForKey:l(@"playerServices")];
        
        YTUserAuthenticator *userAuthenticatior = [playerServices userAuth];
        id authentication = [userAuthenticatior authentication];

        for (MLRemoteStream *stream in [streamManifest valueForKey:l(@"remoteStreams")]) {
            // SABR case
            if ([stream format] == 5) {
                TRSabrStream *sabrStream = (TRSabrStream*)stream;

                // most convient place to put authentication.
                if (authentication != nil) {
                    if ([version() isEqualToString:@"1.4.0"])
                        sabrStream.authentication = authentication;
                    else
                        sabrStream.authentication = [[(SSOAuthorizationImpl*)authentication identity] auth];
                }
            }
        }
        objc_setAssociatedObject(streamManifest, "sabrHackApplied", @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return %orig;
}
%end

%hook YTPlayerViewController

/// this is incredibly hacked together, just since I can't seem to figure out protobuf, AND i also do not want to rewrite stuff again.
/// For some reason, to transition smoothly ig, they translate all video streams into the proper protobuf format. 
/// Now TRSabrStream is not protobuf, and probably won't be nicely translated over to protobuf. Along with this, I have absolutely no idea
/// how to properly decompile the streamingDataWithStreams function where it can compile back, as all the headers seem to just not exist...
/// For the time being, this is my hack to just make this work, though realistically future versions should just hook the newer innertube
/// functions instead of relying soley on the old gdata ones which will eventually disappear.
-(void)loadPlayerWithStreamManifest:(MLStreamManifest*)streamManifest deviceCapabilities:(id)deviceCapabilities airPlayAllowed:(BOOL)airPlayAllowed {
    NSLog(@"loadPlayer called!");
    [[self valueForKey:l(@"activePlayerOverlayViewController")] setAirPlayAllowed:airPlayAllowed];

    YTPlayerServices *playerServices = [self valueForKey:l(@"playerServices")];
    double savedMediaTime = [(NSNumber*)[self valueForKey:l(@"savedMediaTime")] doubleValue];

    YTUserAuthenticator *userAuthenticatior = [playerServices userAuthenticator];
    id authentication = [userAuthenticatior authentication];

    // JANK START
    if (objc_getAssociatedObject(streamManifest, "sabrHackApplied") == NULL) {
        NSMutableArray *manifestStreams = [[streamManifest valueForKey:l(@"remoteStreams")] mutableCopy];

        NSArray *gdataStreams = [(YTVideo*)[self valueForKey:l(@"video")] streams];
        for (YTStream *stream in gdataStreams) {
            // SABR case
            if ([stream format] == 5) {
                TRSabrStream *sabrStream = (TRSabrStream*)stream;

                // most convient place to put authentication.
                if (authentication != nil) {
                    if ([version() isEqualToString:@"1.4.0"])
                        sabrStream.authentication = authentication;
                    else
                        sabrStream.authentication = [[(SSOAuthorizationImpl*)authentication identity] auth];
                }
                
                [manifestStreams addObject:sabrStream];
            }
        }
        [streamManifest setValue:[manifestStreams copy] forKey:l(@"remoteStreams")];
        [manifestStreams release];
        objc_setAssociatedObject(streamManifest, "sabrHackApplied", @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // JANK END
    

    [(MLPlayer*)[self valueForKey:l(@"player")] loadWithStreamManifest:streamManifest
                                    deviceCapabilities:deviceCapabilities
                                    services:playerServices
                                    initialMediaTime:savedMediaTime
                                    airPlayAllowed:airPlayAllowed
                                    authentication:authentication
        ];

    [self setValue:@(0.0) forKey:l(@"savedMediaTime")];
}

%end

@interface MLPassThroughProxy (TubeReplacer)
-(void)reloadPlayerStream;
@end

%hook MLPassThroughProxy

// 1.4.0
-(BOOL)start:(NSError**)error {
    MLRemoteStream *selectedStream = [self selectStream];
    MLRemoteStream *oldSelectedStream = [self valueForKey:l(@"selectedStream")];
    [self setValue:selectedStream forKey:l(@"selectedStream")];
    [oldSelectedStream release];

    if (selectedStream != nil)
    {
        if ([selectedStream format] == 5) {
            TRSabrStream *sabrStream = (TRSabrStream*)selectedStream;
            sabrStream.currentPlayerTimeFunction = ^double{
                // return [player currentMediaTime];
                return 0.0; // unimplemented
            };

            sabrStream.reloadPlayerFunction = ^{
                [self reloadPlayerStream];
            };

            [sabrStream start];
        }
        return YES;
    }
    else
    {
        *error = [NSError errorWithDomain:@"com.google.ios.medialib.ErrorDomain.Player" code:1 userInfo:nil];
        return NO;
    }
}

// 2.0.0
-(void)start {
    MLRemoteStream *selectedStream = [self selectStream];
    MLRemoteStream *oldSelectedStream = [self valueForKey:l(@"selectedStream")];
    [self setValue:selectedStream forKey:l(@"selectedStream")];
    [oldSelectedStream release];

    if (selectedStream != nil)
    {
        if ([selectedStream format] == 5) {
            TRSabrStream *sabrStream = (TRSabrStream*)selectedStream;
            sabrStream.currentPlayerTimeFunction = ^double{
                // return [player currentMediaTime];
                return 0.0; // unimplemented
            };

            sabrStream.reloadPlayerFunction = ^{
                [self reloadPlayerStream];
            };

            [sabrStream start];
        }
        MLProxy *delegate = [self delegate];
        NSURL *streamURL = [selectedStream URL];
        [delegate proxy:self didSetURL:streamURL];
        [delegate release];
    }
    else
    {
        NSError *error = [NSError playerErrorWithCode:1];
        // [streamURL proxy:self failedWithError:error];
        [error release];
    }
}

%new
-(void)reloadPlayerStream
{
    MLProxy *delegate = [self delegate];
    [delegate proxyURLWillChange:self];
    
    if ([version() isEqualToString:@"1.4.0"])
        [delegate proxy:self didChangeURL:[(MLRemoteStream*)[self valueForKey:l(@"selectedStream")] URL]];
    else
        [delegate proxy:self didSetURL:[(MLRemoteStream*)[self valueForKey:l(@"selectedStream")] URL]];
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