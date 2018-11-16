## 載入必要套件
library(tmcn)
library(dplyr)
library(plyr)
library(gtools)
library(data.table)
library(tidyr)
url = "D:/iiiProject/talkingdata/"		#資料路徑設定

## 品牌簡繁體轉換
Sys.setlocale("LC_ALL","Chinese")	#環境轉簡體
brand = fread(paste0(url,"phone_brand_device_model.csv"),encoding="UTF-8",integer64="character") %>% 	#讀取資料+轉繁體
	sapply(toTrad) %>%
	as.data.frame()
Sys.setlocale("LC_ALL","cht")	#環境轉繁體
brand = brand[!duplicated(brand$device_id),]  #去重複值
fwrite(brand,paste0(url,"talkdata_brand2.csv")) #寫入檔案
rm(brand);gc()

## 讀入檔案
train = fread(paste0(url,"gender_age_train.csv"),integer64="character")
test = fread(paste0(url,"gender_age_test.csv"),integer64="character")
brand = fread(paste0(url,"talkdata_brand2.csv"),encoding="UTF-8",integer64="character")
cate = fread(paste0(url,"label_categories.csv"),integer64="character")
event = fread(paste0(url,"events.csv"),integer64="character")
label = fread(paste0(url,"app_labels.csv"),integer64="character")
app = fread(paste0(url,"app_events.csv"),integer64="character")

## 製作應用表格
brand_rank = table(phone_brand=brand$phone_brand) %>% 	#品牌出現次數表
	data.frame() %>% 
	arrange(desc(Freq))	
user = merge(train,brand,"device_id")	#合併train資料，獲得各device_id的gender,age,phone_brand,device_model

## app安裝、啟動計數
app_install = table(event_id=app$event_id) %>% data.frame()	#event對應app安裝數
app_active = table(event_id=subset(app,is_active==1)$event_id) %>% data.frame()	#event對應app啟動數
colnames(app_install) = c("event_id","app_install")
colnames(app_active) = c("event_id","app_active")
app_install$event_id = as.integer(app_install$event_id)
app_active$event_id = as.integer(app_active$event_id)
event_app = merge(subset(event,select=c(event_id,device_id)),app_install,"event_id") %>% 	#合併event對應device,install,active
	merge(app_active,"event_id")

## 將日期時間切割	
split_time = strsplit(as.character(event$timestamp)," ")	#將日期及時間已空格切開
stampday = sapply(split_time,"[",1)		#將所有list中第一個值存為stampday
stamptime = sapply(split_time,"[",2)	#將所有list中第二個值存為stamptime
event2 = event %>% 	#將變數合併入event表，存為event2
	mutate(stampdate=stampday) %>% 
	mutate(stamptime=stamptime) %>% 
	subset(select=-timestamp)
fwrite(event2,paste0(url,"events2.csv"),row.names=F)	#寫入
event2$stampdate = event2$stampdate %>% substring(9)	#只取第9字元(日)
event2$stamptime = event2$stamptime %>% substr(1,2)	#只取頭2字元(小時)
event2 = subset(event2,select=c(device_id,stampdate,stamptime))	#去除經緯度及event資料
fwrite(event2,paste0(url,"events3.csv"),row.names=F)	
user = merge(user,event2,by="device_id")
rm(event2,split_time,stampday,stamptime);gc()

## 將app的類別攤平為稀疏矩陣
cateindex = label[!duplicated(paste0(label$app_id,label$label_id)),] %>%	#去同app_id&label_id重複值
	table() %>%		#轉次數表
	data.frame() %>%
	merge(cate,by="label_id") %>%	
	subset(category!="unknown",select=-label_id)	#去除unknown值、label_id欄位
catespread = cateindex[!duplicated(paste0(cateindex$app_id,cateindex$category)),] %>%	#去除同app_id&category重複值
	spread(category,Freq)	#攤平
fwrite(catespread,paste0(url,"catespfread"),sep=",",row.names=F)
	
app$is_installed = app$is_installed+app$is_active		#將is_installed轉為is_installed+is_active(權重，假設安裝與啟動權重相等)
app = subset(app,select=-is_active)	#去除is_active欄位

i=1	#共1488086個event_id，共1488086=25000*59+13086
for(j in 1:59){		#跑59次迴圈，每次計算25000個event_id
cate1 = subset(app,event_id %in% unique(app$event_id)[i:(i+24999)]) %>%	#合併app啟動權重與對應category資料
merge(catespread,by="app_id")
setDF(cate1)
cate1[-c(1:3)] = cate1[-c(1:3)]*cate1$is_installed	#各category乘上權重(除前3行外全部乘上is_installed)
cate1 = cate1 %>% select(-c(app_id,is_installed))	#去除欄位
cate1 = aggregate(. ~ event_id,cate1,sum)			#依據event_id，合併分數
i=i+25000
fwrite(cate1,paste0(url,"data/",j,".csv"),sep=",",row.names=F)	#寫出
rm(cate1)
gc()
}
cate1 = subset(talkdata_app,event_id %in% unique(talkdata_app$event_id)[i:(i+13095)]) %>%
merge(talkdata_spread,by="app_id")
setDF(cate1)
cate1[-c(1:3)] = cate1[-c(1:3)]*cate1$is_installed
cate1 = cate1 %>% select(-c(app_id,is_installed))
cate1 = aggregate(. ~ event_id,cate1,sum)
i = i+13096
fwrite(cate1,paste0(talkdata_url,"data/","60.csv"),sep=",",row.names=F)
rm(cate1)
gc()

