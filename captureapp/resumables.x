#import <Foundation/Foundation.h>
#import "captureheaders.h"
#include "common-google/potoken-google.h"

// debug
#import <execinfo.h>

@interface KUNetworkManager : NSObject
-(void)beginUpload;
-(void)pushNetworkActivity;
-(void)popNetworkActivity;
-(void)setUploadFetcher:(id)fetcher;
-(void)complete;

// tubereplacer
-(TRPOTokenSolver*)tokenSolver;
@end

@interface KUAsset : NSObject
-(void)setUploadURL:(NSString*)uploadURL;
-(NSString*)uploadURL;
-(NSString*)mimeType;
-(void)synchronize;
-(NSString*)cachedVideoURL; // on disk
-(void)setUploadState:(int)state;
-(void)postChangeNotification;
-(int)privacy;
-(NSString*)title;
-(NSString*)desc;

@end

// saves to -[KUAsset loadFromNSUserDefaults]

%hook KUNetworkManager

%new
-(TRPOTokenSolver*)tokenSolver {
    return objc_getAssociatedObject(self, "tokenSolver");
}

-(instancetype)init {
    id orig = %orig;
    TRPOTokenSolver *tokenSolver = [[TRPOTokenSolver alloc] init];
    objc_setAssociatedObject(orig, "tokenSolver", tokenSolver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // get solvin
    // dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    [tokenSolver fetchBotguardChallengeWithCallback:^(NSError *error) {
        if (error) {
            NSLog(@"an error has occured in token fetching! %@", error);
            return;
        }

        NSLog(@"got botguard challenge!");
        // [tokenSolver initJSEngine];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [tokenSolver solveIntegrityToken];
        });
        
    } auth:[[%c(KUUserAuthenticator) sharedInstance] authentication] isStudio:YES]; 
        // if (!result) {
        //     NSLog(@"an error has occured in token fetching!");
        // }
        // [tokenSolver solveIntegrityToken];
        // NSLog(@"botguard response -> %@", [tokenSolver botguardResponse]);
    // });
    return orig;
}

// based heavily on https://github.com/adasq/youtube-studio/blob/master/src/upload/index.js
-(void)requestResumableURLForAsset:(KUAsset*)asset andContinueUpload:(BOOL)continueUpload {
    // This data is not stored on a remote server, so we either need to create one, or store one.
    [self pushNetworkActivity];
    if (continueUpload) {
        // generate frontendUploadId

        // https://stackoverflow.com/a/35976360
        CFUUIDRef uuidRef = CFUUIDCreate(NULL); // doing it this way because iOS 5
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        NSString *frontendUploadId = [NSString stringWithFormat:@"innertube_studio:%@:0", (NSString *)uuidString];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://upload.youtube.com/upload/studio"]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[[NSString stringWithFormat:@"{\"frontendUploadId\":\"%@\"}", frontendUploadId] dataUsingEncoding:NSUTF8StringEncoding]]; // there shouldn't be any issue with this, since it's not user input.
        [request setValue:@"start" forHTTPHeaderField:@"x-goog-upload-command"];
        [request setValue:(NSString*)uuidString forHTTPHeaderField:@"x-goog-upload-file-name"]; // there's probably something here saying "dont leak your thingy!!111!11!1", but tbh, idc
        [request setValue:@"resumable" forHTTPHeaderField:@"x-goog-upload-protocol"];
        [request setValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"Content-Type"]; // great question! I don't know.
        [request setValue:@"https://studio.youtube.com/" forHTTPHeaderField:@"Referrer"];


        GTMHTTPFetcher *fetcher = [%c(GTMHTTPFetcher) fetcherWithRequest:request];
        [fetcher setAuthorizer:[[%c(KUUserAuthenticator) sharedInstance] authentication]];
        [fetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
                NSString *uploadURL = [[fetcher responseHeaders] objectForKey:@"x-goog-upload-url"];
                [asset setUploadURL:uploadURL];
                objc_setAssociatedObject(asset, "frontendUploadId", frontendUploadId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [asset synchronize];
                if (continueUpload)
                    [self beginUpload];
        }];
    } else {
        // we need to create the token
    }


}

