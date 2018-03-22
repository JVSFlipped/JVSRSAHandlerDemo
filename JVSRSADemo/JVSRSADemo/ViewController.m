//
//  ViewController.m
//  JVSRSADemo
//
//  Created by 程硕 on 2018/3/18.
//  Copyright © 2018年 Flipped. All rights reserved.
//

#import "ViewController.h"
#import "JVSRSAHandler.h"

typedef enum {
    RSAPublicEncrypt,
    RSAPublicDecrypt,
    RSAPrivateEncrypt,
    RSAPrivateDecrypt
}RSAOperationType;

@interface ViewController ()
//加密字典
@property (nonatomic, strong) NSDictionary *dict;

@property(nonatomic, strong) UIButton *encryptBtn;

@property(nonatomic, strong) UIButton *decryptBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

- (void)initUI
{
    _encryptBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_encryptBtn setTitle:@"Encrypt" forState:UIControlStateNormal];
    [_encryptBtn setTitle:@"Encrypt" forState:UIControlStateSelected];
    _encryptBtn.frame = CGRectMake(100, 100, 100, 50);
    [self.view addSubview:_encryptBtn];
    _encryptBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:15];
    _encryptBtn.titleLabel.textColor = [UIColor greenColor];
    _encryptBtn.backgroundColor = [UIColor grayColor];
    [_encryptBtn addTarget:self action:@selector(encryptDictionary) forControlEvents:UIControlEventTouchUpInside];
    
    _decryptBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_decryptBtn setTitle:@"Decrypt" forState:UIControlStateNormal];
    [_decryptBtn setTitle:@"Decrypt" forState:UIControlStateSelected];
    _decryptBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:15];
    _decryptBtn.frame = CGRectMake(100, 200, 100, 50);
    [self.view addSubview:_decryptBtn];
    _decryptBtn.titleLabel.textColor = [UIColor yellowColor];
    _decryptBtn.backgroundColor = [UIColor grayColor];
    [_decryptBtn addTarget:self action:@selector(decryptString) forControlEvents:UIControlEventTouchUpInside];
}

- (void)encryptDictionary
{
    NSString *encryptedString = [[JVSRSAHandler shareInstance] encryptDictionary:self.dict WithRSAKeyType:KeyTypePublic];
    [self writefile:encryptedString withRSAOperationType:RSAPublicEncrypt];
}

- (void)decryptString
{
    NSDictionary *decryptedDict = [[JVSRSAHandler shareInstance] decryptString:[self getDecryptedString] WithRSAKeyType:KeyTypePublic];
    if (decryptedDict) {
        NSLog(@"解密成功,解析出字典为%@",decryptedDict);
    }
}

- (NSString *)getDecryptedString
{
    NSStringEncoding encoding = NSUTF8StringEncoding ;
    NSError *error = [[NSError alloc]init];
    NSString *codeString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RSADecrypetdString" ofType:@".txt"]  usedEncoding:&encoding  error:&error];
    return codeString;
}

