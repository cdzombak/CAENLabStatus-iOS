#import "DZCLabViewController.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "UIColor+DZCColors.h"
#import "DZCLabTableViewManager.h"
#import "CDZTableViewSplitDelegate.h"
#import <MapKit/MapKit.h>

#define DZC_METERS_PER_MILE 1609.344

static const CGFloat DZCLabVCMapStartingZoom = 0.35;
static const CGFloat DZCLabVCMapHeight = 110.0;
static const CGFloat DZCLabVCMapViewYOffset = -150.0;

@interface DZCLabViewController () <UIScrollViewDelegate>

@property (nonatomic, assign) CLLocationCoordinate2D mapZoomLocation;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UIView *bgView;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DZCLabTableViewManager *tvManager;
@property (nonatomic, strong) CDZTableViewSplitDelegate *tvSplitDelegate;

@property (nonatomic, readwrite, strong) DZCLab *lab;

@end

@implementation DZCLabViewController

- (id)initWithLab:(DZCLab *)lab
{
    self = [super init];
    if (self) {
        self.lab = lab;
        self.title = self.lab.humanName;
    }
    return self;
}

#pragma mark - UIViewController view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    UITableViewStyle tvStyle = [DZCLabTableViewManager tableViewStyleForLab:self.lab];
    self.tableView = [[UITableView alloc] initWithFrame:(CGRect){CGPointZero, self.view.bounds.size} style:tvStyle];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];

    self.tvManager = [DZCLabTableViewManager tableViewManagerForLab:self.lab dataController:self.dataController];
    [self.tvManager configureTableView:self.tableView];
    self.tvSplitDelegate = [[CDZTableViewSplitDelegate alloc] initWithScrollViewDelegate:self tableViewDelegate:self.tableView.delegate];
    self.tableView.delegate = self.tvSplitDelegate;

    self.tvManager.vcPushBlock = ^(UIViewController *vc) {
        [self.navigationController pushViewController:vc animated:YES];
    };

    [self setupParallaxView];

    [self.tvManager prepareData];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedIndexPaths.count) {
        for (NSIndexPath *indexPath in selectedIndexPaths) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }

    // we deal with the mapview here because it is destroyed when we leave the screen
    // and recreated when we come back.
    CGFloat mapViewTotalHeight = 2*fabs(DZCLabVCMapViewYOffset)+DZCLabVCMapHeight;
    CGRect mapViewFrame = CGRectMake(0, DZCLabVCMapViewYOffset, self.view.bounds.size.width, mapViewTotalHeight);
    self.mapView = [[MKMapView alloc] initWithFrame:mapViewFrame];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.mapView.userInteractionEnabled = NO;
    self.mapView.mapType = MKMapTypeHybrid;

    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapZoomLocation, DZCLabVCMapStartingZoom*DZC_METERS_PER_MILE, DZCLabVCMapStartingZoom*DZC_METERS_PER_MILE);
    [self.mapView setRegion:viewRegion animated:NO];
    [self.mapView addAnnotation:self.lab];

    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.mapView removeFromSuperview];
    self.mapView = nil;
}

- (void)headerViewTouched:(id)sender
{
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.mapZoomLocation
                                                       addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        mapItem.name = self.lab.humanName;
        [mapItem openInMapsWithLaunchOptions:nil];
    }
}

#pragma mark - Top view and parallax creation

- (void)setupParallaxView
{
    if (self.tableView.backgroundView) {
        // If someone wants to give me any hints on managing the background of a group-style
        // table view while still having a transparent header view, please do.

        self.bgView = [[UIView alloc] initWithFrame:self.tableView.backgroundView.frame];
        self.bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.bgView.backgroundColor = [UIColor dzc_groupTableViewBackgroundColor];

        CGRect bgFrame = self.bgView.frame;
        bgFrame.origin.y = DZCLabVCMapHeight;
        self.bgView.frame = bgFrame;

        [self.view addSubview:self.bgView];
        [self.view sendSubviewToBack:self.bgView];

        self.view.backgroundColor = [UIColor dzc_groupTableViewBackgroundColor];
        self.tableView.backgroundView = nil;
    }

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, DZCLabVCMapHeight)];
    tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableHeaderView.backgroundColor = [UIColor clearColor];
    UIView *blackBorderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, DZCLabVCMapHeight-1.0, self.view.bounds.size.width, 1.0)];
    blackBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    blackBorderView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [tableHeaderView addSubview:blackBorderView];
    self.tableView.tableHeaderView = tableHeaderView;

    UIGestureRecognizer *headerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerViewTouched:)];
    [tableHeaderView addGestureRecognizer:headerTapRecognizer];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGRect mapViewFrame = self.mapView.frame;
    CGRect bgViewFrame = self.bgView.frame;
    CGFloat mileZoom = DZCLabVCMapStartingZoom;

    if (scrollOffset < 0) {
        mapViewFrame.origin.y = DZCLabVCMapViewYOffset - (scrollOffset / 3.0);
        mileZoom += scrollOffset/3.0/900.0;
    } else {
        // We're scrolling up, return to normal behavior
        mapViewFrame.origin.y = DZCLabVCMapViewYOffset - scrollOffset;
    }

    bgViewFrame.origin.y = DZCLabVCMapHeight - scrollOffset;

//    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapZoomLocation, mileZoom*DZC_METERS_PER_MILE, mileZoom*DZC_METERS_PER_MILE);
//    [self.mapView setRegion:viewRegion animated:NO];

    self.bgView.frame = bgViewFrame;
    self.mapView.frame = mapViewFrame;
}

#pragma mark - Property overrides

- (void)setLab:(DZCLab *)lab
{
    _lab = lab;
    self.mapZoomLocation = lab.coordinate;
}

@end
