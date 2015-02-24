#import "EEEvent.h"

@interface EEEventSubscriber ()

@property (nonatomic, copy) NSString *id;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;
@property (nonatomic, copy) EEEventBlock block;

@end

@implementation EEEventSubscriber

+ (instancetype)subscriberWithId:(NSString *)id target:(id)target selector:(SEL)selector
{
  return [[self alloc] initWithId:id target:target selector:selector];
}

+ (instancetype)subscriberWithId:(NSString *)id owner:(id)owner block:(EEEventBlock)block
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

- (instancetype)initWithId:(NSString *)id owner:(id)owner block:(EEEventBlock)block
{
  self = [super init];
  if(self) {
    self.id = id;
    self.target = owner;
    self.block = block;
  }
  return self;
}

- (BOOL)isEqual:(EEEventSubscriber *)object
{
  if(self == object)
    return YES;

  if(![object isKindOfClass:[EEEventSubscriber class]])
    return NO;

  return self.target == object.target && self.selector == object.selector && self.block == object.block && [self.id isEqualToString:object.id];
}

- (void)runWithEvent:(EEEvent *)event
{
  if(_block) {
    _block(event);
  } else if(_target && _selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:event];
#pragma clang diagnostic pop
  }
}

@end


@interface EEEventProducer ()

@property (nonatomic, copy) NSString *id;
@property (nonatomic, weak) id producer;

@end

@implementation EEEventProducer

+ (instancetype)producerWithId:(NSString *)id producer:(id)producer
{
  return [[self alloc] initWithId:id producer:producer];
}

- (instancetype)initWithId:(NSString *)id producer:(id)producer
{
  self = [super init];
  if(self) {
    self.id = id;
    self.producer = producer;
  }
  return self;
}

- (BOOL)isEqual:(EEEventProducer *)object
{
  if(self == object)
    return YES;

  if(![object isKindOfClass:[EEEventProducer class]])
    return NO;

  return self.producer == object.producer && [self.id isEqualToString:object.id];
}

@end


@interface EEEvent ()

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSDictionary *info;

@end

@implementation EEEvent

+ (instancetype)eventWithId:(NSString *)id info:(NSDictionary *)info
{
  return [[self alloc] initWithId:id info:info];
}

- (instancetype)initWithId:(NSString *)id info:(NSDictionary *)info
{
  self = [super init];
  if(self){
    self.id = id;
    self.info = info;
  }
  return self;
}

@end
