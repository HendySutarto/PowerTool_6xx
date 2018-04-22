//---------------------------------------------------------------------------
// Strategy interface ver 1.10 (c) Forex Tester Software 2011
//
// What's new:
//
// ver 1.10
//
//   1. Added new function ObjectGetText - read the object's description
//
//
// ver 1.9
//   1. Added new function CloseOrderPartial - close part of position
//
// ver 1.8
//   1. Added new function iBarShift - returns index of a bar by its time
//   4. Added new function iHighest - returns index of a bar with the
//      highest value
//   5. Added new function iLowest - returns index of a bar with the
//      lowest value
//   6. New constants MODE_OPEN .. MODE_TIME
//   7. Added new external parameter type - ot_Color, represents color
//
// ver 1.7
//   1. Added new function TimeCurrent: TDateTime - current server time
//   2. Added new procedure SetIndicatorBuffStyle - allows to set indicator
//      line styles and colors
//
// ver 1.6
//   1. Constants of timeframes changed
//                   now      before
//      PERIOD_M1  = 1;       0
//      PERIOD_M5  = 5;       1
//      PERIOD_M15 = 15;      2
//      PERIOD_H1  = 60;      3
//      PERIOD_H4  = 60*4;    4
//      PERIOD_D1  = 60*24;   5
//      PERIOD_W1  = 60*24*7; 6
//
//   2. Timeframe should be defined with number of minutes in it
//
// ver 1.5
//   1. Added new object functions
//      ObjectCreate
//      ObjectDelete
//      ObjectExists
//      ObjectType
//      ObjectSet
//      ObjectGet
//      ObjectsDeleteAll
//      ObjectSetText
//   2. Added function to get interface verion - GetInterfaceVersion
//
// ver 1.4
//   1. Added new procedures Pause/Resume, that allow to pause testing from
//      strategy and continue
//
// ver 1.3
//   1. Added additional parameters Comment and MagicNumber to functions
//      SendInstantOrder and SendPendingOrder
//   2. Added new function OrderMagicNumber and OrderComment
//
// ver 1.2
//   1. Added new functions:
//      CreateIndicator, GetIndicatorValue
//
// ver 1.1
//   1. Added new functions to get account information:
//      AccountBalance, AccountEquity, AccountMargin, AccountFreeMargin,
//      AccountLeverage
//   2. Added debug function - Breakpoint
//
// ver 1.0
//
//---------------------------------------------------------------------------
unit StrategyInterfaceUnit;

interface

uses
  graphics;

type
  //-------------------------------------------
  // currency information
  //-------------------------------------------
  PCurrencyInfo = ^TCurrencyInfo;
  TCurrencyInfo = packed record
    Symbol: PAnsiChar;                 // currency name
    Digits: integer;                   // number of digits after '.'
    spread: integer;                   // spread in pips
    Point: double;                     // minimal currency point
    lot: integer;                      // 1 lot cost
    curr: PAnsiChar;                   // lot currency
    SwapLong: double;                  // swap points long
    SwapShort: double;                 // swap points short
  end;


  //-------------------------------------------
  // trade position
  //-------------------------------------------
  TTradePosition = packed record
    ticket: integer;                   // order handle
    OpenTime: TDateTime;               // order open time
    CloseTime: TDateTime;              // order close time
    PosType: integer;                  // position type (tp_Buy ... tp_Credit)
    lot: double;                       // lot
    Symbol: PAnsiChar;                 // currency name
    OpenPrice: double;                 // open price
    ClosePrice: double;                // close price
    StopLoss: double;                  // stop loss
    TakeProfit: double;                // take profit
    commission: double;                // comission
    swap: double;                      // swap
    profit: double;                    // profit in USD
    ProfitPips: integer;               // profit in pips
    comments: PAnsiChar;               // comments
    margin: double;                    // margin
  end;

  // option type
  TOptionType =
    (ot_Longword  = 0,
     ot_Integer   = 1,
     ot_double    = 2,
     ot_String    = 3,
     ot_Boolean   = 4,
     ot_EnumType  = 5,
     ot_Timeframe = 6,
     ot_Currency  = 7,
     ot_LineStyle = 8,
     ot_Separator = 9,
     ot_Reserved0 = 10,
     ot_Color     = 11);

  // search mode
  TSearchMode =
    (MODE_TRADES  = 0,
     MODE_HISTORY = 1);

  // order select mode
  TOrderSelectMode =
    (SELECT_BY_POS     = 0,
     SELECT_BY_TICKET  = 1);

  // market info constants
  TMarketInfo =
    (MODE_BID   = 0,
     MODE_ASK   = 1);

  // trade position type
  TTradePositionType =
    (tp_Buy       = 0,
     tp_Sell      = 1,
     tp_BuyLimit  = 2,
     tp_SellLimit = 3,
     tp_BuyStop   = 4,
     tp_SellStop  = 5,
     tp_Balance   = 6,
     tp_Credit    = 7);

  // instant operation type
  TInstantOrderType =
    (op_Buy       = 0,
     op_Sell      = 1);

  // pending operation type
  TPendingOrderType =
    (op_BuyLimit  = 0,
     op_BuyStop   = 1,
     op_SellLimit = 2,
     op_SellStop  = 3);

  // object types
  TObjectType =
    (obj_AnyObject        = 0,
     obj_VLine            = 1,
     obj_HLine            = 2,
     obj_TrendLine        = 3,
     obj_Ray              = 4,
     obj_PolyLine         = 5,
     obj_FiboRetracement  = 6,
     obj_FiboTimeZones    = 7,
     obj_FiboArc          = 8,
     obj_FiboFan          = 9,
     obj_AndrewsPitchfork = 10,
     obj_Text             = 11,
     obj_TextLabel        = 12,
     obj_Rectangle        = 13,
     obj_Ellipse          = 14,
     obj_Triangle         = 15,
     obj_FiboChannel      = 16,
     obj_LRChannel        = 17,
     obj_FiboExtension    = 18);

const
  // timeframes
  PERIOD_M1  = 1;
  PERIOD_M5  = 5;
  PERIOD_M15 = 15;
  PERIOD_M30 = 30;
  PERIOD_H1  = 60;
  PERIOD_H2  = 60*2;
  PERIOD_H4  = 60*4;
  PERIOD_D1  = 60*24;
  PERIOD_W1  = 60*24*7;
  PERIOD_MN1 = 60*24*30;

  // object properties constants
  OBJPROP_TIME1          = 0;
  OBJPROP_PRICE1         = 1;
  OBJPROP_TIME2          = 2;
  OBJPROP_PRICE2         = 3;
  OBJPROP_TIME3          = 4;
  OBJPROP_PRICE3         = 5;
  OBJPROP_COLOR          = 6;
  OBJPROP_STYLE          = 7;
  OBJPROP_WIDTH          = 8;
  OBJPROP_ELLIPSE        = 11;
  OBJPROP_FIBOCLOSEDENDS = 12;
  OBJPROP_FIBOSHOWPRICE  = 13;
  OBJPROP_FIBOENDWIDTH   = 14;
  OBJPROP_FIBOLEVELS     = 15;
  OBJPROP_FIBOLEVELN     = 16;
  OBJPROP_LEVELCOLOR     = 17;
  OBJPROP_LEVELSTYLE     = 18;
  OBJPROP_LEVELWIDTH     = 19;
  OBJPROP_LEVELVALUE     = 20;
  OBJPROP_FONTSIZE       = 21;
  OBJPROP_HALIGNMENT     = 22;
  OBJPROP_VALIGNMENT     = 23;
  OBJPROP_FONTNAME       = 24;
  OBJPROP_XDISTANCE      = 25;
  OBJPROP_YDISTANCE      = 26;
  OBJPROP_TEXT           = 27;
  OBJPROP_NAME           = 28;
  OBJPROP_SCREENCOORDS   = 29;
  OBJPROP_SCRHALIGNMENT  = 30;
  OBJPROP_SCRVALIGNMENT  = 31;
  OBJPROP_FILLINSIDE     = 32;
  OBJPROP_FILLCOLOR      = 33;

  // text alignment
  tlTop           = 0;
  tlCenter        = 1;
  tlBottom        = 2;

  taLeftJustify   = 0;
  taRightJustify  = 1;
  taCenter        = 2;

  MODE_OPEN    = 0;
  MODE_LOW     = 1;
  MODE_HIGH    = 2;
  MODE_CLOSE   = 3;
  MODE_VOLUME  = 4;
  MODE_TIME    = 5;
  

