//---------------------------------------------------------------------------
// Support library, additional useful functions
//
// Ver 1.0
//---------------------------------------------------------------------------
unit TechnicalFunctions;

interface

uses
  StrategyInterfaceUnit;

type
  TPriceType = (pt_Close, pt_Open, pt_High, pt_Low, pt_HL2, pt_HLC3, pt_HLCC4);
  TMAType = (ma_SMA, ma_EMA, ma_WMA, ma_SSMA);


function  GetPrice(index: integer; PriceType: TPriceType): double;
procedure LRCChannelParams(Offset, period: integer; PriceType: TPriceType;
            var StartValue, EndValue, Height, Top, Bottom: double);

// close all opened positions (except pending orders)
procedure CloseAllOpenPos;

// delete all pending orders
procedure DeleteAllPendingOrders;

// close all open positions and delete all pending orders
procedure CloseAndDeleteAll;

// Get number of open positions
function  GetNumberOfOpenPositions: integer;

// Get number of pending orders
function  GetNumberOfPendingOrders: integer;

// Get profit for open positions
function  GetOpenPosProfit: double;

// Convert price type to string
function  StrPriceType(ptype: TPriceType): AnsiString;

// Convert moving average type to string
function  StrMAType(matype: TMAType): AnsiString;

implementation

{-----Get price--------------------------------------------------------------}
function GetPrice(index: integer; PriceType: TPriceType): double;
begin
  case PriceType of
    pt_Close: result := Close(index);
    pt_Open:  result := Open(index);
    pt_High:  result := High(index);
    pt_Low:   result := Low(index);
    pt_HL2:   result := (High(index) + Low(index))/2;
    pt_HLC3:  result := (High(index) + Low(index) + Close(index))/3;
    pt_HLCC4: result := (High(index) + Low(index) + Close(index)*2)/4;
    else      result := 0;
  end;
end;

{-----Get channel params-----------------------------------------------------}
procedure LRCChannelParams(Offset, period: integer; PriceType: TPriceType;
  var StartValue, EndValue, Height, Top, Bottom: double);
var
  i, x: integer;
  a, b, y, z, sum_x, sum_y, max, sum_xy, sum_x2: double;
begin
  // Variable initialization
  sum_x := 0;
  sum_y := 0;
  sum_xy := 0;
  sum_x2 := 0;

  // Calculating sums for regression line
  i := Offset;
  for x:=0 to Period - 1 do
    begin
      y := GetPrice(i, PriceType);
      sum_x := sum_x + x;
      sum_y := sum_y + y;
      sum_xy := sum_xy + x*y;
      sum_x2 := sum_x2 + x*x;
      inc(i);
    end;

  // Calculating regression line
  b := (Period*sum_xy - sum_x*sum_y)/(Period*sum_x2 - sum_x*sum_x);
  a := (sum_y - b*sum_x)/Period;

  // Calculating channel height
  i := Offset;
  max := 0;
  for x:=0 to Period-1 do
    begin
      y := a + b*x;
      z := abs(GetPrice(i, PriceType) - y);
      if (z > max) then max := z;
      inc(i);
    end;

  // Returning channel values
  StartValue := a + b*Period;
  EndValue := a;
  Height := max;
  Top := a + max;
  Bottom := a - max;
end;

{-----Close all open positions-----------------------------------------------}
procedure CloseAllOpenPos;
var
  i: integer;
begin
  for i:=OrdersTotal - 1 downto 0 do
    if OrderSelect(i, SELECT_BY_POS, MODE_TRADES) then
      if OrderType in [tp_Sell, tp_Buy] then
        CloseOrder(OrderTicket);
end;

{-----Delete all pending orders----------------------------------------------}
procedure DeleteAllPendingOrders;
var
  i: integer;
begin
  for i:=OrdersTotal - 1 downto 0 do
    if OrderSelect(i, SELECT_BY_POS, MODE_TRADES) then
      if OrderType in [tp_SellLimit, tp_SellStop, tp_BuyLimit, tp_BuyStop] then
        DeleteOrder(OrderTicket);
end;

{-----Close all open positions and delete all orders-------------------------}
procedure CloseAndDeleteAll;
var
  i: integer;
begin
  for i:=OrdersTotal - 1 downto 0 do
    if OrderSelect(i, SELECT_BY_POS, MODE_TRADES) then
      if OrderType in [tp_Sell, tp_Buy] then
        CloseOrder(OrderTicket)
      else
        DeleteOrder(OrderTicket);
end;

{-----Get number of open positions-------------------------------------------}
function  GetNumberOfOpenPositions: integer;
var
  i: integer;
begin
  result := 0;
  for i:=OrdersTotal - 1 downto 0 do
    if OrderSelect(i, SELECT_BY_POS, MODE_TRADES) then
      if OrderType in [tp_Sell, tp_Buy] then
        inc(result);
end;

{-----Get number of pending orders-------------------------------------------}
function  GetNumberOfPendingOrders: integer;
var
  i: integer;
begin
  result := 0;
  for i:=OrdersTotal - 1 downto 0 do
    if OrderSelect(i, SELECT_BY_POS, MODE_TRADES) then
      if not(OrderType in [tp_Sell, tp_Buy]) then
        inc(result);
end;

{-----Get profit for open positions------------------------------------------}
function  GetOpenPosProfit: double;
begin
  result := AccountEquity - AccountBalance;
end;

{-----Convert price type to string-------------------------------------------}
function  StrPriceType(ptype: TPriceType): AnsiString;
begin
  case ptype of
    pt_Close: result := 'Close';
    pt_Open:  result := 'Open';
    pt_High:  result := 'High';
    pt_Low:   result := 'Low';
    pt_HL2:   result := '(High + Low)/2';
    pt_HLC3:  result := '(High + Low + Close)/3';
    pt_HLCC4: result := '(High + Low + Close + Close)/4';
    else      result := '';
  end;
end;

{-----Convert moving average type to string----------------------------------}
function  StrMAType(matype: TMAType): AnsiString;
begin
  case matype of
    ma_SMA:  result := 'Simple (SMA)';
    ma_EMA:  result := 'Exponential (EMA)';
    ma_WMA:  result := 'Weighted (WMA)';
    ma_SSMA: result := 'Smoothed (SSMA)';
    else     result := '';
  end;
end;

end.
