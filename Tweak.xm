#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FCMessageString.h"
#import "ChatCoreGUILink.h"
#import "MVChatObject.h"
#import "MVIRCChatConnection.h"
#import "FlowChatAppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIDeviceExtensions.h"

@interface hooks : NSObject {
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
    BOOL backgrounded;
}

-(void)NotificationsSwitched:(id)sender;
+(id)sharedInstance;
-(void)NoticeMessagesSwitched:(id)sender;
-(void)checkMultitaskingTime;

@property (assign) BOOL backgrounded;
@property (assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation hooks

@synthesize backgroundTaskIdentifier;
@synthesize backgrounded;

static hooks* hookPtr = nil;
//static AVAudioPlayer *player = nil; // ugly backgrounding hoooks i decided to get rid of.

+(id)sharedInstance {
    @synchronized(self)
    {
        if(!hookPtr) {
            hookPtr = [[hooks alloc] init];
            hookPtr.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            hookPtr.backgrounded = NO;
        }
        
        return hookPtr;
    }
}

-(void)NotificationsSwitched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender isOn] forKey:@"UILocalNotifications"];
    [defaults synchronize];
}

-(void)NoticeMessagesSwitched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender isOn] forKey:@"NoticeMessages"];
    [defaults synchronize];
}

-(void)_didEnterBackground {
    NSLog(@"entered background");
    self.backgrounded = YES;
    [NSThread detachNewThreadSelector:@selector(checkMultitaskingTime) toTarget:self withObject:nil];
}


-(void)_didEnterForeground {
    
    NSLog(@"entered foreground");
    self.backgrounded = NO;
}

