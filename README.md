##iOS中使用基于RSA使用公钥加密和公钥解密
最近在公司项目中被要求使用RSA加密,且要求是全程加解密,期间也是踩了很多的坑,在此做个记录也算给要使用的朋友一点帮助.注意,具体的RSA加密算法内容并不在此文的讨论范围之内.本文更多聚焦于使用部分.

###我当前的使用场景和环境:
* 1.移动端(iOS端)只有公钥,拿不到私钥,私钥后台保留
* 2.基于base64进行编码
* 3.全程加密,即和后台通讯的时候请求体是一段base64编码.
* 4.由于RSA加密机制决定了明文长度不能大于密文长度,所以需要分段加密和解密.  
* 5.使用的密钥是1024位,要和后台统一

首先,如果你着急用,并且需求跟我差不多,我也就不多说了demo链接在下面,直接拿去用就好,如果好用,欢迎star,有问题也请直接提交issue,或者留言,我看到就会回复.

>https://github.com/JVSFlipped/JVSRSAHandler

直接把JVSRSAHandler文件夹拖进你的工程里面去  
可能会有以下直接问题:  
1.找不到头文件,请在Build Settings -> SearchPatch -> Header Search Patchs 里面填上对应的文件夹路径  
2.库冲突,demo中使用的是openssl,据我所知,支付宝也用了这个东西,它的sdk包含了这个,所以需要删除重复的即可.  
3.报错找不到"没有添加.pem密钥文件或者命名不同于代码内名称",这是我在demo中抛出的异常.中使用了rsa_public_key.pem来读取公钥,这个文件可以问后台要,也可以自己生成,这里不展开讲.注意文件的命名必须跟

> importRSAKeyWithType:  

这个方法中的文件名保持一致.

####接下里我详细谈谈我在做这个需求时候踩到的坑和一些注意点: 
1.网上有很多公钥加密私钥解密的,我找了很久都没找到合适的公钥解密的解决方案,各位不要去找后台要私钥啊,这牵扯到RSA的加密机制,即使用的策略是非对称加密,即客户端使用公钥,后台使用私钥,公钥加密的内容只有私钥能解开,这样即使客户端的公钥被窃取了(实际上设计是公开公钥的),只要私钥妥善得保管在后台,公钥加密数据的安全就能得到保证.  
2.要确定几个重要参数,我在demo中有注释  

```
//RSA算法填充类型,前后台要统一
static NSInteger kRSAPaddingType = RSA_PKCS1_PADDING;
//解密长度,前后台要统一  
static NSInteger kDecryptionLength = 128;
//RSA公钥文件名
static NSString *kPublicKeyFile = @"rsa_public_key";
//加密长度,前后台要统一
static NSInteger kEncryptionLength = 117;
//RSA密钥文件名,目前没有此类调用,后续可能会添加
static NSString *kPrivateKeyFile = @"rsa_private_key";
```
3.有关openssl文件的问题  
这是我在使用过程中遇到的问题,当时忘了截图了大概是类似于

> architecture x86_64:

的报错,这个主要是因为openssl文件夹中lib下的.a库太老,不支持最新的iOS系统,我提供的demo中应该没有这个问题(因为我弄的是比较新的,具体方法这里不展开讲了,跟这里没啥关系).

4.有关分段加密的问题  
由于RSA限制明文长度不能长于密文长度,所以数据过长就需要分段加密,就是说分段加密然后base64编码然后再拼接起来.

###获取公钥
不管加密还是解密都需要提前获取公钥  

```
//获取key
- (BOOL)importRSAKeyWithType:(KeyType)type
{
    FILE *file;
    NSString *keyName = type == KeyTypePublic?kPublicKeyFile:kPrivateKeyFile;
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:keyName ofType:@"pem"];
    file = fopen([keyPath UTF8String], "rb");
    if (NULL != file)
    {
        if (type == KeyTypePublic)
        {
            _rsa = PEM_read_RSA_PUBKEY(file, NULL, NULL, NULL);
            assert(_rsa != NULL);
        }
        else
        {
            _rsa = PEM_read_RSAPrivateKey(file, NULL, NULL, NULL);
            assert(_rsa != NULL);
        }
        fclose(file);
        return (_rsa != NULL) ? YES : NO;
    }
    NSException* exception = [NSException exceptionWithName:@"读取密钥失败!" reason:@"没有添加.pem密钥文件或者命名不同于代码内名称" userInfo:nil];
    @throw exception;
    return NO;
}
```


