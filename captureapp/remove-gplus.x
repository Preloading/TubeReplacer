#import <Foundation/Foundation.h>


%hook PlusOne

-(void)spawnOOBFlow {
    // this dialog is very dead, so i kill it :3
}

%end


%hook GooglePlus 

-(void)spawnOOBFlowIfNeeded {

}

%end
//         void *callstack[128];
// 	int frames = backtrace(callstack, 128);
// 	char **symbols = backtrace_symbols(callstack, frames);
// 	NSMutableString *callstackString = [NSMutableString stringWithFormat:@"YTNavigation_iPhone authenticateFailedWithError message: %@", message];
// 	for (int i = 0; i < frames; i++) {
// 		[callstackString appendFormat:@"%s\n", symbols[i]];
// 	}
// 	NSLog(@"%@", callstackString);