// Get currency information
// Symbol - currency name
// info - pointer to TCurrencyInfo record
// result: true if success
function  GetCurrencyInfo(Symbol: AnsiString; var info: PCurrencyInfo): boolean;

// Register option
// OptionName - name of option
// OptionType - see TOptionType enumeration
// option - pointer to first byte
procedure RegOption(OptionName: AnsiString; OptionType: TOptionType; var option);

// Add separator to options dialog
// text - separator caption
procedure AddSeparator(text: AnsiString);

// Add option value (for drop down box options)
// OptionName - name of previously registered option
// value - new value in drop down box
procedure AddOptionValue(OptionName, value: AnsiString);

// Set option range (for integer, longword and double types)
// OptionName - name of previously registered option
// LowValue - lowest value in range
// HighValue - highest value in range
// note: in dialog box after entering option value it will be checked
//       to be in range LowValue <= value <= HighValue
procedure SetOptionRange(OptionName: AnsiString; LowValue, HighValue: double);

// Set option digits (for double options) defines number of digits after point
// OptionName - name of option
// digits - number of digits after point
procedure SetOptionDigits(OptionName: AnsiString; digits: word);

// Print text in "Journal" window in ForexTester
// s - text
procedure Print(s: AnsiString);

// Set strategy short name
// name - short name
procedure StrategyShortName(name: AnsiString);

// Set strategy description
// desc - description
procedure StrategyDescription(desc: AnsiString);

// Set currency and timeframe (after that such functions will be enabled:
// Bid, Ask, Symbol, Point, Digits, Open, Close, High, Low, Volume, Time, Bars)
// Symbol - requested currency
// TimeFrame - requested timeframe
// result: true if success
function  SetCurrencyAndTimeframe(Symbol: AnsiString; TimeFrame: integer): boolean;

// Get market information
// Symbol - requested currency
// _type - requested item (MODE_BID, MODE_ASK)
function  MarketInfo(Symbol: AnsiString; _type: TMarketInfo): double;

// Send instant order
// Symbol - currency name
// OperationType - type of operation (op_Sell, op_Buy)
// LotSize - lot size
// StopLoss - stop loss
// TakeProfit - take profit
// Comment - text comment
// MagicNumber - special number that will mark this order
// OrderHandle - returned handle of order (-1 if fail)
// result: true if success OrderHandle = ticket, false if failed OrderHandle = -1
function  SendInstantOrder(Symbol: AnsiString; OperationType: TInstantOrderType;
            LotSize, StopLoss, TakeProfit: double; Comment: AnsiString;
            MagicNumber: integer; var OrderHandle: integer): boolean;

// Send pending order
// Symbol - currency name
// OperationType - type of operation (op_SellLimit, op_SellStop, op_BuyLimit, op_BuyStop)
// LotSize - lot size
// StopLoss - stop loss
// TakeProfit - take profit
// ExecutionPrice - price where order should be placed
// Comment - text comment
// MagicNumber - special number that will mark this order
// OrderHandle - returned handle of order (-1 if fail)
// result: true if success OrderHandle = ticket, false if failed OrderHandle = -1
function  SendPendingOrder(Symbol: AnsiString; OperationType: TPendingOrderType;
            LotSize, StopLoss, TakeProfit, ExecutionPrice: double;
            Comment: AnsiString; MagicNumber: integer;
            var OrderHandle: integer): boolean;

// Modify order
// OrderHandle - handle of the order
// NewPrice - new order price (only for pending order)
// StopLoss - new stop loss
// TakeProfit - new take profit
// result: true if success
function  ModifyOrder(OrderHandle: integer; NewPrice, StopLoss,
            TakeProfit: double): boolean;

// Delete order
// OrderHandle - handle of the order
// result: true if success
function  DeleteOrder(OrderHandle: integer): boolean;

// Close order
// OrderHandle - handle of the order
// result: true if success
function  CloseOrder(OrderHandle: integer): boolean;

// Get order information
// OrderHandle - handle of the order
// info - if order is found this structure will be filled with order info
// result: true if success info will contain order information
function  GetOrderInfo(OrderHandle: integer; var info: TTradePosition): boolean;

// Get Bid price
function Bid: double;

// Get Ask price
function Ask: double;

// Currency name
function  Symbol: AnsiString;

// Currency digits after point
function  Digits: integer;

// Minimal currency point
function  Point: double;

// Select order
// index - order index or order handle (depending on flags)
// flags - selecting flags (SELECT_BY_POS, SELECT_BY_TICKET)
// pool - where to find order (MODE_TRADES, MODE_HISTORY) only matters
//        when flags = SELECT_BY_POS
// result: true if success
function  OrderSelect(index: integer; flags: TOrderSelectMode = SELECT_BY_POS;
            pool: TSearchMode = MODE_TRADES): boolean;

// Get profit in dollars of selected order
function OrderProfit: double;

// Get profit in pips of selected order
function OrderProfitPips: double;

// Check if order was closed
// OrderHandle - order handle
// result: true if order is closed, otherwise false
function OrderClosed(OrderHandle: integer): boolean;

// Number of closed positions
function HistoryTotal: integer;

// Number of opened positions
function OrdersTotal: integer;

// Open time of selected order
function OrderOpenTime: TDateTime;

// Close time of selected order
function OrderCloseTime: TDateTime;

// Lot size of selected order
function OrderLots: double;

// Handle of selected order
function OrderTicket: integer;

// Type of the selected order (tp_Buy, tp_Sell, tp_BuyLimit, tp_SellLimit,
// tp_BuyStop, tp_SellStop, tp_Balance, tp_Credit)
function OrderType: TTradePositionType;

// Stop loss of selected order
function OrderStopLoss: double;

// Take profit of selected order
function OrderTakeProfit: double;

// Open price of selected order
function OrderOpenPrice: double;

// Close price of selected order
function OrderClosePrice: double;

// Currency of selected order
function OrderSymbol: AnsiString;

// Get order MagicNumber
function OrderMagicNumber: integer;

// Get order comment
function OrderComment: AnsiString;

// Get open value
// Symbol - requested currency
// TimeFrame - requested timeframe
// index - index in bars array (0 - last bar)
function  iOpen(Symbol: AnsiString; TimeFrame, index: integer): double;

