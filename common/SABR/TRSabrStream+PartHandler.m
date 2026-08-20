#include "TRSabrStream+PartHandler.h"
#include "video_streaming/NextRequestPolicy.pbobjc.h"
#include "video_streaming/SabrRedirect.pbobjc.h"
#include "video_streaming/StreamProtectionStatus.pbobjc.h"
#include <Foundation/NSData.h>
#include <Foundation/NSRange.h>

@implementation TRSabrStream(PartHandler)

-(void)handlePart:(TRUmpPart*)part currentlyParsingDatas:(NSMutableDictionary**)currentlyParsingDatas currentlyParsingHeaders:(NSMutableDictionary**)currentlyParsingHeaders {
    NSLog(@"data type -> %i", part.type);
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
    case UMPPartId_UmpPartIdSabrError: {
        [(*currentlyParsingDatas) removeAllObjects];
        [(*currentlyParsingHeaders) removeAllObjects];
        [self declareStreamBad];
        return;
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
        NSLog(@"itag -> %i, segment -> %i", mediaHeader.itag, mediaHeader.sequenceNumber);
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