-(void)beginResumableUpload
{
    KUAsset *activeUpload = (KUAsset*)[self valueForKey:@"activeUpload_"];
    NSFileHandle *cachedVideoFile = [NSFileHandle fileHandleForReadingAtPath:[activeUpload cachedVideoURL]];
    if (cachedVideoFile && [cachedVideoFile seekToEndOfFile] != 0)  {
        [activeUpload setUploadState:2];
        [activeUpload postChangeNotification];
        [self pushNetworkActivity];

        // i've ripped out a lot of the analytics stuff to avoid the hassle of dealaing with it, so hopefully it doesn't cause issues?
        NSURL *uploadURL = [NSURL URLWithString:[activeUpload uploadURL]];
        NSString *mimeType = [activeUpload mimeType];
        GTMHTTPUploadFetcher *uploadFetcher = [%c(GTMHTTPUploadFetcher) uploadFetcherWithLocation:uploadURL
                            uploadFileHandle:cachedVideoFile
                            uploadMIMEType:mimeType
                            chunkSize:0x100000
                            fetcherService:nil];

        [uploadFetcher setSentDataSelector:@selector(myFetcher:didSendBytes:totalBytesSent:totalBytesExpectedToSend:)];
        [uploadFetcher setDelegate:self];
        [self setUploadFetcher:uploadFetcher];
        [uploadFetcher beginFetchWithCompletionHandler:^(NSData *response, NSError *error){
            // we did it! we uploaded a video, time to tell youtube it exists!
            NSLog(@"colon three");
            [response retain];
            [self popNetworkActivity];        
            if ( error )
            {
                // UIViewController *navigationController = [[[UIApplication sharedApplication] delegate] navigationController]
                // id cre = [[%c(KUCreateChannelViewController) alloc] initWithCompleteHandler: ^{
                //     [navigationController popViewControllerAnimated:1];
                // }];
                // [navigationController pushViewController:v25 animated:1]
                NSLog(@"an error occured! %@", error);
            }
            
            NSError *error2 = nil;
            NSDictionary *decodedData = [NSJSONSerialization
                      JSONObjectWithData:response
                      options:0
                      error:&error2];

            if (error2) {
                [self complete];
                return;
            }
            NSString *scottyId = [decodedData objectForKey:@"scottyResourceId"];
            NSString *frontendUploadId = objc_getAssociatedObject(activeUpload, "frontendUploadId");

            NSString *channelId = [[[%c(KUUserAuthenticator) sharedInstance] authentication] channelID];

            NSLog(@"scottyId -> %@, frontendId -> %@, channel id -> %@", scottyId, frontendUploadId, channelId);
            NSLog(@"privacy -> %i", [activeUpload privacy]);

            NSString *privacy = @"UNLISTED";
            if ([activeUpload privacy] == 0) {
                privacy = @"PRIVATE";
            } else if ([activeUpload privacy] == 1) {
                privacy = @"UNLISTED";
            } else if ([activeUpload privacy] == 2) {
                privacy = @"PUBLIC";
            }

            NSDictionary *videoMetadata = @{
                @"channelId": channelId,
                @"resourceId": @{
                    @"scottyResourceId": @{
                        @"id": scottyId
                    }
                },
                @"frontendUploadId": frontendUploadId,
                @"initialMetadata": @{
                    @"title": @{
                        @"newTitle": [activeUpload title]
                    },
                    @"description": @{
                        @"newDescription": [activeUpload desc],
                        @"shouldSegment": @true
                    },
                    @"privacy": @{
                        @"newPrivacy": privacy
                    },
                    @"draftState": @{
                        @"isDraft": @false
                    }
                },
                @"context": @{
                    @"client": @{
                        @"clientName": @62,
                        @"clientVersion": @"1.20260518.01.00",
                        // @"clientVersion": @"1.20201130.03.00",
                        @"hl": @"en-US",
                        @"gl": @"US",
                        @"experimentsToken": @"",
                        @"utcOffsetMinutes": @60
                    },
                    @"user": @{
                        @"delegationContext": @{
                            @"roleType": @{
                                @"channelRoleType": @"CREATOR_CHANNEL_ROLE_TYPE_OWNER"
                            },
                            @"externalChannelId": channelId
                        },
                        @"serializedDelegationContext": @""
                    },
                    @"clientScreenNonce": @""
                },
                @"delegationContext": @{
                    @"roleType": @{
                        @"channelRoleType": @"CREATOR_CHANNEL_ROLE_TYPE_OWNER"
                    },
                    @"externalChannelId": channelId
                },
            };

            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://studio.youtube.com/youtubei/v1/upload/createvideo?alt=json"]];
            NSLog(@"pleas1");
            [request setHTTPMethod:@"POST"];
            NSLog(@"pleas2");
            [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:videoMetadata
                        options:0
                          error:&error2]];
            NSLog(@"pleas3");
            if (error2) {
                NSLog(@"error jsonencoding!");
                return;
            }
            NSLog(@"pleas4");
        [request setValue:@"https://studio.youtube.com/" forHTTPHeaderField:@"Referrer"];
        [request setValue:@"https://studio.youtube.com/" forHTTPHeaderField:@"Origin"];

            GTMHTTPFetcher *fetcher = [%c(GTMHTTPFetcher) fetcherWithRequest:request];
            NSLog(@"pleas5");
            [fetcher setAuthorizer:[[%c(KUUserAuthenticator) sharedInstance] authentication]];
            NSLog(@"pleas6");
            [fetcher beginFetchWithCompletionHandler:^(NSData *response2, NSError *error3){
                NSLog(@"response -> %@, error -> %@", response2, error3);
                [self complete];
            }];

            // -[KUAsset setYtVideoID:](block->superSelf->activeUpload_, v13);
            
            //     NSString *dataString = [[NSString alloc] initWithData:data encoding:4];
            //     v17 = (char *)dataString;
        }];
    }
    else {
        return %orig; // its just flat out faster to program. Has duplicate logic, but whatever.
    }
}

