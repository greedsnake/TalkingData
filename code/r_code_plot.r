library(dplyr)
library(plotly)
library(data.table)
url = "D:/iiiProject/talkingdata/"

#讀取檔案
event = fread(paste0(url,"events3.csv"),integer64="character")
train = fread(paste0(url,"gender_age_train.csv"),integer64="character")
brand = fread(paste0(url,"talkdata_brand2.csv"),encoding="UTF-8",integer64="character")

#衍生變數
brand_rank = table(phone_brand=brand$phone_brand) %>%	#品牌出現次數排序
	data.frame() %>% 
	arrange(desc(Freq))
brand_rank = brand_rank$phone_brand %>% as.character

brand_per = brand_rank %>% 	#各品牌佔總人口比例
	mutate(per=Freq/sum(brand_rank$Freq)*100)
brand_per$phone_brand = factor(brand_per$phone_brand,levels=brand_rank$phone_brand)
percent = percent1 =brand_per$per[1]	#新增向量為使用品牌累計人口比例
for(i in 2:131){
percent1 = percent1+brand_per$per[i]
percent = c(percent, percent1)
}
brand_per = brand_per %>% 
	mutate(tper=percent)	#累計人口比例
brand_per$per = round(brand_per$per,2)	#四捨五入到小數2位
brand_per$tper = round(brand_per$tper,2)

user = merge(train,brand,"device_id")	#使用者機器對應性別、年齡、品牌
user2 = subset(user,phone_brand %in% head(brand_rank,5))	#前五名品牌
user2$phone_brand = factor(user2$phone_brand,levels = head(brand_rank,5))

timegroup = c("0-6", "7-12", "13-18", "19-24")	#將24小時切成四個區塊
event = event %>% mutate(timegroup = timegroup[ceiling( (stamptime+1)/6 )])	#依據(小時/6)，對照timegroup向量位置，取得相對時間群組
event2 = plyr::count(event,c("device_id","stampdate","timegroup")) %>%		#依據每台機器每天，統計各時間群組出現次數
	arrange(desc(freq))
event2 = event2[!duplicated(event2[,c("device_id","stampdate")]),] %>%	
	subset(select=-freq)
data = merge(train,event2,by="device_id") %>% 
	merge(brand, by="device_id")
data$timegroup = factor(data$timegroup,levels=timegroup)
data2 = subset(data, phone_brand %in% head(brand_rank,5)) #前五名品牌
data2$phone_brand = factor(data2$phone_brand, levels = head(brand_rank,5))
#折線圖，x=品牌(前20); y=累計人數比例
plot_ly(brand_per2,x=~phone_brand,y=~tper,type="scatter",mode="lines") %>%
  layout(title="User percentage of Top20 brands",
		xaxis=list(title="brand"),
		yaxis=list(title="percentage(%)"))
#長條圖，x=品牌(前20); y=總人數比例; z=人口比例權重(比例/3)
brand_per2 = head(brand_per,20)
brand_per2$phone_brand=factor(brand_per2$phone_brand,levels=head(brand_rank$phone_brand,20))
plot_bar_bp = plot_ly(brand_per2,x=~phone_brand,y=~per,color=~factor( round(per/3) ),type="bar") %>%
  layout(title="User percentage of Top20 brands",
		xaxis=list(title="brand"),
		yaxis=list(title="percentage(%)"))
#長條圖，x=年齡; y=數量; z=品牌(前5)
plotly_bar_anb = user2 %>% 	
	count(ages=paste0(floor(age/10)*10,"'s"), phone_brand) %>%
  	plot_ly(x =~ ages,y = ~n, color = ~phone_brand)
#箱型圖，x=品牌(前5); y=年齡; z=性別
plotly_box_bag = plot_ly(user2, x = ~phone_brand, y = ~age, color = ~gender, colors = c("red", "blue"),type = "box") %>%
	layout(boxmode = "group")
#箱型圖，x=時間區間; y=年齡; z=品牌(前5)
plotly_box_tab = plot_ly(data2, x = ~timegroup, y = ~age, color = ~phone_brand, type = "box") %>%
	layout(boxmode = "group")
#箱型圖，x=時間區間; y=年齡; z=性別
plotly_box_tag = plot_ly(data, x = ~timegroup, y = ~age, color = ~gender, type = "box") %>%
	layout(boxmode = "group")
	
