//
//  NSObject+YJKVO.m
//  KVCKVODemo
//
//  Created by 张强 on 2020/10/29.
//

#import "NSObject+YJKVO.h"
#import <objc/message.h>

// 通过 Runtime 动态成子类的前缀
static NSString *const YJKVOPrefix = @"YJKVO_";
// 关联 观察者
static NSString *const YJKVOAssociatedOberverKey = @"YJKVOAssociatedOberverKey";

@implementation NSObject (YJKVO)

#pragma mark - -- public methods
/// 添加观察者
/// @param observer 观察者
/// @param keyPath keyPath
- (void)yj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    
    // 1. 检查时候有 set 方法
    NSString *setterMethodName = setterForGetter(keyPath);
    SEL setterSel = NSSelectorFromString(setterMethodName);
    // method
    Method method = class_getInstanceMethod(self.class, setterSel);
    if (!method) {
        @throw [[NSException alloc] initWithName:NSExtensionItemAttachmentsKey reason:@"没有setter方法" userInfo:nil];
    }
    
    // 2. 动态生成子类
    Class sub_Class = [self registerSubClassWithKeyPath:keyPath];
    if (!sub_Class) {
        @throw [[NSException alloc] initWithName:NSExtensionItemAttachmentsKey reason:@"子类创建失败" userInfo:nil];
    }
    
    // 3. 消息转发
    // 关联 observer
    objc_setAssociatedObject(self, (__bridge void const * _Nonnull)YJKVOAssociatedOberverKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


/// 移除观察者
/// @param observer 观察者
/// @param keyPath keyPath
- (void)yj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    objc_removeAssociatedObjects(observer);
}


/// kvo 回调方法 (由观察者实现)
- (void)yj_observeValueForKeyPath:(NSString *)keyPath ofObject:(nonnull id)object newValue:(nonnull id)newValue { }




#pragma mark - -- private methods
#pragma mark - 通过 getter 方法名，获取 setter 方法名；例如：age ==> setAge:
static NSString * setterForGetter(NSString *getter) {
    if (getter.length < 1) {
        return nil;
    }
    // 获取第一个字符，变成打下
    NSString *firstString = [[getter substringToIndex:1] uppercaseString]; // substringToIndex：从最前头一直截取到Index
    NSString *otherString = [getter substringFromIndex:1]; // substringFromIndex：从Index开始截取到最后
    // 拼接 age == > setAag:
    return [NSString stringWithFormat:@"set%@%@:", firstString, otherString];
}

#pragma mark - 通过 setter 方法名，获取 getter 方法名；例如：setAge: ==> age
static NSString * getterForSetter(NSString *setter) {
    if (setter.length < 1 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    NSString *getter = [setter substringFromIndex:3];
    getter = [getter substringToIndex:getter.length-1];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}


#pragma mark - 动态生成子类
/// 运行时动态创建子类
/// @param keyPath keyPath
- (Class)registerSubClassWithKeyPath:(NSString *)keyPath {
    // 子类名
    NSString *subClsName = [NSString stringWithFormat:@"%@%@", YJKVOPrefix, self.class];
    // 子类，一个 NSObject 默认分贝 16 个字节
    Class subCls = objc_allocateClassPair(self.class, subClsName.UTF8String, 16);
    // 注册
    objc_registerClassPair(subCls);
    
    // 给子类动态添加 setter、class 实现
    Method class_method = class_getClassMethod(self.class, @selector(class));
    Method setter_method = class_getClassMethod(self.class, NSSelectorFromString(setterForGetter(keyPath)));
    class_addMethod(subCls, @selector(class), (IMP)yj_class, method_getTypeEncoding(class_method));
    
    class_addMethod(subCls,  NSSelectorFromString(setterForGetter(keyPath)), (IMP)yj_setter, method_getTypeEncoding(setter_method));
    
    // 将父类的 isa 指向子类
    object_setClass(self, subCls);

    return subCls;
}


#pragma mark - 重写 class 方法
static Class yj_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

#pragma mark - 重写 setter 方法
/// 重写 setter 方法
/// @param newValue 新值
static void yj_setter(id self, SEL _cmd, id newValue) {
    
    // 1. 调用 super setter 方法
    struct objc_super super_cls = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    ///调用父类 setter 方法 设置新值
    ((void(*) (id, SEL, id)) (void *)objc_msgSendSuper)((__bridge id)(&super_cls), _cmd, newValue);
        
    
    // 2. 取出观察者，调用kvo 回调方法
    id observer = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(YJKVOAssociatedOberverKey));
    //
    SEL handleSel = @selector(yj_observeValueForKeyPath:ofObject:newValue:);
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));
    
    // Runtime 调用回到方法
    // objc_msgSend() 默认的情况下，不支持添加参数。
    // 解决方案一： Build Setting –> 搜索： Enable Strict Checking of objc_msgSend Calls 改为 NO （我自己试了下，无效 Xcode12.1）
    // 解决方案二： 这里通过(void *)送入5个参数，你可以根据自己参数类型强转原本是void()的函数方法
    ((void (*) (id, SEL, NSString*, id, id)) (void*)objc_msgSend)(observer, handleSel, keyPath, self, newValue);
}


@end
