#import "EEAction.h"

@interface EEActionSubscriber ()

@property (nonatomic, copy) NSString *id;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;
@property (nonatomic, copy) EEActionBlock block;

@end

@implementation EEActionSubscriber

+ (instancetype)subscriberWithId:(NSString *)id target:(id)target selector:(SEL)selector
{
  return [[self alloc] initWithId:id target:target selector:selector];
}

+ (instancetype)subscriberWithId:(NSString *)id owner:(id)owner block:(EEActionBlock)block
{
  return [[self alloc] initWithId:id owner:owner block:block];
}

- (instancetype)initWithId:(NSString *)id target:(id)target selector:(SEL)selector
{
  self = [super init];
  if(self) {
    self.id = id;
    self.target = target;
    self.selector = selector;
  }
  return self;
}

- (instancetype)initWithId:(NSString *)id owner:(id)owner block:(EEActionBlock)block
{
  self = [super init];
  if(self) {
    self.id = id;
    self.target = owner;
    self.block = block;
  }
  return self;
}

- (BOOL)isEqual:(EEActionSubscriber *)object
{
  if(self == object)
    return YES;

  if(![object isKindOfClass:[EEActionSubscriber class]])
    return NO;

  return self.target == object.target && self.selector == object.selector && self.block == object.block && [self.id isEqualToString:object.id];
}

- (void)runWithAction:(EEAction *)action
{
  if(_block) {
    _block(action);
  } else if(_target && _selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:action];
#pragma clang diagnostic pop
  }
}

@end


@interface EEAction ()

@property (nonatomic, copy) NSArray *subscribers;
@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic, copy) EEActionBlock callback;

@end

@implementation EEAction

+ (instancetype)actionWithSubscribers:(NSArray *)subscribers id:(NSString *)id parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback
{
  return [[self alloc] initWithSubscribers:subscribers id:id parameters:parameters callback:callback];
}

+ (instancetype)actionWithId:(NSString *)id parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback
{
  return [[self alloc] initWithSubscribers:nil id:id parameters:parameters callback:callback];
}

+ (instancetype)actionWithId:(NSString *)id parameters:(NSDictionary *)parameters
{
  return [[self alloc] initWithSubscribers:nil id:id parameters:parameters callback:nil];
}

- (instancetype)initWithSubscribers:(NSArray *)subscribers id:(NSString *)id parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback
{
  self = [super init];
  if(self) {
    self.subscribers = subscribers;
    self.id = id;
    self.parameters = parameters;
    self.callback = callback;
  }
  return self;
}

- (instancetype)run
{
  if(_subscribers.count > 0) {
    [_subscribers makeObjectsPerformSelector:@selector(runWithAction:) withObject:self];
  } else {
    NSLog(@"0@ %@, action not found", _id);
    self.error = [NSError errorWithDomain:@"com.ee.messagebus" code:1 userInfo:@{ NSLocalizedDescriptionKey : @"Action not found" }];
    if(_callback)
      _callback(self);
  }
  return self;
}

- (instancetype)runWithSubscribers:(NSArray *)subscribers
{
  self.subscribers = subscribers;
  return [self run];
}

- (void)finish
{
  if(_callback)
    _callback(self);
}

- (void)finishWithResult:(id)result error:(NSError *)error resultTraits:(NSDictionary *)resultTraits
{
  self.result = result;
  self.error = error;
  self.resultTraits = resultTraits;

  [self finish];
}

@end
