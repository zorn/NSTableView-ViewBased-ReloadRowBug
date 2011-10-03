#import "NSArray+CBAdditions.h"

@implementation NSArray (CBAdditions)

- (id)randomObject
{
	NSUInteger countOfItems = [self count];
	NSUInteger randomIndex = random() % countOfItems;
	return [self objectAtIndex:randomIndex];
}

- (BOOL)cb_containsObjectOfClass:(Class)someClass
{
    __block BOOL answer = NO;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:someClass]) {
            answer = YES;
            *stop = YES;
        }
    }];
    return answer;
}

@end