// Get close value
// Symbol - requested currency
// TimeFrame - requested timeframe
// index - index in bars array (0 - last bar)
function  iClose(Symbol: AnsiString; TimeFrame, index: integer): double;

// Get high value
// Symbol - requested currency
// TimeFrame - requested timeframe
// index - index in bars array (0 - last bar)
function  iHigh(Symbol: AnsiString; TimeFrame, index: integer): double;

// Get low value
// Symbol - requested currency
// TimeFrame - requested timeframe
// index - index in bars array (0 - last bar)
function  iLow(Symbol: AnsiString; TimeFrame, index: integer): double;

// Get volume
// Symbol - requested currency
// TimeFrame - requested timeframe
// index - index in bars array (0 - last bar)
function  iVolume(Symbol: AnsiString; TimeFrame, index: integer): double;

// Get time of bar
// Symbol - requested currency
// TimeFrame - requested timeframe
// index - index in bars array (0 - last bar)
function  iTime(Symbol: AnsiString; TimeFrame, index: integer): TDateTime;

// Get number of bars
// Symbol - requested currency
// TimeFrame - requested timeframe
function  iBars(Symbol: AnsiString; TimeFrame: integer): integer;

// Get open value in default currency and timeframe
// index - index in bars array (0 - last bar)
function  Open(index: integer): double;

// Get close value in default currency and timeframe
// index - index in bars array (0 - last bar)
function  Close(index: integer): double;

// Get high value in default currency and timeframe
// index - index in bars array (0 - last bar)
function  High(index: integer): double;

// Get low value in default currency and timeframe
// index - index in bars array (0 - last bar)
function  Low(index: integer): double;

// Get volume in default currency and timeframe
// index - index in bars array (0 - last bar)
function  Volume(index: integer): double;

// Get time of bar in default currency and timeframe
// index - index in bars array (0 - last bar)
function  Time(index: integer): TDateTime;

// Get number of bars in default currency and timeframe
function  Bars: integer;

// Get account balance
function  AccountBalance: double;

// Get account equity
function  AccountEquity: double;

// Get account margin
function  AccountMargin: double;

// Get account free margin
function  AccountFreeMargin: double;

// Get account leverage
function  AccountLeverage: integer;

// Get account profit
function  AccountProfit: double;

// Breakpoint
// Stop strategy execution and show debug window with text
// number - breakpoint number
// text - text to show
procedure Breakpoint(number: integer; text: AnsiString);

// Pause - set pause mode
// text - text to show in message box, if text = '' then no message will appear
procedure Pause(text: AnsiString = '');

// continue testing
procedure Resume;

// Create indicator and obtaind id
// Symbol - currency name
// TimeFrame - desired timeframe
// IndicatorName - case sensitive indicator name that you can see in progam
// parameters - indicator parameters separated with ';'
// result: id that will be used in GetIndicatorValue
function  CreateIndicator(Symbol: AnsiString; TimeFrame: integer;
            IndicatorName, parameters: AnsiString): integer;

// Get indicator value
// IndicatorHandle - id obtained with CreateIndicator
// index - inder in array of values
// BufferIndex - index of buffer
// result: indicator value
function  GetIndicatorValue(IndicatorHandle, index, BufferIndex: integer): double;

// Get interface version
procedure GetInterfaceVersion(var MajorValue, MinorValue: integer);

// Create object
// name - object name (must be unique)
// ObjType - type of object (see TObjectType)
// window - in what window to show object (ignored)
// time1, price1 .. time3, price3 - time and price coordinates of object
// function returns true if successful
function  ObjectCreate(name: AnsiString; ObjType: TObjectType; window: integer;
  time1: TDateTime; price1: double; time2: TDateTime = 0; price2: double = 0;
  time3: TDateTime = 0; price3: double = 0): boolean;

// Delete object by name
// name - name of the object
procedure ObjectDelete(name: AnsiString);

// Check if object already exists
// name  - name of the object
function  ObjectExists(name: AnsiString): boolean;

// Get object type
// name - name of the object
function  ObjectType(name: AnsiString): TObjectType;

// Set object property
// name - name of the object
// index - property index
// value - new value
// function returns true if successful
function  ObjectSet(name: AnsiString; index: integer; value: double): boolean;

// Get object property
// name - name of the object
// index - property index
function  ObjectGet(name: AnsiString; index: integer): double;

// Delete all objects
// window - window where to delete
// ObjType - type of objects
procedure ObjectsDeleteAll(window: integer = 0; ObjType: TObjectType = obj_AnyObject);

// set text/description for object
// name - name of the object
// text - text to set
// FontSize - font size
// FontName - font name
// Color - font color
// function returns true if successful
function  ObjectSetText(name, text: AnsiString; FontSize: integer = 12;
    FontName: AnsiString = 'Arial'; Color: TColor = clRed): boolean;

// get text/description of the object
// name - name of the object
// function returns text or empty string if failed
function  ObjectGetText(name: AnsiString): AnsiString;

// get current server time
function  TimeCurrent: TDateTime;

// set indicator's buffer style
// IndicatorHandle - indicator's handle received with CreateIndicator
// BuffIndex - index of indicator's buffer where you want to change style
// _style - line style
// width - line width
// clr - line color
procedure SetIndicatorBuffStyle(IndicatorHandle, BuffIndex: integer; _style: TPenStyle;
  width: integer; color: TColor);

// get bar index by its time
// Symbol - requested currency
// TimeFrame - requested timeframe
// time - time of the bar
// Exact - if this parameter is true then time should be exactly the same
//         otherwise will be returned index of the bar where time is
//         between time[index] and time[index + 1]
// function returns index of the bar if successful, and -1 if failed
function  iBarShift(Symbol: AnsiString; TimeFrame: integer; time: TDateTime; Exact: boolean): integer;

// get highest value in array
// Symbol - requested currency
// TimeFrame - requested timeframe
// _type - type of value (see constants MODE_OPEN .. MODE_TIME)
// count - number of bars to search
// index - first index to start searching
// function returns index of the bar if successful, and -1 if failed
function  iHighest(Symbol: AnsiString; TimeFrame: integer; _type, count, index: integer): integer;

// get lowest value in array
// Symbol - requested currency
// TimeFrame - requested timeframe
// _type - type of value (see constants MODE_OPEN .. MODE_TIME)
// count - number of bars to search
// index - first index to start searching
// function returns index of the bar if successful, and -1 if failed
function  iLowest(Symbol: AnsiString; TimeFrame: integer; _type, count, index: integer): integer;

// close part ot position
// OrderHandle - handle of the order
// LotSize - part of position to close (must be less or equal to position size)
// result: true if success
function  CloseOrderPartial(OrderHandle: integer; LotSize: double): boolean;


procedure ReplaceStr(var dest: PAnsiChar; source: PAnsiChar); stdcall;
function  Sell(LotSize, StopLoss, TakeProfit: double): integer;
function  Buy(LotSize, StopLoss, TakeProfit: double): integer;
function  StrTime(DateTime: TDateTime): AnsiString;
function  GetStopLossPoints(OrderHandle: integer): integer;
function  GetTakeProfitPoints(OrderHandle: integer): integer;
procedure SetStopLossPoints(OrderHandle, NewStopLoss: integer);
procedure SetTakeProfitPoints(OrderHandle, NewTakeProfit: integer);


function  _SendInstantOrder(Symbol: AnsiString; OperationType: TInstantOrderType;
            price, LotSize, StopLoss, TakeProfit: double; Comment: AnsiString;
            MagicNumber: integer; var OrderHandle: integer): boolean;

