extern string futures = "GC_2108";
extern string cash = "XAUUSD";
extern double lots = 1.0;
extern double bottom = 0;
extern double top = 0.6;
double futures_ask;
double futures_bid;
double cash_ask;
double cash_bid;
bool check = true;
int OnInit(){ 
   EventSetTimer(5); 
   return(INIT_SUCCEEDED); 
}
void OnTimer(){
   if(Hour() > 0 && Hour() < 21){
      printf("当前时间："+Hour()+",EA运行中...");
      futures_ask = MarketInfo(futures, MODE_ASK);
      futures_bid = MarketInfo(futures, MODE_BID);
      cash_ask = MarketInfo(cash, MODE_ASK);
      cash_bid = MarketInfo(cash, MODE_BID);
      if(cash_bid > futures_ask + bottom){
         if(OrdersTotal() == 0){
            OrderSend(cash,OP_SELL,lots,cash_bid,3,0,0,"cash order",123,0,clrAliceBlue);
            OrderSend(futures,OP_BUY,lots,futures_ask,3,0,0,"futures order",123,0,clrAliceBlue);
         }
      }
      if(futures_bid > cash_ask + top){
         if(OrdersTotal() > 0){
            for(int i=OrdersTotal()-1;i>=0;i--) {
               if(OrderSelect(i,SELECT_BY_POS)) {
                  if(OrderSymbol()==cash)
                     check=OrderClose(OrderTicket(),lots,cash_ask,3);
                  else if(OrderSymbol()==futures)
                     check=OrderClose(OrderTicket(),lots,futures_bid,3);
               }
            }
         }
      }
   }
   else{
      printf("当前时间："+Hour()+",EA休眠中...");
   }
}
