#import "EEMessageBus.h"

@implementation EEMessageBus
{
  NSMutableDictionary *_actions;
  NSMutableDictionary *_eventSubscribers;
  NSMutableDictionary *_eventProducers;
  NSMutableDictionary *_eventMaskProducers;
}

+ (instancetype)instance
{
  static dispatch_once_t once;
  static id messageBus;
  dispatch_once(&once, ^{
    messageBus = [[self alloc] init];
  });
  return messageBus;
}

- (instancetype)init
{
  self = [super init];
  if(self) {
    _actions = [NSMutableDictionary dictionaryWithCapacity:100];
    _eventSubscribers = [NSMutableDictionary dictionaryWithCapacity:100];
    _eventProducers = [NSMutableDictionary dictionaryWithCapacity:100];
    _eventMaskProducers = [NSMutableDictionary dictionaryWithCapacity:10];
  }
  return self;
}

- (void)unregister:(id)object
{
  [self unregisterActionsWithTargetOrOwner:object];
  [self unregisterEventProducer:object];
  [self unsubscribeFromEventsWithTargetOrOwner:object];
}

#pragma mark - Actions registering

- (NSMutableOrderedSet *)subscribersForAction:(NSString *)action create:(BOOL)create
{
  NSMutableOrderedSet *actionSubscribers = _actions[action];
  if(!actionSubscribers && create) {
    actionSubscribers = [NSMutableOrderedSet orderedSet];
    _actions[action] = actionSubscribers;
  }
  return actionSubscribers;
}

- (EEActionSubscriber *)registerAction:(NSString *)action target:(id)target selector:(SEL)selector
{
  NSMutableOrderedSet *subscribers = [self subscribersForAction:action create:YES];
  EEActionSubscriber *subscriber = [EEActionSubscriber subscriberWithId:action target:target selector:selector];
  [subscribers addObject:subscriber];
  return subscriber;
}

- (EEActionSubscriber *)registerAction:(NSString *)action owner:(id)owner block:(EEActionBlock)block
{
  NSMutableOrderedSet *subscribers = [self subscribersForAction:action create:YES];
  EEActionSubscriber *subscriber = [EEActionSubscriber subscriberWithId:action owner:owner block:block];
  [subscribers addObject:subscriber];
  return subscriber;
}

- (void)unregisterAction:(NSString *)action target:(id)target
{
  NSMutableOrderedSet *subscribers = [self subscribersForAction:action create:NO];
  for(NSInteger i = subscribers.count - 1; i >= 0; --i) {
    EEActionSubscriber *subscriber = subscribers[(NSUInteger)i];
    if(subscriber.target == target)
      [subscribers removeObjectAtIndex:(NSUInteger)i];
  }
}

- (void)unregisterAction:(NSString *)action owner:(id)owner
{
  NSMutableOrderedSet *subscribers = [self subscribersForAction:action create:NO];
  for(NSInteger i = subscribers.count - 1; i >= 0; --i) {
    EEActionSubscriber *subscriber = subscribers[(NSUInteger)i];
    if(subscriber.target == owner)
      [subscribers removeObjectAtIndex:(NSUInteger)i];
  }
}

- (void)unregisterActionSubscriber:(EEActionSubscriber *)actionSubscriber
{
  if(!actionSubscriber)
    return;

  NSMutableOrderedSet *subscribers = [self subscribersForAction:actionSubscriber.id create:NO];
  [subscribers removeObject:actionSubscriber];
}

- (void)unregisterActionsWithTargetOrOwner:(id)targetOrOwner
{
  if(!targetOrOwner)
    return;

  [_actions enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableOrderedSet *subscribers, BOOL *stop) {
    for(NSInteger i = subscribers.count - 1; i >= 0; --i) {
      EEActionSubscriber *subscriber = subscribers[(NSUInteger)i];
      if(subscriber.target == targetOrOwner)
        [subscribers removeObjectAtIndex:(NSUInteger)i];
    }
  }];
}