function  _CloseOrder(OrderHandle: integer; price: double): boolean;


implementation

uses
  SysUtils;

type
  // strategy interface procedures
  TGetCurrencyInfoFunc = function(Symbol: PAnsiChar; var info: PCurrencyInfo): boolean of object; stdcall;
  TSetPropertyProc = procedure(PropertyID: integer; value: OLEVariant) of object; stdcall;
  TRegOptionProc = procedure(OptionName: PAnsiChar; OptionType: integer; OptPtr: pointer) of object; stdcall;
  TAddOptionValueProc = procedure(OptionName, value: PAnsiChar) of object; stdcall;
  TSetOptionRange = procedure(OptionName: PAnsiChar; LowValue, HighValue: double) of object; stdcall;
  TSetOptionDigitsProc = procedure(OptionName: PAnsiChar; digits: word) of object; stdcall;
  TPrintProc = procedure(s: PAnsiChar) of object; stdcall;
  TGetDoubleFunc = function: double of object; stdcall;
  TGetPAnsiCharFunc = function: PAnsiChar of object; stdcall;
  TGetIntegerFunc = function: integer of object; stdcall;
  TGetDateTimeFunc = function: TDateTime of object; stdcall;
  TGet_iOHLCVFunc = function(Symbol: PAnsiChar; TimeFrame, index: integer): double of object; stdcall;
  TGet_iTimeFunc = function(Symbol: PAnsiChar; TimeFrame, index: integer): TDateTime of object; stdcall;
  TGet_iBarsFunc = function(Symbol: PAnsiChar; TimeFrame: integer): integer of object; stdcall;
  TGetOHLCVFunc = function(index: integer): double of object; stdcall;
  TGetTimeFunc = function(index: integer): TDateTime of object; stdcall;
  TGetBarsFunc = function: integer of object; stdcall;
  TSendInstantOrderFunc = function(Symbol: PAnsiChar; OperationType: integer;
    LotSize, StopLoss, TakeProfit: double; var OrderHandle: integer): boolean
    of object; stdcall;
  TSendInstantOrder2Func = function(Symbol: PAnsiChar; OperationType: integer;
    LotSize, StopLoss, TakeProfit: double; comment: PAnsiChar;
    MagicNumber: integer; var OrderHandle: integer): boolean of object; stdcall;
  T_SendInstantOrderFunc = function(Symbol: PAnsiChar; OperationType: integer;
    price, LotSize, StopLoss, TakeProfit: double; comment: PAnsiChar;
    MagicNumber: integer; var OrderHandle: integer): boolean of object; stdcall;
  TSendPendingOrderFunc = function(Symbol: PAnsiChar; OperationType: integer;
    LotSize, StopLoss, TakeProfit, ExecutionPrice: double;
    var OrderHandle: integer): boolean of object; stdcall;
  TSendPendingOrder2Func = function(Symbol: PAnsiChar; OperationType: integer;
    LotSize, StopLoss, TakeProfit, ExecutionPrice: double; comment: PAnsiChar;
    MagicNumber: integer; var OrderHandle: integer): boolean of object; stdcall;
  TModifyOrderFunc = function(OrderHandle: integer; NewPrice, StopLoss,
    TakeProfit: double): boolean of object; stdcall;
  TDeleteOrderFunc = function(OrderHandle: integer): boolean of object; stdcall;
  TCloseOrderFunc = function(OrderHandle: integer): boolean of object; stdcall;
  T_CloseOrderFunc = function(OrderHandle: integer; price: double): boolean of object; stdcall;
  TGetOrderInfoFunc = function(OrderHandle: integer;
    var info: TTradePosition): boolean of object; stdcall;
  TSetCurrencyAndTimeframeFunc = function(Symbol: PAnsiChar; TimeFrame: integer): boolean
    of object; stdcall;
  TOrderSelectFunc = function(index, flags: integer;
    pool: integer = 0): boolean of object; stdcall;
  TOrderClosedFunc = function(OrderHandle: integer): boolean of object; stdcall;
  TMarketInfoFunc = function(Symbol: PAnsiChar; _type: integer): double of object; stdcall;
  TStrategyShortNameProc = procedure(name: PAnsiChar) of object; stdcall;
  TStrategyDescriptionProc = procedure(desc: PAnsiChar) of object; stdcall;
  TBreakpointProc = procedure(number: integer; text: PAnsiChar) of object; stdcall;
  TCreateIndicatorFunc = function(CurrencyName: PAnsiChar; Timeframe: integer;
    IndicatorName, parameters: PAnsiChar): integer of object; stdcall;
  TGetIndicatorValueFunc = function(IndicatorHandle, index,
    BufferIndex: integer): double of object; stdcall;
  TPauseProc = procedure(text: PAnsiChar) of object; stdcall;
  TResumeProc = procedure of object; stdcall;
  TGetInterfaceVersionProc = procedure(var MajorValue, MinorValue: integer) of object; stdcall;
  TObjectCreateFunc = function(name: PAnsiChar; ObjType, window: integer;
    time1: TDateTime; price1: double; time2: TDateTime; price2: double;
    time3: TDateTime; price3: double): boolean of object; stdcall;
  TObjectDeleteProc = procedure(name: PAnsiChar) of object; stdcall;
  TObjectExistsFunc = function(name: PAnsiChar): boolean of object; stdcall;
  TObjectTypeFunc = function(name: PAnsiChar): integer of object; stdcall;
  TObjectSetFunc = function(name: PAnsiChar; index: integer; value: double): boolean of object; stdcall;
  TObjectGetFunc = function(name: PAnsiChar; index: integer): double of object; stdcall;
  TObjectsDeleteAllProc = procedure(window, ObjType: integer) of object; stdcall;
  TObjectSetTextFunc = function(name, text: PAnsiChar; FontSize: integer;
    FontName: PAnsiChar; Color: integer): boolean of object; stdcall;
  TSetIndicatorBuffStyleProc = procedure(IndicatorHandle, BuffIndex, _style, width, clr: integer) of object; stdcall;
  TIBarShiftFunc = function(Symbol: PAnsiChar; TimeFrame: integer; time: TDateTime; Exact: boolean): integer of object; stdcall;
  TIHighestFunc = function(Symbol: PAnsiChar; TimeFrame: integer; _type, count, index: integer): integer of object; stdcall;
  TILowestFunc = function(Symbol: PAnsiChar; TimeFrame: integer; _type, count, index: integer): integer of object; stdcall;
  TCloseOrderPartialFunc = function(OrderHandle: integer; LotSize: double): boolean of object; stdcall;
  TObjectGetTextFunc = function(name: PChar): PChar of object; stdcall;


  // pointers to interface procedures
  PInterfaceProcRec = ^TInterfaceProcRec;
  TInterfaceProcRec = packed record
    dwSize: longword;

    RegOption: TRegOptionProc;
    AddOptionValue: TAddOptionValueProc;
    SetOptionRange: TSetOptionRange;
    SetOptionDigits: TSetOptionDigitsProc;
    Print: TPrintProc;
    StrategyShortName: TStrategyShortNameProc;
    StrategyDescription: TStrategyDescriptionProc;

    GetCurrencyInfo: TGetCurrencyInfoFunc;
    SetCurrencyAndTimeframe: TSetCurrencyAndTimeframeFunc;
    MarketInfo: TMarketInfoFunc;

    Bid: TGetDoubleFunc;
    Ask: TGetDoubleFunc;
    Symbol: TGetPAnsiCharFunc;
    Digits: TGetIntegerFunc;
    Point: TGetDoubleFunc;

    SendInstantOrder: TSendInstantOrderFunc;
    SendPendingOrder: TSendPendingOrderFunc;
    ModifyOrder: TModifyOrderFunc;
    DeleteOrder: TDeleteOrderFunc;
    CloseOrder: TCloseOrderFunc;
    OrderClosed: TOrderClosedFunc;
    GetOrderInfo: TGetOrderInfoFunc;

    OrderSelect: TOrderSelectFunc;
    OrderProfit: TGetDoubleFunc;
    OrderProfitPips: TGetDoubleFunc;
    HistoryTotal: TGetIntegerFunc;
    OrdersTotal: TGetIntegerFunc;
    OrderOpenTime: TGetDateTimeFunc;
    OrderCloseTime: TGetDateTimeFunc;
    OrderLots: TGetDoubleFunc;
    OrderTicket: TGetIntegerFunc;
    OrderType: TGetIntegerFunc;
    OrderStopLoss: TGetDoubleFunc;
    OrderTakeProfit: TGetDoubleFunc;
    OrderOpenPrice: TGetDoubleFunc;
    OrderClosePrice: TGetDoubleFunc;
    OrderSymbol: TGetPAnsiCharFunc;

    iOpen: TGet_iOHLCVFunc;
    iClose: TGet_iOHLCVFunc;
    iHigh: TGet_iOHLCVFunc;
    iLow: TGet_iOHLCVFunc;
    iVolume: TGet_iOHLCVFunc;
    iTime: TGet_iTimeFunc;
    iBars: TGet_iBarsFunc;

    Open: TGetOHLCVFunc;
    Close: TGetOHLCVFunc;
    High: TGetOHLCVFunc;
    Low: TGetOHLCVFunc;
    Volume: TGetOHLCVFunc;
    Time: TGetTimeFunc;
    Bars: TGetBarsFunc;

    // extensions ver 1.1 (dwSize > 412)
    AccountBalance: TGetDoubleFunc;
    AccountEquity: TGetDoubleFunc;
    AccountMargin: TGetDoubleFunc;
    AccountFreeMargin: TGetDoubleFunc;
    AccountLeverage: TGetIntegerFunc;
    AccountProfit: TGetDoubleFunc;
    Breakpoint: TBreakpointProc;

    // extensions ver 1.2 (dwSize > 468)
    CreateIndicator: TCreateIndicatorFunc;
    GetIndicatorValue: TGetIndicatorValueFunc;

    // extensions ver 1.3 (dwSize > 484)
    SendInstantOrder2: TSendInstantOrder2Func;
    SendPendingOrder2: TSendPendingOrder2Func;
    OrderComment: TGetPAnsiCharFunc;
    OrderMagicNumber: TGetIntegerFunc;

    // extensions ver 1.4 (dwSize > 516)
    Pause: TPauseProc;
    Resume: TResumeProc;

    // extensions ver 1.41 (dwSize > 532)
    _SendInstantOrder: T_SendInstantOrderFunc;
    _CloseOrder: T_CloseOrderFunc;

    // extensions ver 1.5 (dwSize > 548)
    GetInterfaceVersion: TGetInterfaceVersionProc;
    ObjectCreate: TObjectCreateFunc;
    ObjectDelete: TObjectDeleteProc;
    ObjectExists: TObjectExistsFunc;
    ObjectType: TObjectTypeFunc;
    ObjectSet: TObjectSetFunc;
    ObjectGet: TObjectGetFunc;
    ObjectsDeleteAll: TObjectsDeleteAllProc;
    ObjectSetText: TObjectSetTextFunc;

    // extensions ver 1.7 (dwSize > 620)
    TimeCurrent: TGetDateTimeFunc;
    SetIndicatorBuffStyle: TSetIndicatorBuffStyleProc;

    // extensions ver 1.8 (dwSize > 636)
    iBarShift: TIBarShiftFunc;
    iHighest: TIHighestFunc;
    iLowest: TILowestFunc;

    // extensions ver 1.9 (dwSize > 660)
    CloseOrderPartial: TCloseOrderPartialFunc;

    // extensions ver 1.10 (dwSize > 668)
    ObjectGetText: TObjectGetTextFunc;
  end;


