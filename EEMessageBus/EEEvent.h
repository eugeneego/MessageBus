#import <Foundation/Foundation.h>

@class EEEvent;

typedef void (^EEEventBlock)(EEEvent *action);


@interface EEEventSubscriber : NSObject

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, weak, readonly) id target;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, copy, readonly) EEEventBlock block;

+ (instancetype)subscriberWithId:(NSString *)id target:(id)target selector:(SEL)selector;
+ (instancetype)subscriberWithId:(NSString *)id owner:(id)owner block:(EEEventBlock)block;
- (instancetype)initWithId:(NSString *)id target:(id)target selector:(SEL)selector;
- (instancetype)initWithId:(NSString *)id owner:(id)owner block:(EEEventBlock)block;

- (void)runWithEvent:(EEEvent *)event;

@end


@interface EEEventProducer : NSObject

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, weak, readonly) id producer;

+ (instancetype)producerWithId:(NSString *)id producer:(id)producer;
- (instancetype)initWithId:(NSString *)id producer:(id)producer;

@end


@interface EEEvent: NSObject

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSDictionary *info;

+ (instancetype)eventWithId:(NSString *)id info:(NSDictionary *)info;
- (instancetype)initWithId:(NSString *)id info:(NSDictionary *)info;

@end
