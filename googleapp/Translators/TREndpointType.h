// TREndpointType.h
// TubeReplacer
//
// Unified endpoint types for JSON translation routing

#ifndef TREndpointType_h
#define TREndpointType_h

typedef NS_ENUM(NSInteger, TREndpointType) {
    TREndpointTypeUnknown = 0,
    TREndpointTypeVideo,
    TREndpointTypeChannel,
    TREndpointTypeFeed,
    TREndpointTypePlayer,
    TREndpointTypeComment,
    TREndpointTypeSubscription,
    TREndpointTypePlaylist,
    TREndpointTypeSearch
};

#endif
