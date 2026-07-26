#import <Foundation/Foundation.h>

@interface TRUMPWriter : NSObject

@property (nonatomic, strong) NSMutableData *compositeBuffer;

-(void)writeData:(NSData*)data withPartType:(int)partType;
-(void)writeVarint:(uint)value;

@end