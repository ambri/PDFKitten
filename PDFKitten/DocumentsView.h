#import <UIKit/UIKit.h>

@interface DocumentsView : UINavigationController <UITableViewDelegate, UITableViewDataSource> {
	UITableViewController *tableViewController;
	NSArray *documents;
	NSDictionary *urlsByName;
	
	id __unsafe_unretained delegate;
}

@property (nonatomic, unsafe_unretained) id delegate;
@end