-(void)dealloc {
    [[self tokenSolver] dealloc];
    %orig;
}

%end

// -[GTMHTTPUploadFetcher beginFetchWithDelegate:didFinishSelector:] fuckin confuses me. WHY ARE YOU PASSING -1???
%hook GTMHTTPUploadFetcher
- (void)uploadNextChunkWithOffset:(unsigned int)offset fetcherProperties:(NSDictionary *)properties {
    //         void *callstack[128];
	// int frames = backtrace(callstack, 128);
	// char **symbols = backtrace_symbols(callstack, frames);
	// NSMutableString *callstackString = [NSMutableString stringWithFormat:@"uploadNextChunkWithOffset"];
	// for (int i = 0; i < frames; i++) {
	// 	[callstackString appendFormat:@"%s\n", symbols[i]];
	// }
	// NSLog(@"%@", callstackString);


    NSUInteger chunkSize = [self chunkSize];
    NSUInteger fullUploadLength = [self fullUploadLength];
    
    NSData *chunkData = nil;
    NSString *contentLengthHeader = nil;
    NSLog(@"offset -> %i", offset);

    BOOL isFinalTransaction = false;
    if (offset == -1) {
        offset = 0;
    }
    
    NSUInteger remainingLength = fullUploadLength - offset;
    NSUInteger currentChunkSize = chunkSize;
    
    if ((offset + currentChunkSize > fullUploadLength) || (remainingLength < currentChunkSize + 2500)) {
        currentChunkSize = remainingLength;
        isFinalTransaction = YES;
    }
    
    chunkData = [self uploadSubdataWithOffset:offset length:currentChunkSize];
                            
    contentLengthHeader = [NSString stringWithFormat:@"%llu", (unsigned long long)currentChunkSize];
    
    NSLog(@"offset to calculate: %i", offset);

    [self setCurrentOffset:offset];

    NSURL *locationURL = [self locationURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:locationURL];
    [request setHTTPMethod:@"POST"];
    
    NSString *userAgent = [[self mutableRequest] valueForHTTPHeaderField:@"User-Agent"];
    if ([userAgent length] > 0) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    [request setValue:contentLengthHeader forHTTPHeaderField:@"Content-Length"];

    // additional headers YIPEEE
    [request setValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"content-type"];
    [request setValue:@"upload" forHTTPHeaderField:@"x-goog-upload-command"];
    if (isFinalTransaction) {
        [request setValue:@"upload, finalize" forHTTPHeaderField:@"x-goog-upload-command"];
    }
    [request setValue:@"file" forHTTPHeaderField:@"x-goog-upload-file-name"]; // well
    [request setValue:[NSString stringWithFormat:@"%i", offset] forHTTPHeaderField:@"x-goog-upload-offset"];
    [request setValue:@"https://studio.youtube.com/" forHTTPHeaderField:@"Referrer"];
    
    GTMHTTPFetcher *chunkFetcher = [%c(GTMHTTPFetcher) fetcherWithRequest:request];
    [chunkFetcher setDelegateQueue:[self delegateQueue]];
    [chunkFetcher setRunLoopModes:[self runLoopModes]];
    
    [chunkFetcher setProperties:properties];
    [chunkFetcher setPostData:chunkData];
    [chunkFetcher setRetryEnabled:[self isRetryEnabled]];
    [chunkFetcher setMaxRetryInterval:[self maxRetryInterval]];
    [chunkFetcher setSentDataSelector:[self sentDataSelector]];
    [chunkFetcher setCookieStorageMethod:[self cookieStorageMethod]];
    NSLog(@"done???? request -> %@", request);
    
    if ([self isRetryEnabled]) {
        [chunkFetcher setRetrySelector:@selector(chunkFetcher:willRetry:forError:)];
    }
    
    [self setMutableRequest:request];
    
    BOOL success = [chunkFetcher beginFetchWithDelegate:self 
                                      didFinishSelector:@selector(chunkFetcher:finishedWithData:error:)];
    if (success) {
        NSLog(@"a good occured");
        [self setChunkFetcher:chunkFetcher];
    } 
    else {
        NSLog(@"a bad occured");
        NSError *error = [NSError errorWithDomain:@"com.google.GTMHTTPFetcher"
                                             code:-3 
                                         userInfo:nil];
                                         
        [self invokeFinalCallbacksWithData:nil 
                                     error:error 
                  shouldInvalidateLocation:YES];
                  
        [self destroyChunkFetcher];
    }
}

