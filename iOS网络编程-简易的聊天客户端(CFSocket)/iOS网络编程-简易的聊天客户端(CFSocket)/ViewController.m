//
//  ViewController.m
//  iOS网络编程-简易的聊天客户端(CFSocket)
//
//  Created by Mengjie Chen on 8/3/16.
//  Copyright © 2016 Mengjie Chen. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>


@interface ViewController ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *inputField;
@property (weak, nonatomic) IBOutlet UITextView *showView;

@property (nonatomic,copy) NSString *myName;

@end

@implementation ViewController
{
    CFSocketRef _socket;
    BOOL isOnline;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    //创建一个UIAlertView提醒用户输入名字
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"名字" message:@"请输入姓名" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    //设置UIAlertView风格
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    
    //设置代理
    alert.delegate = self;
}

#pragma mark - Actions
- (IBAction)sendMsg:(UIButton *)sender {
    if (isOnline) {
        NSString *stringToSend = [NSString stringWithFormat:@"%@说:%@",self.myName,self.inputField.text];
        //输入完毕后清空
        self.inputField.text = nil;
        //转换成char *
        const char *data = [stringToSend UTF8String];
        //主线程发送消息
        send(CFSocketGetNative(_socket), data, strlen(data) + 1, 1);
    }else
        NSLog(@"未连接服务器");
}

- (IBAction)finsihEdit:(UITextField *)sender {
    //编辑完了，注销掉第一响应者
    [sender resignFirstResponder];
}

#pragma mark - process
//读取接受的数据
- (void)readStream
{
    char buffer[2048];
    ssize_t hasRead;
    //与本机关联的socket，如果失效，则返回-1：INVALID_SOCKET
    //ssize_t recv(int socket, void *buffer, size_t length, int flags);返回字节长
    while ((hasRead = recv(CFSocketGetNative(_socket), buffer, sizeof(buffer), 0))) {
        NSString *context = [[NSString alloc] initWithBytes:buffer length:hasRead encoding:NSUTF8StringEncoding];
        //使用主线程来更新UI控件的状态
        dispatch_async(dispatch_get_main_queue(), ^{
            self.showView.text = [NSString stringWithFormat:@"%@\n%@",context,self.showView.text];
            [self.showView setTextColor:[UIColor redColor]];
        });
    }
}

//代理方法中实现，连接注册连接
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //获取UIAlertView控件上的文本框字符，赋值给myName
    self.myName = [alertView textFieldAtIndex:0].text;
    
    //1.创建socket
    _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack, nil, NULL);
    
    //2.设置地址、端口，首先需要一个结构体
    struct sockaddr_in addr4;
    //初始化
    memset(&addr4, 0, sizeof(addr4));
    //设置
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    //设置远程地址
    addr4.sin_addr.s_addr = inet_addr("127.0.0.1");
    //设置监听端口
    addr4.sin_port = htons(30000);
    
    //3.将设置信息转换成CFDataRef
    CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
    
    //4.连接远程服务器的socket，并返回连接结果
    CFSocketError result = CFSocketConnectToAddress(_socket, address, 5);
    
    //判断是否连接成功
    if (result == kCFSocketSuccess) {
        isOnline = YES;
        //启动新线程接受数据
        [NSThread detachNewThreadSelector:@selector(readStream) toTarget:self withObject:nil];
    }

}



@end
