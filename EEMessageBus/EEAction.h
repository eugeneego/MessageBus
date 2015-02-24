#import <Foundation/Foundation.h>

@class EEAction;

typedef void (^EEActionBlock)(EEAction *action);


@interface EEActionSubscriber: NSObject

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, weak, readonly) id target;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, copy, readonly) EEActionBlock block;

+ (instancetype)subscriberWithId:(NSString *)id target:(id)target selector:(SEL)selector;
+ (instancetype)subscriberWithId:(NSString *)id owner:(id)owner block:(EEActionBlock)block;
- (instancetype)initWithId:(NSString *)id target:(id)target selector:(SEL)selector;
- (instancetype)initWithId:(NSString *)id owner:(id)owner block:(EEActionBlock)block;

- (void)runWithAction:(EEAction *)action;

@end


@interface EEAction: NSObject

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSDictionary *parameters;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy) NSDictionary *resultTraits;
@property (nonatomic, copy, readonly) EEActionBlock callback;

+ (instancetype)actionWithSubscribers:(NSArray *)subscribers id:(NSString *)id parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback;
+ (instancetype)actionWithId:(NSString *)id parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback;
+ (instancetype)actionWithId:(NSString *)id parameters:(NSDictionary *)parameters;
- (instancetype)initWithSubscribers:(NSArray *)subscribers id:(NSString *)id parameters:(NSDictionary *)parameters callback:(EEActionBlock)callback;

- (instancetype)run;
- (instancetype)runWithSubscribers:(NSArray *)subscribers;

- (void)finish;
- (void)finishWithResult:(id)result error:(NSError *)error resultTraits:(NSDictionary *)resultTraits;

@end
