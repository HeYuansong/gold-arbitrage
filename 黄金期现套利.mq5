extern string futures = "GOLD_AUFG21";
extern string cash = "GOLD";
extern double bottom = 0;
extern double top = 0.6;
extern double lots = 0.1;
MqlTick futures_tick;
MqlTick cash_tick;
MqlTradeRequest req;
MqlTradeResult res;
int number = 123;
int timer = 60;
bool check = true;
int OnInit() {
   EventSetTimer(timer);
   return(INIT_SUCCEEDED);
}
void OnTimer() {
   SymbolInfoTick(futures,futures_tick);
   SymbolInfoTick(cash,cash_tick);
   if(cash_tick.bid > futures_tick.ask + bottom){
      if(PositionsTotal() == 0){
         req.action = TRADE_ACTION_DEAL;
         req.magic = number;                
         req.symbol = futures;                     
         req.volume = lots;                         
         req.sl = 0;                                
         req.tp = 0;                                
         req.type = ORDER_TYPE_BUY;                
         req.price = futures_tick.ask; 
         check = OrderSendAsync(req,res);
         ZeroMemory(req);
         ZeroMemory(res);
         req.action = TRADE_ACTION_DEAL;         
         req.magic = number;                
         req.symbol = cash;                     
         req.volume = lots;                         
         req.sl = 0;
         req.tp = 0;                                
         req.type = ORDER_TYPE_SELL;                
         req.price = cash_tick.bid; 
         check = OrderSendAsync(req,res);
         ZeroMemory(req);
         ZeroMemory(res);
      }
   }
   if(futures_tick.bid > cash_tick.ask + top){
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