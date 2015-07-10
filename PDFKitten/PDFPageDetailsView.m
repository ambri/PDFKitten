#import "PDFPageDetailsView.h"

@implementation PDFPageDetailsView

- (id)initWithFont:(PDFFontCollection *)aFontCollection {
    fontCollection = aFontCollection;
    UITableViewController *rvc = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    rvc.tableView.delegate = self;
    rvc.tableView.dataSource = self;
    self = [super initWithRootViewController:rvc];
    self.navigationBarHidden = YES;
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[fontCollection fontsByName] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [fontCollection names][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSString *name = [fontCollection names][indexPath.section];
    PDFFont *font = [fontCollection fontNamed:name];
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Type";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [font class]];
            break;
        case 1: {
            NSRange range = font.widthsRange;
            cell.textLabel.text = @"Widths";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu (%lu - %lu)", (unsigned long)[[font widths] count], (unsigned long)range.location, (unsigned long)NSMaxRange(range)];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            break;
        }
        case 2:
            cell.textLabel.text = @"Flags";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[font fontDescriptor] flags]];
            break;
        default:
            break;
    }

    return cell;
}


@end
