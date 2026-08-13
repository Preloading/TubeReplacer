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
+(YTStream*)selectStreamForVideo:(YTVideo*)video maxQualityStreamFormat:(int)maxQualityStreamFormat onWiFi:(BOOL)onWifi devicePrivileges:(id)devicePrivileges CPN:(NSString*)cpn {
    NSArray<YTStream*> *streams = [video streams];
    
    // return the stream with the highest number lol
    YTStream *selectedStream = nil;
    
    for (YTStream *stream in streams) {
        if ([stream format] == 2)
            return stream; // if they are using custom, **we use custom**
        if ([stream format] > [selectedStream format])
            selectedStream = stream;
    }
    return selectedStream;

}

%end
%hook YTPlayerController

-(void)setAndPlayVideoStream:(YTStream *)stream
{
    if ([[self valueForKey:l(@"hasFocus")] intValue] == 0)
    {
        [self setValue:@0 forKey:l(@"startPlayback")];
        return;
    }

    [(YTPlayerView *)[self valueForKey:l(@"playerView")] setAirPlayAllowed:1];

    YTPlayer *player = [self valueForKey:l(@"player")];

    // deal with SABR
    if ([stream format] == 5) {
      TRSabrStream *sabrStream = (TRSabrStream*)[stream URL];

      sabrStream.currentPlayerTimeFunction = ^double{
        return [player currentMediaTime];
      };
      
      [player setStreamURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%u/master.m3u8", sabrStream.httpServer.port]]
          initialMediaTime:[[self valueForKey:l(@"savedMediaTime")] doubleValue]
          airPlayAllowed:1];
    } else {
        [player setStreamURL:[stream URL]
          initialMediaTime:[[self valueForKey:l(@"savedMediaTime")] doubleValue]
          airPlayAllowed:1];
    }
    

    [self setValue:@0.0 forKey:l(@"savedMediaTime")];

    if ([[self valueForKey:l(@"startPlayback")] intValue] != 0)
    {
        [self setValue:@0 forKey:l(@"startPlayback")];
        [self playIfPermitted];
    }
}

// todo: THIS IS NEVER CALLED!!! this is maybe an app bug
-(void)dealloc {
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  if ([(YTStream*)[self valueForKey:l(@"videoStream")] format] == 5) {
    // sabr
    [[[self valueForKey:l(@"videoStream")] URL] release];
  }
  return %orig;
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

// - (void)dealloc {
//     NSLog(@"[DEBUG] DEALLOC %@", self);
//     %orig;
// }

// %end

// %hook YTNavigation_iPhone
  
// -(void)back
// {
//   NSLog(@"nav controller -> %@", [self valueForKey:l(@"navigationController")]);
//   return %orig;
// }

// %end