#import "common-google/common-google-headers.h"


@interface KUUserAuthenticator : NSObject
+(instancetype)sharedInstance;
-(id)authentication;
@end


@interface GTMHTTPUploadFetcher : GTMHTTPFetcher
+ (id)uploadFetcherWithRequest:(id)fp8 fetcherService:(id)fp12;
+ (id)uploadFetcherWithLocation:(id)fp8 uploadFileHandle:(id)fp12 uploadMIMEType:(id)fp16 chunkSize:(unsigned int)fp20 fetcherService:(id)fp24;
+ (id)uploadFetcherWithRequest:(id)fp8 uploadFileHandle:(id)fp12 uploadMIMEType:(id)fp16 chunkSize:(unsigned int)fp20 fetcherService:(id)fp24;
+ (id)uploadFetcherWithRequest:(id)fp8 uploadData:(id)fp12 uploadMIMEType:(id)fp16 chunkSize:(unsigned int)fp20 fetcherService:(id)fp24;
- (void)setLocationChangeBlock:(id)fp;
- (id)locationChangeBlock;
- (void)setChunkFetcher:(id)fp8;
- (id)chunkFetcher;
- (void)setCurrentOffset:(unsigned int)fp8;
- (unsigned int)currentOffset;
- (void)setChunkSize:(unsigned int)fp8;
- (unsigned int)chunkSize;
- (void)setUploadMIMEType:(id)fp8;
- (id)uploadMIMEType;
- (void)setUploadFileHandle:(id)fp8;
- (id)uploadFileHandle;
- (void)setUploadData:(id)fp8;
- (id)uploadData;
- (void)setLocationURL:(id)fp8;
- (id)locationURL;
- (id)activeFetcher;
- (void)setSentDataSelector:(SEL)fp8;
- (SEL)sentDataSelector;
- (void)setStatusCode:(int)fp8;
- (int)statusCode;
- (void)setResponseHeaders:(id)fp8;
- (id)responseHeaders;
- (void)stopFetching;
- (void)resumeFetching;
- (void)pauseFetching;
- (BOOL)isPaused;
- (void)uploadFetcher:(id)fp8 didSendBytes:(int)fp12 totalBytesSent:(int)fp16 totalBytesExpectedToSend:(int)fp20;
- (void)destroyChunkFetcher;
- (BOOL)chunkFetcher:(id)fp8 willRetry:(BOOL)fp12 forError:(id)fp16;
- (void)handleResumeIncompleteStatusForChunkFetcher:(id)fp8;
- (void)chunkFetcher:(id)fp8 finishedWithData:(id)fp12 error:(id)fp16;
- (void)reportProgressManually;
- (void)uploadNextChunkWithOffset:(unsigned int)fp8 fetcherProperties:(id)fp12;
- (void)uploadNextChunkWithOffset:(unsigned int)fp8;
- (void)connectionDidFinishLoading:(id)fp8;
- (void)connection:(id)fp8 didFailWithError:(id)fp12;
- (void)invokeFinalCallbacksWithData:(id)fp8 error:(id)fp12 shouldInvalidateLocation:(BOOL)fp16;
- (BOOL)shouldReleaseCallbacksUponCompletion;
- (void)connection:(id)fp8 didSendBodyData:(int)fp12 totalBytesWritten:(int)fp16 totalBytesExpectedToWrite:(int)fp20;
- (BOOL)beginFetchWithCompletionHandler:(id)fp;
- (BOOL)beginFetchWithDelegate:(id)fp8 didFinishSelector:(SEL)fp12;
- (id)uploadSubdataWithOffset:(unsigned int)fp8 length:(unsigned int)fp12;
- (unsigned int)fullUploadLength;
- (void)dealloc;
- (void)setLocationURL:(id)fp8 uploadData:(id)fp12 uploadFileHandle:(id)fp16 uploadMIMEType:(id)fp20 chunkSize:(unsigned int)fp24;
@end

