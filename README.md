# TalkingData
## 題目介紹
TalkingData是中國最大的行動數據服務平台，每天處理超過10TB 行動數據。
本研究為Kaggle競賽，目的是藉由行動裝置的使用行為預測使用者的特徵，藉此提供用戶喜好的服務。
(https://www.kaggle.com/c/talkingdata-mobile-user-demographics)
TalkingData透過其收集手機APP的使用行為，結合不同的手機裝置、型號以及不同所在位置，判別手機使用者的年齡、性別。


## 資料格式
TalkingData將不同類型的資料儲存在不同的csv檔案中

|檔案名稱|檔案內容|
|---------|--|
|gender_age_train.csv| 使用者的年齡、性別、族群|
|phone_brand_device_model.csv|手機的品牌、型號|
|events.csv|使用程式的時間、地點|
|app_events.csv|相關APP的安裝、執行狀態|
|app_labels.csv|APP ID與類別ID對照表|
|label_categories.csv|類別ID與類別名稱對照表|

利用彼此共通的primary key可將各檔案串接   
![image](imgs/TalkingData_relation.jpg)  