-(void)checkMultitaskingTime {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    while([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        [NSThread sleepForTimeInterval:1.0f];
        NSTimeInterval time = [[UIApplication sharedApplication] backgroundTimeRemaining];
        //NSLog(@"Time remaining is %f", time);
        if(round(time) == 90.0){
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertBody = @"FlowChat only has 1:30 until it is terminated.\n Please relaunch soon";
            notification.alertAction = @"Open";
            notification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            [notification release];
        }
    }
    
    [pool drain];
}

@end

#define UINotify @"UILocalNotifications"
#define Notice @"NoticeMessages"


typedef enum {
    UIDeviceUnknown,
    
    UIDeviceiPhoneSimulator,
    UIDeviceiPhoneSimulatoriPhone, // both regular and iPhone 4 devices
    UIDeviceiPhoneSimulatoriPad,
    
    UIDevice1GiPhone,
    UIDevice3GiPhone,
    UIDevice3GSiPhone,
    UIDevice4iPhone,
    UIDevice5iPhone,
    
    UIDevice1GiPod,
    UIDevice2GiPod,
    UIDevice3GiPod,
    UIDevice4GiPod,
    
    UIDevice1GiPad,
    UIDevice2GiPad,
    UIDevice3GiPad,
    
    UIDeviceAppleTV2,
    UIDeviceUnknownAppleTV,
    
    UIDeviceUnknowniPhone,
    UIDeviceUnknowniPod,
    UIDeviceUnknowniPad,
    UIDeviceIFPGA,
    
} UIDevicePlatform;

#define IFPGA_NAMESTRING                @"iFPGA"

#define IPHONE_1G_NAMESTRING            @"iPhone 1G"
#define IPHONE_3G_NAMESTRING            @"iPhone 3G"
#define IPHONE_3GS_NAMESTRING           @"iPhone 3GS" 
#define IPHONE_4_NAMESTRING             @"iPhone 4" 
#define IPHONE_5_NAMESTRING             @"iPhone 5"
#define IPHONE_UNKNOWN_NAMESTRING       @"Unknown iPhone"

#define IPOD_1G_NAMESTRING              @"iPod touch 1G"
#define IPOD_2G_NAMESTRING              @"iPod touch 2G"
#define IPOD_3G_NAMESTRING              @"iPod touch 3G"
#define IPOD_4G_NAMESTRING              @"iPod touch 4G"
#define IPOD_UNKNOWN_NAMESTRING         @"Unknown iPod"

#define IPAD_1G_NAMESTRING              @"iPad 1G"
#define IPAD_2G_NAMESTRING              @"iPad 2G"
#define IPAD_3G_NAMESTRING              @"iPad 3G"
#define IPAD_UNKNOWN_NAMESTRING         @"Unknown iPad"

#define APPLETV_2G_NAMESTRING           @"Apple TV 2G"
#define APPLETV_UNKNOWN_NAMESTRING      @"Unknown Apple TV"

#define IOS_FAMILY_UNKNOWN_DEVICE       @"Unknown iOS device"

#define IPHONE_SIMULATOR_NAMESTRING         @"iPhone Simulator"
#define IPHONE_SIMULATOR_IPHONE_NAMESTRING  @"iPhone Simulator"
#define IPHONE_SIMULATOR_IPAD_NAMESTRING    @"iPad Simulator"


//***************************BEGIN HOOKS************************


%hook FlowChatAppDelegate

-(void)application:(id)application didFinishLaunchingWithOptions:(id)options {
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
NSLog(@"Hooked finishedLaunching");
//NSString *path = [[[[NSBundle mainBundle] pathForResource:@"FlowChat.bundle" ofType:nil] stringByAppendingPathComponent:@"sounds/Futuristic"] stringByAppendingPathComponent:@"alert.aif"];
//NSLog(@"%@", path);
//NSURL *url = [NSURL fileURLWithPath:path];
hooks *hk = [hooks sharedInstance];
[[NSNotificationCenter defaultCenter] addObserver:hk selector:@selector(_didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
[[NSNotificationCenter defaultCenter] addObserver:hk selector:@selector(_didEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];


hk.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{ 

hooks *hk = [hooks sharedInstance];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Backgrounding Expired, All connections closed.";
    notification.alertAction = @"Open";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [notification release];
    [[UIApplication sharedApplication] endBackgroundTask:hk.backgroundTaskIdentifier];
hk.backgroundTaskIdentifier = UIBackgroundTaskInvalid;

}];
/*MPMusicPlayerController *iPod = [MPMusicPlayerController iPodMusicPlayer];
    if([iPod playbackState] != MPMusicPlaybackStatePlaying) {
        if(!player)
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        player.volume = 0.3;
        player.numberOfLoops = -1;
        [player play];
    }*/
[pool drain];
%orig;
return;
}

%end

%hook FCMessageString

-(id)initWithMessage:(id)message fromNick:(id)Nick withTarget:(id)Target withReason:(id)Reason isMine:(id)isMine highlight:(id)highlight atDate:(id)date withType:(id)type {
    FCMessageString *ptr = (FCMessageString*)%orig;
hooks *hk = [hooks sharedInstance];
if(hk.backgroundTaskIdentifier != UIBackgroundTaskInvalid && [[hooks sharedInstance] backgrounded] == TRUE) {
// post notification
if ([[ptr hasHighlight] intValue] == TRUE) {
//post notification
UILocalNotification *notification = [[UILocalNotification alloc] init];
notification.alertBody = [NSString stringWithFormat:@"%@ from %@ %@: %@", @"Highlight", Nick, date, message];
notification.alertAction = @"Open";
notification.soundName = UILocalNotificationDefaultSoundName;
if([[NSUserDefaults standardUserDefaults] boolForKey:UINotify] == TRUE)
[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
[notification release];
        }
    }
return ptr;
}
%end

%hook NHSound

-(void)play:(id)alert {
    if( [[hooks sharedInstance] backgrounded] == TRUE) {
        return;
    }
    else %orig;
}

%end

%hook ChatCoreGUILink

-(void)gotPrivMsg:(id)alert {
    if([[hooks sharedInstance] backgrounded] == FALSE) {
        %orig;
        return;
    }
    NSDictionary *userInfo = [alert userInfo];
    NSString *fromUser = [userInfo objectForKey:@"user"];
    if([[[NSUserDefaults standardUserDefaults] arrayForKey:@"ignores"] containsObject:nil])
        return;
    NSString *date = [self getCurrentDate];
    NSString *message = [[NSString alloc] initWithData:[userInfo objectForKey:@"message"] encoding:NSUTF8StringEncoding];
    if(!message) message = [[NSString alloc] initWithData:[userInfo objectForKey:@"message"] encoding:NSWindowsCP1250StringEncoding];
        if(!message) message = [[NSString alloc] initWithData:[userInfo objectForKey:@"message"] encoding:NSASCIIStringEncoding];
            BOOL isNotice = [[userInfo objectForKey:@"notice"] boolValue];
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            switch (isNotice) {
                case 0:
                    //not notice
                    notification.alertBody = [NSString stringWithFormat:@"%@ from %@ %@: %@", @"Private Message", fromUser, date, message];
                    notification.alertAction = @"Open";
                    notification.soundName = UILocalNotificationDefaultSoundName;
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                    
                    break;
                case 1:
                    if([[NSUserDefaults standardUserDefaults] boolForKey:@"NoticeMessages"] == TRUE)
                        notification.alertBody = [NSString stringWithFormat:@"%@ from %@ %@: %@", @"Notice Message", fromUser, date, message];
                    notification.alertAction = @"Open";
                    notification.soundName = UILocalNotificationDefaultSoundName;
                    if([[NSUserDefaults standardUserDefaults] boolForKey:Notice] == TRUE)
                        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                    break;
                default:
                    break;
            }
    %orig;
    [notification release];
    [message release];
}

-(void)kickedFromChannel:(id)channel {
    if([[hooks sharedInstance] backgrounded] == FALSE) {
        %orig;
        return;
    }
    id object = [channel object];
    MVIRCChatConnection *connection = [object connection];
    NSDictionary *userInfo = [channel userInfo];
    NSString *oname = [[userInfo objectForKey:@"byUser"] oname]; //mvchatobject
    NSString *object_oname = [object oname];
    NSData * reason = [userInfo objectForKey:@"reason"];
    NSString *reasonstr = [[connection _newStringWithBytes:(const char*)[reason bytes] length:[reason length]] autorelease];
    NSString *server = [connection server];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:@"You were kicked from %@ by %@ on %@ with the reason: %@", object_oname, oname, server, reasonstr];
    notification.alertAction = @"Open";
    notification.soundName = UILocalNotificationDefaultSoundName;
    if([[NSUserDefaults standardUserDefaults] boolForKey:UINotify] == TRUE)
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [notification release];
    %orig;
}

-(void)didDisconnect:(id)arg {
    if([[hooks sharedInstance] backgrounded] == FALSE) return;
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Internet Connection Lost:\n All IRC Connnections Dropped.";
    notification.alertAction = @"Open";
    notification.soundName = UILocalNotificationDefaultSoundName;
    if([[NSUserDefaults standardUserDefaults] boolForKey:UINotify] == TRUE)
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [notification release];
    %orig;
}

%end

%hook PreferencesController 

-(NSUInteger)numberOfSectionsInTableView:(id)view {
    return %orig +1;
}

-(NSString*)tableView:(id)view titleForHeaderInSection:(NSUInteger)section {
    if(section == 5) {
        // we are in our new
        return @"Mods";
    }
    else return %orig;
}

-(NSUInteger)tableView:(id)view numberOfRowsInSection:(NSUInteger)section {
    if(section == 5) {
        //NSLog(@"fixed rows");
        return 2;
    }
    else return %orig;
}

-(UITableViewCell*)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath*)path {
    if([path section] == 5) {
       // NSLog(@"Drawing cells");
        static NSString *CellIdentifier = @"Mods";
        
        UITableViewCell *cell = [view dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        id object = [[NSUserDefaults standardUserDefaults] objectForKey:@"UILocalNotifications"];
        if(!object) {
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"UILocalNotifications"];
        }
        id object2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"NoticeMessages"]; 
        if(!object2) {
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"NoticeMessages"];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UISwitch *settingsSwitch;
        
        switch ([path row]) {
            case 0:
                cell.textLabel.text = @"Notifications";
                settingsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                [settingsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"UILocalNotifications"]];
                [settingsSwitch addTarget:[hooks sharedInstance] action:@selector(NotificationsSwitched:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = settingsSwitch;
                [settingsSwitch release];
                break;
            case 1:
                cell.textLabel.text = @"Receive Notices";
                settingsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                [settingsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"NoticeMessages"]];
                [settingsSwitch addTarget:[hooks sharedInstance] action:@selector(NoticeMessagesSwitched:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = settingsSwitch;
                [settingsSwitch release];
                break;
            default:
                break;
        }
        return cell;
        //end switch
        
    }
    else return %orig;
}

-(NSString*)tableView:(id)view titleForFooterInSection:(NSUInteger)section {
    if (section == 4) return nil;
    if(section == 5) return %orig(view, 4);
        else return nil;
}

%end

%hook NSBundle

-(NSDictionary*)infoDictionary {
    NSMutableDictionary *dict = [%orig mutableCopy];
    [dict setObject:@"Mod.2.0.0-NH" forKey:@"CFBundleVersion"];
    return [dict autorelease];
}

%end

%hook OutgoingMessageParser

-(NSArray*)supportedCommands {
    NSMutableArray *array = [%orig mutableCopy];
    [array addObject:@"/np"];
    [array addObject:@"/ipod"];
    [array addObject:@"/music"];
    [array addObject:@"/nowplaying"];
    [array addObject:@"/keyx"];
    return [array autorelease];
}

-(void)handleCommand:(NSString*)command withArguments:(NSArray*)arguments {
    NSString *cmd = [command stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if([cmd isEqualToString:@"np"] || [cmd isEqualToString:@"ipod"] || [cmd isEqualToString:@"music"] || [cmd isEqualToString:@"nowplaying"]) {
        NSString *message;
        NSLog(@"Our addons!");
        MPMediaItem * song = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
        id attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:TRUE], @"action", nil];
        if(!song) {
            NSLog(@"NotPlaying");
            message = @"is currently not playing anything in iPod.app";
            //attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:TRUE] forKey:@"action"];
        }
        else {
        NSString * title   = [song valueForProperty:MPMediaItemPropertyTitle];
        NSString * album   = [song valueForProperty:MPMediaItemPropertyAlbumTitle];
        NSString * artist  = [song valueForProperty:MPMediaItemPropertyArtist];
        NSTimeInterval current = [[MPMusicPlayerController iPodMusicPlayer] currentPlaybackTime];
        NSTimeInterval length = [[song valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        double minutes = floor(current/60);
        double seconds = round(current - minutes * 60);
        double lminutes = floor(length/60);
        double lseconds = round(length - lminutes * 60);
        message = [NSString stringWithFormat:@"is listening to \"%@\" by %@, from the album %@. [%02i:%02i/%02i:%02i]", title, artist, album, (int)minutes, (int)seconds, (int)lminutes, (int)lseconds];
        }
        id delegate = [[UIApplication sharedApplication] delegate];
        id GUILink = [delegate currentGUILink];
        id currentChat = [GUILink currentChat];
        id connection = [currentChat connection];
        [connection sendMessage:message withEncoding:[connection encoding] toTarget:currentChat withAttributes:attributes];
        NSNumber *number = [NSNumber numberWithBool:TRUE];
        MVChatUser * localuser = [connection localUser];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:number, @"myMessage", message, @"messageString", localuser,@"userObject", currentChat, @"chatObject", [NSNumber numberWithBool:TRUE], @"action", nil];
        [self processMessageWithInfo:dict];
        return;
    }
    else %orig;
        return;

}

%end

%hook UIDevice

-(NSString*)platformString {
    switch ((NSUInteger)[self platformType])
    {
        case UIDevice1GiPhone: return IPHONE_1G_NAMESTRING;
        case UIDevice3GiPhone: return IPHONE_3G_NAMESTRING;
        case UIDevice3GSiPhone: return IPHONE_3GS_NAMESTRING;
        case UIDevice4iPhone: return IPHONE_4_NAMESTRING;
        case UIDevice5iPhone: return IPHONE_5_NAMESTRING;
        case UIDeviceUnknowniPhone: return IPHONE_UNKNOWN_NAMESTRING;
            
        case UIDevice1GiPod: return IPOD_1G_NAMESTRING;
        case UIDevice2GiPod: return IPOD_2G_NAMESTRING;
        case UIDevice3GiPod: return IPOD_3G_NAMESTRING;
        case UIDevice4GiPod: return IPOD_4G_NAMESTRING;
        case UIDeviceUnknowniPod: return IPOD_UNKNOWN_NAMESTRING;
            
        case UIDevice1GiPad : return IPAD_1G_NAMESTRING;
        case UIDevice2GiPad : return IPAD_2G_NAMESTRING;
        case UIDevice3GiPad : return IPAD_3G_NAMESTRING;
        case UIDeviceUnknowniPad : return IPAD_UNKNOWN_NAMESTRING;
            
        case UIDeviceAppleTV2 : return APPLETV_2G_NAMESTRING;
        case UIDeviceUnknownAppleTV: return APPLETV_UNKNOWN_NAMESTRING;
            
        case UIDeviceiPhoneSimulator: return IPHONE_SIMULATOR_NAMESTRING;
        case UIDeviceiPhoneSimulatoriPhone: return IPHONE_SIMULATOR_IPHONE_NAMESTRING;
        case UIDeviceiPhoneSimulatoriPad: return IPHONE_SIMULATOR_IPAD_NAMESTRING;
            
        case UIDeviceIFPGA: return IFPGA_NAMESTRING;
            
        default: return IOS_FAMILY_UNKNOWN_DEVICE;
    }
}

-(NSUInteger)platformType {
    NSString *platform = (NSString*)[self platform];
    
    // The ever mysterious iFPGA
    if ([platform isEqualToString:@"iFPGA"])        return UIDeviceIFPGA;
    
    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"])    return UIDevice1GiPhone;
    if ([platform isEqualToString:@"iPhone1,2"])    return UIDevice3GiPhone;
    if ([platform hasPrefix:@"iPhone2"])            return UIDevice3GSiPhone;
    if ([platform hasPrefix:@"iPhone3"])            return UIDevice4iPhone;
    if ([platform hasPrefix:@"iPhone4"])            return UIDevice5iPhone;
    
    // iPod
    if ([platform hasPrefix:@"iPod1"])             return UIDevice1GiPod;
    if ([platform hasPrefix:@"iPod2"])              return UIDevice2GiPod;
    if ([platform hasPrefix:@"iPod3"])              return UIDevice3GiPod;
    if ([platform hasPrefix:@"iPod4"])              return UIDevice4GiPod;
    
    // iPad
    if ([platform hasPrefix:@"iPad1"])              return UIDevice1GiPad;
    if ([platform hasPrefix:@"iPad2"])              return UIDevice2GiPad;
    if ([platform hasPrefix:@"iPad3"])              return UIDevice3GiPad;
    
    // Apple TV
    if ([platform hasPrefix:@"AppleTV2"])           return UIDeviceAppleTV2;
    
    if ([platform hasPrefix:@"iPhone"])             return UIDeviceUnknowniPhone;
    if ([platform hasPrefix:@"iPod"])               return UIDeviceUnknowniPod;
    if ([platform hasPrefix:@"iPad"])               return UIDeviceUnknowniPad;
    
    // Simulator thanks Jordan Breeding
    if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"])
    {
        BOOL smallerScreen = [[UIScreen mainScreen] bounds].size.width < 768;
        return smallerScreen ? UIDeviceiPhoneSimulatoriPhone : UIDeviceiPhoneSimulatoriPad;
    }
    
    return UIDeviceUnknown;
}

%end


@interface NSDictionary (NSDictionaryExtensions)

-(BOOL) boolForKey: (id) aKey;
-(int) intForKey: (id) aKey;
-(BOOL) hasKey: (id) aKey;


@end


@implementation NSDictionary (NSDictionaryExtensions)

-(BOOL) boolForKey: (id) aKey
{
    BOOL result = NO; // lame default return value
    id <NSObject> obj = [self objectForKey:aKey];
    if (obj) {
        SEL bv = @selector(boolValue);
        if ([obj respondsToSelector:bv])
            result = ([obj performSelector:bv] ? YES : NO);
        else if ([obj isKindOfClass:[NSString class]]) {
            result = ([(NSString *)obj caseInsensitiveCompare: @"YES"] == NSOrderedSame);
            if (!result)
                result = ([(NSString *)obj caseInsensitiveCompare: @"TRUE"] == NSOrderedSame);
        }
    }
    return result;
}

-(int) intForKey: (id) aKey
{
    int result = 0; // lame default return value
    id <NSObject> obj = [self objectForKey:aKey];
    if (obj) {
        SEL iv = @selector(intValue);
        if ([obj respondsToSelector:iv])
            result = (int)[obj performSelector:iv];
    }
    return result;
}

-(BOOL) hasKey: (id) testKey
{
    return ([self objectForKey:testKey] != nil);
}


@end