var
  IntrfProcsRec: TInterfaceProcRec;


{-----Replace PAnsiChar string with new one--------------------------------------}
procedure ReplaceStr(var dest: PAnsiChar; source: PAnsiChar); stdcall;
begin
  FreeMem(dest);
  GetMem(dest, StrLen(source) + 1);
  StrCopy(dest, source);
end;

{-----Sell-------------------------------------------------------------------}
function Sell(LotSize, StopLoss, TakeProfit: double): integer;
var
  tp, sl: double;
begin
  if TakeProfit = 0 then tp := 0 else tp := Bid - TakeProfit*Point;
  if StopLoss = 0   then sl := 0 else sl := Bid + StopLoss*Point;
  SendInstantOrder(Symbol, op_Sell, LotSize, sl, tp, '', 0, result);
end;

{-----Buy--------------------------------------------------------------------}
function Buy(LotSize, StopLoss, TakeProfit: double): integer;
var
  tp, sl: double;
begin
  if TakeProfit = 0 then tp := 0 else tp := Ask + TakeProfit*Point;
  if StopLoss = 0   then sl := 0 else sl := Ask - StopLoss*Point;
  SendInstantOrder(Symbol, op_Buy, LotSize, sl, tp, '', 0, result);
end;

{-----Convert time to string-------------------------------------------------}
function StrTime(DateTime: TDateTime): AnsiString;
var
  s: string;
begin
  DateTimeToString(s, 'yyyy.mm.dd hh:nn', DateTime);
  result := s;
end;

{-----Get currency information-----------------------------------------------}
function GetCurrencyInfo(Symbol: AnsiString; var info: PCurrencyInfo): boolean;
begin
  result := IntrfProcsRec.GetCurrencyInfo(PAnsiChar(Symbol), info)
end;

{-----Register option--------------------------------------------------------}
procedure RegOption(OptionName: AnsiString; OptionType: TOptionType; var option);
begin
  IntrfProcsRec.RegOption(PAnsiChar(OptionName), integer(OptionType), @option);
end;

{-----Add separator----------------------------------------------------------}
procedure AddSeparator(text: AnsiString);
begin
  IntrfProcsRec.RegOption(PAnsiChar(text), integer(ot_Separator), nil);
end;

{-----Add option value (for drop down box options)---------------------------}
procedure AddOptionValue(OptionName, value: AnsiString);
begin
  IntrfProcsRec.AddOptionValue(PAnsiChar(OptionName), PAnsiChar(value));
end;

{-----Set option range (for integer, longword and double types)--------------}
procedure SetOptionRange(OptionName: AnsiString; LowValue, HighValue: double);
begin
  IntrfProcsRec.SetOptionRange(PAnsiChar(OptionName), LowValue, HighValue);
end;

{-----Set option digits------------------------------------------------------}
procedure SetOptionDigits(OptionName: AnsiString; digits: word);
begin
  IntrfProcsRec.SetOptionDigits(PAnsiChar(OptionName), digits);
end;

