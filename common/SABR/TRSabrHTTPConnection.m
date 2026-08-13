#import "TRSabrHTTPConnection.h"
#include <Foundation/NSRange.h>
#import "TRSabrHTTPServer.h"
#import "TRSabrStream.h"
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
		// HTTPDataResponse *resp = [[HTTPDataResponse alloc] initWithData:[@"tubereplacer sabr player" dataUsingEncoding:NSUTF8StringEncoding]];
		
		// return 
		return [[[HTTPDataResponse alloc] initWithData:[[stream.videoStream generateHLSManifest] dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	} else if ([cmpPath isEqualToString:@"/audio.m3u8"])
	{
		return [[[HTTPDataResponse alloc] initWithData:[[stream.audioStream generateHLSManifest] dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	}
	
	// videos
	if ([cmpPath hasSuffix:@".ts"]) {
		// is requesting a stream of some type of media
		NSArray *videoComponents = [[cmpPath substringWithRange:NSMakeRange(2, [cmpPath length]-5)] componentsSeparatedByString:@"-"];
		if (videoComponents.count != 2)
			return [[HTTPDataResponse alloc] initWithData:[@"bad url" dataUsingEncoding:NSUTF8StringEncoding]];

		int itag = [videoComponents[0] unsignedIntValue];
		int fragmentIndex = [videoComponents[1] unsignedIntValue];
		NSLog(@"fragment index -> %i", fragmentIndex);

		
		if (stream.videoStream.itag == itag) {
			[stream requestAdditionalData:llround(([stream.videoStream.segmentIndexesCombined[fragmentIndex+1] doubleValue]/(double)stream.videoStream.timescale) * 1000)];
			return [[[HTTPDataResponse alloc] initWithData:[stream.videoStream convertFMP4ToMPEGTSWithIndex:fragmentIndex+1]] autorelease];
		} else if (stream.audioStream.itag == itag) {
			[stream requestAdditionalData:llround(([stream.audioStream.segmentIndexesCombined[fragmentIndex+1] doubleValue]/(double)stream.audioStream.timescale) * 1000)];
			return [[[HTTPDataResponse alloc] initWithData:[stream.audioStream convertFMP4ToMPEGTSWithIndex:fragmentIndex+1]] autorelease];
		}
		
	}


	return [[HTTPDataResponse alloc] initWithData:[@"tubereplacer sabr player" dataUsingEncoding:NSUTF8StringEncoding]];
}

@end