#pragma mark - Actions getting and running

- (EEAction *)action:(NSString *)action parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback
{
  return [EEAction actionWithSubscribers:[self subscribersForAction:action create:NO].array id:action parameters:parameters callback:callback];
}

- (EEAction *)runAction:(NSString *)action parameters:(NSDictionary *)parameters
{
  return [[EEAction actionWithSubscribers:[self subscribersForAction:action create:NO].array id:action parameters:parameters callback:nil] run];
}

- (EEAction *)runAction:(NSString *)action parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback
{
  return [[EEAction actionWithSubscribers:[self subscribersForAction:action create:NO].array id:action parameters:parameters callback:callback] run];
}

- (EEAction *)runAction:(EEAction *)action
{
  return [action runWithSubscribers:[self subscribersForAction:action.id create:NO].array];
}

#pragma mark - Events producing

- (BOOL)eventHasMask:(NSString *)event
{
  return [event rangeOfString:@"*"].location == NSNotFound;
}

- (NSMutableOrderedSet *)producersForEvent:(NSString *)event create:(BOOL)create
{
  NSMutableDictionary *producers = [self eventHasMask:event] ? _eventMaskProducers : _eventProducers;
  NSMutableOrderedSet *producersForEvent = producers[event];
  if(!producersForEvent && create) {
    producersForEvent = [NSMutableOrderedSet orderedSet];
    producers[event] = producersForEvent;
  }
  return producersForEvent;
}

- (void)registerEvent:(NSString *)event producer:(id)producer
{
  NSMutableOrderedSet *producers = [self producersForEvent:event create:YES];
  EEEventProducer *eventProducer = [EEEventProducer producerWithId:event producer:producer];
  [producers addObject:eventProducer];
}

- (void)unregisterEvent:(NSString *)event producer:(id)producer
{
  NSMutableOrderedSet *producers = [self producersForEvent:event create:NO];
  for(NSInteger i = producers.count - 1; i >= 0; --i) {
    EEEventProducer *eventProducer = producers[(NSUInteger)i];
    if(eventProducer.producer == producer)
      [producers removeObjectAtIndex:(NSUInteger)i];
  }
}

- (void)unregisterEventProducer:(id)producer
{
  if(!producer)
    return;

  [_eventProducers enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableOrderedSet *producers, BOOL *stop) {
    for(NSInteger i = producers.count - 1; i >= 0; --i) {
      EEEventProducer *eventProducer = producers[(NSUInteger)i];
      if(eventProducer.producer == producer)
        [producers removeObjectAtIndex:(NSUInteger)i];
    }
  }];

  [_eventMaskProducers enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableOrderedSet *producers, BOOL *stop) {
    for(NSInteger i = producers.count - 1; i >= 0; --i) {
      EEEventProducer *eventProducer = producers[(NSUInteger)i];
      if(eventProducer.producer == producer)
        [producers removeObjectAtIndex:(NSUInteger)i];
    }
  }];
}

- (BOOL)eventHasProducers:(NSString *)event
{
  __block NSMutableOrderedSet *producers = _eventProducers[event];
  if(producers.count > 0)
    return YES;

  [_eventMaskProducers enumerateKeysAndObjectsUsingBlock:^(NSString *evt, NSMutableOrderedSet *evtProducers, BOOL *stop) {
    if(event.length < evt.length)
      return;

    NSRange range = [evt rangeOfString:@"*"];
    NSString *prefix = [evt substringToIndex:range.location];
    NSString *suffix = [evt substringFromIndex:range.location + range.length];
    if([event hasPrefix:prefix] && [event hasSuffix:suffix]) {
      NSString *middlePart = [event substringWithRange:NSMakeRange(prefix.length, event.length - prefix.length - suffix.length)];
      if([middlePart rangeOfString:@"/"].location == NSNotFound) {
        producers = evtProducers;
        *stop = YES;
      }
    }
  }];

  return producers.count > 0;
}