{-----Print text in "Journal" window in ForexTester--------------------------}
procedure Print(s: AnsiString);
begin
  IntrfProcsRec.Print(PAnsiChar(s));
end;

{-----Set strategy short name------------------------------------------------}
procedure StrategyShortName(name: AnsiString);
begin
  IntrfProcsRec.StrategyShortName(PAnsiChar(name));
end;

{-----Set strategy description-----------------------------------------------}
procedure StrategyDescription(desc: AnsiString);
begin
  IntrfProcsRec.StrategyDescription(PAnsiChar(desc));
end;

{-----Get Bid price----------------------------------------------------------}
function Bid: double;
begin
  result := IntrfProcsRec.Bid;
end;

{-----Get Ask price----------------------------------------------------------}
function Ask: double;
begin
  result := IntrfProcsRec.Ask;
end;

{-----Currency name----------------------------------------------------------}
function  Symbol: AnsiString;
begin
  result := IntrfProcsRec.Symbol;
end;

{-----Currency digits after point--------------------------------------------}
function  Digits: integer;
begin
  result := IntrfProcsRec.Digits;
end;

{-----Minimal currency point-------------------------------------------------}
function  Point: double;
begin
  result := IntrfProcsRec.Point;
end;

{-----Get open value---------------------------------------------------------}
function  iOpen(Symbol: AnsiString; TimeFrame: integer; index: integer): double;
begin
  result := IntrfProcsRec.iOpen(PAnsiChar(Symbol), TimeFrame, index);
end;

{-----Get close value--------------------------------------------------------}
function  iClose(Symbol: AnsiString; TimeFrame: integer; index: integer): double;
begin
  result := IntrfProcsRec.iClose(PAnsiChar(Symbol), TimeFrame, index);
end;

{-----Get high value---------------------------------------------------------}
function  iHigh(Symbol: AnsiString; TimeFrame: integer; index: integer): double;
begin
  result := IntrfProcsRec.iHigh(PAnsiChar(Symbol), TimeFrame, index);
end;

{-----Get low value----------------------------------------------------------}
function  iLow(Symbol: AnsiString; TimeFrame: integer; index: integer): double;
begin
  result := IntrfProcsRec.iLow(PAnsiChar(Symbol), TimeFrame, index);
end;

{-----Get volume-------------------------------------------------------------}
function  iVolume(Symbol: AnsiString; TimeFrame: integer; index: integer): double;
begin
  result := IntrfProcsRec.iVolume(PAnsiChar(Symbol), TimeFrame, index);
end;

{-----Get time of bar--------------------------------------------------------}
function  iTime(Symbol: AnsiString; TimeFrame: integer; index: integer): TDateTime;
begin
  result := IntrfProcsRec.iTime(PAnsiChar(Symbol), TimeFrame, index);
end;

{-----Get number of bars-----------------------------------------------------}
function  iBars(Symbol: AnsiString; TimeFrame: integer): integer;
begin
  result := integer(IntrfProcsRec.iBars(PAnsiChar(Symbol), TimeFrame));
end;

{-----Get open value in default currency and timeframe-----------------------}
function  Open(index: integer): double;
begin
  result := IntrfProcsRec.Open(index);
end;

{-----Get close value in default currency and timeframe----------------------}
function  Close(index: integer): double;
begin
  result := IntrfProcsRec.Close(index);
end;

{-----Get high value in default currency and timeframe-----------------------}
function  High(index: integer): double;
begin
  result := IntrfProcsRec.High(index);
end;

{-----Get low value in default currency and timeframe------------------------}
function  Low(index: integer): double;
begin
  result := IntrfProcsRec.Low(index);
end;

{-----Get volume in default currency and timeframe---------------------------}
function  Volume(index: integer): double;
begin
  result := IntrfProcsRec.Volume(index);
end;

{-----Get time of bar in default currency and timeframe----------------------}
function  Time(index: integer): TDateTime;
begin
  result := IntrfProcsRec.Time(index);
end;

{-----Get number of bars in default currency and timeframe-------------------}
function  Bars: integer;
begin
  result := integer(IntrfProcsRec.Bars);
end;

{-----Set currency and timeframe---------------------------------------------}
function  SetCurrencyAndTimeframe(Symbol: AnsiString; TimeFrame: integer): boolean;
begin
  result := IntrfProcsRec.SetCurrencyAndTimeframe(PAnsiChar(Symbol), TimeFrame);
end;

{-----Get market information-------------------------------------------------}
function  MarketInfo(Symbol: AnsiString; _type: TMarketInfo): double;
begin
  result := IntrfProcsRec.MarketInfo(PAnsiChar(Symbol), integer(_type));
end;

{-----Send instant order-----------------------------------------------------}
function  SendInstantOrder(Symbol: AnsiString; OperationType: TInstantOrderType;
  LotSize, StopLoss, TakeProfit: double; Comment: AnsiString;
  MagicNumber: integer; var OrderHandle: integer): boolean;
begin
  result := IntrfProcsRec.SendInstantOrder2(PAnsiChar(Symbol), integer(OperationType),
    LotSize, StopLoss, TakeProfit, PAnsiChar(comment), MagicNumber, OrderHandle);
end;

{-----Send pending order-----------------------------------------------------}
function  SendPendingOrder(Symbol: AnsiString; OperationType: TPendingOrderType;
  LotSize, StopLoss, TakeProfit, ExecutionPrice: double;
  Comment: AnsiString; MagicNumber: integer; var OrderHandle: integer): boolean;
begin
  result := IntrfProcsRec.SendPendingOrder2(PAnsiChar(Symbol), integer(OperationType),
    LotSize, StopLoss, TakeProfit, ExecutionPrice, PAnsiChar(Comment),
    MagicNumber, OrderHandle);
end;

{-----Modify order-----------------------------------------------------------}
function  ModifyOrder(OrderHandle: integer; NewPrice, StopLoss,
  TakeProfit: double): boolean;
begin
  result := IntrfProcsRec.ModifyOrder(OrderHandle, NewPrice, StopLoss, TakeProfit);
end;

{-----Delete order-----------------------------------------------------------}
function  DeleteOrder(OrderHandle: integer): boolean;
begin
  result := IntrfProcsRec.DeleteOrder(OrderHandle);
end;

{-----Close order------------------------------------------------------------}
function  CloseOrder(OrderHandle: integer): boolean;
begin
  result := IntrfProcsRec.CloseOrder(OrderHandle);
end;

{-----Get order information--------------------------------------------------}
function  GetOrderInfo(OrderHandle: integer; var info: TTradePosition): boolean;
begin
  result := IntrfProcsRec.GetOrderInfo(OrderHandle, info);
end;

{-----Select order-----------------------------------------------------------}
function  OrderSelect(index: integer; flags: TOrderSelectMode = SELECT_BY_POS;
  pool: TSearchMode = MODE_TRADES): boolean;
begin
  result := IntrfProcsRec.OrderSelect(index, integer(flags), integer(pool));
end;

{-----Get profit in dollars of selected order--------------------------------}
function OrderProfit: double;
begin
  result := IntrfProcsRec.OrderProfit;
end;

{-----Get profit in pips of selected order-----------------------------------}
function OrderProfitPips: double;
begin
  result := IntrfProcsRec.OrderProfitPips;
end;

{-----Check if order was closed----------------------------------------------}
function OrderClosed(OrderHandle: integer): boolean;
begin
  result := IntrfProcsRec.OrderClosed(OrderHandle);
end;

