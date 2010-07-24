//
//  VoicesViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VoicesViewController.h"
#import "CommodityFunctions.h"


@implementation VoicesViewController
@synthesize teamDictionary, voiceArray, lastIndexPath;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    srandom(time(NULL));

    voiceBeingPlayed = NULL;

    // load all the voices names and store them into voiceArray
    // it's here and not in viewWillAppear because user cannot add/remove them
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:VOICES_DIRECTORY() error:NULL];
    self.voiceArray = array;
    
    self.title = NSLocalizedString(@"Set hedgehog voices",@"");
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // this moves the tableview to the top
    [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(voiceBeingPlayed != NULL) {
        Mix_HaltChannel(lastChannel);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.voiceArray count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *voice = [[voiceArray objectAtIndex:[indexPath row]] stringByDeletingPathExtension];
    cell.textLabel.text = voice;
    
    if ([voice isEqualToString:[teamDictionary objectForKey:@"voicepack"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastIndexPath = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int newRow = [indexPath row];
    int oldRow = (lastIndexPath != nil) ? [lastIndexPath row] : -1;
    
    if (newRow != oldRow) {
        [teamDictionary setObject:[voiceArray objectAtIndex:newRow] forKey:@"voicepack"];
        
        // tell our boss to write this new stuff on disk
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWriteNeedTeams" object:nil];
        [self.tableView reloadData];
        
        self.lastIndexPath = indexPath;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } 
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (voiceBeingPlayed != NULL) {
        Mix_HaltChannel(lastChannel);
        Mix_FreeChunk(voiceBeingPlayed);
        voiceBeingPlayed = NULL;
    }
    
    NSString *voiceDir = [[NSString alloc] initWithFormat:@"%@/%@/",VOICES_DIRECTORY(),[voiceArray objectAtIndex:newRow]];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:voiceDir error:NULL];
    
    int index = random() % [array count];
    
    voiceBeingPlayed = Mix_LoadWAV([[voiceDir stringByAppendingString:[array objectAtIndex:index]] UTF8String]);
    [voiceDir release];
    lastChannel = Mix_PlayChannel(-1, voiceBeingPlayed, 0);    
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    voiceBeingPlayed = NULL;
    self.lastIndexPath = nil;
    self.teamDictionary = nil;
    self.voiceArray = nil;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [voiceArray release];
    [teamDictionary release];
    [lastIndexPath release];
    [super dealloc];
}


@end

