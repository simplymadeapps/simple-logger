//
//  ViewController.m
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "ViewController.h"
#import "LogDetailViewController.h"
#import "SimpleLogger.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *savedLogs;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.title = @"Simple Logger";
	
	self.savedLogs = [self savedLogFiles];
	
	UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLogButtonPressed:)];
	self.navigationItem.rightBarButtonItem = add;
}

- (NSArray *)savedLogFiles {
	NSMutableArray *matches = [[NSMutableArray alloc] init];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *contents = [manager contentsOfDirectoryAtPath:docDirectory error:nil];
	
	for (NSString *item in contents) {
		if ([[item pathExtension] isEqualToString:@"log"]) {
			[matches addObject:item];
		}
	}
	
	return matches;
}

- (void)reloadTableData {
	self.savedLogs = [self savedLogFiles];
	[self.tableView reloadData];
}

#pragma mark - Actions
- (void)addLogButtonPressed:(id)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Log" message:@"Add a message to append to the log file." preferredStyle:UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.placeholder = @"enter text to append to log";
		textField.keyboardType = UIKeyboardTypeDefault;
		textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
	}];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *log = [UIAlertAction actionWithTitle:@"Add Log" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		UITextField *logTextField = alert.textFields.firstObject;
		[SimpleLogger logEvent:logTextField.text];
		[self reloadTableData];
	}];
	[alert addAction:cancel];
	[alert addAction:log];
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.savedLogs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	
	cell = [tableView dequeueReusableCellWithIdentifier:@"SimpleLoggerCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SimpleLoggerCell"];
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	NSString *filename = self.savedLogs[indexPath.row];
	
	cell.textLabel.text = filename;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"ShowLogDetailsSegue" sender:self];
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Segue Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	NSString *filename = self.savedLogs[indexPath.row];
	LogDetailViewController *destinationView = segue.destinationViewController;
	destinationView.filename = filename;
}

@end
