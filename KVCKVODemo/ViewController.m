//
//  ViewController.m
//  KVCKVODemo
//
//  Created by 张强 on 2020/10/28.
//

#import "ViewController.h"
#import <objc/message.h>

#import "Person.h"
#import "NSObject+YJKVO.h"

@interface ViewController ()

@property (nonatomic, strong) Person * p;
@property (nonatomic, strong) Person * p1;
@property (nonatomic, strong) Person * p2;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self useCustomKVOTest];
}


#pragma mark - 使用自定义kvo
- (void)useCustomKVOTest {
    self.p = [[Person alloc] init];
    [self.p yj_addObserver:self forKeyPath:NSStringFromSelector(@selector(name))];
    self.p.name = @"张三";
}


#pragma mark - 自定义kvo，回调
- (void)yj_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object newValue:(id)newValue {
    NSLog(@"newValue = %@", newValue);
}




#pragma mark - 使用系统kvo测试
/*
 KVO 的全称 Key Value Observing，俗称“键值监听”，以及用于监听对象某个属性值的变化
 1. iOS用什么方式实现对一个对象的KVO？（KVO的本质是什么？）
    答：当一个对象使用了KVO监听，iOS系统会修改这个对象的isa指针，改为指向一个全新的通过Runtime动态创建的子类，子类拥有自己的set方法实现，set方法实现内部会顺序调用willChangeValueForKey方法、原来的setter方法实现、 didChangeValueForKey方法，而didChangeValueForKey方法内部又会调用监听器的observeValueForKeyPath:ofObject:change:context:监听方法。
 2. 如何手动触发kvo
    答：被监听的属性的值被修改时，就会自动触发KVO。 如果想要手动触发KVO，则需要我们自己调用willChangeValueForKey和didChangeValueForKey方法即可在不改变属性值的情况下手动触发KVO，并且这两个方法缺一不可。
 */
- (void)useSystemKVOTest {
    // 1. 创建测试对象
    self.p1 = [Person new];
    self.p2 = [Person new];
    self.p1.age = 1;
    self.p2.age = 2;

    // 2. 打印监听前p1、p2 所属类、setter 方法实现地址
    NSLog(@"监听前 p1 class is : %@, p2 class is : %@", object_getClass(self.p1), object_getClass(self.p2));
    // 输出结果：监听前 p1 class is : Person, p2 class is : Person
    NSLog(@"监听前 p1-setAage: address is : = %p, p2-setAage: address is : %p", [self.p1 methodForSelector:@selector(setAge:)], [self.p2 methodForSelector:@selector(setAge:)]);
    // 输出结果：监听前 p1-setAage: address is : = 0x102f98ea8, p2-setAage: address is : 0x102f98ea8

    // 3. 添加监听，
    [self.p1 addObserver:self forKeyPath:NSStringFromSelector(@selector(age)) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];

    // 4. 打印监听后p1、p2 所属类、setter 方法实现地址
    NSLog(@"监听后 p1 class is : %@, p2 class is : %@", object_getClass(self.p1), object_getClass(self.p2));
    // 输出结果：监听后 p1 class is : NSKVONotifying_Person, p2 class is : Person
    NSLog(@"监听后 p1-setAage: address is : = %p, p2-setAage: address is : %p", [self.p1 methodForSelector:@selector(setAge:)], [self.p2 methodForSelector:@selector(setAge:)]);
    // 输出结果：监听后 p1-setAage: address is : = 0x194c61d54, p2-setAage: address is : 0x102f98ea8

    // 5. 改变值
    self.p1.age = 10;
    self.p2.age = 20;


    [self printMethods];

    // 6.移除 p1.age 的监听者
    [self.p1 removeObserver:self forKeyPath:NSStringFromSelector(@selector(age))];
}

#pragma mark - kvo 回调方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"监听到 %@ 的 %@ 改变了 %@", [object isEqual:self.p1]?@"p1":@"p2", keyPath, change);
    /* 输出结果：
     监听到 p1 的 age 改变了 {
         kind = 1;
         new = 10;
         old = 1;
     }
     */
}

- (void)printMethods {
    [self printMehtodsOfClass:object_getClass(self.p1)];
    [self printMehtodsOfClass:object_getClass(self.p2)];
}

- (void)printMehtodsOfClass:(Class)cls {

    unsigned int count = 0;
    Method * methods = class_copyMethodList(cls, &count);

    NSMutableString *methodNames = @"".mutableCopy;
    [methodNames appendFormat:@"%@ - ", cls];

    for (int i = 0; i < count; i++) {
        Method method = methods[i];
        NSString * methodName = NSStringFromSelector(method_getName(method));
        [methodNames appendString:methodName];
        [methodNames appendString:@"  "];
    }

    NSLog(@"%@", methodNames);

    free(methods);
}




@end
