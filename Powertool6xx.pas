library Powertool6XX;

{
  TITLE           : Powertool6 Project
  PURPOSE         : Implementation full logic for Powertool6
  AUTHOR          : Hendy Sutarto
  DATE            : 25 Dec 2017
  PRE-REQUISITE   : Simple implementation to start, then elaborate the flow with well articulation.
  NOTES           : -


  ABSTRACTS
  --------------------------------------------------

  This code is to implement full logic of Powertool6. Coding approach is to write flowing flows that
  articulate the story of the logic, with elements are self-explanatory, well-articulated writing,
  so that, translating the .PAS code into .MQ4 is easy to do. The system written in .PAS is to
  demonstrate the logic on Forex Tester, so that I can see the flow and dynamics of the rule, while
  also to provide translatable code to .MQ4 for implementation on production platform (a VPS with
  Metatrader 4 Terminal).

}


{   James Dyson:

    I made 5,127 prototypes of my vaccum before I got it right.
    There were 5,126 failures. But I learned from each one.
    That’s how I came up with a solution. So I don’t mind failure.

    It is said that to be an overnight success takes years of effort.
    So it has proved with me.
}



{

    VERSIONING NAMING
    
    Powertool601.dll
    
    The library version is named Powertool601 ; 6 is the version, the 01 is the build.
    
    Last two digit can continue 01, 02, 03, to 99.
    
    
    

    Ver_5_20180311
    --------------

    Separation logic for Rally, Jaggy, FlipFlop, and CANTTELL_RALLYORJAGGYORFLIPFLOP

    Adding self-explanatory variables


    Ver_4_20180204
    --------------

    Adding mode:

    - Rally
    - Jaggy
    - CANTTELL_RALLYORJAGGYORFLIPFLOP

    Including block separation for Rally, Jaggy, and CANTTELL_RALLYORJAGGYORFLIPFLOP.

    The code reuses the core from Ver_3_20180126, only get restructured better.



    Ver 3_20180126
    --------------

    Changes for entry criteria to meet up:

    See reference: search on OneNote "D1 Tips as oversold tool overbought tool" for complete description

    Goal:

    - To find:

        - Near-bottom for buying or
        - Near-top for selling

      by finding bottom tips of the daily chart

    - To produce "nicer" visual entry signals that shows itself at the bottom tips when buying (likewise at
      top-tips when selling), AND not to missed out each daily tip during run up.




    Ver 2_20180114
    --------------

    Addition:

    Changes for entry criteria:

    From:

        - DriftLine H1 falls back into direction of DriftLine D1
        - M5 Cycle back to main D1 trend via RSI3_M5
    To:
        - Overbought / oversold H1 via RSI7_H1 against the D1 main trend = "Cocked_Direction"
        - M5 Momentun back into the D1 main trend after temporary overbought H1 / oversold H1

    Goal:

        - To reduce unwanted trade "near tip - peak" for bullish / or "near tip - bottom" for bearish
          Refer: Onenote search title "To be continued Powertool 6" for picture of unwanted trade

        - To produce "nicer" visual entry signals than on the "To be continued Powertool 6", where
          signals is at near tip - bottom for buying & near tip - top for selling.


    - gRSI3_H1_CockingDirection
    - gRSI3_M5_MomentumEvent


}


uses
      interfaces,
      Windows,
      SysUtils,
      DateUtils,        // For WeekOfTheYear
      Graphics,         // For TPenStyle
      Classes,
      Math,
      StrategyInterfaceUnit,
      TechnicalFunctions

      // Reporting_PLR,
      // Reporting_EQD,
      // Reporting_OnScreen
      // Reporting_TechnicalValues
  ;



