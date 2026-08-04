#include "TRSabrStream.h"
#include "common/SABR/TRUmpReader.h"

@interface TRSabrStream(PartHandler)
-(void)handlePart:(TRUmpPart*)part currentlyParsingDatas:(NSMutableDictionary**)currentlyParsingDatas currentlyParsingHeaders:(NSMutableDictionary**)currentlyParsingHeaders;
@end