- (void)checkProducersForEvent:(NSString *)event
{
  if(![self eventHasProducers:event]) {
    NSLog(@"-@ %@, event has no producers", event);
  }
}

#pragma mark - Events subscribing

- (NSMutableOrderedSet *)subscribersForEvent:(NSString *)event create:(BOOL)create
{
  NSMutableOrderedSet *subscribersForEvent = _eventSubscribers[event];
  if(!subscribersForEvent && create) {
    subscribersForEvent = [NSMutableOrderedSet orderedSet];
    _eventSubscribers[event] = subscribersForEvent;
  }
  return subscribersForEvent;
}

- (EEEventSubscriber *)subscribeToEvent:(NSString *)event target:(id)target selector:(SEL)selector
{
  //[self checkProducersForEvent:event];

  NSMutableOrderedSet *subscribers = [self subscribersForEvent:event create:YES];
  EEEventSubscriber *subscriber = [EEEventSubscriber subscriberWithId:event target:target selector:selector];
  [subscribers addObject:subscriber];
  return subscriber;
}

- (EEEventSubscriber *)subscribeToEvent:(NSString *)event owner:(id)owner block:(EEEventBlock)block
{
  //[self checkProducersForEvent:event];

  NSMutableOrderedSet *subscribers = [self subscribersForEvent:event create:YES];
  EEEventSubscriber *subscriber = [EEEventSubscriber subscriberWithId:event owner:owner block:block];
  [subscribers addObject:subscriber];
  return subscriber;
}

- (void)unsubscribeFromEvent:(NSString *)event target:(id)target
{
  NSMutableOrderedSet *subscribers = [self subscribersForEvent:event create:NO];
  for(NSInteger i = subscribers.count - 1; i >= 0; --i) {
    EEEventSubscriber *subscriber = subscribers[(NSUInteger)i];
    if(subscriber.target == target)
      [subscribers removeObjectAtIndex:(NSUInteger)i];
  }
}

- (void)unsubscribeFromEvent:(NSString *)event owner:(id)owner
{
  NSMutableOrderedSet *subscribers = [self subscribersForEvent:event create:NO];
  for(NSInteger i = subscribers.count - 1; i >= 0; --i) {
    EEEventSubscriber *subscriber = subscribers[(NSUInteger)i];
    if(subscriber.target == owner)
      [subscribers removeObjectAtIndex:(NSUInteger)i];
  }
}

- (void)unregisterEventSubscriber:(EEEventSubscriber *)eventSubscriber
{
  if(!eventSubscriber)
    return;

  NSMutableOrderedSet *subscribers = [self subscribersForEvent:eventSubscriber.id create:NO];
  [subscribers removeObject:eventSubscriber];
}

- (void)unsubscribeFromEventsWithTargetOrOwner:(id)targetOrOwner
{
  if(!targetOrOwner)
    return;

  [_eventSubscribers enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableOrderedSet *subscribers, BOOL *stop) {
    for(NSInteger i = subscribers.count - 1; i >= 0; --i) {
      EEEventSubscriber *subscriber = subscribers[(NSUInteger)i];
      if(subscriber.target == targetOrOwner)
        [subscribers removeObjectAtIndex:(NSUInteger)i];
    }
  }];
}

#pragma mark - Event posting

- (void)postEvent:(EEEvent *)event
{
  NSArray *subscribers = [self subscribersForEvent:event.id create:NO].array;
  if(subscribers.count) {
    [subscribers makeObjectsPerformSelector:@selector(runWithEvent:) withObject:event];
  } else {
    NSLog(@"-@ %@, event has no subscribers", event.id);
  }
}

- (void)postEvent:(NSString *)event info:(NSDictionary *)info
{
  EEEvent *evt = [EEEvent eventWithId:event info:info];
  [self postEvent:evt];
}

#pragma mark - Statistics

// todo: actions and events statistics

@end