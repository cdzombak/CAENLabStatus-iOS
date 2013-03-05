#import <MapKit/MapKit.h>
#import "DZCEmptyDetailViewController.h"

@interface DZCEmptyDetailViewController ()

@property (nonatomic, strong) MKMapView *mapView;

@end

@implementation DZCEmptyDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.mapView.userInteractionEnabled = YES;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsUserLocation = NO;

    [self zoomMapViewToUmich];
    [self.mapView addAnnotations:[self.dataController.labs allObjects]];

    [self.view addSubview:self.mapView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(zoomToMeTapped)];
}

- (void)zoomToMeTapped
{
    if (self.mapView.userTrackingMode == MKUserTrackingModeNone) {
        self.mapView.showsUserLocation = YES;
        self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    } else {
        self.mapView.showsUserLocation = NO;
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
        [self zoomMapViewToUmich];
    }
}

- (void)zoomMapViewToUmich
{
    CLLocationCoordinate2D mapCenter = CLLocationCoordinate2DMake(42.2845, -83.7280);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(mapCenter, 3*DZC_METERS_PER_MILE, 3*DZC_METERS_PER_MILE);
    [self.mapView setRegion:viewRegion animated:NO];
}

@end