{-----Number of closed positions---------------------------------------------}
function HistoryTotal: integer;
begin
  result := IntrfProcsRec.HistoryTotal;
end;

{-----Number of opened positions---------------------------------------------}
function OrdersTotal: integer;
begin
  result := IntrfProcsRec.OrdersTotal;
end;

{-----Open time of selected order--------------------------------------------}
function OrderOpenTime: TDateTime;
begin
  result := IntrfProcsRec.OrderOpenTime;
end;

{-----Close time of selected order-------------------------------------------}
function OrderCloseTime: TDateTime;
begin
  result := IntrfProcsRec.OrderCloseTime;
end;

{-----Lot size of selected order---------------------------------------------}
function OrderLots: double;
begin
  result := IntrfProcsRec.OrderLots;
end;

{-----Handle of selected order-----------------------------------------------}
function OrderTicket: integer;
begin
  result := IntrfProcsRec.OrderTicket;
end;

{-----Type of the selected order---------------------------------------------}
function OrderType: TTradePositionType;
begin
  result := TTradePositionType(IntrfProcsRec.OrderType);
end;

{-----Stop loss of selected order--------------------------------------------}
function OrderStopLoss: double;
begin
  result := IntrfProcsRec.OrderStopLoss;
end;

{-----Take profit of selected order------------------------------------------}
function OrderTakeProfit: double;
begin
  result := IntrfProcsRec.OrderTakeProfit;
end;

{-----Open price of selected order-------------------------------------------}
function OrderOpenPrice: double;
begin
  result := IntrfProcsRec.OrderOpenPrice;
end;

{-----Close price of selected order------------------------------------------}
function OrderClosePrice: double;
begin
  result := IntrfProcsRec.OrderClosePrice;
end;

{-----Currency of selected order---------------------------------------------}
function OrderSymbol: AnsiString;
begin
  result := IntrfProcsRec.OrderSymbol;
end;

{-----Get stop loss in points------------------------------------------------}
function  GetStopLossPoints(OrderHandle: integer): integer;
var
  info: PCurrencyInfo;
begin
  result := 0;
  if OrderSelect(OrderHandle, SELECT_BY_TICKET, MODE_TRADES) then
    begin
      if OrderStopLoss = 0 then
        exit;

      if not(GetCurrencyInfo(OrderSymbol, info)) then
        exit;

      result := round((OrderOpenPrice - OrderStopLoss)/info.Point);
      if OrderType = tp_Buy then
        result := -result;
    end;
end;

{-----Get take profit points-------------------------------------------------}
function  GetTakeProfitPoints(OrderHandle: integer): integer;
var
  info: PCurrencyInfo;
begin
  result := 0;
  if OrderSelect(OrderHandle, SELECT_BY_TICKET, MODE_TRADES) then
    begin
      if OrderTakeProfit = 0 then
        exit;

      if not(GetCurrencyInfo(OrderSymbol, info)) then
        exit;

      result := round((OrderOpenPrice - OrderTakeProfit)/info.Point);
      if OrderType = tp_Sell then
        result := -result;
    end;
end;

{-----Set stop loss in points------------------------------------------------}
procedure SetStopLossPoints(OrderHandle, NewStopLoss: integer);
var
  info: PCurrencyInfo;
begin
  if OrderSelect(OrderHandle, SELECT_BY_TICKET, MODE_TRADES) then
    begin
      if not(GetCurrencyInfo(OrderSymbol, info)) then
        exit;

      case OrderType of
        tp_Buy:  ModifyOrder(OrderHandle, OrderOpenPrice,
                   OrderOpenPrice - NewStopLoss*info.Point, OrderTakeProfit);
        tp_Sell: ModifyOrder(OrderHandle, OrderOpenPrice,
                   OrderOpenPrice + NewStopLoss*info.Point, OrderTakeProfit);
      end;
    end;
end;

{-----Set take profit in points----------------------------------------------}
procedure SetTakeProfitPoints(OrderHandle, NewTakeProfit: integer);
var
  info: PCurrencyInfo;
begin
  if OrderSelect(OrderHandle, SELECT_BY_TICKET, MODE_TRADES) then
    begin
      if not(GetCurrencyInfo(OrderSymbol, info)) then
        exit;

      case OrderType of
        tp_Buy:  ModifyOrder(OrderHandle, OrderOpenPrice, OrderStopLoss,
                   OrderOpenPrice + NewTakeProfit*info.Point);
        tp_Sell: ModifyOrder(OrderHandle, OrderOpenPrice, OrderStopLoss,
                   OrderOpenPrice - NewTakeProfit*info.Point);
      end;
    end;
end;

{-----Get account balance----------------------------------------------------}
function  AccountBalance: double;
begin
  if assigned(IntrfProcsRec.AccountBalance) then
    result := IntrfProcsRec.AccountBalance
  else
    result := 0;
end;

{-----Get account equity-----------------------------------------------------}
function  AccountEquity: double;
begin
  if assigned(IntrfProcsRec.AccountEquity) then
    result := IntrfProcsRec.AccountEquity
  else
    result := 0;
end;

{-----Get account margin-----------------------------------------------------}
function  AccountMargin: double;
begin
  if assigned(IntrfProcsRec.AccountMargin) then
    result := IntrfProcsRec.AccountMargin
  else
    result := 0;
end;

{-----Get account free margin------------------------------------------------}
function  AccountFreeMargin: double;
begin
  if assigned(IntrfProcsRec.AccountFreeMargin) then
    result := IntrfProcsRec.AccountFreeMargin
  else
    result := 0;
end;

{-----Get account leverage---------------------------------------------------}
function  AccountLeverage: integer;
begin
  if assigned(IntrfProcsRec.AccountLeverage) then
    result := IntrfProcsRec.AccountLeverage
  else
    result := 0;
end;

{-----Get account profit-----------------------------------------------------}
function  AccountProfit: double;
begin
  if assigned(IntrfProcsRec.AccountProfit) then
    result := IntrfProcsRec.AccountProfit
  else
    result := 0;
end;

{-----Breakpoint-------------------------------------------------------------}
procedure Breakpoint(number: integer; text: AnsiString);
begin
  if assigned(IntrfProcsRec.Breakpoint) then
    IntrfProcsRec.Breakpoint(number, PAnsiChar(text));
end;

{-----Create indicator and obtaind id----------------------------------------}
function  CreateIndicator(Symbol: AnsiString; TimeFrame: integer;
            IndicatorName, parameters: AnsiString): integer;
begin
  if assigned(IntrfProcsRec.CreateIndicator) then
    result := IntrfProcsRec.CreateIndicator(PAnsiChar(Symbol), TimeFrame,
      PAnsiChar(IndicatorName + '.dll'), PAnsiChar(parameters))
  else
    result := 0;
end;

{-----Get indicator value----------------------------------------------------}
function  GetIndicatorValue(IndicatorHandle, index, BufferIndex: integer): double;
begin
  if assigned(IntrfProcsRec.GetIndicatorValue) then
    result := IntrfProcsRec.GetIndicatorValue(IndicatorHandle, index, BufferIndex)
  else
    result := 0;
end;

{-----Get order MagicNumber--------------------------------------------------}
function OrderMagicNumber: integer;
begin
  if assigned(IntrfProcsRec.OrderMagicNumber) then
    result := IntrfProcsRec.OrderMagicNumber
  else
    result := 0;
end;

