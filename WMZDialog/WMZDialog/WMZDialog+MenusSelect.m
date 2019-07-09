


//
//  WMZDialog+MenusSelect.m
//  WMZDialog
//
//  Created by wmz on 2019/6/28.
//  Copyright © 2019年 wmz. All rights reserved.
//

#import "WMZDialog+MenusSelect.h"
@implementation WMZDialog (MenusSelect)
- (UIView*)menusSelectAction{
    
    //递归计算深度
    self.depth = 0;
    if ([self.wData isKindOfClass:[NSArray class]]||[self.wData isKindOfClass:[NSMutableArray class]]){
        if ([self.wData count]) {
            self.depth = 1;
            self.tree = [WMZTree new];
            self.tree.depth = 0;
            for (NSDictionary *dic in self.wData) {
                
                WMZTree *tree = [[WMZTree alloc]initWithDetpth:1 withName:dic[@"name"]?:@"" withID:dic[@"id"]?:@""];
                [self.tree.children addObject:tree];
                if (dic[@"children"]) {
                    [self getDepth:dic[@"children"] withTree:tree withDepth:1];
                }
            }
            
        }
    }
    
    //添加UI
    UITableView *temp = nil;
    
    for (int i = 0; i<self.depth; i++) {
        UITableView *ta = [[UITableView alloc]initWithFrame:CGRectMake(!temp?0:CGRectGetMaxX(temp.frame), 0, self.wWidth/self.depth, self.wHeight) style:UITableViewStyleGrouped];
        if (self.wTableViewColor&&i<self.wTableViewColor.count) {
            ta.backgroundColor = self.wTableViewColor[i];
        }
        ta.delegate = self;
        ta.dataSource = self;
        ta.estimatedSectionFooterHeight = 0.01;
        ta.estimatedSectionHeaderHeight = 0.01;
        ta.rowHeight = self.wMainBtnHeight;
        ta.tag = 100+i;
        temp = ta;
        [self.mainView addSubview:ta];
        if (i>0) ta.hidden = YES;
    }
    
    [self reSetMainViewFrame:CGRectMake(0,self.wTapView?CGRectGetMaxY(self.wTapView.frame):0,self.wWidth, CGRectGetMaxY(temp.frame))];
    self.mainView.center = CGPointMake(self.view.center.x, self.mainView.center.y);
    
    return self.mainView;
}


//获取深度
- (void)getDepth:(NSArray*)arr withTree:(WMZTree*)treePoint withDepth:(NSInteger)depth{
    if (arr&&([arr isKindOfClass:[NSArray class]]||[arr isKindOfClass:[NSMutableArray class]])&&[arr count]){
        self.depth = depth+1;
        for (NSDictionary *dic in arr) {
            WMZTree *tree = [[WMZTree alloc]initWithDetpth:depth+1 withName:dic[@"name"]?:@"" withID:dic[@"id"]?:@""];
            [treePoint.children addObject:tree];
            if (dic[@"children"]&&([dic[@"children"] isKindOfClass:[NSArray class]]||[dic[@"children"] isKindOfClass:[NSMutableArray class]])&&[dic[@"children"] count]) {
                [self getDepth:dic[@"children"] withTree:tree withDepth:depth+1];
                
            }
        }
    }
}


//数据处理  type 1返回tree对象
- (id)getMyDataArr:(NSInteger )tableViewTag withType:(NSInteger)type{
    if (tableViewTag==100) {
        return type?self.tree:self.tree.children;
    }else{
        NSInteger taNum = 100;
        WMZTree *resultDic = nil;
        while (taNum < tableViewTag) {
            NSMutableArray *arr = (taNum == 100?self.tree.children:resultDic.children);
            int selectLastIndex = 0;
            for (int i = 0; i<arr.count; i++) {
                WMZTree *tree = arr[i];
                if (tree.isSelected) {
                    selectLastIndex = i;
                    break;
                }
            }
            resultDic = arr[selectLastIndex];
            taNum++;
        }
        return  type?resultDic:resultDic.children;
    }
}

//点击处理
- (void)selectWithTableView:(UITableView *)tableView withIndexPath:(NSIndexPath*)indexPath{
    NSMutableArray *dataArr = [self getMyDataArr:tableView.tag withType:0];
    for (int i = 0 ; i<dataArr.count; i++) {
        WMZTree *tree = dataArr[i];
        if (i == indexPath.row) {
            tree.isSelected = YES;
        }else{
            tree.isSelected = NO;
        }
    }
    WMZTree *selectTree =  dataArr[indexPath.row];
    //下一级选中全变为NO
    for (WMZTree *tree in selectTree.children) {
        tree.isSelected = NO;
    }
    [tableView reloadData];
    if (tableView.tag < self.depth+99) {
        NSInteger num = tableView.tag+1;
        while (num<self.depth+100) {
            UITableView *ta = [self.mainView viewWithTag:num];
            if (num == tableView.tag+1) {
                ta.hidden = NO;
                [ta reloadData];
            }else{
                ta.hidden = YES;
            }
            num++;
        }
    }else{
        [self closeView];
    }

    
    if (self.wEventMenuClick) {
        self.wEventMenuClick(selectTree, tableView.tag-99,indexPath.row+1);
    }
}

/*
 * 更新下拉菜单数据 用于外部传入数据 只更新下一列的数据 下下列的数据不变
 *
 * @param  section  列
 * @param  update  是否更新子列表数组
 * @param  data   数据
 *
 */
- (void)updateMenuChildrenDataWithSection:(NSInteger)section  withUpdateChildren:(BOOL)update withData:(NSArray*)data{
    if (section>0&&section<=self.depth) {
        WMZTree *tree = [self getMyDataArr:section+99 withType:1];
        if (data.count<=tree.children.count) {
            NSMutableArray *arr = [NSMutableArray arrayWithArray:tree.children];
            for (int i = 0; i<tree.children.count; i++) {
                WMZTree *tempTree = arr[i];
                NSDictionary *dic = data[i];
                tempTree.name = dic[@"name"];
                tempTree.ID = dic[@"id"];
                tempTree.isSelected = NO;
                if (update) {
                    tempTree.children = dic[@"children"];
                }
                if (i>=data.count) {
                    [arr removeObject:arr];
                }
            }
            tree.children = arr;
        }else{
            for (int i = 0; i<data.count; i++) {
                NSDictionary *dic = data[i];
                if (i>=tree.children.count) {
                    WMZTree *tempTree = [[WMZTree alloc]initWithDetpth:tree.depth+1 withName:dic[@"name"]?:@"name" withID:dic[@"id"]?:@"id"];
                    [tree.children addObject:tempTree];
                }else{
                    WMZTree *tempTree = tree.children[i];
                    if (update) {
                        tempTree.children = dic[@"children"];
                    }
                    tempTree.name = dic[@"name"];
                    tempTree.ID = dic[@"id"];
                    tempTree.isSelected = NO;
                }
            }
        }
        UITableView *ta = [self.mainView viewWithTag:99+section];
        [ta reloadData];
    }
}

@end