- (void)writefile:(NSString *)string withRSAOperationType:(RSAOperationType)type
{
    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *homePath = [paths objectAtIndex:0];
    NSString *filePath = @"";
    if (type == RSAPublicEncrypt) {
        filePath =[homePath stringByAppendingPathComponent:@"客户端公钥加密结果.txt"];
    }else if (type == RSAPrivateEncrypt){
        //尚未做
        filePath =[homePath stringByAppendingPathComponent:@"客户端私钥加密结果.txt"];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //如果不存在
    if(![fileManager fileExistsAtPath:filePath])
    {
        NSString *str = @"";
        [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    //将节点跳到文件的末尾
    [fileHandle seekToEndOfFile];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *datestr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *str = [NSString stringWithFormat:@"\n%@\n%@",datestr,string];
    NSData* stringData  = [str dataUsingEncoding:NSUTF8StringEncoding];
    //追加写入数据
    [fileHandle writeData:stringData];
    [fileHandle closeFile];
    NSLog(@"加密成功,内容保存至%@",filePath);
}



- (NSDictionary *)dict
{
    _dict = @{
              @"navigation": @{
                      @"bgcolor": @"",
                      @"navigation_items": @[
                              @{
                                  @"icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_nav_location_white.png",
                                  @"text": @"全国",
                                  @"bg_color": @"",
                                  @"text_color": @"#FFFFFF",
                                  @"sub_icon": @"",
                                  @"magic": @"",
                                  @"href_model": @"near_list",
                                  @"is_show": @"1"
                                  },
                              @{
                                  @"type": @"search_big",
                                  @"icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_nav_search_small_black.png",
                                  @"text": @"请输入关键词搜索",
                                  @"bg_color": @"#F5F5F5",
                                  @"text_color": @"#999999",
                                  @"sub_icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_nav_code_black.png",
                                  @"magic": @"qr_code",
                                  @"href_model": @"search",
                                  @"is_show": @"1"
                                  },
                              @{
                                  @"type": @"message",
                                  @"icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_nav_message_white.png",
                                  @"text": @"",
                                  @"bg_color": @"",
                                  @"text_color": @"",
                                  @"sub_icon": @"",
                                  @"magic": @"",
                                  @"href_model": @"message",
                                  @"is_show": @"1"
                                  },
                              @{
                                  @"type": @"webname",
                                  @"icon": @"",
                                  @"text": @"中国房地产产业平台",
                                  @"bg_color": @"",
                                  @"text_color": @"#FFFFFF",
                                  @"sub_icon": @"",
                                  @"magic": @"",
                                  @"href_model": @"",
                                  @"is_show": @"1"
                                  },
                              @{
                                  @"type": @"search",
                                  @"icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_nav_search_big_white.png",
                                  @"text": @"",
                                  @"bg_color": @"",
                                  @"text_color": @"",
                                  @"sub_icon": @"",
                                  @"magic": @"",
                                  @"href_model": @"search",
                                  @"is_show": @"1"
                                  },
                              @{
                                  @"type": @"cart",
                                  @"icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_nav_cart_white.png",
                                  @"text": @"",
                                  @"bg_color": @"",
                                  @"text_color": @"#FFFFFF",
                                  @"sub_icon": @"",
                                  @"magic": @"",
                                  @"href_model": @"cart",
                                  @"is_show": @"1"
                                  }
                              ]
                      },
              @"section": @[
                      @{
                          @"section_type": @"carousel",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"0",
                          @"section_title_show": @"0",
                          @"section_title_icon": @"",
                          @"section_title_text": @"",
                          @"section_title_sub": @"",
                          @"section_title_arrow": @"0",
                          @"section_title_href": @"",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"",
                                      @"title": @"111",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170814/20170814173053_39127.jpg",
                                      @"line_height": @"300",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"1",
                                      @"href_model": @"weburl",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"",
                                      @"title": @"111",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170814/20170814173110_70122.jpg",
                                      @"line_height": @"300",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"1",
                                      @"href_model": @"weburl",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"",
                                      @"title": @"111",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531155617_63964.png",
                                      @"line_height": @"300",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"1",
                                      @"href_model": @"weburl",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      }
                                  ]
                          },
                      @{
                          @"section_type": @"table",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"1",
                          @"section_title_show": @"0",
                          @"section_title_icon": @"",
                          @"section_title_text": @"",
                          @"section_title_sub": @"",
                          @"section_title_arrow": @"0",
                          @"section_title_href": @"",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"1",
                                      @"title": @"新房",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531155446_89212.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"2",
                                      @"title": @"二手房",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531160413_68078.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"3",
                                      @"title": @"招租房",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531160434_15095.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"4",
                                      @"title": @"商铺写字楼",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531161204_49593.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"5",
                                      @"title": @"餐饮地产",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531161815_81356.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"6",
                                      @"title": @"工业地产",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531162148_88794.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"7",
                                      @"title": @"帮你找房",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531162222_99348.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"circle_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"8",
                                      @"title": @"招商加盟",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531162253_82568.png",
                                      @"line_height": @"50",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_list",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      }
                                  ]
                          },
                      @{
                          @"section_type": @"scroll",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"10",
                          @"section_title_show": @"0",
                          @"section_title_icon": @"https://fdc.m.huisou.com/Public/Apps/images/index_news_top.png",
                          @"section_title_text": @"",
                          @"section_title_sub": @"",
                          @"section_title_arrow": @"1",
                          @"section_title_href": @"",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"27",
                                      @"title": @"2018年楼市会怎么走？任志强：这一次我也判断不好了",
                                      @"sub_title": @"",
                                      @"img": @"",
                                      @"line_height": @"",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"26",
                                      @"title": @"限制房价的政策几乎没有任何开发商遵守",
                                      @"sub_title": @"",
                                      @"img": @"",
                                      @"line_height": @"",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"25",
                                      @"title": @"传承财富管理基因 打造海外规划旗舰",
                                      @"sub_title": @"",
                                      @"img": @"",
                                      @"line_height": @"",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"24",
                                      @"title": @"专家：调控政策几乎到极致 房地产税将逐步落地",
                                      @"sub_title": @"",
                                      @"img": @"",
                                      @"line_height": @"",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"15",
                                      @"title": @"如何抓住城镇化建设机遇促楼宇对讲繁荣?",
                                      @"sub_title": @"",
                                      @"img": @"",
                                      @"line_height": @"",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      }
                                  ]
                          },
                      @{
                          @"section_type": @"news_column",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"10",
                          @"section_title_show": @"1",
                          @"section_title_icon": @"",
                          @"section_title_text": @"推荐资讯",
                          @"section_title_sub": @"更多",
                          @"section_title_arrow": @"1",
                          @"section_title_href": @"news_list",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"23",
                                      @"title": @"最新土地规划调整解读：政策意图何在、对房价何影响",
                                      @"sub_title": @"最新土地规划调整解读：政策意图何在、对房价何影响",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170816/20170816171612_81372.jpg",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"2017-08-16",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"22",
                                      @"title": @"传承财富管理基因 打造海外规划旗舰",
                                      @"sub_title": @"传承财富管理基因 打造海外规划旗舰",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170816/20170816171409_93360.jpg",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"2017-08-16",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"21",
                                      @"title": @"专家：调控政策几乎到极致 房地产税将逐步落地",
                                      @"sub_title": @"专家：调控政策几乎到极致 房地产税将逐步落地",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170816/20170816171129_68835.jpg",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"news_detail",
                                      @"time": @"2017-08-16",
                                      @"price": @"",
                                      @"oprice": @""
                                      }
                                  ]
                          },
                      @{
                          @"section_type": @"table_row",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"10",
                          @"section_title_show": @"1",
                          @"section_title_icon": @"",
                          @"section_title_text": @"房产中介品牌",
                          @"section_title_sub": @"更多",
                          @"section_title_arrow": @"1",
                          @"section_title_href": @"company_list",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"20",
                                      @"title": @"昆山六九网络科技有限公司",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170731/20170731153449_20882.png",
                                      @"line_height": @"150",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"company_home",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"3",
                                      @"title": @"深圳市世祥房地产中介服务部",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531154850_72806.png",
                                      @"line_height": @"150",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"company_home",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"4",
                                      @"title": @"江苏恒迪集团有限公司",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531154921_95913.png",
                                      @"line_height": @"150",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"company_home",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"5",
                                      @"title": @"东莞市光怡房地产代理有限公司",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531154955_13264.png",
                                      @"line_height": @"150",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"company_home",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"2",
                                      @"title": @"21世纪不动产信德益家房地产",
                                      @"sub_title": @"",
                                      @"img": @"https://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531154753_48840.png",
                                      @"line_height": @"150",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"company_home",
                                      @"time": @"",
                                      @"price": @"",
                                      @"oprice": @""
                                      }
                                  ]
                          },
                      @{
                          @"section_type": @"product_column",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"10",
                          @"section_title_show": @"1",
                          @"section_title_icon": @"",
                          @"section_title_text": @"热门求购",
                          @"section_title_sub": @"更多",
                          @"section_title_arrow": @"1",
                          @"section_title_href": @"need_list",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"4",
                                      @"title": @"天阳尚城国际",
                                      @"sub_title": @"天阳尚城国际",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531174552_97116.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"need_detail",
                                      @"time": @"",
                                      @"price": @"3677",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"3",
                                      @"title": @"金龙大厦",
                                      @"sub_title": @"金龙大厦",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531174431_27249.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"need_detail",
                                      @"time": @"",
                                      @"price": @"12000",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"2",
                                      @"title": @"风云社区",
                                      @"sub_title": @"风云社区",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531174341_17990.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"need_detail",
                                      @"time": @"",
                                      @"price": @"8600",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"1",
                                      @"title": @"贝越流明新苑",
                                      @"sub_title": @"贝越流明新苑",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531173939_23862.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"need_detail",
                                      @"time": @"",
                                      @"price": @"1280000",
                                      @"oprice": @""
                                      }
                                  ]
                          },
                      @{
                          @"section_type": @"page",
                          @"section_magic": @"",
                          @"section_top": @"0",
                          @"section_bottom": @"0",
                          @"section_title_show": @"1",
                          @"section_title_icon": @"",
                          @"section_title_text": @"推荐产品",
                          @"section_title_sub": @"",
                          @"section_title_arrow": @"0",
                          @"section_title_href": @"",
                          @"section_datas": @[
                                  @{
                                      @"data_id": @"62",
                                      @"title": @"近市北工业园区 ",
                                      @"sub_title": @"近市北工业园区 ",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170822/20170822154338_23855.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"20.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"61",
                                      @"title": @"泰和名都商铺可做重餐饮 装潢设计",
                                      @"sub_title": @"泰和名都商铺可做重餐饮 装潢设计",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170822/20170822153351_47967.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"12.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"60",
                                      @"title": @"一楼商铺出租，可重餐饮已经装修",
                                      @"sub_title": @"一楼商铺出租，可重餐饮已经装修",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170822/20170822152937_24013.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"11.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"59",
                                      @"title": @"万科七宝国际 二期办公楼/商",
                                      @"sub_title": @"万科七宝国际 二期办公楼/商铺",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170822/20170822151857_92400.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"2.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"10",
                                      @"title": @"天阳尚城国际二期",
                                      @"sub_title": @"天阳尚城国际二期",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531165106_99400.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"2270.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"9",
                                      @"title": @"天阳尚城国际二期",
                                      @"sub_title": @"天阳尚城国际二期",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531165020_24935.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"1650.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"8",
                                      @"title": @"(单间出租)家乐公寓新房装修，环境优雅，高品质的人租高品质房，不要错过。",
                                      @"sub_title": @"(单间出租)家乐公寓新房装修，环境优雅，高品质的人租高品质房，不要错过。",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531164924_24618.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"1550.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"7",
                                      @"title": @"促销房源，好房出租，拎包入住",
                                      @"sub_title": @"促销房源，好房出租，拎包入住",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531164837_87052.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"2773.00元/㎡",
                                      @"oprice": @""
                                      },
                                  @{
                                      @"data_id": @"6",
                                      @"title": @"城市公寓",
                                      @"sub_title": @"城市公寓",
                                      @"img": @"http://fdc.m.huisou.com/Uploads/Admin/image/20170531/20170531164749_38722.png",
                                      @"line_height": @"100",
                                      @"radius": @"0",
                                      @"href": @"",
                                      @"href_type": @"2",
                                      @"href_model": @"product_detail",
                                      @"time": @"",
                                      @"price": @"1770.00元/㎡",
                                      @"oprice": @""
                                      }
                                  ]
                          }
                      ]
              };
    //    _dict = @{@"token":@"ringqweqwweqwe1231312312"};
    return _dict;
}
@end