{///////////////////////////////////////////////////////////////////////////////////////////////////////}
{*******************************************************************************************************}
{**                              ENUMERATION and GLOBAL VARIABLE DECLARATION                          **}
{*******************************************************************************************************}
{///////////////////////////////////////////////////////////////////////////////////////////////////////}



{** Enumeration Global Variable
--------------------------------------------------------------------------------------------------------}

type
    TActivateSystem     = (YES , NO);
    TTradeDirection     = (BUY, SELL , BUY_SELL);
    TTrendDirection     = (UP, DOWN, SIDEWAY);

    //** Ver 2_20180114  **
    TCockingDirection   = (COCK_UP, COCK_NEUTRAL , COCK_DOWN);
    TMomentumDirection  = (MOMEN_UP, MOMEN_NEUTRAL , MOMEN_DOWN);

    //** Ver_4_20180204 **
    TMarketMode         = (RALLY , JAGGY , FLIPFLOP, CANTTELL_RALLYORJAGGYORFLIPFLOP );
    


{///////////////////////////////////////////////////////////////////////////////////////////////////////}
{/////////////////////////////////////////     GLOBAL VARIABLES    /////////////////////////////////////}
{///////////////////////////////////////////////////////////////////////////////////////////////////////}

var

    {++ 	GENERAL     ++}
    {-----------------------------------------------------------------------------------}

    gActivateSystem         :   TActivateSystem         ;
    gCurrency               :   pchar = nil             ;
    gTimeFrame              :   integer                 ;
    gRiskSize               :   double                  ;
    gRiskSizePercent        :   double                  ;
    gPointToPrice           :   double                  ;

    gTradeDirection         :   TTradeDirection         ;       // 0 -> BUY | 1 -> SELL | 2 -> BUY_SELL
    gTrendDirection_D1      :   TTrendDirection         ;

    gMarketMode             :   TMarketMode             ;


    {++ BAR NAME ++}
    {-----------------------------------------------------------------------------------}


    {** D1 **}
    gBarName_D1_Curr        : string                    ;
    gBarName_D1_Prev        : string                    ;
    gBarName_D1_FirstTick   : boolean                   ;

    // Ver_3_20180126
    gD1_DayName_Curr        : string                    ;


    {** H1 **}
    gBarName_H1_Curr        : string                    ;
    gBarName_H1_Prev        : string                    ;
    gBarName_H1_FirstTick   : boolean                   ;


    {** M5 **}
    gBarName_M5_Curr        : string                    ;
    gBarName_M5_Prev        : string                    ;
    gBarName_M5_FirstTick   : boolean                   ;



    {++ INDICATOR ++}
    {-----------------------------------------------------------------------------------}


    // D1 - Indicators
    // ---------------------------------------------------------------------------------

    {** Driftline_D1 **}
    gDriftline_D1_Handle        : integer               ;
    gDriftline_D1_val_1         : double                ;
    gDriftline_D1_val_2         : double                ;
    gDriftline_D1_val_3         : double                ;


    {** BarWave_D1 **}
    gBarWave_D1_Handle          : integer               ;
    gBarWave_D1_val_1           : double                ;
    gBarWave_D1_val_2           : double                ;


    // D1 - Setups
    // -------------------------------------------

    {** Setup Rule D1 **}
    gSetup_D1_StayAway          : boolean               ;


    { Ver_5_20180311 }
    gSetup_D1_Rally_Buy         : boolean               ;
    gSetup_D1_Rally_Sell        : boolean               ;

    gSetup_D1_Jaggy_Buy         : boolean               ;
    gSetup_D1_Jaggy_Sell        : boolean               ;

    gSetup_D1_CantTellRorJ_Buy  : boolean               ;
    gSetup_D1_CantTellRorJ_Sell : boolean               ;


    { Added in Ver_3_20180126 }
    { Ver_5_20180311 ** This may be redundant ** }    
    gSetup_D1_FlipFlop_Buy      : boolean               ;
    gSetup_D1_FlipFlop_Sell     : boolean               ;
    

    {** Setup Rule Daily Token **}
    // Added in Ver_3_20180126
    
    { Rule 1 = Rally }
    { Rule 2 = Jaggy }
    { Rule 3 = Flip Flop }
    { Rule 4 = All 3 above }
    
    gDailyToken_Seq_1_rule_1    : boolean               ;
    gDailyToken_Seq_2_rule_1    : boolean               ;
    gD1_RecentClose             : double                ;

    // Ver_3_20180126
    // For D1 red bars in uptrend and D1 blue bars in downtrend
    gDailyToken_Seq_1_rule_2    : boolean               ;
    gDailyToken_Seq_2_rule_2    : boolean               ;

    gDailyToken_Seq_1_rule_3    : boolean               ;
    gDailyToken_Seq_2_rule_3    : boolean               ;
    
    { Up to 6 token for all }
    gDailyToken_Seq_1_rule_4    : boolean               ;
    gDailyToken_Seq_2_rule_4    : boolean               ;
    gDailyToken_Seq_3_rule_4    : boolean               ;
    gDailyToken_Seq_4_rule_4    : boolean               ;
    gDailyToken_Seq_5_rule_4    : boolean               ;
    gDailyToken_Seq_6_rule_4    : boolean               ;

    
    // H1 - Indicators
    // ---------------------------------------------------------------------------------

    {** Driftline_H1 **}
    gDriftline_H1_Handle        : integer               ;
    gDriftline_H1_val_1         : double                ;
    gDriftline_H1_val_2         : double                ;


    {** Setup Rule H1 **}
    {** Ver_5_20180311 **}
    gSetup_H1_Rally_Buy         : boolean               ;
    gSetup_H1_Rally_Sell        : boolean               ;
    
    gSetup_H1_Jaggy_Buy         : boolean               ;
    gSetup_H1_Jaggy_Sell        : boolean               ;

    gSetup_H1_FlipFlop_Buy      : boolean               ;
    gSetup_H1_FlipFlop_Sell     : boolean               ;    
    

    {** Trigger one entry per hour **}
    gH1_Token_Trigger           : boolean               ;



    {** Setup Rule in Bar Number **}
    // gSetup_H1_Buy_Curr          : boolean            ;
    // gSetup_H1_Sell_Curr         : boolean            ;

    gSetup_H1_Buy_BarNum_In     : integer               ;
    gSetup_H1_Sell_BarNum_In    : integer               ;

    {** BarWave_H1 **}
    gBarWave_H1_Handle          : integer               ;
    
    gBarWave_H1_val_1,
    gBarWave_H1_val_2,
    gBarWave_H1_val_3,
    gBarWave_H1_val_4           : double                ;


    {** BarWave_H1_EXIT **}
    gBarWave_H1_Exit_Handle     : integer               ;
    gBarWave_H1_Exit_val_1      : double                ;
    gBarWave_H1_Exit_val_2      : double                ;
    



    //** Ver 2_20180114  **
    //----------------------------------------------------------------

    {** RSI_7_H1 **}

    gRSI7_H1_Handle             : integer               ;
    gRSI7_H1_val_1              : double                ;
    gRSI7_H1_val_2              : double                ;

    {** Cocking direction **}
    gRSI7_H1_CockingDirection   : TCockingDirection     ;


    // M5 - Indicators
    // ---------------------------------------------------------------------------------

    {** RSI3 M5 **}
    gRSI3_M5_Handle             : integer               ;
    gRSI3_M5_val_1              : double                ;
    gRSI3_M5_val_2              : double                ;

    {** MACDH M5 **}
    gMACDH_M5_Handle            : integer               ;
    gMACDH_M5_val_1             : double                ;
    gMACDH_M5_val_2             : double                ;
    gMACDH_M5_val_3             : double                ;


    gBollingerM5_Handle         : integer               ;
    
    gBollingerM5_val_1_TopBand  : double                ;
    gBollingerM5_val_1_MidBand  : double                ;
    gBollingerM5_val_1_BotBand  : double                ;
    
    gBollingerM5_val_2_TopBand  : double                ;
    gBollingerM5_val_2_MidBand  : double                ;
    gBollingerM5_val_2_BotBand  : double                ;

    gBollingerM5_val_3_TopBand  : double                ;
    gBollingerM5_val_3_MidBand  : double                ;
    gBollingerM5_val_3_BotBand  : double                ;
    
    // M5 - Setup on Ver_3_20180126
    // -------------------------------------------

    gOversold_M5                : boolean               ;
    gOverbought_M5              : boolean               ;


    // M5 - Triggers
    // -------------------------------------------

    {** Trigger M5 **}
    //** Ver_2_20180114  **
    gTrigger_M5_Sell            : boolean               ;
    gTrigger_M5_Buy             : boolean               ;

    // Ver_3_20180126
    gTrigger_M5_Buy_Market_Rally    : boolean           ;
    gTrigger_M5_Sell_Market_Rally   : boolean           ;
    
    gTrigger_M5_Buy_Market_Jaggy    : boolean           ;
    gTrigger_M5_Sell_Market_Jaggy   : boolean           ;

    gTrigger_M5_Buy_Market_FlipFlop : boolean           ;
    gTrigger_M5_Sell_Market_FlipFlop: boolean           ;


    //** Previous version's does not fit and we need code simplicity

    //** Ver 2_20180114  **
    //----------------------------------------------------------------

    gRSI3_M5_MomentumEvent      : TMomentumDirection    ;



    // M5 - Volatility
    // ---------------------------------------------------------------------------------

    {** ATR M5 **}
    gATR_M5_Handle              : integer               ;
    gATR_M5_val_1               : double                ;


    {** Stop Loss M5 **}
    gStopLoss_Dist_val          : double                ;
    gStopLoss_Dist_pips         : double                ;


    {** Position Sizing **}

    // P1
    gP1_LotSize                 :   double              ;
    gP1_OrderHandle             :   integer             ;
    gP1_OrderStyle              :   TTradePositionType  ;
    gP1_OpenTime                :   TDateTime           ;

    // P2
    gP2_LotSize                 :   double              ;
    gP2_OrderHandle             :   integer             ;
    gP2_OrderStyle              :   TTradePositionType  ;
    gP2_OpenTime                :   TDateTime           ;

    // P3
    gP3_LotSize                 :   double              ;
    gP3_OrderHandle             :   integer             ;
    gP3_OrderStyle              :   TTradePositionType  ;
    gP3_OpenTime                :   TDateTime           ;

    // P4
    gP4_LotSize                 :   double              ;
    gP4_OrderHandle             :   integer             ;
    gP4_OrderStyle              :   TTradePositionType  ;
    gP4_OpenTime                :   TDateTime           ;

    // P5
    gP5_LotSize                 :   double              ;
    gP5_OrderHandle             :   integer             ;
    gP5_OrderStyle              :   TTradePositionType  ;
    gP5_OpenTime                :   TDateTime           ;

    // P6
    gP6_LotSize                 :   double              ;
    gP6_OrderHandle             :   integer             ;
    gP6_OrderStyle              :   TTradePositionType  ;
    gP6_OpenTime                :   TDateTime           ;

    // P7
    gP7_LotSize                 :   double              ;
    gP7_OrderHandle             :   integer             ;
    gP7_OrderStyle              :   TTradePositionType  ;
    gP7_OpenTime                :   TDateTime           ;

    // P8
    gP8_LotSize                 :   double              ;
    gP8_OrderHandle             :   integer             ;
    gP8_OrderStyle              :   TTradePositionType  ;
    gP8_OpenTime                :   TDateTime           ;



    {++ LOGIC SUPPORT ++}
    {-----------------------------------------------------------------------------------}

    iOrder                      :   integer             ;


    {++ OPEN POSITION TRACKER ++}
    {-----------------------------------------------------------------------------------}

    gP1_Profit_Pips             :   double              ;
    gP1_Profit_Price            :   double              ;
    gP1_LargeProfitExit_Bool    :   boolean             ;
    gOpenPositionsNumber        :   integer             ;   // also OrderTotals()


    {++ OBJECT ON CHART ++}
    {-----------------------------------------------------------------------------------}

    gTextName                   :   string              ;



{///////////////////////////////////////////////////////////////////////////////////////////////////////}
{*******************************************************************************************************}
{**                                  SUPPORT FUNCTIONS & PROCEDURES                                   **}
{*******************************************************************************************************}
{///////////////////////////////////////////////////////////////////////////////////////////////////////}




{-------------------------------------------------------------------------------------------------------}
{***** ENTRY MANAGEMENT *****}
{-------------------------------------------------------------------------------------------------------}

procedure ENTRY_MANAGEMENT_RALLY_STANDARD ; stdcall ;
var
        _text       :   string      ;
begin

    if (gMarketMode <> RALLY) and (gMarketMode <> CANTTELL_RALLYORJAGGYORFLIPFLOP) then exit ; 
    
    {===================================================================================================}
    {  INDICATOR VALUE RETRIEVAL  }
    {===================================================================================================}
    { This procedure operates on the first tick of M5 }

    gATR_M5_val_1 := GetIndicatorValue( gATR_M5_Handle , 1, 0  );


    {===================================================================================================}
    {  SIGNAL GENERATION: Consider all setups, then trigger  }
    {===================================================================================================}



    // SETUP D1 - RALLY
    // -------------------------------------------

    if gBarName_D1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1

        // Set setup FALSE daily until retracement below recent close
        gOversold_M5    := false;
        gOverbought_M5  := false ;
        


        // Set daily tokens true at opening bar
        gDailyToken_Seq_1_rule_1   := true ;
        gDailyToken_Seq_2_rule_1   := true ;


        // Recent closing price
        gD1_RecentClose     := Close(1);


        gDriftline_D1_val_1 := GetIndicatorValue( gDriftline_D1_Handle , 3, 0 );
        { The index for driftline value 1 recent bar has to be 3, not 1 ! }

        gDriftline_D1_val_2 := GetIndicatorValue( gDriftline_D1_Handle , 4 , 0 );
        { The index for driftline value 2 recent bar has to be 4, not 1 !
          Ver_3_20180126 }
        gDriftline_D1_val_3 := GetIndicatorValue( gDriftline_D1_Handle , 5 , 0 );


        gBarWave_D1_val_1   := GetIndicatorValue( gBarWave_D1_Handle , 1, 4 );
        gBarWave_D1_val_2   := GetIndicatorValue( gBarWave_D1_Handle , 2, 4 );


        { Print(  '[ENTRY_MANAGEMENT]: RALLY MODE First Tick D1 ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' + }
                { 'Open(1)-D1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' + }
                { 'Close(1)-D1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' + }
                { 'Driftline_D1: '+ FloatToStrF( gDriftline_D1_val_1 , ffFixed , 6, 4 )   + ' / ' + }
                { 'BarWave_D1: '  + FloatToStrF( gBarWave_D1_val_1, ffNumber , 15 , 4 ) }
                { ); }


        // Setup D1 Buy - RALLY
        // -------------------------------------------

        gSetup_D1_Rally_Buy   :=  (   // Recent bar body is above driftline of D1
                                    (Open(1)    > gDriftline_D1_val_1)
                                and (Close(1)   > gDriftline_D1_val_1)
                                and (Open(1) <= Close(1) )
                                and (gD1_DayName_Curr <> 'Sun')
                                    // Recent bar is BLUE in Ver_3_20180126
                                // and (gBarWave_D1_val_1 > gBarWave_D1_val_2)
                            )
                                // Monday Starting Trade ; Ver_3_20180126
                                or
                                (
                                        (Open(2)    > gDriftline_D1_val_2)
                                    and (Close(2)   > gDriftline_D1_val_2)
                                    and (Open(2) <= Close(2) )
                                    and (gD1_DayName_Curr = 'Mon')
                                        // Recent bar wave is rising
                                        // Friday bar is BLUE in Ver_3_20180126
                                );



        // Setup D1 Sell - RALLY
        // -------------------------------------------


        gSetup_D1_Rally_Sell  :=  (   // Recent bar body is below driftline of D1
                                    (Open(1)    < gDriftline_D1_val_1)
                                and (Close(1)   < gDriftline_D1_val_1)
                                and (Open(1) >= Close(1) )
                                and (gD1_DayName_Curr <> 'Sun')                                
                                    // Recent bar is RED in Ver_3_20180126

                            )
                                // Monday Starting Trade ; Ver_3_20180126
                                or
                                (
                                        (Open(2)    < gDriftline_D1_val_2)
                                    and (Close(2)   < gDriftline_D1_val_2)
                                    and (Open(2) >= Close(2) )
                                    and (gD1_DayName_Curr = 'Mon')
                                        // Recent bar wave is descending
                                        // Recent bar is RED in Ver_3_20180126
                                );


        // Setup D1 Stay Away
        // -------------------------------------------

        gSetup_D1_StayAway := (
                                    (not gSetup_D1_Rally_Buy)
                                and (not gSetup_D1_Rally_Sell)
                            );


    end;


            // SETUP D1 RALLY MONITORING
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_D1_FirstTick then
            begin


                Str( gSetup_D1_Rally_Buy , _text );
                Print( 'gSetup_D1_Rally_Buy: ' + _text );

                Str( gSetup_D1_Rally_Sell , _text );
                Print( 'gSetup_D1_Rally_Sell: ' + _text );

                Str( gSetup_D1_StayAway , _text );
                Print( 'gSetup_D1_StayAway: ' + _text );

            end;



    // SETUP H1 - RALLY
    // ---------------------------------------------------------------------------------
    // *** IMPORTANT: Ver_3_20180126 does not use H1 !!!

    if gBarName_H1_FirstTick then
    begin

        { Left as placeholder }

        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );
        
        gH1_Token_Trigger   := false ;
        { one hour only one entry }
        

        { gDriftline_H1_val_1 := GetIndicatorValue( gDriftline_H1_Handle, 3 , 0 ); }
        { gDriftline_H1_val_2 := GetIndicatorValue( gDriftline_H1_Handle, 4 , 0 ); }
        { The index for driftline has to be 3, not 1 ! }

        gBarWave_H1_val_1   := GetIndicatorValue( gBarWave_H1_Handle, 1 , 4 );
        gBarWave_H1_val_2   := GetIndicatorValue( gBarWave_H1_Handle, 2 , 4 );
        gBarWave_H1_val_3   := GetIndicatorValue( gBarWave_H1_Handle, 3 , 4 );
        gBarWave_H1_val_4   := GetIndicatorValue( gBarWave_H1_Handle, 4 , 4 );


        //** Ver_3_20180126 **


        { OLDER LOGIC IS DELETED }
        {
        Need older logic: refer to
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - MultiForexScale\PowerTool 6\PT6_FT3_v2_20180114\
            Powertool6_v2_20180114.pas
        }



        { Print(  '[ENTRY_MANAGEMENT_RALLY]: 1st Tick H1 ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )           + ' / ' + }
                { 'Open(1)-H1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )                   + ' / ' + }
                { 'Close(1)-H1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )                  + ' / ' + }
                { 'BarWave-H1(1): '  + FloatToStrF( gBarWave_H1_val_1, ffNumber , 15 , 4 )    + ' / ' + }
                { 'BarWave-H1(2): '  + FloatToStrF( gBarWave_H1_val_2, ffNumber , 15 , 4 )    + ' / ' + }
                { 'BarWave-H1(3): '  + FloatToStrF( gBarWave_H1_val_3, ffNumber , 15 , 4 ) }
                { //'Driftline_H1: '+ FloatToStrF( gDriftline_H1_val_1 , ffFixed , 6, 4 ) }
                { ); }

                
                
                
        gSetup_H1_Rally_Buy :=  (   // First hour
                            (
                                    gSetup_D1_Rally_Buy
                                and ( gBarWave_H1_val_2 < 0.0 )
                                and ( gBarWave_H1_val_2 < gBarWave_H1_val_1 )
                                and ( gBarWave_H1_val_2 < gBarWave_H1_val_3 )
                            )
                            or
                            (       // Second hour
                                    gSetup_D1_Rally_Buy
                                and ( gBarWave_H1_val_3 < 0.0 )
                                and ( gBarWave_H1_val_2 < gBarWave_H1_val_1 )
                                and ( gBarWave_H1_val_3 < gBarWave_H1_val_2 )
                                and ( gBarWave_H1_val_3 < gBarWave_H1_val_4 )
                            )
            );
            
        gSetup_H1_Rally_Sell :=  (  
                            (       // First hour
                                    gSetup_D1_Rally_Sell
                                and ( gBarWave_H1_val_2 > 0.0 )
                                and ( gBarWave_H1_val_2 > gBarWave_H1_val_1 )
                                and ( gBarWave_H1_val_2 > gBarWave_H1_val_3 )
                            )
                            or  
                            (       // Second hour
                                    gSetup_D1_Rally_Sell
                                and ( gBarWave_H1_val_3 > 0.0 )
                                and ( gBarWave_H1_val_2 > gBarWave_H1_val_1 )
                                and ( gBarWave_H1_val_3 > gBarWave_H1_val_2 )
                                and ( gBarWave_H1_val_3 > gBarWave_H1_val_4 )
                            )

            );            
        
        { gSetup_H1_Buy_Opt_1 := ( }
                                    { gSetup_D1_Buy_Bar_Red }
                                { and ( Close(1) > gDriftline_H1_val_1 ) }
                                { and ( Open(1)   > gDriftline_H1_val_1 ) }
                                { and ( gDriftline_H1_val_1 > gDriftline_H1_val_2 ) }
            { ); }
        { gSetup_H1_Buy_Opt_2 := ( }
                                    { gSetup_D1_Buy_Bar_Red }
                                { and ( Close(1)  > gDriftline_H1_val_1 ) }
                                { and ( Open(1)   > gDriftline_H1_val_1 ) }
            { ); }

        { gSetup_H1_Sell_Opt_1    := ( }
                                    { gSetup_D1_Jaggy_Sell }
                                { and ( Close(1)  < gDriftline_H1_val_1 ) }
                                { and ( Open(1)   < gDriftline_H1_val_1 ) }
                                { and ( gDriftline_H1_val_1 < gDriftline_H1_val_2 ) }
            
        { gSetup_H1_Sell_Opt_2    := ( }
                                    { gSetup_D1_Jaggy_Sell }
                                { and ( Close(1)  < gDriftline_H1_val_1 ) }
                                { and ( Open(1)   < gDriftline_H1_val_1 ) }
            { ); }

        {** Consolidate H1 Setup Rule options into one **}

        { gSetup_H1_Buy_Curr      := ( gSetup_H1_Buy_Opt_1 { or  gSetup_H1_Buy_Opt_2 ); }
        { gSetup_H1_Sell_Curr     := ( gSetup_H1_Sell_Opt_1 {or gSetup_H1_Sell_Opt_2 ); }



        {
        Every single hour, if the event is found oversold with D1 uptrend, this become buy setup.
        likewise, if found overbought with D1 downtrend, this become sell setup.
        BUT
        within the same hour, when M5 makes momentum back into main trend, the setup cancels itself
        for that hour, until the next hour, if H1 is in retracement zone again.
        This way, cancelling the setup, means one signal per hour per retracement hour.
        }

    end;


            // SETUP H1 MONITORING
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_H1_FirstTick then
            begin

                Print('*** gBarName_H1_FirstTick RALLY event found: ***');

                Str( gSetup_D1_Rally_Buy , _text );
                Print( 'gSetup_D1_Rally_Buy: ' + _text );
                Str( gSetup_D1_Rally_Sell , _text );
                Print( 'gSetup_D1_Rally_Sell: ' + _text );

                if gSetup_H1_Rally_Buy then
                begin
                    Str( gSetup_H1_Rally_Buy , _text );
                    Print('gSetup_H1_Rally_Buy: ' + _text );
                end;

                if gSetup_H1_Rally_Sell then
                begin
                    Str( gSetup_H1_Rally_Sell , _text );
                    Print('gSetup_H1_Rally_Sell: ' + _text );
                end;

            end;








    // Return the timeframe back to M5
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

    // TRIGGER M5 - RALLY
    // ---------------------------------------------------------------------------------
    // Ver_3_20180126
    // Trigger type 1 is when blue bar race in uptrend (likewise red bar race in downtrend)
    // Buying at the D1 tip of oversold or sell at D1 the tip of overbought

    if gBarName_M5_FirstTick then
    begin


        // Overbought and oversold rule
        // -------------------------------------------
        { Ver_3_20180126 }

        if (Close(1) < gD1_RecentClose) then
            gOversold_M5 := true;

        if (Close(1) > gD1_RecentClose) then
            gOverbought_M5 := true ;

        // The oversold and overbought stays true for the next M5 bars or until next day
        // Once trigger is in ; it is cancelled until another event of retracement


        // RSI3 MOMEN_UP / MOMEN_DOWN
        // -------------------------------------------

        { gRSI3_M5_val_1      := GetIndicatorValue( gRSI3_M5_Handle , 1 , 0 ); }
        { gRSI3_M5_val_2      := GetIndicatorValue( gRSI3_M5_Handle , 2 , 0 ); }


        { gRSI3_M5_MomentumEvent := MOMEN_NEUTRAL; }
        { if ( (gRSI3_M5_val_1 > 70.0) and (gRSI3_M5_val_2 <= 70.0) ) then }
            { gRSI3_M5_MomentumEvent := MOMEN_UP }
        { else if ( (gRSI3_M5_val_1 < 30.0) and (gRSI3_M5_val_2 >= 30.0) ) then }
            { gRSI3_M5_MomentumEvent := MOMEN_DOWN; }

            
        gMACDH_M5_val_1     := GetIndicatorValue( gMACDH_M5_Handle, 1 , 4 );
        gMACDH_M5_val_2     := GetIndicatorValue( gMACDH_M5_Handle, 2 , 4 );
        gMACDH_M5_val_3     := GetIndicatorValue( gMACDH_M5_Handle, 3 , 4 );


        
        gBollingerM5_val_1_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 0 );
        gBollingerM5_val_1_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 1 );
        gBollingerM5_val_1_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 2 );
        
        gBollingerM5_val_2_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 0 );
        gBollingerM5_val_2_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 1 );
        gBollingerM5_val_2_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 2 );
        
        gBollingerM5_val_3_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 0 );
        gBollingerM5_val_3_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 1 );
        gBollingerM5_val_3_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 2 );

        
        {
        The momentum event happens *ONLY* at first tick of M5 bar!
        }

        { gTrigger_M5_Buy_Market_Rally    := (   }
                                { gSetup_H1_Rally_Buy }
                            { and ( gMACDH_M5_val_2 < 0.0 ) }
                            { and ( gMACDH_M5_val_2 < gMACDH_M5_val_1 ) }
                            { and ( gMACDH_M5_val_2 < gMACDH_M5_val_3 ) }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }
        
        
        { gTrigger_M5_Sell_Market_Rally    := (   }
                                { gSetup_H1_Rally_Sell }
                            { and ( gMACDH_M5_val_2 > 0.0 ) }
                            { and ( gMACDH_M5_val_2 > gMACDH_M5_val_1 ) }
                            { and ( gMACDH_M5_val_2 > gMACDH_M5_val_3 )                             }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }
                
        gTrigger_M5_Buy_Market_Rally  := (
                                    gSetup_D1_Rally_Buy       // Ver_3_20180126 
                            and     gOversold_M5
                            and     ( Close(2) < gBollingerM5_val_2_BotBand )
                            and     ( Close(2) < gD1_RecentClose )      // Find the tips
                            and ( gMACDH_M5_val_2 < 0.0 )
                            and ( gMACDH_M5_val_2 < gMACDH_M5_val_1 )
                            and ( gMACDH_M5_val_2 < gMACDH_M5_val_3 )
                                and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two opportunities
                                and ( gH1_Token_Trigger = false )           // one signal per hour
                            );

        gTrigger_M5_Sell_Market_Rally :=  (
                                    gSetup_D1_Rally_Sell
                            and     gOverbought_M5
                            and     ( Close(2) > gBollingerM5_val_2_TopBand )
                            and     ( Close(2) > gD1_RecentClose )      // Find the antenna
                            and ( gMACDH_M5_val_2 > 0.0 )               
                            and ( gMACDH_M5_val_2 > gMACDH_M5_val_1 )
                            and ( gMACDH_M5_val_2 > gMACDH_M5_val_3 )                                                            
                                and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two opportunities
                                and ( gH1_Token_Trigger = false )               // one signal per hour
                            );                
                
                
        { gTrigger_M5_Buy_Market_Rally    := (   }
                                { gSetup_H1_Rally_Buy }
                            { and ( gRSI3_M5_val_1 > 50.0 ) }
                            { and ( gRSI3_M5_val_2 <= 50.0 )                             }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }
        
        
        { gTrigger_M5_Sell_Market_Rally    := (   }
                                { gSetup_H1_Rally_Sell                             }
                            { and ( gRSI3_M5_val_1 < 50.0 ) }
                            { and ( gRSI3_M5_val_2 >= 50.0 ) }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }
                
        { gTrigger_M5_Buy_Market_Rally  := ( }
                                    { gSetup_D1_Rally_Buy       // Ver_3_20180126  }
                                { and gOversold_M5 }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two opportunities }
                                { and (gRSI3_M5_MomentumEvent = MOMEN_UP) }
                            { ); }

        { gTrigger_M5_Sell_Market_Rally :=  ( }
                                    { gSetup_D1_Rally_Sell }
                                { and gOverbought_M5 }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two opportunities }
                                { and (gRSI3_M5_MomentumEvent = MOMEN_DOWN) }
                            { ); }



        // Cancel daily setups for this trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Market_Rally then
        begin

            // After one trigger, cancel hourly token
            gH1_Token_Trigger := true ;
            
            // After one trigger, cancel the gOversold_M5
            gOversold_M5    := false ;

            // Cancel sequentially, to allow two signals per day
            if gDailyToken_Seq_1_rule_1 then
                gDailyToken_Seq_1_rule_1 := false
            else if gDailyToken_Seq_2_rule_1 then
                gDailyToken_Seq_2_rule_1 := false ;

        end;

        if gTrigger_M5_Sell_Market_Rally then
        begin

            // After one trigger, cancel hourly token
            gH1_Token_Trigger := true ;

            // After one trigger, cancel gOverbought_M5
            gOverbought_M5 := false ;

            // Cancel sequentially, to allow two signals per day
            if gDailyToken_Seq_1_rule_1 then
                gDailyToken_Seq_1_rule_1 := false
            else if gDailyToken_Seq_2_rule_1 then
                gDailyToken_Seq_2_rule_1 := false ;

        end;



        {**********  ADD PRINTS FOR trigger settings ***********}

                if gTrigger_M5_Buy_Market_Rally then
                begin
                    Str( gTrigger_M5_Buy_Market_Rally , _text );
                    Print('gTrigger_M5_Buy_Market_Rally: ' + _text );
                end;

                if gTrigger_M5_Sell_Market_Rally then
                begin
                    Str( gTrigger_M5_Sell_Market_Rally , _text );
                    Print('gTrigger_M5_Sell_Market_Rally: ' + _text );
                end;        
        
    end;




    // MARKING THE CHART WITH TRIGGER M5 - RALLY
    // ---------------------------------------------------------------------------------

    if gTrigger_M5_Buy_Market_Rally then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        Print(  '[ENTRY_MANAGEMENT_RALLY]: 1st Tick M5 BUY Signal ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )
                //'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 )
                );

        gTextName := 'TGR_RALLY_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Market_Rally then
    begin

        Print(  '[ENTRY_MANAGEMENT_RALLY]: 1st Tick M5 SELL Signal ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )
                //'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 )
                );

        gTextName := 'TGR_RALLY_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;
    end;

    {===================================================================================================}
    {  COUNT EXISTING POSITION/S, ENTER INTO THE MARKET }
    {  Open new Position when there is none, and add more if previous one in profit  }
    {  Disable entry after large profit registers in the system  }
    {  Disable entry in the same day after NEntry attempts }
    {===================================================================================================}
    { for every requirement, there are two variables at minimum to support requirement }


end;


procedure ENTRY_MANAGEMENT_JAGGY ; stdcall ;
var
        _text       :   string      ;
begin

    if (gMarketMode <> JAGGY) and (gMarketMode <> CANTTELL_RALLYORJAGGYORFLIPFLOP) then exit ;

    {===================================================================================================}
    {  INDICATOR VALUE RETRIEVAL  }
    {===================================================================================================}
    { This procedure operates on the first tick of M5 }

    gATR_M5_val_1 := GetIndicatorValue( gATR_M5_Handle , 1, 0  );


    {===================================================================================================}
    {  SIGNAL GENERATION: Consider all setups, then trigger  }
    {===================================================================================================}



    // SETUP D1 - JAGGY
    // -------------------------------------------

    if gBarName_D1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1


        // Set daily tokens true at opening bar
        gDailyToken_Seq_1_rule_2 := true ;
        gDailyToken_Seq_2_rule_2 := true ;



        // Recent closing price
        gD1_RecentClose     := Close(1);


        gDriftline_D1_val_1 := GetIndicatorValue( gDriftline_D1_Handle , 3, 0 );
        { The index for driftline value 1 recent bar has to be 3, not 1 ! }

        gDriftline_D1_val_2 := GetIndicatorValue( gDriftline_D1_Handle , 4 , 0 );
        { The index for driftline value 2 recent bar has to be 4, not 1 !
          Ver_3_20180126 }
        gDriftline_D1_val_3 := GetIndicatorValue( gDriftline_D1_Handle , 5 , 0 );


        gBarWave_D1_val_1   := GetIndicatorValue( gBarWave_D1_Handle , 1, 4 );
        gBarWave_D1_val_2   := GetIndicatorValue( gBarWave_D1_Handle , 2, 4 );


        Print(  '[ENTRY_MANAGEMENT]: JAGGY MODE First Tick D1 ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-D1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-D1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'Driftline_D1: '+ FloatToStrF( gDriftline_D1_val_1 , ffFixed , 6, 4 )   + ' / ' +
                'BarWave_D1: '  + FloatToStrF( gBarWave_D1_val_1, ffNumber , 15 , 4 )
                );


        // Setup D1 Buy - JAGGY
        // -------------------------------------------

        gSetup_D1_Jaggy_Buy := (   // Recent bar body is above driftline of D1
                                    (Open(1)    > gDriftline_D1_val_1)
                                and (Close(1)   > gDriftline_D1_val_1)
                                and (Open(1) >= Close(1) )
                                    // Recent bar wave is rising
                                    // Recent bar is RED in Ver_3_20180126
                                    // Needs pairing with Hourly H1 bounce up
                            );


        // Setup D1 Sell - JAGGY
        // -------------------------------------------

        gSetup_D1_Jaggy_Sell := (   // Recent bar body is below driftline of D1
                                    (Open(1)    < gDriftline_D1_val_1)
                                and (Close(1)   < gDriftline_D1_val_1)
                                and (Open(1) <= Close(1) )
                                    // Recent bar wave is descending
                                    // Recent bar is RED in Ver_3_20180126
                                    // Needs pairing with Hourly H1 bounce down
                            );



        // Setup D1 Stay Away
        // -------------------------------------------

        gSetup_D1_StayAway := (
                                    (not gSetup_D1_Jaggy_Buy)
                                and (not gSetup_D1_Jaggy_Sell)
                            );


    end;


            // SETUP D1 JAGGY MONITORING
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_D1_FirstTick then
            begin


                Str( gSetup_D1_Jaggy_Buy , _text );
                Print( 'gSetup_D1_Jaggy_Buy - JAGGY: ' + _text );

                Str( gSetup_D1_Jaggy_Sell , _text );
                Print( 'gSetup_D1_Jaggy_Sell - JAGGY: ' + _text );

                Str( gSetup_D1_StayAway , _text );
                Print( 'gSetup_D1_StayAway - JAGGY: ' + _text );

            end;



    // SETUP H1 - JAGGY
    // ---------------------------------------------------------------------------------
    // *** IMPORTANT: Ver_3_20180126 does not use H1 !!!

    if gBarName_H1_FirstTick then
    begin


        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );

        gDriftline_H1_val_1 := GetIndicatorValue( gDriftline_H1_Handle, 3 , 0 );
        gDriftline_H1_val_2 := GetIndicatorValue( gDriftline_H1_Handle, 4 , 0 );
        { The index for driftline has to be 3, not 1 ! }

        { gBarWave_H1_val_1   := GetIndicatorValue( gBarWave_H1_Handle, 1 , 4 ); }
        { gBarWave_H1_val_2   := GetIndicatorValue( gBarWave_H1_Handle, 2 , 4 ); }


        //** Ver_3_20180126 **


        { OLDER LOGIC IS DELETED }
        {
        Need older logic: refer to
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - MultiForexScale\PowerTool 6\PT6_FT3_v2_20180114\
            Powertool6_v2_20180114.pas
        }


        Print(  '[ENTRY_MANAGEMENT]: First Tick H1 SETUP JAGGY' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-H1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-H1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'Driftline_H1: '+ FloatToStrF( gDriftline_H1_val_1 , ffFixed , 6, 4 )
                );

        gSetup_H1_Jaggy_Buy  := (
                                    gSetup_D1_Jaggy_Buy
                                and ( Close(1) > gDriftline_H1_val_1 )
                                and ( Open(1)   > gDriftline_H1_val_1 )
                                // and ( gDriftline_H1_val_1 > gDriftline_H1_val_2 )
            );


        gSetup_H1_Jaggy_Sell   := (
                                    gSetup_D1_Jaggy_Sell
                                and ( Close(1)  < gDriftline_H1_val_1 )
                                and ( Open(1)   < gDriftline_H1_val_1 )
                                // and ( gDriftline_H1_val_1 < gDriftline_H1_val_2 )
            );

        {
        Every single hour, if the event is found oversold with D1 uptrend, this become buy setup.
        likewise, if found overbought with D1 downtrend, this become sell setup.
        BUT
        within the same hour, when M5 makes momentum back into main trend, the setup cancels itself
        for that hour, until the next hour, if H1 is in retracement zone again.
        This way, cancelling the setup, means one signal per hour per retracement hour.
        }

    end;


            // SETUP H1 MONITORING
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_H1_FirstTick then
            begin

                Print('*** gBarName_H1_FirstTick event found JAGGY ENTRY: ***');

                Str( gSetup_D1_Jaggy_Buy , _text );
                Print( 'gSetup_D1_Jaggy_Buy: ' + _text );
                Str( gSetup_D1_Jaggy_Sell , _text );
                Print( 'gSetup_D1_Jaggy_Sell: ' + _text );

                if gSetup_H1_Jaggy_Buy then
                begin
                    Str( gSetup_H1_Jaggy_Buy , _text );
                    Print('gSetup_H1_Jaggy_Buy: ' + _text );
                end;

                if gSetup_H1_Jaggy_Sell then
                begin
                    Str( gSetup_H1_Jaggy_Sell , _text );
                    Print('gSetup_H1_Jaggy_Sell: ' + _text );
                end;

            end;



    // Return the timeframe back to M5
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

    // TRIGGER M5 - JAGGY
    // ---------------------------------------------------------------------------------
    // Ver_3_20180126
    // Trigger type 2 is when D1 red bar in uptrend, we need hourly bounce up, and take the
    // M5 cycle up as flagger
    // Likewise


    if gBarName_M5_FirstTick then
    begin



        gRSI3_M5_val_1      := GetIndicatorValue( gRSI3_M5_Handle , 1 , 0 );
        gRSI3_M5_val_2      := GetIndicatorValue( gRSI3_M5_Handle , 2 , 0 );



        gTrigger_M5_Buy_Market_Jaggy   := ( gSetup_H1_Jaggy_Buy
                                and ( (gRSI3_M5_val_1 > 50.0) and ( gRSI3_M5_val_2 <= 50.0 ) )
                                and (gDailyToken_Seq_1_rule_2 or gDailyToken_Seq_2_rule_2 )
                            );


        gTrigger_M5_Sell_Market_Jaggy  := ( gSetup_H1_Jaggy_Sell 
                                and ( (gRSI3_M5_val_1 < 50.0) and ( gRSI3_M5_val_2 >= 50.0 ) )
                                and (gDailyToken_Seq_1_rule_2 or gDailyToken_Seq_2_rule_2 )
                            );



        // Cancel setups for this trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Market_Jaggy then
        begin

            // Cancel sequentially, to allow two signals per day
            if gDailyToken_Seq_1_rule_2 then
                gDailyToken_Seq_1_rule_2 := false
            else if gDailyToken_Seq_2_rule_2 then
                gDailyToken_Seq_2_rule_2 := false ;

        end;

        if gTrigger_M5_Sell_Market_Jaggy then
        begin

            // Cancel sequentially, to allow two signals per day
            if gDailyToken_Seq_1_rule_2 then
                gDailyToken_Seq_1_rule_2 := false
            else if gDailyToken_Seq_2_rule_2 then
                gDailyToken_Seq_2_rule_2 := false ;

        end;

        {**********  ADD PRINTS FOR trigger settings ***********}

    end;



    // MARKING THE CHART WITH TRIGGER M5 - JAGGY 
    // ---------------------------------------------------------------------------------

    if gTrigger_M5_Buy_Market_Jaggy then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        Print(  '[ENTRY_MANAGEMENT]: First Tick M5 JAGGY BUY Signal ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 )
                );

        gTextName := 'TGR_JAGGY_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Market_Jaggy then
    begin

        Print(  '[ENTRY_MANAGEMENT]: First Tick M5 JAGGY SELL Signal ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 )
                );

        gTextName := 'TGR_JAGGY__' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;
    end;

    {===================================================================================================}
    {  COUNT EXISTING POSITION/S, ENTER INTO THE MARKET }
    {  Open new Position when there is none, and add more if previous one in profit  }
    {  Disable entry after large profit registers in the system  }
    {  Disable entry in the same day after NEntry attempts }
    {===================================================================================================}
    { for every requirement, there are two variables at minimum to support requirement }


end;



procedure ENTRY_MANAGEMENT_FLIPFLOP ; stdcall ;
var
        _text       :   string      ;
begin

    if (gMarketMode <> FLIPFLOP) and (gMarketMode <> CANTTELL_RALLYORJAGGYORFLIPFLOP) then exit ;

    {===================================================================================================}
    {  INDICATOR VALUE RETRIEVAL  }
    {===================================================================================================}
    { This procedure operates on the first tick of M5 }

    gATR_M5_val_1 := GetIndicatorValue( gATR_M5_Handle , 1, 0  );


    {===================================================================================================}
    {  SIGNAL GENERATION: Consider all setups, then trigger  }
    {===================================================================================================}



    // SETUP D1 - FLIPFLOP
    // -------------------------------------------

    if gBarName_D1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1


        // Set daily tokens true at opening bar
        gDailyToken_Seq_1_rule_2 := true ;
        gDailyToken_Seq_2_rule_2 := true ;



        // Recent closing price
        gD1_RecentClose     := Close(1);


        gDriftline_D1_val_1 := GetIndicatorValue( gDriftline_D1_Handle , 3, 0 );
        { The index for driftline value 1 recent bar has to be 3, not 1 ! }

        gDriftline_D1_val_2 := GetIndicatorValue( gDriftline_D1_Handle , 4 , 0 );
        { The index for driftline value 2 recent bar has to be 4, not 1 !
          Ver_3_20180126 }
        gDriftline_D1_val_3 := GetIndicatorValue( gDriftline_D1_Handle , 5 , 0 );


        gBarWave_D1_val_1   := GetIndicatorValue( gBarWave_D1_Handle , 1, 4 );
        gBarWave_D1_val_2   := GetIndicatorValue( gBarWave_D1_Handle , 2, 4 );


        Print(  '[ENTRY_MANAGEMENT]: FLIPFLOP MODE First Tick D1 ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-D1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-D1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'Driftline_D1: '+ FloatToStrF( gDriftline_D1_val_1 , ffFixed , 6, 4 )   + ' / ' +
                'BarWave_D1: '  + FloatToStrF( gBarWave_D1_val_1, ffNumber , 15 , 4 )
                );


        // Setup D1 Buy - FLIPFLOP
        // -------------------------------------------

        gSetup_D1_FlipFlop_Buy := (   // Recent bar body is above driftline of D1
                                    (Open(1)    > gDriftline_D1_val_1)
                                and (Close(1)   > gDriftline_D1_val_1)
                                and (Close(1)  >= Open(1) )
                                    // Recent bar wave is rising
                                    // Recent bar is BLUE
                                    // Needs pairing with Hourly H1 bounce up
                            );


        // Setup D1 Sell - FLIPFLOP
        // -------------------------------------------

        gSetup_D1_FlipFlop_Sell := (   // Recent bar body is below driftline of D1
                                    (Open(1)    < gDriftline_D1_val_1)
                                and (Close(1)   < gDriftline_D1_val_1)
                                and (Close(1)  <= Open(1) )
                                    // Recent bar wave is descending
                                    // Recent bar is RED 
                                    // Needs pairing with Hourly H1 bounce down
                            );



        // Setup D1 Stay - FLIPFLOP Away
        // -------------------------------------------

        gSetup_D1_StayAway := (
                                    (not gSetup_D1_FlipFlop_Buy)
                                and (not gSetup_D1_FlipFlop_Sell)
                            );


    end;


            // SETUP D1 FLIPFLOP MONITORING
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_D1_FirstTick then
            begin


                Str( gSetup_D1_FlipFlop_Buy , _text );
                Print( 'gSetup_D1_FlipFlop_Buy: ' + _text );

                Str( gSetup_D1_FlipFlop_Sell , _text );
                Print( 'gSetup_D1_FlipFlop_Sell: ' + _text );

                Str( gSetup_D1_StayAway , _text );
                Print( 'gSetup_D1_StayAway - FLIPFLOP: ' + _text );

            end;



    // SETUP H1 - FLIPFLOP
    // ---------------------------------------------------------------------------------
    // *** IMPORTANT: Ver_3_20180126 does not use H1 !!!

    if gBarName_H1_FirstTick then
    begin


        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );
        
        gRSI7_H1_val_1      := GetIndicatorValue( gRSI7_H1_Handle , 1 , 0 ) ;
        gRSI7_H1_val_2      := GetIndicatorValue( gRSI7_H1_Handle , 2 , 0 ) ;


        //** Ver_3_20180126 **


        { OLDER LOGIC IS DELETED }
        {
        Need older logic: refer to
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - MultiForexScale\PowerTool 6\PT6_FT3_v2_20180114\
            Powertool6_v2_20180114.pas
        }


        Print(  '[ENTRY_MANAGEMENT]: First Tick H1 SETUP FLIPFLOP' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-H1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-H1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'Driftline_H1: '+ FloatToStrF( gDriftline_H1_val_1 , ffFixed , 6, 4 )
                );

        gSetup_H1_FlipFlop_Buy  := (
                                    gSetup_D1_FlipFlop_Buy 
                                and ( gRSI7_H1_val_1 >  40 )
                                and ( gRSI7_H1_val_2 <= 40 )
            );


        gSetup_H1_FlipFlop_Sell   := (
                                    gSetup_D1_FlipFlop_Sell 
                                and ( gRSI7_H1_val_1 < 60 )
                                and ( gRSI7_H1_val_2 >= 60 )
            );

        {
        Every single hour, if the event is found oversold with D1 uptrend, this become buy setup.
        likewise, if found overbought with D1 downtrend, this become sell setup.
        BUT
        within the same hour, when M5 makes momentum back into main trend, the setup cancels itself
        for that hour, until the next hour, if H1 is in retracement zone again.
        This way, cancelling the setup, means one signal per hour per retracement hour.
        }

    end;


            // SETUP H1 MONITORING FLIPFLOP
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_H1_FirstTick then
            begin

                Print('*** gBarName_H1_FirstTick event found FLIPFLOP ENTRY: ***');

                Str( gSetup_D1_FlipFlop_Buy , _text );
                Print( 'gSetup_D1_FlipFlop_Buy: ' + _text );
                Str( gSetup_D1_FlipFlop_Sell , _text );
                Print( 'gSetup_D1_Sell FLIPFLOP: ' + _text );

                if gSetup_H1_FlipFlop_Buy then
                begin
                    Str( gSetup_H1_FlipFlop_Buy , _text );
                    Print('gSetup_H1_FlipFlop_Buy: ' + _text );
                end;

                if gSetup_H1_FlipFlop_Sell then
                begin
                    Str( gSetup_H1_FlipFlop_Sell , _text );
                    Print('gSetup_H1_FlipFlop_Sell: ' + _text );
                end;

            end;



    // Return the timeframe back to M5
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

    // TRIGGER M5 - FLIPFLOP
    // ---------------------------------------------------------------------------------
    // Ver_3_20180126
    // Trigger type 2 is when D1 red bar in uptrend, we need hourly bounce up, and take the
    // M5 cycle up as flagger
    // Likewise


    if gBarName_M5_FirstTick then
    begin



        gRSI3_M5_val_1      := GetIndicatorValue( gRSI3_M5_Handle , 1 , 0 );
        gRSI3_M5_val_2      := GetIndicatorValue( gRSI3_M5_Handle , 2 , 0 );



        gTrigger_M5_Buy_Market_FlipFlop   := ( gSetup_H1_FlipFlop_Buy
                                and ( (gRSI3_M5_val_1 > 50.0) and ( gRSI3_M5_val_2 <= 50.0 ) )
                                and (gDailyToken_Seq_1_rule_3 or gDailyToken_Seq_2_rule_3 )
                            );


        gTrigger_M5_Sell_Market_FlipFlop  := ( gSetup_H1_FlipFlop_Sell 
                                and ( (gRSI3_M5_val_1 < 50.0) and ( gRSI3_M5_val_2 >= 50.0 ) )
                                and (gDailyToken_Seq_1_rule_3 or gDailyToken_Seq_2_rule_3 )
                            );



        // Cancel setups for this trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Market_FlipFlop then
        begin

            // Cancel sequentially, to allow two signals per day
            if gDailyToken_Seq_1_rule_3 then
                gDailyToken_Seq_1_rule_3 := false
            else if gDailyToken_Seq_2_rule_3 then
                gDailyToken_Seq_2_rule_3 := false ;

        end;

        if gTrigger_M5_Sell_Market_FlipFlop then
        begin

            // Cancel sequentially, to allow two signals per day
            if gDailyToken_Seq_1_rule_3 then
                gDailyToken_Seq_1_rule_3 := false
            else if gDailyToken_Seq_2_rule_3 then
                gDailyToken_Seq_2_rule_3 := false ;

        end;

        {**********  ADD PRINTS FOR trigger settings ***********}

    end;



    // MARKING THE CHART WITH TRIGGER M5 - FLIPFLOP 
    // ---------------------------------------------------------------------------------

    if gTrigger_M5_Buy_Market_FlipFlop then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        Print(  '[ENTRY_MANAGEMENT]: First Tick M5 FLIPFLOP BUY Signal ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 )
                );

        gTextName := 'TGR_FLIPFLOP_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Market_FlipFlop then
    begin

        Print(  '[ENTRY_MANAGEMENT]: First Tick M5 FLIPFLOP SELL Signal ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 )
                );

        gTextName := 'TGR_FLIPFLOP__' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;
    end;

    {===================================================================================================}
    {  COUNT EXISTING POSITION/S, ENTER INTO THE MARKET }
    {  Open new Position when there is none, and add more if previous one in profit  }
    {  Disable entry after large profit registers in the system  }
    {  Disable entry in the same day after NEntry attempts }
    {===================================================================================================}
    { for every requirement, there are two variables at minimum to support requirement }


end;







{-------------------------------------------------------------------------------------------------------}
{***** EXIT MANAGEMENT *****}
{-------------------------------------------------------------------------------------------------------}

procedure EXIT_MANAGEMENT   ; stdcall ;
begin


end;




{-------------------------------------------------------------------------------------------------------}
{***** OPEN POSITION TRACKER *****}
{-------------------------------------------------------------------------------------------------------}

procedure   OPEN_POSITION_TRACKER   ; stdcall ;
begin



end;



{-------------------------------------------------------------------------------------------------------}
{***** MAGIC NUMBER FUNCTIONS *****}
{-------------------------------------------------------------------------------------------------------}

function PositionToMagicNumber( _iPos: integer): longint ;
begin
    { use string process to catch string bit from integer value, then convert the string bit to integer }
    result := 0 ;
end;

function MagicNumberToPosition( _magicNumber: longint ) : integer ;
begin
    { use string process to add components, convert the string to integer, then return the value }
    result := 0 ;
end;



{-------------------------------------------------------------------------------------------------------}
{***** POSITION SIZE CALCULATOR *****}
{-------------------------------------------------------------------------------------------------------}

{ Global variables are used ; specific variables non-global, are fed through parameters }
function LotSizeCalculator(): double ;
var
    _riskdollar         :   double  ;
    _distance           :   double  ;
    _lot_size           :   double  ;
begin

    // Adjust Risk Size to Percent
    gRiskSizePercent := gRiskSize  / 100.0 ;

    // Calculate risk dollar and distance
    _riskdollar := gRiskSizePercent * AccountEquity ;
    _distance := gATR_M5_val_1 ;

    // IMPORTANT:
    // _lot_size is in FULL CONTRACT

        // Example 1:
        // risk = $100 ; dist = 15 pips (GBPJPY)
        // lot size = $100 / (15 * 0.01) / 1000.00 = 0.67 normal contracts

        // Example 2:
        // risk = $100 ; dist = 15 pips (EURUSD)
        // $100 / (15 * 0.0001) / 100000.00 = 0.67 normal contracts

    _lot_size := _riskdollar / _distance / 100000.0 ;
    if AnsiPos('JPY', gCurrency) > 0 then
        _lot_size := _riskdollar / _distance / 1000.0 ;



    Print('[LotSizeCalculator]: ' +
    'AccountEquity: '   + FloatToStrF(AccountEquity , ffCurrency , 12,2 )                   + ' / ' +
    'Risk size: '       + FloatToStrF(gRiskSize , ffFixed, 5,2) + '% '                      + ' / ' +
    'Distance in pips: '+ FloatToStrF(_distance/(Point * gPointToPrice) , ffNumber, 7,1 )   + ' / ' +
    'Lot size'          + FloatToStrF(_lot_size , ffNumber, 7,1 )
            );

    { use string process to catch string bit from integer value, then convert the string bit to integer }
    result := _lot_size ;


    {/~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    * Mini Contract:
    * --------------
    * #tipsandtricks #important
    *
    * 1 mini contract, 1 pips = $1 base currency
    * 1 mini contract, 5 pips = $5 base currency
    *
    \~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/}

end;



{///////////////////////////////////////////////////////////////////////////////////////////////////////}
{*******************************************************************************************************}
{**                                  CORE PROCEDURES IN FOREX TESTER                                  **}
{*******************************************************************************************************}
{///////////////////////////////////////////////////////////////////////////////////////////////////////}




{-----Init strategy-----------------------------------------}
procedure InitStrategy; stdcall;
begin

  StrategyShortName('Powertool601');
  StrategyDescription('Strategy Swing based on Triple Time Frame');


  RegOption     ('Activate the System', ot_EnumType , gActivateSystem );
  AddOptionValue('Activate the System' , 'YES'  );      // 0
  AddOptionValue('Activate the System' , 'NO'   );      // 1


  // Register external parameters
  RegOption('Currency', ot_Currency, gCurrency );
  ReplaceStr(gCurrency, 'GBPJPY');

  RegOption('Timeframe', ot_Timeframe, gTimeFrame );
  gTimeFrame := PERIOD_M5 ;

  { RegOption('LotSize', ot_Double, gP1_LotSize ); }
  { SetOptionDigits('LotSize', 1); }
  { gP1_LotSize := 0.1; }

  RegOption('Risk Size Percent (ex/ 0.75 means 0.75%', ot_Double, gRiskSize );
  SetOptionDigits('Risk Size Percent (ex/ 0.75 means 0.75%', 2);
  gRiskSize := 0.95;


  RegOption     ('Market Mode' , ot_EnumType , gMarketMode );
  AddOptionValue('Market Mode' , 'Rally' );                                     // 0
  AddOptionValue('Market Mode' , 'Jaggy' );                                     // 1
  AddOptionValue('Market Mode' , 'Flip Flop' );                                 // 2
  AddOptionValue('Market Mode' , 'Cant Tell Rally or Jaggy of FlipFlop' );      // 3


  RegOption     ('Trade Direction', ot_EnumType , gTradeDirection );
  AddOptionValue('Trade Direction' , 'BUY');        // 0
  AddOptionValue('Trade Direction' , 'SELL');       // 1
  AddOptionValue('Trade Direction' , 'BUY_SELL');   // 2


end;


{-----Done strategy---------------------------------------}
procedure DoneStrategy; stdcall;
begin
    FreeMem(gCurrency);
end;


{-----Reset strategy--------------------------------------}
procedure ResetStrategy; stdcall;
begin

    // Order Handle Initialisation
    // ---------------------------------------------------------------------------------

    gP1_OrderHandle := -1;
    gP2_OrderHandle := -1;
    gP3_OrderHandle := -1;
    gP4_OrderHandle := -1;
    gP5_OrderHandle := -1;
    gP6_OrderHandle := -1;
    gP7_OrderHandle := -1;
    gP8_OrderHandle := -1;


    // Establish Indicator Instances - D1
    // ---------------------------------------------------------------------------------

    gDriftline_D1_Handle := CreateIndicator(
                            gCurrency
                    ,       PERIOD_D1
                    ,       'MovingAverage'
                    ,       format('%d;%d;%d;%s;%s',
                            [ 8 , 2, 0, StrMAType(ma_SMA), StrPriceType(pt_HL2)])
                );
            { '<Period>; <Shift>; <VShift> ; <MAtype>; <ApplyToPrice>' }

    gBarWave_D1_Handle :=   CreateIndicator(
                            gCurrency
                    ,       PERIOD_D1
                    ,       'MACDHistogramX100'
                    ,       '12;26;9;(High + Low + Close)/3'
                );



    // Establish Indicator Instances - H1
    // ---------------------------------------------------------------------------------

    gDriftline_H1_Handle := CreateIndicator(
                            gCurrency
                    ,       PERIOD_H1
                    ,       'MovingAverage'
                    ,       format('%d;%d;%d;%s;%s',
                            [ 8 , 2, 0, StrMAType(ma_SMA), StrPriceType(pt_HL2)])
                );
            { '<Period>; <Shift>; <VShift> ; <MAtype>; <ApplyToPrice>' }

    gBarWave_H1_Handle :=   CreateIndicator(
                            gCurrency
                    ,       PERIOD_H1
                    ,       'MACDHistogramX100'
                    ,       '12;26;9;(High + Low)/2'
                );

    gBarWave_H1_Exit_Handle :=   CreateIndicator(
                            gCurrency
                    ,       PERIOD_H1
                    ,       'MACDHistogramX100'
                    ,       '18;39;18;(High + Low + Close)/3'
                );

    //** Ver 2_20180114 **
    gRSI7_H1_Handle :=      CreateIndicator(
                            gCurrency
                    ,       PERIOD_H1
                    ,       'RSI'
                    ,       '7;Close'
                );



    // Establish Indicator Instances - M5
    // ---------------------------------------------------------------------------------

    gRSI3_M5_Handle :=      CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'RSI'
                    ,       '3;Close'
                );

    gMACDH_M5_Handle :=     CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'MACDHistogramX100'
                    ,       '12;26;9;(High + Low + Close)/3'
                );
                
    gBollingerM5_Handle :=  CreateIndicator( 
                            gCurrency
                    ,       PERIOD_M5
                    ,       'BollingerBands'
                    ,       '30;1.00;0;Close;Simple (SMA)'    
                );

    gATR_M5_Handle :=       CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'ATR'
                    ,       '5;Close'
                );



    // Establish Point to Price
    // ---------------------------------------------------------------------------------

    if( (Digits = 5) or (Digits=3) or (Digits = 1) )then
        gPointToPrice := 10.0
    else
        gPointToPrice := 1.0 ;



    // Initiate large profit operation
    // ---------------------------------------------------------------------------------

    gP1_LargeProfitExit_Bool := false ;
    { This variable is  }



    // Initiate tracker variables for bar numbers
    // ---------------------------------------------------------------------------------

    // gSetup_H1_Buy_Curr          := false ;
    // gSetup_H1_Sell_Curr         := false ;
    // gSetup_H1_Buy_BarNum_In     := 0 ;
    // gSetup_H1_Sell_BarNum_In    := 0 ;


    // Print the version on Journal
    // ---------------------------------------------------------------------------------
    Print(
        'Ver_3_20180126 + 2018.01.27 (0230) - Saturday'
        );


