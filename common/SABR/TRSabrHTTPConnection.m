#import "TRSabrHTTPConnection.h"
#include <Foundation/NSRange.h>
#import "TRSabrHTTPServer.h"
#import "TRSabrStream.h"
#import "TRSabrHTTPResponse.h"
#import "lib/cocoahttpserver/HTTPMessage.h"
#import "lib/cocoahttpserver/HTTPResponse.h"
#import "lib/cocoahttpserver/DDNumber.h"

@implementation TRSabrHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	TRSabrStream *stream = ((TRSabrHTTPServer*)self->server).stream;
	NSString *cmpPath = [path componentsSeparatedByString:@"?"][0];
	NSLog(@"path -> %@", cmpPath);
	
	if ([cmpPath isEqualToString:@"/master.m3u8"])
	{
		return [[[HTTPDataResponse alloc] initWithData:[[stream createHLSRootManifest] dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	} else if ([cmpPath isEqualToString:@"/video.m3u8"])
	{
		if (!stream.videoStream.isReadyForPlayback) {
			NSThread *currentThread = [NSThread currentThread];
			[stream.videoStream registerCallback:^{
				[self performSelector:@selector(responseHasAvailableData)
					onThread:currentThread
					withObject:nil
				waitUntilDone:NO];
			} forLoadedSegment:0];
		}
		return [[[TRSabrHTTPResponse alloc] initWithMedia:stream.videoStream andSegment:0] autorelease];
	} else if ([cmpPath isEqualToString:@"/audio.m3u8"])
	{
		if (!stream.audioStream.isReadyForPlayback) {
			NSThread *currentThread = [NSThread currentThread];
			[stream.audioStream registerCallback:^{
				[self performSelector:@selector(responseHasAvailableData)
					onThread:currentThread
					withObject:nil
				waitUntilDone:NO];
			} forLoadedSegment:0];
		}

		return [[[TRSabrHTTPResponse alloc] initWithMedia:stream.audioStream andSegment:0] autorelease];
	}
	
	// videos
	if ([cmpPath hasSuffix:@".ts"]) {
		// is requesting a stream of some type of media
		NSArray *videoComponents = [[cmpPath substringWithRange:NSMakeRange(2, [cmpPath length]-5)] componentsSeparatedByString:@"-"];
		if (videoComponents.count != 2)
			return [[[HTTPDataResponse alloc] initWithData:[@"bad url" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];

		int itag = [videoComponents[0] unsignedIntValue];
		int fragmentIndex = [videoComponents[1] unsignedIntValue];
		// NSLog(@"fragment index -> %i", fragmentIndex);

		
		if (stream.videoStream.itag == itag) {
			if (stream.videoStream.segmentData[@(fragmentIndex+1)] == nil) {
				NSThread *currentThread = [NSThread currentThread];
				[stream.videoStream registerCallback:^{
					[self performSelector:@selector(responseHasAvailableData)
						onThread:currentThread
						withObject:nil
					waitUntilDone:NO];
				} forLoadedSegment:fragmentIndex+1];
			}


			[stream handleBufferingWithCurrentSegment:fragmentIndex mediaType:TRSabrMediaTypeVideo];

			return [[[TRSabrHTTPResponse alloc] initWithMedia:stream.videoStream andSegment:fragmentIndex+1] autorelease];
		} else if (stream.audioStream.itag == itag) {
			if (stream.audioStream.segmentData[@(fragmentIndex+1)] == nil) {
				NSThread *currentThread = [NSThread currentThread];
				[stream.audioStream registerCallback:^{
					[self performSelector:@selector(responseHasAvailableData)
						onThread:currentThread
						withObject:nil
					waitUntilDone:NO];
				} forLoadedSegment:fragmentIndex+1];
			}

			[stream handleBufferingWithCurrentSegment:fragmentIndex mediaType:TRSabrMediaTypeAudio];
			return [[[TRSabrHTTPResponse alloc] initWithMedia:stream.audioStream andSegment:fragmentIndex+1] autorelease];
		}
		
	}


	return [[[HTTPDataResponse alloc] initWithData:[@"tubereplacer sabr player" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
}

@end