-(void)chunkFetcher:(GTMHTTPFetcher*)fetcher finishedWithData:(NSData*)data error:(NSError*)error
{
    NSLog(@"chunk fetcher done");
    int statusCode = [fetcher statusCode];
    [self setStatusCode:statusCode];
    NSDictionary *responseHeaders = [fetcher responseHeaders];
    [self setResponseHeaders:responseHeaders];

    NSLog(@"error -> %@", error);

    if ([[responseHeaders valueForKey:@"X-Goog-Upload-Status"] isEqualToString:@"active"]) {
        NSLog(@"is active");

        NSUInteger chunkSize = [self chunkSize];
        NSUInteger fullUploadLength = [self fullUploadLength];
        NSUInteger offset = [self currentOffset];

        if (offset == -1) {
            offset = 0;
        }
        
        NSUInteger remainingLength = fullUploadLength - offset;
        NSUInteger currentChunkSize = chunkSize;
        
        if ((offset + currentChunkSize > fullUploadLength) || (remainingLength < currentChunkSize + 2500)) {
            currentChunkSize = remainingLength;
        }

        [self setCurrentOffset:offset + currentChunkSize];

        if ([self valueForKey:@"needsManualProgress_"]) // who knows if this will work?
            [self reportProgressManually];


        NSLog(@"location url -> %@", [self locationURL]);
        id properties = [[fetcher properties] retain];
        // NSURL *prevURL = [[[fetcher mutableRequest] URL] retain];
        [self destroyChunkFetcher];
        [self uploadNextChunkWithOffset:[self currentOffset] fetcherProperties:properties];

        // NSError *error = [NSError errorWithDomain:@"com.google.GTMHTTPFetcher"
        //                     code:308 userInfo:nil];

        // [self invokeFinalCallbacksWithData:data error:nil shouldInvalidateLocation:NO];
    } else {
        NSLog(@"is not active");
        return %orig;
    }
    


    // [self destroyChunkFetcher];
}
%end


// todo: look at -[GTMHTTPUploadFetcher chunkFetcher:finishedWithData:error:](, since it expects cod 308, when we get 200 when we finish a chunk.