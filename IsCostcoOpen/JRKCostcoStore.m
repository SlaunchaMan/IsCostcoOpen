//
//  JRKCostcoStore.m
//  IsCostcoOpen
//
//  Created by Jeff Kelley on 2/13/14.
//  Copyright (c) 2014 Jeff Kelley. All rights reserved.
//


#import "JRKCostcoStore.h"


@interface JRKCostcoStore ()

@property (strong) MKPlacemark *storePlacemark;
@property (strong) NSTimeZone *timeZone;

@end


@implementation JRKCostcoStore

#pragma mark - Costco Store Lifecycle

- (id)initWithResponse:(NSDictionary *)response
             placemark:(MKPlacemark *)storePlacemark
{
    self = [super init];
    
    if (self) {
        _storePlacemark = storePlacemark;
        
        NSString *timeZoneID = response[@"timeZoneId"];
        
        NSLog(@"Time zone ID: %@", timeZoneID);
        
        if (timeZoneID) {
            self.timeZone = [NSTimeZone timeZoneWithName:timeZoneID];
        }
    }
    
    return self;
}

- (BOOL)isOpenAtDate:(NSDate *)date
{
    BOOL isOpen = NO;
    
    NSCalendar *calendar =
    [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    calendar.timeZone = self.timeZone;
    
    NSDateComponents *nowComponents =
    [calendar components:(NSWeekdayCalendarUnit |
                          NSHourCalendarUnit |
                          NSMinuteCalendarUnit |
                          NSMonthCalendarUnit |
                          NSDayCalendarUnit |
                          NSYearCalendarUnit)
                fromDate:date];
    
    NSDateComponents *openingComponents = [nowComponents copy];
    NSDateComponents *closingComponents = [nowComponents copy];
    
    if (nowComponents.weekday == 1) {
        // Sunday
        openingComponents.hour = 10;
        openingComponents.minute = 0;
        
        closingComponents.hour = 18;
        closingComponents.minute = 0;
    }
    else if (nowComponents.weekday == 7) {
        // Saturday
        openingComponents.hour = 9;
        openingComponents.minute = 30;
        
        closingComponents.hour = 18;
        closingComponents.minute = 0;
    }
    else {
        // Monday - Friday
        openingComponents.hour = 10;
        openingComponents.minute = 0;
        
        closingComponents.hour = 20;
        closingComponents.minute = 30;
    }
    
    NSDate *openingDate = [calendar dateFromComponents:openingComponents];
    NSDate *closingDate = [calendar dateFromComponents:closingComponents];
    
    isOpen = (([openingDate compare:date] == NSOrderedAscending) &&
              ([closingDate compare:date] == NSOrderedDescending));
    
    return isOpen;
}

#pragma mark - MKAnnotation Protocol Methods

- (CLLocationCoordinate2D)coordinate
{
    return self.storePlacemark.coordinate;
}

- (NSString *)subtitle
{
    return self.storePlacemark.title;
}

- (NSString *)title
{
    return self.storePlacemark.name;
}

#pragma mark -

@end
