#import <Foundation/Foundation.h>

@interface TRUMPWriter : NSObject

@property (nonatomic, strong) NSMutableData *compositeBuffer;

-(void)writeData:(NSData*)data withPartType:(uint)partType;
-(void)writeVarInt:(uint)value;

@end