###加密过程
JVSRSAHandler提供了加密方法将字典转换并基于RSA加密后再base64编码获得字符串的方法

```
//加密字典
- (NSString *)encryptDictionary:(NSDictionary*)dict WithRSAKeyType:(KeyType)keyType
{
    //将字典转成json字符串
    NSString *jsonString = [self conversionDictionary:dict];
    //转成UTF8Data
    NSData *UTF8Data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    //加密过程
    NSData *RSAEncryptData = [self encryptionData:UTF8Data WithRSAKeyType:keyType];
    //转成base64的string
    NSString *encryptString = [RSAEncryptData base64EncodedString];
    return encryptString;
}
```

加密方法,这里主要是分段过程:

```
//加密方法,这里主要是分段内容
- (NSData *)encryptionData:(NSData *)expressData WithRSAKeyType:(KeyType)keyType
{
    if (expressData && [expressData length]) {
        //计划分段加密长度
        NSInteger planSubLength = kEncryptionLength;
        //数据总长度
        NSInteger sumLength = [expressData length];
        //分段数
        NSInteger blockCount = sumLength/planSubLength + ((sumLength%planSubLength)?1:0);
        //总的数据,存放解密后的数据
        NSMutableData *sumData = [[NSMutableData alloc ] initWithCapacity:0];
        for(int i = 0;i < blockCount; i++)
        {
            //实际分段长度,注意最后一段不够的问题
            int relSubLength = (int)MIN(planSubLength, sumLength - i*planSubLength);
            //定义放置待加密数据的数组,容量为实际分段长度(明文,较短)
            unsigned char expressArr[relSubLength];
            //C函数方法,将数组初始化置空
            bzero(expressArr, sizeof(expressArr));
            //在expressArr中放入目标要加密的数据
            memcpy(expressArr, [[expressData subdataWithRange:NSMakeRange(i*planSubLength, relSubLength)] bytes], relSubLength);
            //定义存放加密后数据的数组,因为明文长度不得大于密文长度,所以这里的长度为计划长度(密文,较长)
            unsigned char encryptedArr[planSubLength];
            //同上,将数组初始化置空
            bzero(encryptedArr, sizeof(encryptedArr));
            //加密expressArr中的数据并放入encryptedArr数组中
            [self encryptFrom:expressArr length:(int)relSubLength to:encryptedArr WithKeyType:keyType];
            //取出encryptedArr数组的有效内容长度，不能用数组长度，因为encryptedArr为unsigned char*型，可能有效内容之间也有“\0”,需要去除
            int k=0;
            //不明白这里为什么是128,按理说128会越界的,因为定义的时候数组长度只有117
            for(int j = 0;j< 128;j++)
            {
                if(encryptedArr[j] != '\0')
                {
                    k = j+1;
                }
            }
            //同样不明白这里的操作含义,去掉的话加密成功率降低很多
            if(k%4 != 0){
                
                k = ((int)(k/4) + 1)*4;
                
            }
            //拼接加密后数据
            [sumData appendData:[NSData dataWithBytes:encryptedArr length:k]];
        }
        return sumData;
    }
    return nil;
}
```

真正的加密部分

```
//加密部分
- (NSInteger)encryptFrom:(const unsigned char *)expressArr length:(int)length to:(unsigned char *)encryptedArr WithKeyType:(KeyType)keyType
{
    //导入文件中密钥
    if (![self importRSAKeyWithType:keyType])
        return 0;
    if (expressArr != NULL && encryptedArr != NULL) {
        NSInteger status;
        switch (keyType) {
            case KeyTypePrivate:{
                //私钥加密
                status =  RSA_private_encrypt(length, expressArr,encryptedArr, _rsa, kRSAPaddingType);
            }
                break;
                
            default:{
                //公钥加密
                status =  RSA_public_encrypt(length,expressArr,encryptedArr, _rsa,  kRSAPaddingType);
            }
                break;
        }
        return status;
    }
    return -1;
}

```

###解密过程
JVSHandler提供了解密方法将后台给的base64字符串转化成字典

```
//解密字符串
- (NSDictionary *)decryptString:(NSString *)encryptedString WithRSAKeyType:(KeyType)keyType
{
    //将要解密的字符串base64解码
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    //解密过程
    NSData *jsonData = [self decryptData:encryptedData WithRSAKeyType:keyType];
    //将data转成string
    NSString *josnString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //转成字典输出
    NSDictionary *dict = [self dictionaryWithJsonString:josnString];
    return dict;
}
```
解密方法,这里主要是分段过程:

