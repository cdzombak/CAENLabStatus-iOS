#import "DZCLabViewController.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "UIColor+DZCColors.h"
#import "DZCLabTableViewManager.h"
#import "CDZTableViewSplitDelegate.h"
#import <MapKit/MapKit.h>

#define DZC_METERS_PER_MILE 1609.344

static const CGFloat DZCLabVCMapStartingZoom = 0.4;
static const CGFloat DZCLabVCMapHeight = 100.0;
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

    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapZoomLocation, DZCLabVCMapStartingZoom*DZC_METERS_PER_MILE, DZCLabVCMapStartingZoom*DZC_METERS_PER_MILE);
    [self.mapView setRegion:viewRegion animated:NO];
    [self.mapView addAnnotation:self.lab];

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView flashScrollIndicators];
}

#pragma mark - Top view and parallax creation

- (void)setupParallaxView
{
    if (self.tableView.backgroundView) {
        // backgrounds with this stuff are hard
        UIView *bgView = self.tableView.backgroundView;
        self.tableView.backgroundView = nil;
        bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        CGRect bgFrame = bgView.frame;
        bgFrame.origin.y = DZCLabVCMapHeight;
        bgFrame.size.height += 200; // for good measure.
        bgView.frame = bgFrame;
        [self.view addSubview:bgView];
        [self.view sendSubviewToBack:bgView];

        self.bgView = bgView;
    }

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, DZCLabVCMapHeight)];
    tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableHeaderView.backgroundColor = [UIColor clearColor];
    UIView *blackBorderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, DZCLabVCMapHeight-1.0, self.view.bounds.size.width, 1.0)];
    blackBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    blackBorderView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [tableHeaderView addSubview:blackBorderView];
    self.tableView.tableHeaderView = tableHeaderView;

    CGFloat mapViewTotalHeight = 2*fabs(DZCLabVCMapViewYOffset)+tableHeaderView.bounds.size.height;
    CGRect mapViewFrame = CGRectMake(0, DZCLabVCMapViewYOffset, self.view.bounds.size.width, mapViewTotalHeight);
    self.mapView = [[MKMapView alloc] initWithFrame:mapViewFrame];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.mapView.userInteractionEnabled = NO;
    self.mapView.mapType = MKMapTypeHybrid;
    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
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

    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapZoomLocation, mileZoom*DZC_METERS_PER_MILE, mileZoom*DZC_METERS_PER_MILE);
    [self.mapView setRegion:viewRegion animated:NO];

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
