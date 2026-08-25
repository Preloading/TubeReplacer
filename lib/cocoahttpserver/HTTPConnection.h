#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
// Note: You may need to add the CFNetwork Framework to your project
#import <CFNetwork/CFNetwork.h>
#endif

@class TRAsyncSocket;
@class TRHTTPMessage;
@class TRHTTPServer;
@class TRWebSocket;
@protocol TRHTTPResponse;


#define HTTPConnectionDidDieNotification  @"HTTPConnectionDidDie"

@interface TRHTTPConnection : NSObject
{
	TRAsyncSocket *asyncSocket;
	TRHTTPServer *server;
	
	TRHTTPMessage *request;
	int numHeaderLines;
	
	NSString *nonce;
	long lastNC;
	
	NSObject<TRHTTPResponse> *httpResponse;
	
	NSMutableArray *ranges;
	NSMutableArray *ranges_headers;
	NSString *ranges_boundry;
	int rangeIndex;
	
	UInt64 requestContentLength;
	UInt64 requestContentLengthReceived;
	
	NSMutableArray *responseDataSizes;
}

- (id)initWithAsyncSocket:(TRAsyncSocket *)newSocket forServer:(TRHTTPServer *)myServer;

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path;
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path;

- (BOOL)isSecureServer;
- (NSArray *)sslIdentityAndCertificates;

- (BOOL)isPasswordProtected:(NSString *)path;
- (BOOL)useDigestAccessAuthentication;
- (NSString *)realm;
- (NSString *)passwordForUser:(NSString *)username;

- (NSDictionary *)parseParams:(NSString *)query;
- (NSDictionary *)parseGetParams;

- (NSString *)requestURI;

- (NSArray *)directoryIndexFileNames;
- (NSString *)filePathForURI:(NSString *)path;
- (NSObject<TRHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path;
- (TRWebSocket *)webSocketForURI:(NSString *)path;

- (void)prepareForBodyWithSize:(UInt64)contentLength;
- (void)processDataChunk:(NSData *)postDataChunk;

- (void)handleVersionNotSupported:(NSString *)version;
- (void)handleAuthenticationFailed;
- (void)handleResourceNotFound;
- (void)handleInvalidRequest:(NSData *)data;
- (void)handleUnknownMethod:(NSString *)method;

- (NSData *)preprocessResponse:(TRHTTPMessage *)response;
- (NSData *)preprocessErrorResponse:(TRHTTPMessage *)response;

- (BOOL)shouldDie;
- (void)die;

@end

@interface TRHTTPConnection (AsynchronousHTTPResponse)
- (void)responseHasAvailableData;
@end
