#import <Foundation/Foundation.h>
#import "EEAction.h"
#import "EEEvent.h"

@class EEEventSubscriber;

@interface EEMessageBus : NSObject

+ (instancetype)instance;

- (void)unregister:(id)object;

// actions

- (EEActionSubscriber *)registerAction:(NSString *)action target:(id)target selector:(SEL)selector;
- (EEActionSubscriber *)registerAction:(NSString *)action owner:(id)owner block:(EEActionBlock)block;
- (void)unregisterAction:(NSString *)action target:(id)target;
- (void)unregisterAction:(NSString *)action owner:(id)owner;
- (void)unregisterActionSubscriber:(EEActionSubscriber *)actionSubscriber;
- (void)unregisterActionsWithTargetOrOwner:(id)targetOrOwner;

- (EEAction *)action:(NSString *)action parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback;
- (EEAction *)runAction:(NSString *)action parameters:(NSDictionary *)parameters;
- (EEAction *)runAction:(NSString *)action parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback;
- (EEAction *)runAction:(EEAction *)action;

// events

- (void)registerEvent:(NSString *)event producer:(id)producer;
- (void)unregisterEvent:(NSString *)event producer:(id)producer;
- (void)unregisterEventProducer:(id)producer;

- (EEEventSubscriber *)subscribeToEvent:(NSString *)event target:(id)target selector:(SEL)selector;
- (EEEventSubscriber *)subscribeToEvent:(NSString *)event owner:(id)owner block:(EEEventBlock)block;
- (void)unsubscribeFromEvent:(NSString *)event target:(id)target;
- (void)unsubscribeFromEvent:(NSString *)event owner:(id)owner;
- (void)unregisterEventSubscriber:(EEEventSubscriber *)eventSubscriber;
- (void)unsubscribeFromEventsWithTargetOrOwner:(id)targetOrOwner;

- (void)postEvent:(EEEvent *)event;
- (void)postEvent:(NSString *)event info:(NSDictionary *)info;

@end