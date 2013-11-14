#import "ViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "GDataXMLNode.h"
#import "UIImageView+WebCache.h"

@interface ViewController () <ASIHTTPRequestDelegate>
{
    UIScrollView *scrollView;
}
// 开始请求
- (void)startRequest;
- (void)startPostRequest;
// 解析XML
- (NSArray *)parseXMLString:(NSString *)xmlString;
//刷新scrollView
- (void)updateScrollViewWithDatasource:(NSArray *)datasource;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // @"http://lab.hudong.com/ipad/zutujingxuan.xml"
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 10, 320, 540)];
    [self.view addSubview:scrollView];
    // 开始请求
    [self startRequest];

}

- (void)startPostRequest
{
    NSURL *requestUrl = [NSURL URLWithString:@"http://lab.hudong.com/ipad/zutujingxuan.xml"];
    ASIFormDataRequest *httpRequest = [[ASIFormDataRequest alloc] initWithURL:requestUrl];
    //设置请求的委托对象
    [httpRequest setDelegate:self];
    //设置请求的方法
    [httpRequest setRequestMethod:@"POST"];
    //请求超时时长
    [httpRequest setTimeOutSeconds:10.0];
    //是否是加密的，如果是HTTPS，设为YES
    [httpRequest setValidatesSecureCertificate:NO];
    [httpRequest setDefaultResponseEncoding:NSUTF8StringEncoding];
    
    [httpRequest setPostValue:@"hello!" forKey:@"XMLString"];
}


// 开始请求
- (void)startRequest
{
    NSURL *requestURL = [NSURL URLWithString:@"http://lab.hudong.com/ipad/zutujingxuan.xml"];
    //HTTP网络请求对象 初始化
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:requestURL];
    //设置请求的委托对象
    [request setDelegate:self];
    //设置请求的方法
    [request setRequestMethod:@"GET"];
    //请求超时时长
    [request setTimeOutSeconds:10.0];
    //是否是加密的，如果是HTTPS，设为YES
    [request setValidatesSecureCertificate:NO];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    
    
    //允许断点续传
    [request setAllowResumeForFileDownloads:YES];
    //设置文件存储路径
    [request setDownloadDestinationPath:nil];
    //设置缓冲区
    [request setTemporaryFileDownloadPath:nil];
    
    [request startAsynchronous];
    
    [request release];
}
// 解析XML
- (NSArray *)parseXMLString:(NSString *)xmlString
{
    // 为空判断
    if (xmlString.length == 0) {
        return nil;
    }
    NSError *error = nil;
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithXMLString:xmlString options:0 error:&error];
    NSAssert(!error, @"parse xml string '%@' failed with error message '%@'.",xmlString,[error localizedDescription]);
    
    //结果集合
    NSMutableArray *results = [NSMutableArray array];
    
    //方法一：结点路径 解析
    NSArray *titleElements = [document nodesForXPath:@"///docTitle" error:&error];
    NSArray *imageElements = [document nodesForXPath:@"///docImg" error:&error];
    
    NSInteger count = [titleElements count];
    for (int i = 0; i < count; i++) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        GDataXMLElement *titleElement = [titleElements objectAtIndex:i];
        GDataXMLElement *imageElement = [imageElements objectAtIndex:i];
        // title
        [dictionary setObject:[titleElement stringValue] forKey:[titleElement name]];
        // image url
        [dictionary setObject:[imageElement stringValue] forKey:[imageElement name]];
        [results addObject:dictionary];
    }
    return results;
}

//刷新scrollView
- (void)updateScrollViewWithDatasource:(NSArray *)datasource
{
    CGFloat height = [datasource count]/2 * (180+40+20);
    scrollView.contentSize = CGSizeMake(320, height);
    for (int i = 0; i < [datasource count]; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i%2*160, i/2*230, 160, 180)];
        [imageView setImageWithURL:[[datasource objectAtIndex:i] objectForKey:@"docImg"]];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(i%2*160+5, i/2*230+180, 155, 40)];
        label.text = [[datasource objectAtIndex:i] objectForKey:@"docTitle"];
        label.font = [UIFont systemFontOfSize:13];
        
        [scrollView addSubview:imageView];
        [scrollView addSubview:label];
    }
    UIButton *btnClear = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnClear.frame = CGRectMake(130, height-40, 70, 50);
    [btnClear addTarget:self action:@selector(btnClearCache:) forControlEvents:UIControlEventTouchUpInside];
    [btnClear setTitle:@"清除缓存" forState:UIControlStateNormal];
    [scrollView addSubview:btnClear];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    //NSData 转NSString
    //NSString *responseString = [[NSString alloc] initWithData:request.responseData encoding:NSUTF8StringEncoding];
    
    NSArray *results = [self parseXMLString:request.responseString];
    
    [self updateScrollViewWithDatasource:results];
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"%@",[request.error localizedDescription]);
}


- (void)btnClearCache:(UIButton *)_sender
{
    [[SDImageCache sharedImageCache] clearDisk];
    [[SDImageCache sharedImageCache] clearMemory];
    NSLog(@"Clear");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
