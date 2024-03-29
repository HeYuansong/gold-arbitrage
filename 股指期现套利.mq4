﻿extern string futures = "GC_2112";
extern string cash = "XAUUSD";
extern double lots = 1.0;
double bottom;
double top;
extern double spread = 0.2;
extern int time1 = 0;
extern int time2 = 21;
double futures_ask;
double futures_bid;
double cash_ask;
double cash_bid;
int futures_ticket;
int cash_ticket;
bool check = true;
double ma;
double circle = 60;
int OnInit(){ 
   EventSetTimer(3); 
   return(INIT_SUCCEEDED); 
}
void OnTimer(){
   ma = iMA(futures,0,circle,8,MODE_SMMA,PRICE_MEDIAN,0) - iMA(cash,0,circle,8,MODE_SMMA,PRICE_MEDIAN,0);
   printf("ma "+ma);
   if(OrdersTotal() == 0){
      bottom = ma - spread;
      top = ma + spread;
   }
   if(Hour() > time1 && Hour() < time2){
      printf("当前时间："+Hour()+",EA运行中...");
      futures_ask = MarketInfo(futures, MODE_ASK);
      futures_bid = MarketInfo(futures, MODE_BID);
      cash_ask = MarketInfo(cash, MODE_ASK);
      cash_bid = MarketInfo(cash, MODE_BID);
      if(futures_bid - cash_bid < bottom){
         if(OrdersTotal() == 0){
            cash_ticket = OrderSend(cash,OP_SELL,lots,cash_bid,3,0,0,"cash order",123,0,clrAliceBlue);
            futures_ticket = OrderSend(futures,OP_BUY,lots,futures_ask,3,0,0,"futures order",123,0,clrAliceBlue);
         }
      }
      if(futures_bid - cash_bid > top){
         if(OrdersTotal() > 0){
            check=OrderClose(cash_ticket,lots,cash_ask,3);
            check=OrderClose(futures_ticket,lots,futures_bid,3);
         }
      }
   }
   else{
      printf("当前时间："+Hour()+",EA休眠中...");
   }
}