combine=data.frame()		#利用迴圈讀取資料，併入空data.frame中
for(i in 1:60){
temp = fread(paste0(url,"data/",i,".csv"),integer64="character")
combine = rbind(combine,temp)
rm(temp);gc()
}
combine = merge(combine,event[,1:2],by="event_id") %>% subset(select=-event_id)
fwrite(combine,paste0(url,"combine2.csv"),sep=",",row.names=F)	#寫入檔案
rm(temp,catespread,cateindex)

## 將app偏好對應key從event改為device，並依據其出現次數求平均值
i=1	#共60822個device_id，60822=10000*6+822
for(j in 1:6){	#6次迴圈，每次計算10000個device_id
comp = subset(combine,device_id %in% unique(combine$device_id)[i:(i+9999)])
comp = aggregate(.~device_id,comp,mean)		#合併相同的device_id資料，求平均值
fwrite(comp,paste0(url,"data4/",j,".csv"),row.names=F)
rm(comp);gc()
i=i+10000
}
comp = subset(combine,device_id %in% unique(combine$device_id)[i:(i+821)])
comp = aggregate(.~device_id,comp,mean)
fwrite(comp,paste0(url,"data4/","7.csv"),row.names=F)
rm(comp,combine);gc()
i=i+822

combine=data.frame()		#利用迴圈讀取資料，併入空data.frame中
for(i in 1:7){
temp = fread(paste0(url,"data4/",i,".csv"),integer64="character")
combine = rbind(combine,temp)
rm(temp);gc()
}
fwrite(combine,paste0(url,"combine3.csv"),row.names=F)

## 製作出有完整app對應資料的device表
train = subset(train,select=device_id)	#只保留train表中的device_id欄位
device = rbind(train,test)	#合併train和test
device = data.frame(device_id=unique(device$device_id))	#取train&test表中的device_id唯一值
combine = subset(combine,device_id %in% device$device_id)	#只取包含在train及test中的device_id
device1 = subset(device,!(device_id %in% combine$device))	#取出不包含在combine表中的device_id
combine2 = smartbind(combine,device1,fill=0)	#透過合併combine表及未重複的device_id，獲得完整device_id，缺值補0
combine2 = combine2[!duplicated(combine2$device_id),]	#去重複值
rm(combine);gc()

event = fread(paste0(url,"events.csv"),integer64="character")
event = subset(event,select = c("event_id","device_id"))	#篩選欄位，只取event_id和device_id
app2 = subset(app, is_active==1, select=-is_installed)	#篩選欄位，只取有active的app，去除is_installed
app2 = merge(event,app2,by="event_id") %>% 	#利用merge將app2的event_id與device_id調換，並去除多餘欄位 -> 各device的app對應表
	subset(select=-c(event_id,is_active))
app2 = plyr::count(app2,c("device_id","app_id"))	#使用plyr的count函數，計算各device_id中各app出現次數，藉此讓其變為唯一值
app2$freq = app2$freq^0		#利用乘上0次方，將次數變為1(有)及0(無)

spread = data.frame()	
i=1
for(j in 1:6){	#60668個device_id，分為10000*6+668次處理
app3 = subset(app2,device_id %in% unique(app2$device_id)[i:(i+9999)])	#每次處理10000台device_id資訊
app_spread = spread(app3, key=app_id, value=freq, fill=0)		#攤平table，將其變為device對應app的稀疏矩陣，空值補0

spread = smartbind(spread,app_spread,fill=0)	#合併資料，空值補0
rm(app3,app_spread)		#刪除變數，清理資源
gc()
i = i+10000
}
app3 = subset(app2,device_id %in% unique(app2$device_id)[i:(i+667)])
app_spread = spread(app3, key=app_id, value=freq, fill=0)
spread = smartbind(spread,app_spread,fill=0)
rm(app3,app_spread)
gc()
i = i+668
fwirte(spread,paste0(url,"appspread.csv"),row.names=F)
##取出各group中出現次數前五多的型號
heady = function(x){	#創立一function為head(5)
x=head(x,n=5)
return(x)
}
modelcnt = merge(train,brand,by="device_id")	#合併train和brand資料，取得年齡、性別、族群、品牌、型號
modelcnt = modelcnt[,4:6]	#去除id、年齡、性別
modelcnt = plyr::count(modelcnt ,c("group","phone_brand","device_model")) %>%	#依照出現次數計數，並由大到小排序
arrange(desc(freq)) %>%
subset(select=-freq)
setDT(modelcnt)
modelcnt = modelcnt[, lapply(.SD,heady), by=group]	#依據族群(group)分群，取前5筆(因先前排序過，因此為出現次數最多的5個型號)