end;




{///////////////////////////////////////////////////////////////////////////////////////////////////////}
{*******************************************************************************************************}
{**                                             PROCESS SINGLE TICK                                   **}
{*******************************************************************************************************}
{///////////////////////////////////////////////////////////////////////////////////////////////////////}


{-----Process single tick----------------------------------}
procedure GetSingleTick; stdcall;
  var
    myYear , myMonth,
    myDay, myHour,
    myMin, mySec,
    myMilli             :   Word        ;

begin



    {***************************************************************************************************}
    {**   FOUNDATION WORKS  **}
    {***************************************************************************************************}

    // check our currency
    if Symbol <> string(gCurrency) then exit;

    // Set timeframe to D1 and check the bar number must be greater than longest parameter in D1
    SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );

        // check number of bars of D1
        if (Bars < (26+1))  then exit;

    // Set timeframe back to M5, SO THAT it works on M5 chart
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );


    // Decode tick date time
    DecodeDateTime(TimeCurrent,
        myYear, myMonth, myDay,
        myHour, myMin, mySec, myMilli);


    {***************************************************************************************************}
    {**   BAR NAMING AND IDENTIFYING FIRST TICK OF THE BAR  **}
    {***************************************************************************************************}


    {-----------------------------------------------------------------------------------}
    {***** Bar Naming D1 *****}
    {-----------------------------------------------------------------------------------}

    gBarName_D1_Curr := FormatDateTime( 'yyyymmdd', TimeCurrent);
    gBarName_D1_FirstTick := (gBarName_D1_Curr <> gBarName_D1_Prev) ;

    gD1_DayName_Curr := FormatDateTime( 'ddd' , TimeCurrent );


    {-----------------------------------------------------------------------------------}
    {***** Bar Naming H1 *****}
    {-----------------------------------------------------------------------------------}

    gBarName_H1_Curr := FormatDateTime( 'yyyymmddhh', TimeCurrent);
    gBarName_H1_FirstTick := (gBarName_H1_Curr <> gBarName_H1_Prev);


    {-----------------------------------------------------------------------------------}
    {***** Bar Naming M5 *****}
    {-----------------------------------------------------------------------------------}

    // Get a name for the current bar
    gBarName_M5_Curr :=
        FormatDateTime( 'yyyymmddhh', TimeCurrent) + Format( '%.2d' , [(myMin div 5) * 5]) ;
    { The end part of formatting is to force the bar naming with 00, 05, 10, 15, 20.
      Example: 201406251405 }
    {Ref:
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - Multi Forex Capital\03.Codes - Main\
        SYS - Trend 1 - D1 Wave 3\Trend1_D1_Wave_3_ver4.pas}

    // Identify first tick of the bar
    gBarName_M5_FirstTick := ( gBarName_M5_Curr <> gBarName_M5_Prev ) ;

    // We only act on the first tick on the new bars
    if not gBarName_M5_FirstTick then
    begin
        gBarName_M5_Prev := gBarName_M5_Curr ;
        exit;
        // EXIT THE GET SINGLE TICK !!!!
    end;

    // Print('Bar name of M5: ' + gBarName_M5_Curr );

    {/~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    * IMPORTANT:
    * --------------
    * From this point onward, the procedure operates only on new bar of M5 bar.
    * In-between ticks are ignored
    \~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/}



    {***************************************************************************************************}
    {**   EXIT MANAGEMENT  **}
    {***************************************************************************************************}

    // if BUY order exists and fast SMA crosses slow SMA from top
    // then close order
    { if (gOrderHandleP1 <> -1) and (gOrderStyleP1 = tp_Buy) and }
     { (gOpenTimeP1 <> Time(0)) and (gSMA1_Val_1 < gSMA2_Val_1 ) then }
    { begin }
      { CloseOrder( gOrderHandleP1 ); }
      { gOrderHandleP1 := -1; }
    { end; }



    // if SELL order exists and fast SMA crosses slow SMA from bottom
    // then close order
    { if (gOrderHandleP1 <> -1) and (gOrderStyleP1 = tp_Sell) and }
     { (gOpenTimeP1 <> Time(0)) and (gSMA1_Val_1 > gSMA2_Val_1 ) then }
    { begin }
      { CloseOrder( gOrderHandleP1 ); }
      { gOrderHandleP1 := -1; }
    { end; }





    {***************************************************************************************************}
    {**   ENTRY MANAGEMENT  **}
    {***************************************************************************************************}

    ENTRY_MANAGEMENT_RALLY_STANDARD;
    ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC;
    
    ENTRY_MANAGEMENT_JAGGY;
    ENTRY_MANAGEMENT_FLIPFLOP;

    // if there is no order and fast SMA crosses slow SMA from top
      // then open SELL order
      { if (gOrderHandleP1 = -1) and ( gSMA1_Val_1 < gSMA2_Val_1 ) }
        { and (gTradeDirection = SELL) and (gActivateSystem = YES) then }
        { begin }
          { SendInstantOrder(gCurrency , op_Sell, gP1_LotSize , 0, 0, '', 0, gOrderHandleP1 ); }
          { gOrderStyleP1 := tp_Sell; }
          { gOpenTimeP1 := Time(0); }
        { end; }

      // if there is no order and fast SMA crosses slow SMA from bottom
      // then open BUY order
      { if (gOrderHandleP1 = -1) and (gSMA1_Val_1 > gSMA1_Val_2 ) }
        { and (gTradeDirection = BUY) and (gActivateSystem = YES) then }
        { begin }
          { SendInstantOrder(gCurrency , op_Buy, gP1_LotSize , 0, 0, '', 0, gOrderHandleP1 ); }
          { gOrderStyleP1 := tp_Buy; }
          { gOpenTimeP1 := Time(0); }
        { end; }










    {***************************************************************************************************}
    {**   TIMEFRAME MANAGEMENT **}
    {***************************************************************************************************}
    {Ref:
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - Multi Forex Capital\03.Codes - Main\
        SYS - Trend 1 - D1 Wave 3\Trend1_D1_Wave_3_ver4.pas}

    SetCurrencyAndTimeframe(gCurrency , PERIOD_D1);
    gBarName_D1_Prev := gBarName_D1_Curr ;


    SetCurrencyAndTimeframe(gCurrency , PERIOD_H1);
    gBarName_H1_Prev := gBarName_H1_Curr ;


    { timeframe low ** at the last point }

    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 ) ;
    gBarName_M5_Prev := gBarName_M5_Curr ;

end;

exports
  InitStrategy,
  DoneStrategy,
  ResetStrategy,
  GetSingleTick;
end.