library(leaflet)
library(ggplot2)
library(data.table)
library(dplyr)
library(plyr)
library(leaflet.extras)
url = "D:/iiiProject/talkingdata/"	
event = fread(paste0(url,"events.csv"),integer64="character")
brand = fread(paste0(url,"talkdata_brand2.csv"),encoding="UTF-8",,integer64="character")
train = fread(paste0(url,"gender_age_train.csv"),integer64="character")
brand_rank = table(phone_brand=brand$phone_brand) %>%	#品牌出現次數排序
	data.frame() %>% 
	arrange(desc(Freq))
brand_rank = as.character(brand_rank$phone_brand)
user = merge(train,brand,"device_id")	#結合使用者個資與使用偏好


## 製作地圖(人數)
map = subset(event,!(longitude^2<4 & latitude^2<4))	#去Error座標
map_count = map[!duplicated(map$device_id),] %>% #去除重複值(一台機器顯示一個座標)
	subset(select=c(longitude,latitude)) %>%	
	leaflet() %>%
	addTiles() %>%
	addMarkers(clusterOptions = markerClusterOptions())

map_count2 = map[!duplicated(paste0(map$device_id,map$longitude,map$device_latiude)),] %>% #去重複值(同一台機器一個座標只顯示一次)
	subset(select=c(longitude,latitude)) %>%
	leaflet() %>%
	addTiles() %>%
	addMarkers(clusterOptions = markerClusterOptions())

mapcnt = count(map,c("device_id","longitude","latitude")) %>% #每台機器每個座標的出現次數(資料取map -> 去除Error座標; 取event -> 不去除Error座標)
	arrange(desc(freq))
mapcnt = mapcnt[!duplicated(mapcnt$device_id),]	#去除重複值(一台機器顯示其出現次數最多之座標=眾數)，只保留座標資料
		
map_mode = subset(mapcnt,select = c(longitude,latitude)) %>%	
	leaflet() %>%
	addTiles() %>%
	addMarkers(clusterOptions = markerClusterOptions())

map2 = 	merge(mapcnt,subset(brand,select=-device_model),"device_id") %>%
	arrange(desc(freq)) %>%
	subset(select=-freq)
	
#熱圖
map_heat = map2 %>%
	subset(select=-device_id) %>%
	leaflet() %>%
	addTiles() %>%
	addHeatmap(radius=8) %>%
	setView(lng = 110, lat = 30, zoom = 5)	

#依據性別(男女)標示
colgender = colorFactor(palette = c("red","blue"), domain = map2$gender)
map_gender = map2 %>%
	subset(select=-device_id) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.1,color = ~colgender(gender)) %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#男性
map_male = map2 %>%
	subset(gender=="M",select=-device_id) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.1,color="blue") %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#女性
map_female = map2 %>%
	subset(gender=="F",select=-device_id) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.1,color="red") %>%
	setView(lng = 110, lat = 30, zoom = 5)	

#依據品牌(前五名)標示
colbrand = colorFactor(palette = c("firebrick","blue","forestgreen","darkviolet","darkgoldenrod"), domain = head(brand_rank,5))
map_brand = map2 %>%
	subset(phone_brand %in% head(brand_rank,5)) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.1,color = ~colbrand(phone_brand)) %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#品牌1-小米
map_brand1 = map2 %>%
	subset(phone_brand == brand_rank[1]) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.3,color = "firebrick") %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#品牌2-三星
map_brand2 = map2 %>%
	subset(phone_brand == brand_rank[2]) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.3,color = "blue") %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#品牌3-華為
map_brand3 = map2 %>%
	subset(phone_brand == brand_rank[3]) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.3,color = "forestgreen") %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#品牌4-vivo
map_brand4 = map2 %>%
	subset(phone_brand == brand_rank[4]) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.3,color = "darkviolet") %>%
	setView(lng = 110, lat = 30, zoom = 5)	
#品牌5-OPPO
map_brand5 = map2 %>%
	subset(phone_brand == brand_rank[5]) %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.3,color = "darkgoldenrod") %>%
	setView(lng = 110, lat = 30, zoom = 5)	

#依據年齡(10年單位)標示
colage = colorFactor(palette=c("white","blue","red","goldenrod","darkorange","forestgreen","darkorchid","darkturquoise","cyan","black")
, domain = ceiling(train$age/10))
map_age = map2 %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.1,color = ~colage(ceiling(age/10) %>% as.factor())) %>%
	setView(lng = 110, lat = 30, zoom = 5)	
	
#依據Group標示
map3 = mapcnt[!duplicated(mapcnt$device_id),] %>%	
	subset(select=-freq) %>%
	merge(subset(user,select=-device_model),"device_id") %>%
	subset(select=-device_id)	
cgroupf = c("maroon1","maroon2","maroon3","magenta1","magenta2","magenta3")
cgroupm = c("deepskyblue1","deepskyblue2","deepskyblue3","dodgerblue1","dodgerblue2","dodgerblue3")
colgroup = colorFactor(palette = c(cgroupf,cgroupm), domain = train$group)
map_group = map3 %>%
	leaflet() %>%
	addTiles() %>%
	addCircleMarkers(radius=0.1,color = ~colgroup(group)) %>%
	setView(lng = 110, lat = 30, zoom = 5)	

	
