//
//  JRKCostcoStore.h
//  IsCostcoOpen
//
//  Created by Jeff Kelley on 2/13/14.
//  Copyright (c) 2014 Jeff Kelley. All rights reserved.
//


#import <Foundation/Foundation.h>

@import MapKit;


@interface JRKCostcoStore : NSObject <MKAnnotation>

- (id)initWithResponse:(NSDictionary *)response
             placemark:(MKPlacemark *)storePlacemark;

- (BOOL)isOpenAtDate:(NSDate *)date;

@end