#長條圖，x=年齡; y=計數; color=時間; 分類=性別
ggplot(data,aes(x=age,y=1,fill=timegroup)) + 
	xlab("age") + 
	ylab("user_count") +
	labs(fill="time_group") +
	facet_grid(gender~.) +
	xlim(15,65) +
	geom_bar(stat="identity")
#長條圖，x=時間; y=計數; color=年齡(10年); 分類=性別
ggplot(data,aes(x=timegroup,y=1,fill=paste0(floor(age/10)*10,"'s"))) + 
	xlab("timegroup") + 
	ylab("user_count") +
	labs(fill="ages") +
	facet_grid(gender~.) +
	geom_bar(stat="identity")
#長條圖，x=時間; y=計數; color=年齡(10年); 分類=品牌(前5)
ggplot(data2,aes(x=timegroup,y=1,fill=paste0(floor(age/10)*10,"'s"))) + 
	xlab("timegroup") + 
	ylab("user_count") +
	labs(fill="ages") +
	facet_grid(phone_brand~.) +
	geom_bar(stat="identity")
#長條圖，x=年齡; y=比例; color=時間; 分類=性別
countga = plyr::count(data,c("age","gender"))
colnames(countga) = c("age","gender","age_freq")
countper = plyr::count(data,vars=c("age","timegroup","gender")) %>%
	merge(countga) %>%
	mutate(per = freq/age_freq*100)
ggplot(countper,aes(x=age,per,fill=timegroup)) +
	xlab("age") + ylab("user_percentage(%)")+
	labs(fill="time_group") +
	facet_grid(gender~.) +
	geom_bar(stat="identity") +
	scale_x_continuous(limits=c(15,75),breaks=c(20,30,40,50,60,70)) 
#長條圖，x=年齡; y=比例; color=品牌(前5); 分類=性別
countga_top5 = plyr::count(user2,vars=c("age","gender"))
names(countga_top5) = c("age","gender","age_freq")
countper_top5 = plyr::count(user2,vars=c("age","phone_brand","gender")) %>%
	merge(countga_top5) %>%
	mutate(per = freq/age_freq*100)
ggplot(countper_top5,aes(x=age,per,fill=phone_brand)) +
	xlab("age") + ylab("user_percentage(%)")+
	labs(fill="phone_brand") +
	facet_grid(gender~.) +
	geom_bar(stat="identity") +
	scale_x_continuous(limits=c(15,75),breaks=c(20,30,40,50,60,70)) 
#長條圖，x=年齡; y=比例; color=性別
countga_gender = plyr::count(user2,vars=c("age"))
names(countga_gender) = c("age","age_freq")
countper_gender= plyr::count(user2,vars=c("age","gender")) %>%
	merge(countga_gender) %>%
	mutate(per = freq/age_freq*100)
ggplot(countper_gender,aes(x=age,per,fill=gender)) +
	xlab("age") + ylab("user_percentage(%)")+
	labs(fill="gender") +
	geom_bar(stat="identity") +
	scale_x_continuous(limits=c(15,75),breaks=c(20,30,40,50,60,70)) 
#動態折線圖，x=時間; y=人數; color=性別
accumulate_by <- function(dat, var) {
  var <- lazyeval::f_eval(var, dat)
  lvls <- plotly:::getLevels(var)
  dats <- lapply(seq_along(lvls), function(x) {
    cbind(dat[var %in% lvls[seq(1, x)], ], frame = lvls[[x]])
  })
  dplyr::bind_rows(dats)
}
tdata = merge(train,event,by="device_id")
tdata = plyr::count(tdata,c("gender","stamptime")) %>%
	accumulate_by(~stamptime)
plotly_ani_tng = plot_ly(tdata, x=~stamptime, y=~freq,
		frame=~frame, split=~gender, type='scatter',
		mode='lines', line=list(simplyfy=F)) %>%
	layout(xaxis=list(title="time(hour)", zeroline=F),
		yaxis=list(title="user", zeroline=F)) %>%
	animation_opts(frame=100, transition=0,redraw=FALSE) %>%
	animation_slider(hide=T) %>%
	animation_button(x=1,xanchor="right",y=0,yanchor="bottom")