{-----Get order comment------------------------------------------------------}
function OrderComment: AnsiString;
begin
  if assigned(IntrfProcsRec.OrderComment) then
    result := IntrfProcsRec.OrderComment
  else
    result := '';
end;

{-----Pause------------------------------------------------------------------}
procedure Pause(text: AnsiString = '');
begin
  if assigned(IntrfProcsRec.Pause) then
    IntrfProcsRec.Pause(PAnsiChar(text));
end;

{-----Resume-----------------------------------------------------------------}
procedure Resume;
begin
  if assigned(IntrfProcsRec.Resume) then
    IntrfProcsRec.Resume;
end;

{-----Send instant order with selected price---------------------------------}
function  _SendInstantOrder(Symbol: AnsiString; OperationType: TInstantOrderType;
  price, LotSize, StopLoss, TakeProfit: double; Comment: AnsiString;
  MagicNumber: integer; var OrderHandle: integer): boolean;
begin
  if assigned(IntrfProcsRec._SendInstantOrder) then
    result := IntrfProcsRec._SendInstantOrder(PAnsiChar(Symbol), integer(OperationType),
      price, LotSize, StopLoss, TakeProfit, PAnsiChar(Comment), MagicNumber, OrderHandle)
  else
    begin
      OrderHandle := -1;
      result := false;
    end;
end;

{-----Close order with requested price---------------------------------------}
function  _CloseOrder(OrderHandle: integer; price: double): boolean;
begin
  if assigned(IntrfProcsRec._CloseOrder) then
    result := IntrfProcsRec._CloseOrder(OrderHandle, price)
  else
    result := false;
end;

{-----Create object----------------------------------------------------------}
function  ObjectCreate(name: AnsiString; ObjType: TObjectType; window: integer;
  time1: TDateTime; price1: double; time2: TDateTime; price2: double;
  time3: TDateTime; price3: double): boolean;
begin
  if assigned(IntrfProcsRec.ObjectCreate) then
    result := IntrfProcsRec.ObjectCreate(PAnsiChar(name), integer(ObjType),
      window, time1, price1, time2, price2, time3, price3)
  else
    result := false;
end;

{-----Delete object by name--------------------------------------------------}
procedure ObjectDelete(name: AnsiString);
begin
  if assigned(IntrfProcsRec.ObjectDelete) then
    IntrfProcsRec.ObjectDelete(PAnsiChar(name));
end;

{-----Check if object already exists-----------------------------------------}
function  ObjectExists(name: AnsiString): boolean;
begin
  if assigned(IntrfProcsRec.ObjectExists) then
    result := IntrfProcsRec.ObjectExists(PAnsiChar(name))
  else
    result := false;
end;

{-----Get object type--------------------------------------------------------}
function  ObjectType(name: AnsiString): TObjectType;
begin
  if assigned(IntrfProcsRec.ObjectType) then
    result := TObjectType(IntrfProcsRec.ObjectType(PAnsiChar(name)))
  else
    result := obj_Text;
end;

{-----Set object property----------------------------------------------------}
function  ObjectSet(name: AnsiString; index: integer; value: double): boolean;
begin
  if assigned(IntrfProcsRec.ObjectSet) then
    result := IntrfProcsRec.ObjectSet(PAnsiChar(name), index, value)
  else
    result := false;
end;

{-----Get object property----------------------------------------------------}
function  ObjectGet(name: AnsiString; index: integer): double;
begin
  if assigned(IntrfProcsRec.ObjectGet) then
    result := IntrfProcsRec.ObjectGet(PAnsiChar(name), index)
  else
    result := 0;
end;

{-----Delete all objects-----------------------------------------------------}
procedure ObjectsDeleteAll(window: integer = 0; ObjType: TObjectType = obj_AnyObject);
begin
  if assigned(IntrfProcsRec.ObjectsDeleteAll) then
    IntrfProcsRec.ObjectsDeleteAll(window, integer(ObjType));
end;

{-----Get interface version--------------------------------------------------}
procedure GetInterfaceVersion(var MajorValue, MinorValue: integer);
begin
  if assigned(IntrfProcsRec.GetInterfaceVersion) then
    IntrfProcsRec.GetInterfaceVersion(MajorValue, MinorValue)
  else
    begin
      MajorValue := 1;
      MinorValue := 6;
    end;
end;

{-----Set text---------------------------------------------------------------}
function  ObjectSetText(name, text: AnsiString; FontSize: integer = 12;
    FontName: AnsiString = 'Arial'; Color: TColor = clRed): boolean;
begin
  if assigned(IntrfProcsRec.ObjectSetText) then
    result := IntrfProcsRec.ObjectSetText(PAnsiChar(name), PAnsiChar(text), FontSize,
      PAnsiChar(FontName), color)
  else
    result := false;
end;

{-----Get text---------------------------------------------------------------}
function  ObjectGetText(name: AnsiString): AnsiString;
begin
  if assigned(IntrfProcsRec.ObjectGetText) then
    result := AnsiString(IntrfProcsRec.ObjectGetText(PChar(name)))
  else
    result := '';
end;

{-----Get current server time------------------------------------------------}
function  TimeCurrent: TDateTime;
begin
  if assigned(IntrfProcsRec.TimeCurrent) then
    result := IntrfProcsRec.TimeCurrent
  else
    result := iTime(Symbol, 1, 0);
end;

{-----Set indicator's buffer style-------------------------------------------}
procedure SetIndicatorBuffStyle(IndicatorHandle, BuffIndex: integer; _style: TPenStyle;
  width: integer; color: TColor);
begin
  if assigned(IntrfProcsRec.SetIndicatorBuffStyle) then
    IntrfProcsRec.SetIndicatorBuffStyle(IndicatorHandle, BuffIndex, integer(_style),
      width, integer(color));
end;

{-----Get bar shift by its time----------------------------------------------}
function  iBarShift(Symbol: AnsiString; TimeFrame: integer; time: TDateTime; Exact: boolean): integer;
begin
  if assigned(IntrfProcsRec.iBarShift) then
    result := IntrfProcsRec.iBarShift(PAnsiChar(Symbol), TimeFrame, time, Exact)
  else
    result := -1;
end;

{-----Get highest value in array---------------------------------------------}
function  iHighest(Symbol: AnsiString; TimeFrame: integer; _type, count, index: integer): integer;
begin
  if assigned(IntrfProcsRec.iHighest) then
    result := IntrfProcsRec.iHighest(PAnsiChar(Symbol), TimeFrame, _type, count, index)
  else
    result := -1;
end;

{-----Get lowest value in array----------------------------------------------}
function  iLowest(Symbol: AnsiString; TimeFrame: integer; _type, count, index: integer): integer;
begin
  if assigned(IntrfProcsRec.iLowest) then
    result := IntrfProcsRec.iLowest(PAnsiChar(Symbol), TimeFrame, _type, count, index)
  else
    result := -1;
end;

{-----Close part of position-------------------------------------------------}
function CloseOrderPartial(OrderHandle: integer; LotSize: double): boolean;
begin
  if assigned(IntrfProcsRec.CloseOrderPartial) then
    result := IntrfProcsRec.CloseOrderPartial(OrderHandle, LotSize)
  else
    result := false;
end;


exports

IntrfProcsRec, ReplaceStr;


initialization

fillchar(IntrfProcsRec, sizeof(IntrfProcsRec), 0);
IntrfProcsRec.dwSize := sizeof(IntrfProcsRec);

end.
