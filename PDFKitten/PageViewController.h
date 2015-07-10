#import <UIKit/UIKit.h>
#import "PageView.h"

@interface PageViewController : UIViewController <PageViewDelegate> {
    IBOutlet PageView *__unsafe_unretained pageView;
}

@property(unsafe_unretained, nonatomic, readonly) PageView *pageView;

@end
