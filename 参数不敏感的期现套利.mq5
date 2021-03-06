//+------------------------------------------------------------------+
//|                                                   参数不敏感的期现套利.mq5 |
//|                                                       HeYuansong |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "HeYuansong"
#property link      "https://www.mql5.com"
#property version   "1.00"
input string   futures="GOLD_DEC21";
input string   cash="GOLD";
input int      circle=20;
double lots = 0.02;
double bottom;
double top;
MqlTick futures_tick;
MqlTick cash_tick;
MqlTradeRequest req;
MqlTradeResult res;
int number = 123;
bool check = true;
input int timer = 1;
input double spread = 0.4;
double ma;
int fma;
int cma;
int OnInit(){
   EventSetTimer(timer);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){
   EventKillTimer();
}
void OnTimer(){
   if(AccountInfoDouble(ACCOUNT_BALANCE) >= 40.2 + lots * 2000) {
       if(lots >= 100){
               lots = 100;
       }
       else{
               lots += 0.01;
       }
   }
   fma = iMA(futures,PERIOD_M1,circle,0,MODE_EMA,PRICE_CLOSE) ;
   cma = iMA(cash,PERIOD_M1,circle,0,MODE_EMA,PRICE_CLOSE);
   double ma1[1];
   double ma2[1];
   if(CopyBuffer(fma,0,0,1,ma1)!=1){
      Print("CopyBuffer from iMA failed, no data");
      return;
     }
   if(CopyBuffer(cma,0,0,1,ma2)!=1)
     {
      Print("CopyBuffer from iMA failed, no data");
      return;
     }
   
   Print("期货均线 ", ma1[0]);
   Print("现货均线", ma2[0]);
   ma = ma1[0] - ma2[0];
   Print("均线值 ",ma);
   if(PositionsTotal() == 0){
      bottom = ma - spread;
      top = ma + spread;
   }
   Print("当前持仓数 ",PositionsTotal());
   Print("底部 ",bottom," 顶部 ",top);
   SymbolInfoTick(futures,futures_tick);
   SymbolInfoTick(cash,cash_tick);
   if(futures_tick.bid - cash_tick.bid > top){
      if(PositionsTotal() == 0){
         req.action = TRADE_ACTION_DEAL;
         req.magic = number;                
         req.symbol = futures;                     
         req.volume = lots;                         
         req.sl = 0;                                
         req.tp = 0;                                
         req.type = ORDER_TYPE_SELL;                
         req.price = futures_tick.bid; 
         check = OrderSendAsync(req,res);
         ZeroMemory(req);
         ZeroMemory(res);
         req.action = TRADE_ACTION_DEAL;         
         req.magic = number;                
         req.symbol = cash;                     
         req.volume = lots;                         
         req.sl = 0;
         req.tp = 0;                                
         req.type = ORDER_TYPE_BUY;                
         req.price = cash_tick.ask; 
         check = OrderSendAsync(req,res);
         ZeroMemory(req);
         ZeroMemory(res);
      }
   }
   if(futures_tick.bid - cash_tick.bid < bottom){
      if(PositionsTotal() > 0){
         int total=PositionsTotal();
         for(int i=total-1; i>=0; i--){
            ulong  position_ticket=PositionGetTicket(i);                                      // 持仓价格
            string position_symbol=PositionGetString(POSITION_SYMBOL);                        // 交易品种 
            int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // 小数位数
            ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // 持仓的幻数
            double volume=PositionGetDouble(POSITION_VOLUME);                                 // 持仓交易量
            ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // 持仓类型
            if(magic==number){
               req.action   =TRADE_ACTION_DEAL;        // 交易操作类型
               req.position =position_ticket;          // 持仓位置
               req.symbol   =position_symbol;          // 交易品种 
               req.volume   =volume;                   // 持仓交易量
               req.deviation=5;                        // 允许价格偏差
               req.magic    =number;                   // 持仓幻数
               if(type==POSITION_TYPE_BUY){
                  req.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
                  req.type =ORDER_TYPE_SELL;
               }
               else {
                  req.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
                  req.type =ORDER_TYPE_BUY;
               }
               check = OrderSendAsync(req,res);
               ZeroMemory(req);
               ZeroMemory(res);
            }
         }
      }
   }
}