```
//解密方法(主要是分段)
- (NSData *)decryptData:(NSData *)encryptedData WithRSAKeyType:(KeyType)keyType
{
    if (encryptedData && [encryptedData length]) {
        //计划解密长度
        NSInteger planSubLength = kDecryptionLength;
        //数据总长度
        NSInteger sumLength = [encryptedData length];
        //分段数
        NSInteger blockCount = sumLength/planSubLength + ((sumLength%planSubLength)?1:0);
        //存放解密后的数据
        NSMutableData *sumData = [[NSMutableData alloc ] initWithCapacity:0];
        for(int i = 0;i < blockCount; i++)
        {
            //实际分段的长度,注意最后一段不够的情况
            int realSubLength = (int)MIN(planSubLength, sumLength - i*planSubLength);
            //定义存放待解密数据的数组encryptedArr(密文,较长)
            unsigned char encryptedArr[planSubLength];
            //C函数,初始化置空encryptedArr数组
            bzero(encryptedArr, sizeof(encryptedArr));
            //将待解密的data数据存放入encryptedArr数组中
            memcpy(encryptedArr, [[encryptedData subdataWithRange:NSMakeRange(i*planSubLength, realSubLength)] bytes], realSubLength);
            //定义存放解密出来的数据的数组expressArr(明文,较短)
            unsigned char expressArr[realSubLength];
            //初始化置空expressArr数组
            bzero(expressArr, sizeof(expressArr));
            //解密encryptedArr中的数据并存入expressArr中
            [self decryptFrom:encryptedArr length:realSubLength to:expressArr WithKeyType:keyType];
            int k=0;
            //取出expressArr数组的有效内容长度，不能用数组长度，因为expressArr为unsigned char*型，可能有效内容之间也有“\0”,需要去除
            for(int j = 0;j< planSubLength;j++)
            {
                if(expressArr[j] != '\0')
                {
                    k = j+1;
                }
            }
            //拼接解密出来的数据
            [sumData appendData:[NSData dataWithBytes:expressArr length:k]];
        }
        return sumData;
    }
    return nil;
}
```
真正的解密部分

```
//解密方法
- (NSInteger)decryptFrom:(const unsigned char *)encryptedArr length:(int)length to:(unsigned char *)expressArr WithKeyType:(KeyType)keyType
{
    //获取密钥
    if (![self importRSAKeyWithType:keyType])
        return -1;
    if (encryptedArr != NULL && expressArr != NULL) {
        int status;
        switch (keyType) {
            case KeyTypePrivate:{
                //私钥解密
                status =  (int)RSA_private_decrypt(length, encryptedArr,expressArr, _rsa, kRSAPaddingType);
            }
                break;
            default:{
                //公钥解密
                status =  RSA_public_decrypt(length, encryptedArr, expressArr, _rsa,  kRSAPaddingType);
            }
                break;
        }
        return status;
    }
    return -1;
}

```
其他的字符串转字典互转的部分我就不详细码出来了,demo里面都有,注意留意控制台打印的信息,会有测试加密出来的密文保存的txt文档路径以及解密密文出来的字典打印.

###总结
简单来说,在这个过程中JVSHandler做了以下事情:
  
加密过程:字典 -> 字符串(UTF-8) -> Data(UTF-8) -> Data(分段) -> Data(加密) -> 字符串(base64) 
 
解密过程:字符串(base64) -> Data(base64解码) -> Data(分段) -> Data(解密) -> 字符串(UTF-8) -> 字典

###目前存在的问题  
* 1.0版本的时候加密不稳定,后来新版本添加了代码基本解决了这个问题,但是这部分代码我是在网上找来的,具体为啥我目前也很懵(emmmmmmm...)

```
//不明白这里为什么是128,按理说128会越界的,因为定义的时候数组长度只有117
            for(int j = 0;j< 128;j++)
            {
                if(encryptedArr[j] != '\0')
                {
                    k = j+1;
                }
            }
            //同样不明白这里的操作含义,去掉的话加密成功率降低很多
            if(k%4 != 0){
                k = ((int)(k/4) + 1)*4;
            }
```

我的疑惑点在哪我已经写在上面了,希望有大神可以赐教.我目前怀疑是RSA本身需要或是编码规则需要,目前还没时间仔细去研究,后续如果搞明白了我会补充的.具体的RSA加解密算法过程之后有时间也会研究下,有必要也会做出一份这样的记录文档分享出来.





