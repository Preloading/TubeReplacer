#import "challengesolver.h"

@implementation TRPOTokenSolver

static TRPOTokenSolver *_sharedInstance = nil;

+(TRPOTokenSolver *)sharedInstance {
    @synchronized([TRPOTokenSolver class]) {
        if (!_sharedInstance)
          _sharedInstance = [[self alloc] init];
        return _sharedInstance;
    }
    return nil;
}

-(instancetype)init {
    [super init];
    return self;
}


-(void)dealloc {
    if (_webView) [_webView release];

    if (_messageId) [_messageId release];
    if (_safeScript) [_safeScript release];
    if (_resourceURL) [_resourceURL release];
    if (_interpreterHash) [_interpreterHash release];
    if (_program) [_program release];
    if (_globalName) [_globalName release];
    if (_clientExperimentsStateBlob) [_clientExperimentsStateBlob release];

    if (_botguardChallenge) [_botguardChallenge release];
    if (_botguardResponse) [_botguardResponse release];

    if (_vmReadyCallback) [_vmReadyCallback release];
    if (_poGenReady) [_poGenReady release];    
    if (_botguardResponseCallback) [_botguardResponseCallback release];

    if (_nsigJS) [_nsigJS release];
    if (_ytCfg) [_ytCfg release];

    if (_integrityToken) [_integrityToken release];
    if (_integrityTokenExpiration) [_integrityTokenExpiration release];
    if (_integrityTokenShouldProbablyRenew) [_integrityTokenShouldProbablyRenew release];

    [super dealloc];
}

@end