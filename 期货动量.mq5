#property copyright "HeYuansong"
#property link      "https://www.heyuansong.github.io/"
#property version   "1.02"
input string futures="GOLD_DEC21";//期货符号
input string cash="GOLD";//现货符号
input int circle=240;//开平点均线周期
input int timer = 1;//判断条件的时间间隔
input double spread = 0.5;//开平点的价差
input int bff = 5;//缓冲区数量，这是最近若干个timer的均值
input double mylots = 0.01;//输入的手数
input int input_state = 0;//输入账户状态，0未持仓，1卖出，2买入
input int show = 0;//抬头显示数据
input double out = 0.3;//出仓点位
input bool ci = true;//复利
input int addlots = 30;//盈利加仓手数
input double slpoint = 3.0;//追踪止损点位
double lots = 0.01;//手数
double bottom;//利润线底部
double top;//利润线顶部
MqlTick futures_tick;//期货价格对象
MqlTick cash_tick;//现货价格对象
double take;//价差
MqlTradeRequest req;//交易请求体
MqlTradeResult res;//交易返回体
int number = 123;//EA幻数
bool check = true;//返回交易函数的值
double ma;//均线
int fma;//期货均线
int cma;//现货均线
int take_state = 0;//账户持仓状态
double front_buffer[20] = {0};//短周期过滤缓冲区
double shortprc = 0;//短周期均线值
input int i_counts = 1;//输入同时开仓数 
int counts = 1;
void Open(int buyOrsell);//开仓函数，传0买入，传1卖出
void Close();//平仓函数
int OnInit(){ 
   SymbolInfoTick(futures,futures_tick);//期货价格
   SymbolInfoTick(cash,cash_tick);//现货价格
   for(int i = 0;i<bff;i++){ //更新用来过滤噪音的缓冲区
      front_buffer[i] = futures_tick.bid - cash_tick.bid;
   }
   take_state = input_state;counts = i_counts;
   lots = mylots; EventSetTimer(timer); return(INIT_SUCCEEDED); 
}//初始化，设置间隔时间为timer
double shortPrice(){//计算短周期均线值
   double acu = 0;
   for(int i = 0;i<bff;i++){ acu+=front_buffer[i]/bff; }//用当前几个timer的值取平均
   return acu;
}
void ChangeOrders();

