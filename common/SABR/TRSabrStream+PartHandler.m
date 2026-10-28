#include "TRSabrStream+PartHandler.h"
#include "video_streaming/NextRequestPolicy.pbobjc.h"
#include "video_streaming/SabrContextSendingPolicy.pbobjc.h"
#include "video_streaming/SabrError.pbobjc.h"
#include "video_streaming/SabrRedirect.pbobjc.h"
#include "video_streaming/StreamProtectionStatus.pbobjc.h"
#include <Foundation/NSData.h>
#include <Foundation/NSRange.h>

@implementation TRSabrStream(PartHandler)

-(void)handlePart:(TRUmpPart*)part currentlyParsingDatas:(NSMutableDictionary**)currentlyParsingDatas currentlyParsingHeaders:(NSMutableDictionary**)currentlyParsingHeaders {
    if (!self.isStreamReady)
        return;
    // NSLog(@"data type -> %i", part.type);
    // NSLog(@"data -> %@", part.data);
    NSError *error = nil;
    switch (part.type) {
    case UMPPartId_UmpPartIdStreamProtectionStatus: {
        StreamProtectionStatus *protectionStatus = [[StreamProtectionStatus alloc] initWithData:part.data error:&error];
        if (error) {
            NSLog(@"an error occured while decoding stream protection status. error -> %@", error);
            break;
        }
        // NSLog(@"current protection status -> %i", protectionStatus.status);
        self.streamProtectionStatus = protectionStatus.status;
        
        if (protectionStatus.status == 3) {
            // stream is RIP
            NSLog(@"Stream protection status is 3, unlikely to be able to continue, failing..");
            [self declareStreamBad];
        }
        [protectionStatus release];
        break;
    }
    case UMPPartId_UmpPartIdNextRequestPolicy: {
        NextRequestPolicy *nextRequestPolicy = [[NextRequestPolicy alloc] initWithData:part.data error:&error];
        if (error) {
            NSLog(@"an error occured while decoding next request policy. error -> %@", error);
            break;
        }
        // NSLog(@"next request policy -> %@", nextRequestPolicy);

        if (nextRequestPolicy.playbackCookie) {
            self.playbackCookie = nextRequestPolicy.playbackCookie;

            // initalize the video streams
            // i really hope that this exists **always** when a request is made. if it doesn't I should be able to use the list of all video streams I have.
            if (self.videoStream.itag == 0) {
                self.videoStream.itag = self.playbackCookie.videoFmt.itag;
                self.videoStream.mediaType = TRSabrMediaTypeVideo;
            }
            if (self.audioStream.itag == 0) {
                self.audioStream.itag = self.playbackCookie.audioFmt.itag;
                self.audioStream.mediaType = TRSabrMediaTypeAudio;
            }
        }
        
        if (nextRequestPolicy.hasBackoffTimeMs) {
            self.backoffTill = [NSDate dateWithTimeIntervalSinceNow:(double)(nextRequestPolicy.backoffTimeMs)/1000.0];
        }

        [nextRequestPolicy release];
        break;
    }
    case UMPPartId_UmpPartIdSabrRedirect: {
        SabrRedirect *redirect = [[SabrRedirect alloc] initWithData:part.data error:&error];
        if (error) {
            NSLog(@"an error occured while decoding sabr redirect. error -> %@", error);
            break;
        }

        if (redirect.hasURL) {
            self.decipheredStreamURL = redirect.URL;
        }

        [redirect release];
        break;
    }
    case UMPPartId_UmpPartIdSabrContextUpdate: {
        SabrContextUpdate *contextUpdate = [[SabrContextUpdate alloc] initWithData:part.data error:&error];
                if (contextUpdate.writePolicy == SabrContextUpdate_SabrContextWritePolicy_KeepExisting && [self.activeContextUpdates containsObject:@(contextUpdate.type)]) {
            [contextUpdate release];
            break;
        }

        self.contextUpdates[@(contextUpdate.type)] = contextUpdate.value;

        if (contextUpdate.sendByDefault) {
            [self.activeContextUpdates addObject:@(contextUpdate.type)];
        }

        [contextUpdate release];
        break;
    }
    case UMPPartId_UmpPartIdSabrContextSendingPolicy: {
        SabrContextSendingPolicy *sendingPolicy = [[SabrContextSendingPolicy alloc] initWithData:part.data error:&error];

        for (int i = 0; i>sendingPolicy.startPolicyArray_Count; i++) {
            if (![self.activeContextUpdates containsObject:@([sendingPolicy.startPolicyArray valueAtIndex:i])]) {
                [self.activeContextUpdates addObject:@([sendingPolicy.startPolicyArray valueAtIndex:i])];
            }
        }

        for (int i = 0; i>sendingPolicy.stopPolicyArray_Count; i++) {
            if (![self.activeContextUpdates containsObject:@([sendingPolicy.stopPolicyArray valueAtIndex:i])]) {
                [self.activeContextUpdates removeObject:@([sendingPolicy.stopPolicyArray valueAtIndex:i])];
            }
        }

        for (int i = 0; i>sendingPolicy.discardPolicyArray_Count; i++) {
            if (self.contextUpdates[@([sendingPolicy.stopPolicyArray valueAtIndex:i])] != nil) {
                [self.contextUpdates removeObjectForKey:@([sendingPolicy.stopPolicyArray valueAtIndex:i])];
            }
        }

        [sendingPolicy release];
        break;
    }
    case UMPPartId_UmpPartIdSabrError: {
        SabrError *sabrError = [[SabrError alloc] initWithData:part.data error:&error];
        NSLog(@"SABR reported an error! type -> %@, code -> %i", sabrError.type, sabrError.code);
        [sabrError release];
        [self declareStreamBad];
        break;
    }
    case UMPPartId_UmpPartIdMediaHeader: {
        MediaHeader *mediaHeader = [[MediaHeader alloc] initWithData:part.data error:&error];
        if (error) {
            NSLog(@"an error occured while decoding the media header. error -> %@", error);
            break;
        }

        if (mediaHeader.isInitSeg) {
            if (mediaHeader.itag == self.videoStream.itag && self.videoStream.isReadyForPlayback) {
                [mediaHeader release];
                break;
            }

            if (mediaHeader.itag == self.audioStream.itag && self.audioStream.isReadyForPlayback) {
                [mediaHeader release];
                break;
            }
        }
        
        (*currentlyParsingHeaders)[@(mediaHeader.headerId)] = mediaHeader;
        [mediaHeader release];
        (*currentlyParsingDatas)[@(mediaHeader.headerId)] = [[NSMutableData alloc] init];
        
        // NSLog(@"media header -> %@", mediaHeader);

        break;
    }
    case UMPPartId_UmpPartIdMedia: {
        if (part.data == nil) {
            NSLog(@"media part is bad!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        }

        uint8_t headerId = *(const uint8_t *)[[part.data subdataWithRange:NSMakeRange(0,1)] bytes];

        if ((*currentlyParsingDatas)[@(headerId)] != nil)
            [(*currentlyParsingDatas)[@(headerId)] appendData:[part.data subdataWithRange:NSMakeRange(1, [part.data length]-1)]];
        break;
    }
    case UMPPartId_UmpPartIdMediaEnd: {
        uint8_t mediaHeaderId = *(const uint8_t *)[part.data bytes];
        MediaHeader *mediaHeader = (MediaHeader*)((*currentlyParsingHeaders)[@(mediaHeaderId)]);
        if (mediaHeader == nil)
            break;

        // i really love Address of property expression requested
        // NSLog(@"itag -> %i, segment -> %i", mediaHeader.itag, mediaHeader.sequenceNumber);
        if (mediaHeader.itag == self.videoStream.itag) {
            if (mediaHeader.isInitSeg) {
                if (!self.videoStream.isReadyForPlayback)
                    [self.videoStream parseMP4Header:(*currentlyParsingDatas)[@(mediaHeaderId)]];
                [(*currentlyParsingDatas)[@(mediaHeaderId)] release];
                [(*currentlyParsingDatas) removeObjectForKey:@(mediaHeaderId)];
                [(*currentlyParsingHeaders) removeObjectForKey:@(mediaHeaderId)];
            } else {
                if (self.videoStream.segmentData[@(mediaHeader.sequenceNumber)] == nil)
                    [self.videoStream addNewFMP4FragmentWithID:mediaHeader.sequenceNumber data:(*currentlyParsingDatas)[@(mediaHeaderId)]];
                [(*currentlyParsingDatas)[@(mediaHeaderId)] release];
                [(*currentlyParsingDatas) removeObjectForKey:@(mediaHeaderId)];
                [(*currentlyParsingHeaders) removeObjectForKey:@(mediaHeaderId)];
            }
        } else if (mediaHeader.itag == self.audioStream.itag) {
            if (mediaHeader.isInitSeg) {
                if (!self.audioStream.isReadyForPlayback)
                    [self.audioStream parseMP4Header:(*currentlyParsingDatas)[@(mediaHeaderId)]];
                [(*currentlyParsingDatas)[@(mediaHeaderId)] release];
                [(*currentlyParsingDatas) removeObjectForKey:@(mediaHeaderId)];
                [(*currentlyParsingHeaders) removeObjectForKey:@(mediaHeaderId)];
            } else {
                if (self.audioStream.segmentData[@(mediaHeader.sequenceNumber)] == nil)
                    [self.audioStream addNewFMP4FragmentWithID:mediaHeader.sequenceNumber data:(*currentlyParsingDatas)[@(mediaHeaderId)]];
                [(*currentlyParsingDatas)[@(mediaHeaderId)] release];
                [(*currentlyParsingDatas) removeObjectForKey:@(mediaHeaderId)];
                [(*currentlyParsingHeaders) removeObjectForKey:@(mediaHeaderId)];
            }
        } else {
            NSLog(@"Something went wrong buffering the media!");
        }

        break;
    }
    default:
        // NSLog(@"unparsed UMP data! data -> %@", part.data);
        break;
    }
}


@end