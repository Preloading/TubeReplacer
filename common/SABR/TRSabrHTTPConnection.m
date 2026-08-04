#import "TRSabrHTTPConnection.h"
#import "TRSabrHTTPServer.h"
#import "TRSabrStream.h"
#import "lib/cocoahttpserver/HTTPMessage.h"
#import "lib/cocoahttpserver/HTTPResponse.h"
#import "lib/cocoahttpserver/DDNumber.h"

@implementation TRSabrHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSLog(@"path -> %@", path);
	
	if ([path isEqualToString:@"/master.m3u8"])
	{
		return [[[HTTPDataResponse alloc] initWithData:[[((TRSabrHTTPServer*)self->server).stream createHLSRootManifest] dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	} else if ([path isEqualToString:@"/video.m3u8"])
	{
		return [[[HTTPDataResponse alloc] initWithData:[[((TRSabrHTTPServer*)self->server).stream.videoStream generateHLSManifest] dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	} else if ([path isEqualToString:@"/audio.m3u8"])
	{
		return [[[HTTPDataResponse alloc] initWithData:[[((TRSabrHTTPServer*)self->server).stream.audioStream generateHLSManifest] dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	}
	
	return [[HTTPDataResponse alloc] initWithData:[@"tubereplacer sabr player" dataUsingEncoding:NSUTF8StringEncoding]];
}

@end