void OnTimer(){//每一个timer判断一次
   if(ci){
      if(AccountInfoDouble(ACCOUNT_BALANCE) >= 40.2 + (counts*lots * 2000)) {
         if(lots >= 100){
            lots = 100;
            if(counts >= 3){
               counts = 3;
            }
            else{
               counts += 1;   
            }
         }
         else{
            lots += 0.01;//现在打开它
         }
      }
   }
   SymbolInfoTick(futures,futures_tick);//期货价格
   SymbolInfoTick(cash,cash_tick);//现货价格
   ChangeOrders();
   /*下面一段拿到一分钟周期的均线值*/
   fma = iMA(futures,PERIOD_M1,circle,0,MODE_EMA,PRICE_CLOSE);
   cma = iMA(cash,PERIOD_M1,circle,0,MODE_EMA,PRICE_CLOSE);
   double ma1[1];
   double ma2[1];
   if(CopyBuffer(fma,0,0,1,ma1)!=1){
      Print("CopyBuffer from iMA failed, no data");
      return;
   }
   if(CopyBuffer(cma,0,0,1,ma2)!=1){
      Print("CopyBuffer from iMA failed, no data");
      return;
   }
   ma = ma1[0] - ma2[0];
   /*拿到一分钟均线ma*/
   bottom = ma - spread;
   top = ma + spread; 
   take = futures_tick.bid - cash_tick.bid;//计算当前时刻的价差take  
   for(int i = 0;i<bff-1;i++){ //更新用来过滤噪音的缓冲区
      front_buffer[i] = front_buffer[i+1];
   }
   front_buffer[bff-1] = take;
   shortprc = shortPrice();//把平滑后的价差算出来
   if(show == 1){
   Comment(
      "当前均线 ：",MathCeil(ma*1000)/1000,"\n",
      "底部 ：",MathCeil(bottom*1000)/1000,"\n",
      "顶部 ：",MathCeil(top*1000)/1000,"\n",
      "状态 ：",take_state,"\n",
      "持仓数 ：",PositionsTotal(),"\n",
      "缓冲价格区域 ：","\n 1: ",
      MathCeil(front_buffer[0]*1000)/1000,"\n 2: ",
      MathCeil(front_buffer[1]*1000)/1000,"\n 3: ",
      MathCeil(front_buffer[2]*1000)/1000,"\n 4: ",
      MathCeil(front_buffer[3]*1000)/1000,"\n 5: ",
      MathCeil(front_buffer[4]*1000)/1000,"\n",
      "当前缓冲值 ：",MathCeil(shortprc*1000)/1000,"\n",
      "当前价格 ：",MathCeil(take*1000)/1000,"\n"
   );
   }
   
   if(shortprc>top){ //如果平滑后的价差和当前价差都满足顶部条件，则准备做空
      if(take_state == 0){ //如果当前账户持仓状态为0，做空
         for(int i=0;i<counts;i++){
            Open(1); //传1做空
         }
         take_state = 1; //账户状态更改为1
         return;
      }
      double sum = 0;
      for(int i=1;i<addlots;i++){
         sum = sum + mylots*50*i;
         if(take_state == 2*i-1){
            if(AccountInfoDouble(ACCOUNT_PROFIT) > sum){
               for(int k=0;k<counts;k++){
                  Open(1); //传1做空
               }
               take_state = 2*i+1;
               return;
            }
         }
      }
   }
   if(shortprc<bottom){
      if(take_state == 0){      
         for(int i=0;i<counts;i++){
            Open(0); //传0做多
         }
         take_state = 2;
         return;
      }
      double sum = 0;
      for(int i=1;i<addlots;i++){
         sum = sum + mylots*50*i;
         if(take_state == 2*i){
            if(AccountInfoDouble(ACCOUNT_PROFIT) > sum){
               for(int k=0;k<counts;k++){
                  Open(0); //传1做空
               }              
               take_state = 2*i+2;
               return;
            }
         }
      }   
   }
   for(int i=1;i<addlots*2;i++){
   if(take_state == 2*i-1){
      if(shortprc < ma + out){   
         Close();
         take_state = 0;
         return;
      }
   }
   if(take_state == 2*i){
      if(shortprc > ma - out){
         Close();
         take_state = 0;
         return;
      }
   }
   }
}
void Open(int buyOrsell){
   req.action = TRADE_ACTION_DEAL;         
   req.magic = number;                
   req.symbol = cash;                     
   req.volume = lots;
   req.tp = 0;           
   if(buyOrsell == 0){     
      req.sl = cash_tick.ask + slpoint;              
      req.type = ORDER_TYPE_SELL;                
      req.price = cash_tick.bid;
   }
   else if(buyOrsell == 1){
      req.sl = cash_tick.bid - slpoint;
      req.type = ORDER_TYPE_BUY;
      req.price = cash_tick.ask;      
   }
   check = OrderSendAsync(req,res);
   ZeroMemory(req);
   ZeroMemory(res);
}
void ChangeOrders(){
   int total=PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong  position_ticket=PositionGetTicket(i);                                      
      string position_symbol=PositionGetString(POSITION_SYMBOL);                         
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  
      double volume=PositionGetDouble(POSITION_VOLUME);                                 
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    
      if(magic==number){
         req.action   =TRADE_ACTION_SLTP;        
         req.position =position_ticket;         
         req.symbol   =position_symbol;          
         req.volume   =volume;                   
         req.deviation=5;                        
         req.magic    =number;                   
         if(type==POSITION_TYPE_BUY){
            if(cash_tick.bid - slpoint > PositionGetDouble(POSITION_SL)){
               req.sl = cash_tick.bid - slpoint;
            }
            else{
               return;
            }
            req.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            req.type =ORDER_TYPE_BUY;
         }
         if(type==POSITION_TYPE_SELL){
            if(cash_tick.ask + slpoint < PositionGetDouble(POSITION_SL)){
               req.sl = cash_tick.ask + slpoint;
            }
            else{
               return;
            }
            req.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            req.type =ORDER_TYPE_SELL;
         }
         check = OrderSendAsync(req,res);
         ZeroMemory(req);
         ZeroMemory(res);
      }
   }   
}
void Close(){
   int total=PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong  position_ticket=PositionGetTicket(i);                                      
      string position_symbol=PositionGetString(POSITION_SYMBOL);                         
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  
      double volume=PositionGetDouble(POSITION_VOLUME);                                 
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    
      if(magic==number){
         req.action   =TRADE_ACTION_DEAL;        
         req.position =position_ticket;         
         req.symbol   =position_symbol;          
         req.volume   =volume;                   
         req.deviation=5;                        
         req.magic    =number;                   
         if(type==POSITION_TYPE_BUY){
            req.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            req.type =ORDER_TYPE_SELL;
         }
         else{
            req.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            req.type =ORDER_TYPE_BUY;
         }
         check = OrderSendAsync(req,res);
         ZeroMemory(req);
         ZeroMemory(res);
      }
   }
}