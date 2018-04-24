library Powertool6X;

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


    {===================================================================================================}
    {  COUNT EXISTING POSITION/S, ENTER INTO THE MARKET }
    {  Open new Position when there is none, and add more if previous one in profit  }
    {  Disable entry after large profit registers in the system or after you notice large profit }
    {  Disable entry in the same day after NEntry attempts }
    {===================================================================================================}
    { for every requirement, there are two variables at minimum to support requirement }

{

    From 2018.03.25.SUN, GitHub is used for version control, so that, I don’t want to have headache
    in maintaining version control.

    As such filenaming will be only Powertool6X to with X in the end to denote flexible versioning.

    At the end of each build, the file will be staged, committed, and pushed to remote.


    VERSIONING NAMING
    -----------------

    Powertool601.dll

    The library version is named Powertool601 ; 6 is the version, the 01 is the build.

    Last two digit can continue 01, 02, 03, to 99.




    Ver_5_20180311
    --------------

    Separation logic for Rally, Jaggy, FlipFlop, and CANTTELL_RALLY_OR_JAGGY

    Adding self-explanatory variables


    Ver_4_20180204
    --------------

    Adding mode:

    - Rally
    - Jaggy
    - CANTTELL_RALLY_OR_JAGGY

    Including block separation for Rally, Jaggy, and CANTTELL_RALLY_OR_JAGGY.

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
      Windows,          // For MessageBox
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
    TMarketMode         = (RALLY , JAGGY , CANTTELL_RALLY_OR_JAGGY , FLIPFLOP  );
    
    TSystemLockStatus   = (LOCKED , UNLOCKED);



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

    // Trend Direction: UP, DOWN, SIDEWAY
    gTrend_D1_Curr          :   TTrendDirection         ;
    gTrend_D1_Prev          :   TTrendDirection         ;
    // For gTrend_D1_Prev -- Update value at the end of GetSingleTick

    gTrend_D1_NewUp_NewDown :   boolean                 ;    
    // Flag for new up trend or downtrend. Sideway trend does not count
    gSystemTradeLockStatus  :   TSystemLockStatus       ;
    // With key for system to trade, we can activate or deactivate system 
    // from the outside of the system. 
    // For example when new trend exist, but big picture is not favorable
    // after long large trend, and we don’t want the system trade it,
    // then we can deactivate the system.
    
    
    
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

    {** D1 Bar Counter **}
    gD1_Bar_Count               : integer               ;


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


    // Token counter (new one)

    gDay_Token_Trig_Rall_Stan_Count         : integer   ;

    gDay_Token_Trig_Rall_Extr_All__Count    : integer   ;
    gDay_Token_Trig_Rall_Extr_Main_Count    : integer   ;
    gDay_Token_Trig_Rall_Extr_Tand_Count    : integer   ;


    gDay_Token_Trig_Jaggy_All_Count         : integer   ;

    gDay_Token_Trig_FlipF_All_Count         : integer   ;


    { gDailyToken_Seq_1_rule_1    : boolean               ; }
    { gDailyToken_Seq_2_rule_1    : boolean               ; }

    gD1_RecentClose             : double                ;

    // Ver_3_20180126
    // For D1 red bars in uptrend and D1 blue bars in downtrend
    gDailyToken_Seq_1_rule_2    : boolean               ;
    gDailyToken_Seq_2_rule_2    : boolean               ;
    gDailyToken_Seq_1_rule_3    : boolean               ;
    gDailyToken_Seq_2_rule_3    : boolean               ;



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


    gH1_Setup_Rall_extr_Buy   : boolean                 ;
    gH1_Setup_Rall_extr_Sell  : boolean                 ;

    gSetup_H1_Jaggy_Buy         : boolean               ;
    gSetup_H1_Jaggy_Sell        : boolean               ;

    gSetup_H1_FlipFlop_Buy      : boolean               ;
    gSetup_H1_FlipFlop_Sell     : boolean               ;


    {** Hourly Token **}
    // Token for trigger one entry per hour

    gH1_Token_Trig_Rall_Stan_Count      : integer       ;

    gH1_Token_Trig_Rall_Extr_Main_Count : integer       ;
    gH1_Token_Trig_Rall_Extr_Tand_Count : integer       ;

    gH1_Token_Trig_Jaggy_Count  : integer               ;

    gH1_Token_Trig_FlipF_Count  : integer               ;

    gH1_Token_Trigger           : boolean               ;       // Marked_for_deletion
                                                                // Used by Rally Standard
    // Used by Jaggy with H1 deep retracement
    gH1_OverBought              : boolean               ;
    gH1_OverSold                : boolean               ;


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

    // EMA 5/20

    gM5_EMA_5_Handle            : integer               ;
    gM5_EMA_5_val_1             : double                ;
    gM5_EMA_5_val_2             : double                ;

    gM5_EMA_20_Handle           : integer               ;
    gM5_EMA_20_val_1            : double                ;
    gM5_EMA_20_val_2            : double                ;


    // RL Regression Line 12 / 30

    gM5_RL_10_Handle            : integer               ;
    gM5_RL_10_val_1             : double                ;
    gM5_RL_10_val_2             : double                ;
    gM5_RL_10_val_3             : double                ;

    gM5_RL_30_Handle            : integer               ;
    gM5_RL_30_val_1             : double                ;
    gM5_RL_30_val_2             : double                ;

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


    // M5 - Setups
    // -------------------------------------------

    gOversold_M5                : boolean               ;
    gOverbought_M5              : boolean               ;

    gM5_Setup_BollBand_Overbought   : boolean           ;
    gM5_Setup_BollBand_Oversold     : boolean           ;

    gM5_RL10_RL30_Posi_Curr         : string            ;
    gM5_RL10_RL30_Posi_Prev         : string            ;


    // M5 - Triggers
    // -------------------------------------------

    {** Trigger M5 **}

    // 25 MAR 2018
    gTrigger_M5_Buy_Rally_Standard    : boolean         ;
    gTrigger_M5_Sell_Rally_Standard   : boolean         ;


    gTrigger_M5_Buy_Rall_Extr_retrac  : boolean         ;
    gTrigger_M5_Sell_Rall_Extr_retrac : boolean         ;


    gTrigger_M5_Buy_Market_Jaggy      : boolean         ;
    gTrigger_M5_Sell_Market_Jaggy     : boolean         ;


    gTrigger_M5_Rally_AllSignals_Buy  : boolean         ;
    gTrigger_M5_Rally_AllSignals_Sell : boolean         ;
    { Consolidate all signals from Trendy }

    gTrigger_M5_Buy_Market_FlipFlop   : boolean         ;
    gTrigger_M5_Sell_Market_FlipFlop  : boolean         ;


    //** Previous version's does not fit and we need code simplicity

    //** Ver 2_20180114  **
    //----------------------------------------------------------------

    gRSI3_M5_MomentumEvent      : TMomentumDirection    ;



    // M5 - Volatility
    // ---------------------------------------------------------------------------------

    {** ATR M5 **}
    gATR_M5_Handle              : integer               ;
    gATR_M5_val_1               : double                ;



    // Entry, Stop Loss, Distance
    // ---------------------------------------------------------------------------------

    {** Spread **}
    gSpreadPips                 : double                ;
    gSpreadInPrice              : double                ;


    {** Estimated entry price **}
    gEstimatedEntryPrice_Buy    : double                ;
    gEstimatedEntryPrice_Sell   : double                ;


    {** Stop Loss **}
    gStopLoss_Price_Buy         : double                ;
    gStopLoss_Price_Sell        : double                ;

    gDistance_Buy               : double                ;
    gDistance_Sell              : double                ;
    gDistance_Buy_Pips          : double                ;
    gDistance_Sell_Pips         : double                ;
    gDistance_Pips              : double                ;

    {** Take Profit **}
    gTakeProfitPrice_Buy        : double                ;
    gTakeProfitPrice_Sell       : double                ;
    
    {** Large Profit Flag **}   
    gEntryPrice_Position_One    : double                ;
    gLargeProfitFlag            : boolean               ;


    {** Position Sizing **}

    // General LotSize
    gLotSize_General            :   double              ;
    
    gNumberOfOpenPositions      :   integer             ;
    gMagicNumberThisPosition    :   integer             ;
    gOrderHandle_General        :   integer             ;


    {++ FILES for VARIABLE SUPPORT ++}
    {-----------------------------------------------------------------------------------}

    // Directory
    gVarFileDirectory               :   string          ;
    
    // gLargeProfitFlag     
    gVarFile_gLargeProfitFlag_Text  :   string          ;
    
    gToggleCheck_FileVar_AtNewTrend :   boolean         ;
    
    
    
    
    {***    DELETE IF CONFIRMED UNUSED    ****}
    { // P1 }
    { gP1_LotSize                 :   double              ; }
    { gP1_OrderHandle             :   integer             ; }
    { gP1_OrderStyle              :   TTradePositionType  ; }
    { gP1_OpenTime                :   TDateTime           ; }

    { // P2 }
    { gP2_LotSize                 :   double              ; }
    { gP2_OrderHandle             :   integer             ; }
    { gP2_OrderStyle              :   TTradePositionType  ; }
    { gP2_OpenTime                :   TDateTime           ; }

    { // P3 }
    { gP3_LotSize                 :   double              ; }
    { gP3_OrderHandle             :   integer             ; }
    { gP3_OrderStyle              :   TTradePositionType  ; }
    { gP3_OpenTime                :   TDateTime           ; }

    { // P4 }
    { gP4_LotSize                 :   double              ; }
    { gP4_OrderHandle             :   integer             ; }
    { gP4_OrderStyle              :   TTradePositionType  ; }
    { gP4_OpenTime                :   TDateTime           ; }

    { // P5 }
    { gP5_LotSize                 :   double              ; }
    { gP5_OrderHandle             :   integer             ; }
    { gP5_OrderStyle              :   TTradePositionType  ; }
    { gP5_OpenTime                :   TDateTime           ; }

    { // P6 }
    { gP6_LotSize                 :   double              ; }
    { gP6_OrderHandle             :   integer             ; }
    { gP6_OrderStyle              :   TTradePositionType  ; }
    { gP6_OpenTime                :   TDateTime           ; }

    { // P7 }
    { gP7_LotSize                 :   double              ; }
    { gP7_OrderHandle             :   integer             ; }
    { gP7_OrderStyle              :   TTradePositionType  ; }
    { gP7_OpenTime                :   TDateTime           ; }

    { // P8 }
    { gP8_LotSize                 :   double              ; }
    { gP8_OrderHandle             :   integer             ; }
    { gP8_OrderStyle              :   TTradePositionType  ; }
    { gP8_OpenTime                :   TDateTime           ; }



    {++ LOGIC SUPPORT ++}
    {-----------------------------------------------------------------------------------}

    iOrder                      :   integer             ;


    {++ OPEN POSITION TRACKER ++}
    {-----------------------------------------------------------------------------------}

    { gP1_Profit_Pips             :   double              ; }
    { gP1_Profit_Price            :   double              ; }
    { gP1_LargeProfitExit_Bool    :   boolean             ; }
    { gOpenPositionsNumber        :   integer             ;   // also OrderTotals() }


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

    if (gMarketMode <> RALLY) and (gMarketMode <> CANTTELL_RALLY_OR_JAGGY) then exit ;

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
    // ENTRY_MANAGEMENT_RALLY_STANDARD

    if gBarName_D1_FirstTick then
    begin

        Print(  '[ENTRY_MANAGEMENT_RALLY_STANDARD]: DAILY TICK' );


        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1

        // Set setup FALSE daily until retracement below recent close
        gOversold_M5    := false;
        gOverbought_M5  := false ;



        // Set daily tokens true at opening bar
        gDay_Token_Trig_Rall_Stan_Count := 0 ;


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


        { Print(  '[ENTRY_MANAGEMENT_RALLY_STANDARD]: First Tick D1 ' + }
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

                if gSetup_D1_Rally_Buy then
                begin
                    Str( gSetup_D1_Rally_Buy , _text );
                    { Print( 'gSetup_D1_Rally_Buy STANDARD: ' + _text ); }
                end;

                if gSetup_D1_Rally_Sell then
                begin
                    Str( gSetup_D1_Rally_Sell , _text );
                    { Print( 'gSetup_D1_Rally_Sell STANDARD: ' + _text ); }
                end;

                if gSetup_D1_StayAway then
                begin
                    Str( gSetup_D1_StayAway , _text );
                    { Print( 'gSetup_D1_StayAway STANDARD: ' + _text ); }
                end;

            end;



    // SETUP H1 - RALLY
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_RALLY_STANDARD


    if gBarName_H1_FirstTick then
    begin

        { Left as placeholder }

        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );

        gH1_Token_Trig_Rall_Stan_Count := 0 ;
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



        { Print(  '[ENTRY_MANAGEMENT_RALLY_STANDARD]: 1st Tick H1 ' + }
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

                { Print('*** gBarName_H1_FirstTick RALLY event found: ***'); }

                { Str( gSetup_D1_Rally_Buy , _text ); }
                { Print( 'gSetup_D1_Rally_Buy STANDARD: ' + _text ); }
                { Str( gSetup_D1_Rally_Sell , _text ); }
                { Print( 'gSetup_D1_Rally_Sell STANDARD: ' + _text ); }

                if gSetup_H1_Rally_Buy then
                begin
                    Str( gSetup_H1_Rally_Buy , _text );
                    { Print('gSetup_H1_Rally_Buy STANDARD: ' + _text ); }
                end;

                if gSetup_H1_Rally_Sell then
                begin
                    Str( gSetup_H1_Rally_Sell , _text );
                    { Print('gSetup_H1_Rally_Sell STANDARD: ' + _text ); }
                end;

            end;








    // Return the timeframe back to M5
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

    // TRIGGER M5 - RALLY
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_RALLY_STANDARD

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

        // Regression Line
        gM5_RL_10_val_1     :=  GetIndicatorValue( gM5_RL_10_Handle , 1 , 0 );
        gM5_RL_10_val_2     :=  GetIndicatorValue( gM5_RL_10_Handle , 2 , 0 );

        gM5_RL_30_val_1     :=  GetIndicatorValue( gM5_RL_30_Handle , 1 , 0 );
        gM5_RL_30_val_2     :=  GetIndicatorValue( gM5_RL_30_Handle , 2 , 0 );



        gTrigger_M5_Buy_Rally_Standard  := (
                                    gSetup_D1_Rally_Buy       // Ver_3_20180126
                            and     gOversold_M5
                            and     ( Close(2) < gBollingerM5_val_2_BotBand )
                            and     ( Close(2) < gD1_RecentClose )      // Find the tips
                            and ( gM5_RL_10_val_1 >  gM5_RL_30_val_1 )
                            and ( gM5_RL_10_val_2 <= gM5_RL_30_val_2 )
                                and (gDay_Token_Trig_Rall_Stan_Count < 2)    // two triggers per day
                                and ( gH1_Token_Trig_Rall_Stan_Count < 1 )           // one trigger per hour
                            );

        gTrigger_M5_Sell_Rally_Standard :=  (
                                    gSetup_D1_Rally_Sell
                            and     gOverbought_M5
                            and     ( Close(2) > gBollingerM5_val_2_TopBand )
                            and     ( Close(2) > gD1_RecentClose )      // Find the antenna
                            and ( gM5_RL_10_val_1 <  gM5_RL_30_val_1 )
                            and ( gM5_RL_10_val_2 >= gM5_RL_30_val_2 )
                                and (gDay_Token_Trig_Rall_Stan_Count < 2)    // two triggers per day
                                and ( gH1_Token_Trig_Rall_Stan_Count < 1 )               // one trigger per hour
                            );




        {
        The momentum event happens *ONLY* at first tick of M5 bar!
        }

        { gTrigger_M5_Buy_Rally_Standard    := (   }
                                { gSetup_H1_Rally_Buy }
                            { and ( gMACDH_M5_val_2 < 0.0 ) }
                            { and ( gMACDH_M5_val_2 < gMACDH_M5_val_1 ) }
                            { and ( gMACDH_M5_val_2 < gMACDH_M5_val_3 ) }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }


        { gTrigger_M5_Sell_Rally_Standard    := (   }
                                { gSetup_H1_Rally_Sell }
                            { and ( gMACDH_M5_val_2 > 0.0 ) }
                            { and ( gMACDH_M5_val_2 > gMACDH_M5_val_1 ) }
                            { and ( gMACDH_M5_val_2 > gMACDH_M5_val_3 )                             }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }

        { gTrigger_M5_Buy_Rally_Standard  := ( }
                                    { gSetup_D1_Rally_Buy       // Ver_3_20180126 }
                            { and     gOversold_M5 }
                            { and     ( Close(2) < gBollingerM5_val_2_BotBand ) }
                            { and     ( Close(2) < gD1_RecentClose )      // Find the tips }
                            { and ( gMACDH_M5_val_2 < 0.0 ) }
                            { and ( gMACDH_M5_val_2 < gMACDH_M5_val_1 )       // V Pattern with M5 }
                            { and ( gMACDH_M5_val_2 < gMACDH_M5_val_3 )       // V Pattern with M5 }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two triggers per day }
                                { and ( gH1_Token_Trigger = false )           // one trigger per hour }
                            { ); }

        { gTrigger_M5_Sell_Rally_Standard :=  ( }
                                    { gSetup_D1_Rally_Sell }
                            { and     gOverbought_M5 }
                            { and     ( Close(2) > gBollingerM5_val_2_TopBand ) }
                            { and     ( Close(2) > gD1_RecentClose )      // Find the antenna }
                            { and ( gMACDH_M5_val_2 > 0.0 ) }
                            { and ( gMACDH_M5_val_2 > gMACDH_M5_val_1 )   // inverted-V with M5 }
                            { and ( gMACDH_M5_val_2 > gMACDH_M5_val_3 )   // inverted-V with M5 }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two triggers per day }
                                { and ( gH1_Token_Trigger = false )               // one trigger per hour }
                            { ); }




        { gTrigger_M5_Buy_Rally_Standard  := ( }
                                    { gSetup_D1_Rally_Buy       // Ver_3_20180126 }
                            { and     gOversold_M5 }
                            { and     ( Close(2) < gBollingerM5_val_2_BotBand ) }
                            { and     ( Close(2) < gD1_RecentClose )      // Find the tips }
                            { and ( gM5_RL_10_val_1 >  gM5_RL_30_val_1 ) }
                            { and ( gM5_RL_10_val_2 <= gM5_RL_30_val_2 ) }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two triggers per day }
                                { and ( gH1_Token_Trigger = false )           // one trigger per hour }
                            { ); }

        { gTrigger_M5_Sell_Rally_Standard :=  ( }
                                    { gSetup_D1_Rally_Sell }
                            { and     gOverbought_M5 }
                            { and     ( Close(2) > gBollingerM5_val_2_TopBand ) }
                            { and     ( Close(2) > gD1_RecentClose )      // Find the antenna }
                            { and ( gM5_RL_10_val_1 <  gM5_RL_30_val_1 ) }
                            { and ( gM5_RL_10_val_2 >= gM5_RL_30_val_2 ) }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two triggers per day }
                                { and ( gH1_Token_Trigger = false )               // one trigger per hour }
                            { ); }

        { gTrigger_M5_Buy_Rally_Standard    := (   }
                                { gSetup_H1_Rally_Buy }
                            { and ( gRSI3_M5_val_1 > 50.0 ) }
                            { and ( gRSI3_M5_val_2 <= 50.0 )                             }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }


        { gTrigger_M5_Sell_Rally_Standard    := (   }
                                { gSetup_H1_Rally_Sell                             }
                            { and ( gRSI3_M5_val_1 < 50.0 ) }
                            { and ( gRSI3_M5_val_2 >= 50.0 ) }
                                { and ( gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1 )                             }
                                { and ( gH1_Token_Trigger = false ) }
                { ); }

        { gTrigger_M5_Buy_Rally_Standard  := ( }
                                    { gSetup_D1_Rally_Buy       // Ver_3_20180126  }
                                { and gOversold_M5 }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two opportunities }
                                { and (gRSI3_M5_MomentumEvent = MOMEN_UP) }
                            { ); }

        { gTrigger_M5_Sell_Rally_Standard :=  ( }
                                    { gSetup_D1_Rally_Sell }
                                { and gOverbought_M5 }
                                { and (gDailyToken_Seq_1_rule_1 or gDailyToken_Seq_2_rule_1)    // two opportunities }
                                { and (gRSI3_M5_MomentumEvent = MOMEN_DOWN) }
                            { ); }



        // Cancel daily setups for this trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Rally_Standard then
        begin

            // Increase hourly token
            Inc( gH1_Token_Trig_Rall_Stan_Count );

            // Increase daily token
            Inc( gDay_Token_Trig_Rall_Stan_Count );

            // After one trigger, cancel the gOversold_M5
            gOversold_M5    := false ;

        end;

        if gTrigger_M5_Sell_Rally_Standard then
        begin

            // Increase hourly token
            Inc( gH1_Token_Trig_Rall_Stan_Count );

            // Increase daily token
            Inc( gDay_Token_Trig_Rall_Stan_Count );

            // After one trigger, cancel gOverbought_M5
            gOverbought_M5 := false ;

        end;



        {**********  ADD PRINTS FOR trigger settings ***********}

                if gTrigger_M5_Buy_Rally_Standard then
                begin
                    Str( gTrigger_M5_Buy_Rally_Standard , _text );
                    { Print('gTrigger_M5_Buy_Rally_Standard: ' + _text ); }
                end;

                if gTrigger_M5_Sell_Rally_Standard then
                begin
                    Str( gTrigger_M5_Sell_Rally_Standard , _text );
                    { Print('gTrigger_M5_Sell_Rally_Standard: ' + _text ); }
                end;

    end;




    // MARKING THE CHART WITH TRIGGER M5 - RALLY
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_RALLY_STANDARD

    if gTrigger_M5_Buy_Rally_Standard then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        { Print(  '[ENTRY_MANAGEMENT_RALLY_STANDARD]: 1st Tick M5 BUY Signal ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' + }
                { 'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' + }
                { 'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 ) }
                { //'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 ) }
                { ); }

        gTextName := 'TGR_RALLSTAN_B_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, 'x', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Rally_Standard then
    begin

        { Print(  '[ENTRY_MANAGEMENT_RALLY_STANDARD]: 1st Tick M5 SELL Signal ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' + }
                { 'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' + }
                { 'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 ) }
                { //'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 ) }
                { ); }

        gTextName := 'TGR_RALLSTAN_S_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
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




procedure ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC ; stdcall ;
var
        _text               :   string      ;
        _signal_EMA_Buy     :   boolean     ;
        _signal_RegLin_Buy  :   boolean     ;
        _signal_EMA_Sell    :   boolean     ;
        _signal_RegLin_Sell :   boolean     ;

begin

    if (gMarketMode <> RALLY) and (gMarketMode <> CANTTELL_RALLY_OR_JAGGY) then exit ;

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
    // ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC


    if gBarName_D1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1

        // Set setup FALSE daily until retracement below recent close

        gM5_Setup_BollBand_Overbought   := false ;
        gM5_Setup_BollBand_Oversold     := false ;


        // Set daily token to zero at opening bar of D1
        gDay_Token_Trig_Rall_Extr_Main_Count  := 0    ;
        gDay_Token_Trig_Rall_Extr_Tand_Count  := 0    ;
        gDay_Token_Trig_Rall_Extr_All__Count  := 0    ;


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


        { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: First Tick D1 ' + }
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

                if gSetup_D1_Rally_Buy then
                begin
                    Str( gSetup_D1_Rally_Buy , _text );
                    { Print( 'gSetup_D1_Rally_Buy EXTR_RETR: ' + _text ); }
                end;

                if gSetup_D1_Rally_Sell then
                begin
                    Str( gSetup_D1_Rally_Sell , _text );
                    { Print( 'gSetup_D1_Rally_Sell EXTR_RETR: ' + _text ); }
                end;

                if gSetup_D1_StayAway then
                begin
                    Str( gSetup_D1_StayAway , _text );
                    { Print( 'gSetup_D1_StayAway EXTR_RETR: ' + _text ); }
                end;

            end;



    // SETUP H1 - RALLY
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC


    if gBarName_H1_FirstTick then
    begin

        { Left as placeholder }

        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );


        gH1_Token_Trig_Rall_Extr_Main_Count := 0 ;
        gH1_Token_Trig_Rall_Extr_Tand_Count := 0 ;
        { one hour only one entry }


        {
        Need older logic: refer to
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - MultiForexScale\PowerTool 6\PT6_FT3_v2_20180114\
            Powertool6_v2_20180114.pas
        }



        gRSI7_H1_val_1      := GetIndicatorValue( gRSI7_H1_Handle , 1 , 0 ) ;
        gRSI7_H1_val_2      := GetIndicatorValue( gRSI7_H1_Handle , 2 , 0 ) ;

        { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: 1st Tick H1 ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )           + ' / ' + }
                { 'Open(1)-H1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )                   + ' / ' + }
                { 'Close(1)-H1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )                  + ' / ' + }
                { 'RSI7-H1(1): '  + FloatToStrF( gRSI7_H1_val_1, ffNumber , 7 , 2 )    + ' / ' + }
                { 'RSI7-H1(2): '  + FloatToStrF( gRSI7_H1_val_2, ffNumber , 7 , 2 ) }
                { ); }


        gH1_Setup_Rall_Extr_Buy := ( // First hour
                            (
                                    gSetup_D1_Rally_Buy
                                and ( gRSI7_H1_val_1 < 30.0 )
                            )
                            or
                            (       // Second hour ; in case cross down is happen later
                                    gSetup_D1_Rally_Buy
                                and ( gRSI7_H1_val_2 < 30.0 )
                            )
                    );

        gH1_Setup_Rall_Extr_Sell := ( // First hour
                            (
                                    gSetup_D1_Rally_Sell
                                and ( gRSI7_H1_val_1 > 70.0 )
                            )
                            or
                            (       // Second hour ; in case cross down is happen later
                                    gSetup_D1_Rally_Sell
                                and ( gRSI7_H1_val_2 > 70.0 )
                            )
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

                { Print('*** gBarName_H1_FirstTick RALLY event found: ***'); }

                { Str( gSetup_D1_Rally_Buy , _text ); }
                { Print( 'gSetup_D1_Rally_Buy EXTR_RETR: ' + _text ); }
                { Str( gSetup_D1_Rally_Sell , _text ); }
                { Print( 'gSetup_D1_Rally_Sell EXTR_RETR: ' + _text ); }

                if gH1_Setup_Rall_Extr_Buy then
                begin
                    Str( gH1_Setup_Rall_Extr_Buy , _text );
                    { Print('gH1_Setup_Rall_Extr_Buy: ' + _text ); }
                end;

                if gH1_Setup_Rall_Extr_Sell then
                begin
                    Str( gH1_Setup_Rall_Extr_Sell , _text );
                    { Print('gH1_Setup_Rall_Extr_Sell: ' + _text ); }
                end;

            end;








    // Return the timeframe back to M5
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

    // TRIGGER M5 - RALLY
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC


    if gBarName_M5_FirstTick then
    begin



        // RSI3 MOMEN_UP / MOMEN_DOWN
        // -------------------------------------------

        { gRSI3_M5_val_1      := GetIndicatorValue( gRSI3_M5_Handle , 1 , 0 ); }
        { gRSI3_M5_val_2      := GetIndicatorValue( gRSI3_M5_Handle , 2 , 0 ); }


        { gRSI3_M5_MomentumEvent := MOMEN_NEUTRAL; }
        { if ( (gRSI3_M5_val_1 > 70.0) and (gRSI3_M5_val_2 <= 70.0) ) then }
            { gRSI3_M5_MomentumEvent := MOMEN_UP }
        { else if ( (gRSI3_M5_val_1 < 30.0) and (gRSI3_M5_val_2 >= 30.0) ) then }
            { gRSI3_M5_MomentumEvent := MOMEN_DOWN; }


        { gMACDH_M5_val_1     := GetIndicatorValue( gMACDH_M5_Handle, 1 , 4 ); }
        { gMACDH_M5_val_2     := GetIndicatorValue( gMACDH_M5_Handle, 2 , 4 ); }
        { gMACDH_M5_val_3     := GetIndicatorValue( gMACDH_M5_Handle, 3 , 4 ); }



        gBollingerM5_val_1_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 0 );
        gBollingerM5_val_1_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 1 );
        gBollingerM5_val_1_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 2 );

        gBollingerM5_val_2_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 0 );
        gBollingerM5_val_2_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 1 );
        gBollingerM5_val_2_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 2 );

        gBollingerM5_val_3_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 0 );
        gBollingerM5_val_3_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 1 );
        gBollingerM5_val_3_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 2 );


        // Regression Line
        gM5_RL_10_val_1     :=  GetIndicatorValue( gM5_RL_10_Handle , 1 , 0 );
        gM5_RL_10_val_2     :=  GetIndicatorValue( gM5_RL_10_Handle , 2 , 0 );

        gM5_RL_30_val_1     :=  GetIndicatorValue( gM5_RL_30_Handle , 1 , 0 );
        gM5_RL_30_val_2     :=  GetIndicatorValue( gM5_RL_30_Handle , 2 , 0 );


        // Moving Average
        gM5_EMA_5_val_1     :=  GetIndicatorValue( gM5_EMA_5_Handle , 1 , 0 );
        gM5_EMA_5_val_2     :=  GetIndicatorValue( gM5_EMA_5_Handle , 2 , 0 );

        gM5_EMA_20_val_1    :=  GetIndicatorValue( gM5_EMA_20_Handle , 1 , 0 );
        gM5_EMA_20_val_2    :=  GetIndicatorValue( gM5_EMA_20_Handle , 2 , 0 );



        _signal_RegLin_Buy  := false ;
        _signal_EMA_Buy     := false ;
        _signal_RegLin_Sell := false ;
        _signal_EMA_Sell    := false ;



        // Overbought and oversold rule
        // -------------------------------------------

        if not gM5_Setup_BollBand_Overbought then
        begin
            gM5_Setup_BollBand_Overbought := (
                                    gM5_RL_10_val_1 > gBollingerM5_val_1_TopBand
                        );
            // the Overbought will stay true until there is trigger for EMA
            // or until the next day
            // the flow skips this chunk when the overbought is true
        end;

        if not gM5_Setup_BollBand_Oversold then
        begin
            gM5_Setup_BollBand_Oversold := (
                                    gM5_RL_10_val_1 < gBollingerM5_val_1_BotBand
                        );
            // the oversold will stay true until there is trigger for EMA
            // or until the next day
            // the flow skips this chunk when the oversold is true
        end;


        { if (gH1_Setup_Rall_Extr_Buy or gH1_Setup_Rall_Extr_Sell) then }
        { begin }

            { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: 1st Tick M5 ' + }
                    { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )           + ' / ' + }
                    { 'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )                   + ' / ' + }
                    { 'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )                   }
                    { ); }

            { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: 1st Tick M5 ' + }
                    { 'gM5_RL_10_val_1: '     + FloatToStrF( gM5_RL_10_val_1 , ffFixed , 12 , 4 )    + ' / ' + }
                    { 'gM5_RL_30_val_1: '     + FloatToStrF( gM5_RL_30_val_1 , ffFixed , 12 , 4 )    + ' / ' + }
                    { 'gM5_RL_10_val_2: '     + FloatToStrF( gM5_RL_10_val_2 , ffFixed , 12 , 4 )    + ' / ' + }
                    { 'gM5_RL_30_val_2: '     + FloatToStrF( gM5_RL_30_val_2 , ffFixed , 12 , 4 ) }
                  { ); }


            { Print(  'gDay_Token_Trig_Rall_Extr_Main_Count: ' +  IntToStr( gDay_Token_Trig_Rall_Extr_Main_Count ) + ' / ' + }
                    { 'gH1_Token_Trig_Rall_Extr_Main_Count: ' + IntToStr(gH1_Token_Trig_Rall_Extr_Main_Count) }
                    { ); }

            { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: 1st Tick M5 ' + }
                    { 'gM5_EMA_5_val_1: '     + FloatToStrF( gM5_EMA_5_val_1 , ffFixed , 9, 4 )    + ' / ' + }
                    { 'gM5_EMA_20_val_1: '    + FloatToStrF( gM5_EMA_20_val_1, ffFixed , 9, 4 ) }
                    { ); }
        { end; }



        { if (gH1_Setup_Rall_Extr_Buy or gH1_Setup_Rall_Extr_Sell) then }
        { begin }
            { if ( gM5_RL_10_val_1 > gM5_RL_30_val_1 ) then gM5_RL10_RL30_Posi_Curr := 'ABOVE'; }
            { if ( gM5_RL_10_val_1 < gM5_RL_30_val_1 ) then gM5_RL10_RL30_Posi_Curr := 'BELOW'; }
        { end; }


        if (gH1_Setup_Rall_Extr_Buy or gH1_Setup_Rall_Extr_Sell) then
        begin
            if    ( gM5_RL_10_val_1 > gM5_RL_30_val_1 ) then gM5_RL10_RL30_Posi_Curr := 'ABOVE';
            if    ( gM5_RL_10_val_1 < gM5_RL_30_val_1 ) then gM5_RL10_RL30_Posi_Curr := 'BELOW';
            // Print( 'CURR: ---' + gM5_RL10_RL30_Posi_Curr + '--- ' + 'PREV: ---' + gM5_RL10_RL30_Posi_Prev + '---' ) ;
        end;

        // Main signal buy
        gTrigger_M5_Buy_Rall_Extr_retrac :=   (       // Main signal
                                    gH1_Setup_Rall_Extr_Buy
                                { and ( gM5_RL_10_val_1 >  gM5_RL_30_val_1 ) }
                                { and ( gM5_RL_10_val_2 <= gM5_RL_30_val_2 ) }
                                and ( gM5_RL10_RL30_Posi_Curr = 'ABOVE' )
                                and ( gM5_RL10_RL30_Posi_Prev = 'BELOW' )
                                and ( gDay_Token_Trig_Rall_Extr_Main_Count < 2 )        // two main triggers per day
                                and (  gH1_Token_Trig_Rall_Extr_Main_Count < 1 )        // one trigger per hour
                                and ( gDay_Token_Trig_Rall_Extr_All__Count < 4 )        // max all 4 triggers per day
                        );

                // Tag the signal if coming from regression line trigger
                // The tag will be used for marker
                _signal_RegLin_Buy := ( gTrigger_M5_Buy_Rall_Extr_retrac
                                and ( gM5_RL10_RL30_Posi_Curr = 'ABOVE' )
                                and ( gM5_RL10_RL30_Posi_Prev = 'BELOW' )
                        );





        // Tandem signal buy
        gTrigger_M5_Buy_Rall_Extr_retrac :=
                        gTrigger_M5_Buy_Rall_Extr_retrac        // From Signal Main, so that Signal Main does not cancel
                            or
                            (       // Tandem signal
                                        gH1_Setup_Rall_Extr_Buy
                                    and gM5_Setup_BollBand_Oversold
                                    and ( gM5_EMA_5_val_1  >  gM5_EMA_20_val_1 )
                                    and ( gM5_EMA_5_val_2  <= gM5_EMA_20_val_2 )
                                    and ( gDay_Token_Trig_Rall_Extr_Tand_Count < 2 )        // three triggers per day
                                    and (  gH1_Token_Trig_Rall_Extr_Tand_Count < 1 )        // one trigger per hour
                                    and ( gDay_Token_Trig_Rall_Extr_All__Count < 4 )        // max all 4 triggers per day
                            );

                // Tag the signal if comeing from tandem trigger
                // the tag will be used to cancel oversold setup M5
                _signal_EMA_Buy := ( gTrigger_M5_Buy_Rall_Extr_retrac
                                and ( gM5_EMA_5_val_1 >  gM5_EMA_20_val_1 )
                                and ( gM5_EMA_5_val_2 <= gM5_EMA_20_val_2 )
                        );




        // Main signal sell
        gTrigger_M5_Sell_Rall_Extr_retrac :=   (      // Main signal
                                    gH1_Setup_Rall_Extr_Sell
                                and ( gM5_RL10_RL30_Posi_Curr = 'BELOW' )
                                and ( gM5_RL10_RL30_Posi_Prev = 'ABOVE' )
                                { and ( gM5_RL_10_val_1 <  gM5_RL_30_val_1 ) }
                                { and ( gM5_RL_10_val_2 >= gM5_RL_30_val_2 ) }
                                and ( gDay_Token_Trig_Rall_Extr_Main_Count < 2 )        // two triggers per day
                                and ( gH1_Token_Trig_Rall_Extr_Main_Count < 1 )         // one trigger per hour
                                and ( gDay_Token_Trig_Rall_Extr_All__Count < 4 )        // max all 4 triggers per day
                        );

                // Tag the signal if coming from regression line trigger
                // The tag will be used for marker
                _signal_RegLin_Sell := ( gTrigger_M5_Sell_Rall_Extr_retrac
                                and ( gM5_RL10_RL30_Posi_Curr = 'BELOW' )
                                and ( gM5_RL10_RL30_Posi_Prev = 'ABOVE' )
                        );



        // Tandem signal sell
        gTrigger_M5_Sell_Rall_Extr_retrac :=
                        gTrigger_M5_Sell_Rall_Extr_retrac       // From Signal Main, so that Signal Main does not cancel
                            or
                            (       // Tandem signal
                                        gH1_Setup_Rall_Extr_Sell
                                    and gM5_Setup_BollBand_Overbought
                                    and ( gM5_EMA_5_val_1 <  gM5_EMA_20_val_1 )
                                    and ( gM5_EMA_5_val_2 >= gM5_EMA_20_val_2 )
                                    and ( gDay_Token_Trig_Rall_Extr_Tand_Count < 2 )        // two triggers per day
                                    and ( gH1_Token_Trig_Rall_Extr_Tand_Count < 1 )         // one trigger per hour
                                    and ( gDay_Token_Trig_Rall_Extr_All__Count < 4 )        // max all 4 triggers per day

                            );

                // Tag the signal if comeing from tandem trigger
                // the tag will be used to cancel overbought setup M5
                _signal_EMA_Sell := ( gTrigger_M5_Sell_Rall_Extr_retrac
                                and ( gM5_EMA_5_val_1 <  gM5_EMA_20_val_1 )
                                and ( gM5_EMA_5_val_2 >= gM5_EMA_20_val_2 )
                        );


        // Cancel daily setups for this trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Rall_Extr_retrac then
        begin
            //  Increase daily token signal
            if _signal_EMA_Buy then
            begin
                // After tandem Moving Average signal, cancel the oversold
                gM5_Setup_BollBand_Oversold := false ;
                // Increase hourly token
                Inc(gH1_Token_Trig_Rall_Extr_Tand_Count);
                // Increase daily token
                Inc(gDay_Token_Trig_Rall_Extr_Tand_Count);
                // Increase daily token for all trades
                Inc(gDay_Token_Trig_Rall_Extr_All__Count);
            end
            else
            begin
                // Increase hourly token
                Inc(gH1_Token_Trig_Rall_Extr_Main_Count);
                // Increase daily token
                Inc(gDay_Token_Trig_Rall_Extr_Main_Count);
                // Increase daily token for all trades
                Inc(gDay_Token_Trig_Rall_Extr_All__Count);
            end;
        end;

        if gTrigger_M5_Sell_Rall_Extr_retrac then
        begin

            { Print( '*** BEFORE gDay_Token_Trig_Rall_Extr_Tand_Count: ' + IntToStr(gDay_Token_Trig_Rall_Extr_Tand_Count) ) ; }

            //  Increase daily token signal
            if _signal_EMA_Sell then
            begin
                // After tandem Moving Average signal, cancel the oversold
                gM5_Setup_BollBand_Overbought := false ;
                // Increase hourly token
                Inc(  gH1_Token_Trig_Rall_Extr_Tand_Count );
                // Increase daily token
                Inc( gDay_Token_Trig_Rall_Extr_Tand_Count );
                // Increase daily token for all trades
                Inc(gDay_Token_Trig_Rall_Extr_All__Count);
            end
            else
            begin
                // Increase hourly token
                Inc(  gH1_Token_Trig_Rall_Extr_Main_Count );
                // Increase daily token
                Inc( gDay_Token_Trig_Rall_Extr_Main_Count );
                // Increase daily token for all trades
                Inc(gDay_Token_Trig_Rall_Extr_All__Count);
            end;

            { Print( '*** AFTER gDay_Token_Trig_Rall_Extr_Tand_Count: ' + IntToStr(gDay_Token_Trig_Rall_Extr_Tand_Count) ) ; }

        end;



        {**********  ADD PRINTS FOR trigger settings ***********}

                if gTrigger_M5_Buy_Rall_Extr_retrac then
                begin
                    Str( gTrigger_M5_Buy_Rall_Extr_retrac , _text );
                    { Print('gTrigger_M5_Buy_Rall_Extr_retrac: ' + _text ); }
                    Str( _signal_EMA_Buy, _text  );
                    { Print('*** We want one signal TRUE, not BOTH: _signal_EMA_Buy: ' + _text ); }
                    Str( _signal_RegLin_Buy, _text  );
                    { Print('*** We want one signal TRUE, not BOTH: _signal_RegLin_Buy: ' + _text ); }
                end;

                if gTrigger_M5_Sell_Rall_Extr_retrac then
                begin
                    Str( gTrigger_M5_Sell_Rall_Extr_retrac , _text );
                    { Print('gTrigger_M5_Sell_Rall_Extr_retrac: ' + _text ); }
                end;


        // Assign Curr variable for Prev variable
        // -------------------------------------------

        gM5_RL10_RL30_Posi_Prev := gM5_RL10_RL30_Posi_Curr ;

    end;




    // MARKING THE CHART WITH TRIGGER M5 - RALLY
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC

    if gTrigger_M5_Buy_Rall_Extr_retrac then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: M5 BUY TRIGGER ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' + }
                { 'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' + }
                { 'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 ) }
                { //'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 ) }
                { ); }

        gTextName := 'TGRRALLEXTBUY_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            if _signal_EMA_Buy then
                ObjectSetText(gTextName, 'O', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            if _signal_RegLin_Buy then
                ObjectSetText(gTextName, '@', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Rall_Extr_retrac then
    begin

        { Print(  '[ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC]: M5 SELL TRIGGER ' + }
                { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' + }
                { 'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' + }
                { 'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 ) }
                { //'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 ) }
                { ); }

        gTextName := 'TGR_RALL_EXTR_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            if _signal_EMA_Sell then
                ObjectSetText(gTextName, 'O', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
            if _signal_RegLin_Sell then
                ObjectSetText(gTextName, '@', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
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


end;        // ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC








procedure ENTRY_MANAGEMENT_JAGGY ; stdcall ;
var
        _text               :   string      ;
begin

    if (gMarketMode <> JAGGY) and (gMarketMode <> CANTTELL_RALLY_OR_JAGGY) then exit ;

    {===================================================================================================}
    {  INDICATOR VALUE RETRIEVAL  }
    {===================================================================================================}
    { This procedure operates on the first tick of M5 }

    gATR_M5_val_1 := GetIndicatorValue( gATR_M5_Handle , 1, 0  );


    {===================================================================================================}
    {  SIGNAL GENERATION: Consider all setups, then trigger  }
    {===================================================================================================}



    // SETUP D1
    // -------------------------------------------
    // ENTRY_MANAGEMENT_JAGGY


    if gBarName_D1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1


        // Set daily tokens zero for the trigger on this rule
        gDay_Token_Trig_Jaggy_All_Count := 0    ;


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


        Print(  '[ENTRY_MANAGEMENT_JAGGY]: First Tick D1 ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-D1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-D1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'Driftline_D1: '+ FloatToStrF( gDriftline_D1_val_1 , ffFixed , 6, 4 )   + ' / ' +
                'BarWave_D1: '  + FloatToStrF( gBarWave_D1_val_1, ffNumber , 15 , 4 )
                );


        // Setup D1 Buy - JAGGY
        // -------------------------------------------

        gSetup_D1_Jaggy_Buy   :=  (   // Recent bar body is above driftline of D1
                                    (Open(1)    > gDriftline_D1_val_1)  // Above driftline
                                and (Close(1)   > gDriftline_D1_val_1)
                                and (Open(1) >= Close(1) )              // Red bar
                                and (gD1_DayName_Curr <> 'Sun')         // Not Sunday
                                // and (gBarWave_D1_val_1 > gBarWave_D1_val_2)
                            )
                                // Monday Starting Trade
                                or
                                (
                                        (Open(2)    > gDriftline_D1_val_2)  // Friday / Saturday above driftline
                                    and (Close(2)   > gDriftline_D1_val_2)
                                    and (Open(2) >= Close(2) )              // Red bar
                                    and (gD1_DayName_Curr = 'Mon')          // Monday starting trade
                                );



        // Setup D1 Sell - JAGGY
        // -------------------------------------------


        gSetup_D1_Jaggy_Sell  :=  (   // Recent bar body is below driftline of D1
                                    (Open(1)    < gDriftline_D1_val_1)      // Below driftline
                                and (Close(1)   < gDriftline_D1_val_1)
                                and (Open(1) <= Close(1) )                  // Blue bar
                                and (gD1_DayName_Curr <> 'Sun')             // Not Sunday
                            )
                                or
                                (
                                        (Open(2)    < gDriftline_D1_val_2)  // Below driftline
                                    and (Close(2)   < gDriftline_D1_val_2)
                                    and (Open(2) <= Close(2) )              // Blue bar
                                    and (gD1_DayName_Curr = 'Mon')          // Monday starting trade
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

                if gSetup_D1_Jaggy_Buy then
                begin
                    Str( gSetup_D1_Jaggy_Buy , _text );
                    Print( 'gSetup_D1_Jaggy_Buy - JAGGY: ' + _text );
                end;

                if gSetup_D1_Jaggy_Sell then
                begin
                    Str( gSetup_D1_Jaggy_Sell , _text );
                    Print( 'gSetup_D1_Jaggy_Sell - JAGGY: ' + _text );
                end;

                if gSetup_D1_StayAway then
                begin
                    Str( gSetup_D1_StayAway , _text );
                    Print( 'gSetup_D1_StayAway - JAGGY: ' + _text );
                end;

            end;



    // SETUP H1
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_JAGGY

    if gBarName_H1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );

        gH1_Token_Trig_Jaggy_Count  := 0 ;
        { one hour only one entry }


        gRSI7_H1_val_1      := GetIndicatorValue( gRSI7_H1_Handle , 1 , 0 ) ;
        gRSI7_H1_val_2      := GetIndicatorValue( gRSI7_H1_Handle , 2 , 0 ) ;


        gH1_OverBought      := ( gRSI7_H1_val_1 > (70.0 + 2.0) );       // Deeper retracement
        gH1_OverSold        := ( gRSI7_H1_val_1 < (30.0 - 2.0) );       // Deeper retracement



        Print(  '[ENTRY_MANAGEMENT_JAGGY]: First Tick H1 SETUP ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-H1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-H1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'RSI7-H1(1): '+ FloatToStrF( gRSI7_H1_val_1 , ffFixed , 7, 4 )
                );


        gSetup_H1_Jaggy_Buy     := ( gSetup_D1_Jaggy_Buy
                                and  gH1_OverSold
                        );


        gSetup_H1_Jaggy_Sell    := ( gSetup_D1_Jaggy_Sell
                                and  gH1_OverBought
                        );

    end;        // End of { if gBarName_H1_FirstTick then }


            // SETUP H1 MONITORING
            // -------------------------------------------------------------------------
            // This is to monitor H1 Bar length

            if gBarName_H1_FirstTick then
            begin
                { Print('*** gBarName_H1_FirstTick event found JAGGY ENTRY: ***'); }
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

    // TRIGGER M5
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_JAGGY


    if gBarName_M5_FirstTick then
    begin

        gBollingerM5_val_1_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 0 );
        gBollingerM5_val_1_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 1 );
        gBollingerM5_val_1_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 1 , 2 );

        gBollingerM5_val_2_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 0 );
        gBollingerM5_val_2_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 1 );
        gBollingerM5_val_2_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 2 , 2 );

        gBollingerM5_val_3_TopBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 0 );
        gBollingerM5_val_3_MidBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 1 );
        gBollingerM5_val_3_BotBand :=  GetIndicatorValue( gBollingerM5_Handle , 3 , 2 );


        // Regression Line
        gM5_RL_10_val_1     :=  GetIndicatorValue( gM5_RL_10_Handle , 1 , 0 );
        gM5_RL_10_val_2     :=  GetIndicatorValue( gM5_RL_10_Handle , 2 , 0 );
        gM5_RL_10_val_3     :=  GetIndicatorValue( gM5_RL_10_Handle , 3 , 0 );

        gM5_RL_30_val_1     :=  GetIndicatorValue( gM5_RL_30_Handle , 1 , 0 );
        gM5_RL_30_val_2     :=  GetIndicatorValue( gM5_RL_30_Handle , 2 , 0 );


        // M5 BollingerBands Overbought or Oversold
        // This is to avoid entry signal at non active market. Non active market meanings
        // the movement is WITHIN BollingerBands 1 standard deviation

        gM5_Setup_BollBand_Overbought := (
                                    ( gM5_RL_10_val_2 > gBollingerM5_val_2_BotBand )
                                or  ( gM5_RL_10_val_3 > gBollingerM5_val_3_BotBand )
                            );

        gM5_Setup_BollBand_Oversold   := (
                                    ( gM5_RL_10_val_2 < gBollingerM5_val_2_BotBand )
                                or  ( gM5_RL_10_val_3 < gBollingerM5_val_3_BotBand )
                            );



        gTrigger_M5_Buy_Market_Jaggy   := ( gSetup_H1_Jaggy_Buy
                                and ( gM5_RL_10_val_1 >  gM5_RL_30_val_1 )      // Cross-over of Regression Line
                                and ( gM5_RL_10_val_2 <= gM5_RL_30_val_2 )      // Cross-over of Regression Line
                                and ( Close(1) < gD1_RecentClose )              // Oversold price, deep retracement
                                and gM5_Setup_BollBand_Oversold                 // Oversold BollingerBands,
                                                                                // to exclude false signal of inactive market
                                and ( gH1_Token_Trig_Jaggy_Count < 1 )          // Hourly limitor
                                and ( gDay_Token_Trig_Jaggy_All_Count < 2 )     // Daily signal limitor
                            );
        gTrigger_M5_Sell_Market_Jaggy  := ( gSetup_H1_Jaggy_Sell
                                and ( gM5_RL_10_val_1 <  gM5_RL_30_val_1 )      // Cross-under of Regression Line
                                and ( gM5_RL_10_val_2 >= gM5_RL_30_val_2 )      // Cross-under of Regression Line
                                and ( Close(1) >  gD1_RecentClose )             // Overbought price, deep retracement
                                and gM5_Setup_BollBand_Overbought               // Oversold BollingerBands,
                                                                                // to exclude false signal of inactive market
                                and ( gH1_Token_Trig_Jaggy_Count < 1 )          // Hourly limitor
                                and ( gDay_Token_Trig_Jaggy_All_Count < 2 )     // Daily signal limitor

                            );


            // DEBUGGING
            // -------------------------------------------

            { if gSetup_H1_Jaggy_Sell then }
            { begin }
                { Print(  'DEBUG_[ENTRY_MANAGEMENT_JAGGY]: M5 Setup for Selling ' + }
                        { 'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )           + ' / ' +                          }
                        { 'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )                  + ' / ' + }
                        { 'RL(10)_val_1: '  + FloatToStrF( gM5_RL_10_val_1, ffNumber , 9 , 4 )    + ' / ' + }
                        { 'RL(30)_val_1: '  + FloatToStrF( gM5_RL_30_val_1, ffNumber , 9 , 4 ) }
                        { );             }
            { end; }



        { gTrigger_M5_Buy_Market_Jaggy   := ( gSetup_H1_Jaggy_Buy }
                                { and ( (gRSI3_M5_val_1 > 50.0) and ( gRSI3_M5_val_2 <= 50.0 ) ) }
                                { and ( gH1_Token_Trig_Jaggy_Count < 1 )                                 }
                                { and ( gDay_Token_Trig_Jaggy_All_Count < 2 ) }
                            { ); }
        { gTrigger_M5_Sell_Market_Jaggy  := ( gSetup_H1_Jaggy_Sell }
                                { and ( (gRSI3_M5_val_1 < 50.0) and ( gRSI3_M5_val_2 >= 50.0 ) ) }
                                { and ( gH1_Token_Trig_Jaggy_Count < 1 )                                 }
                                { and ( gDay_Token_Trig_Jaggy_All_Count < 2 ) }
                            { ); }


        // Control daily and hourly trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Market_Jaggy then
        begin
            Inc( gDay_Token_Trig_Jaggy_All_Count );
            Inc( gH1_Token_Trig_Jaggy_Count );
        end;

        if gTrigger_M5_Sell_Market_Jaggy then
        begin
            Inc( gDay_Token_Trig_Jaggy_All_Count );
            Inc( gH1_Token_Trig_Jaggy_Count );
        end;



        {**********  ADD PRINTS FOR trigger settings ***********}

                if gTrigger_M5_Buy_Market_Jaggy then
                begin
                    Str( gTrigger_M5_Buy_Market_Jaggy , _text );
                    Print('gTrigger_M5_Buy_Market_Jaggy: ' + _text );
                end;

                if gTrigger_M5_Sell_Market_Jaggy then
                begin
                    Str( gTrigger_M5_Sell_Market_Jaggy , _text );
                    Print('gTrigger_M5_Sell_Market_Jaggy: ' + _text );
                end;

    end;    // End of [ if gBarName_M5_FirstTick then ]




    // MARKING THE CHART WITH TRIGGER M5
    // ---------------------------------------------------------------------------------
    // ENTRY_MANAGEMENT_JAGGY

    if gTrigger_M5_Buy_Market_Jaggy then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        Print(  '[ENTRY_MANAGEMENT_JAGGY]: M5 BUY Trigger ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              {+ ' / ' +}
                { 'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 ) }
                );

        gTextName := 'TGR_JAGGY_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, '#', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Market_Jaggy then
    begin

        Print(  '[ENTRY_MANAGEMENT_JAGGY]: M5 SELL Trigger ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-M5: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              {+ ' / ' +}
                { 'RSI3(1): '     + FloatToStrF( gRSI3_M5_val_1 , ffFixed , 6, 2 ) }
                );

        gTextName := 'TGR_JAGGY_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, '#', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
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


end;        // ENTRY_MANAGEMENT_JAGGY







procedure ENTRY_MANAGEMENT_FLIPFLOP ; stdcall ;
var
        _text       :   string      ;
begin

    if (gMarketMode <> FLIPFLOP) then exit ;

    {===================================================================================================}
    {  INDICATOR VALUE RETRIEVAL  }
    {===================================================================================================}
    { This procedure operates on the first tick of M5 }

    gATR_M5_val_1 := GetIndicatorValue( gATR_M5_Handle , 1, 0  );


    {===================================================================================================}
    {  SIGNAL GENERATION: Consider all setups, then trigger  }
    {===================================================================================================}

    {
        Use ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC
        as base to derive the FLIPFLOP
    }


    // SETUP D1 - FLIPFLOP
    // -------------------------------------------
    // ENTRY_MANAGEMENT_FLIPFLOP

    if gBarName_D1_FirstTick then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1


        // Set daily token to zero at opening bar of D1
        gDay_Token_Trig_FlipF_All_Count := 0 ;


        // Recent closing price
        gD1_RecentClose     := Close(1);


        gDriftline_D1_val_1 := GetIndicatorValue( gDriftline_D1_Handle , 3, 0 );
        gDriftline_D1_val_2 := GetIndicatorValue( gDriftline_D1_Handle , 4 , 0 );
        { The index for driftline value 1 recent bar has to be 3, not 1 ! }
        { The index for driftline value 2 recent bar has to be 4, not 2 !

        { gBarWave_D1_val_1   := GetIndicatorValue( gBarWave_D1_Handle , 1, 4 ); }
        { gBarWave_D1_val_2   := GetIndicatorValue( gBarWave_D1_Handle , 2, 4 ); }


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
                            );


        // Setup D1 Sell - FLIPFLOP
        // -------------------------------------------

        gSetup_D1_FlipFlop_Sell := (   // Recent bar body is below driftline of D1
                                    (Open(1)    < gDriftline_D1_val_1)
                                and (Close(1)   < gDriftline_D1_val_1)
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
                if gSetup_D1_FlipFlop_Buy then
                begin
                    Str( gSetup_D1_FlipFlop_Buy , _text );
                    Print( 'gSetup_D1_FlipFlop_Buy: ' + _text );
                end;

                if gSetup_D1_FlipFlop_Sell then
                begin
                    Str( gSetup_D1_FlipFlop_Sell , _text );
                    Print( 'gSetup_D1_FlipFlop_Sell: ' + _text );
                end;

                if gSetup_D1_StayAway then
                begin
                    Str( gSetup_D1_StayAway , _text );
                    Print( 'gSetup_D1_StayAway - FLIPFLOP: ' + _text );
                end;
            end;



    // SETUP H1 - FLIPFLOP
    // ---------------------------------------------------------------------------------
    // *** IMPORTANT: Ver_3_20180126 does not use H1 !!!

    if gBarName_H1_FirstTick then
    begin


        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );

        // Reset token for trigger every hour
        gH1_Token_Trig_FlipF_Count := 0 ;

        gRSI7_H1_val_1      := GetIndicatorValue( gRSI7_H1_Handle , 1 , 0 ) ;
        gRSI7_H1_val_2      := GetIndicatorValue( gRSI7_H1_Handle , 2 , 0 ) ;


        Print(  '[ENTRY_MANAGEMENT_FLIPFLOP]: H1 SETUP ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-H1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-H1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'gRSI7_H1_val_1: '+ FloatToStrF( gRSI7_H1_val_1 , ffFixed , 6, 4 )
                );

        gSetup_H1_FlipFlop_Buy  := (
                                    gSetup_D1_FlipFlop_Buy
                                and ( gRSI7_H1_val_1 <= (30.0-3.0) )        // Oversold under 27.0
            );


        gSetup_H1_FlipFlop_Sell   := (
                                    gSetup_D1_FlipFlop_Sell
                                and ( gRSI7_H1_val_1 >= (70.0+3.0) )        // Overbought above 73.0
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



        { gRSI3_M5_val_1      := GetIndicatorValue( gRSI3_M5_Handle , 1 , 0 ); }
        { gRSI3_M5_val_2      := GetIndicatorValue( gRSI3_M5_Handle , 2 , 0 ); }


        // Regression Line
        gM5_RL_10_val_1     :=  GetIndicatorValue( gM5_RL_10_Handle , 1 , 0 );
        gM5_RL_10_val_2     :=  GetIndicatorValue( gM5_RL_10_Handle , 2 , 0 );

        gM5_RL_30_val_1     :=  GetIndicatorValue( gM5_RL_30_Handle , 1 , 0 );
        gM5_RL_30_val_2     :=  GetIndicatorValue( gM5_RL_30_Handle , 2 , 0 );


        gTrigger_M5_Buy_Market_FlipFlop   := ( gSetup_H1_FlipFlop_Buy
                                and ( gM5_RL_10_val_1 >  gM5_RL_30_val_1 )
                                and ( gM5_RL_10_val_2 <= gM5_RL_30_val_2 )
                                and ( gDay_Token_Trig_FlipF_All_Count < 2 )
                                and ( gH1_Token_Trig_FlipF_Count < 1 )
                            );


        gTrigger_M5_Sell_Market_FlipFlop  := ( gSetup_H1_FlipFlop_Sell
                                and ( gM5_RL_10_val_1 <  gM5_RL_30_val_1 )
                                and ( gM5_RL_10_val_2 >= gM5_RL_30_val_2 )
                                and ( gDay_Token_Trig_FlipF_All_Count < 2 )
                                and ( gH1_Token_Trig_FlipF_Count < 1 )
                            );



        // Cancel setups for this trigger
        // -------------------------------------------

        if gTrigger_M5_Buy_Market_FlipFlop then
        begin
            Inc( gDay_Token_Trig_FlipF_All_Count );
            Inc( gH1_Token_Trig_FlipF_Count )
        end;

        if gTrigger_M5_Sell_Market_FlipFlop then
        begin
            Inc( gDay_Token_Trig_FlipF_All_Count );
            Inc( gH1_Token_Trig_FlipF_Count )
        end;

        {**********  ADD PRINTS FOR trigger settings ***********}

    end;



    // MARKING THE CHART WITH TRIGGER M5 - FLIPFLOP
    // ---------------------------------------------------------------------------------

    if gTrigger_M5_Buy_Market_FlipFlop then
    begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );

        Print(  '[ENTRY_MANAGEMENT_FLIPFLOP]: M5 BUY Trigger ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )           + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )                  + ' / ' +
                'gM5_RL_10_val_1: '  + FloatToStrF( gM5_RL_10_val_1 , ffFixed , 9, 4 )      + ' / ' +
                'gM5_RL_30_val_1: '  + FloatToStrF( gM5_RL_30_val_1 , ffFixed , 9, 4 )
                );

        gTextName := 'TGR_FLIPFLOP_' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, '*', 14, 'Consolas', clBlue);  // Possible placement for PowerTool trade long
            ObjectSet(gTextName, OBJPROP_VALIGNMENT, tlCenter);     // StrategyInterfaceUnit
            ObjectSet(gTextName, OBJPROP_HALIGNMENT, taCenter );    // StrategyInterfaceUnit
        end;

    end
    else if gTrigger_M5_Sell_Market_FlipFlop then
    begin

        Print(  '[ENTRY_MANAGEMENT_FLIPFLOP]: M5 SELL Trigger ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )           + ' / ' +
                'Close(1)-M5: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )                  + ' / ' +
                'gM5_RL_10_val_1: '  + FloatToStrF( gM5_RL_10_val_1 , ffFixed , 9, 4 )      + ' / ' +
                'gM5_RL_30_val_1: '  + FloatToStrF( gM5_RL_30_val_1 , ffFixed , 9, 4 )
                );

        gTextName := 'TGR_FLIPFLOP__' + FormatDateTime('YYMMDD-hh-nn', TimeCurrent);
        if ObjectExists( gTextName ) then ObjectDelete( gTextName );
        if not(ObjectExists( gTextName )) then
        begin
            ObjectCreate( gTextName, obj_Text, 0, TimeCurrent, (Bid+Ask)/2 );
            ObjectSetText(gTextName, '*', 14, 'Consolas', clRed);  // Possible placement for PowerTool trade long
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
{***** FILE READER FUNCTION *****}
{-------------------------------------------------------------------------------------------------------}



function VarFile_Exists( varName: string ): boolean ;
var _fullname   : string ;    
begin    
    _fullname := (gVarFileDirectory + varName + '.txt')   ;
    result := FileExists( _fullname );
end;



function VarFile_Read_Then_Delete( varName: string ): string ;
var _text       : string ;
    _fullname   : string ;
    _fileVar    : TextFile ;
begin
    
    _fullname := (gVarFileDirectory + varName + '.txt')   ;
    
    AssignFile(_fileVar , _fullname );            
    Reset(_fileVar);
    ReadLn(_fileVar , _text );
    CloseFile( _fileVar );
    
    if DeleteFile( _fullname ) then 
        Print( '*** DELETED: ' + _fullname )
    else
        Print( '*** DELETIION FAILS: ' + _fullname + 'error = '+ IntToStr(GetLastError) );
    
    result := _text ;
    
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



    {/~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    * Mini Contract:
    * --------------
    * #tipsandtricks #important
    *
    * 1 mini contract, 1 pips = $1 base currency
    * 1 mini contract, 5 pips = $5 base currency
    *
    \~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~/}

    
{-------------------------------------------------------------------------------------------------------}
{***** SYSTEM RESET AT NEW TREND *****}
{-------------------------------------------------------------------------------------------------------}
    
procedure ENTRY_NEWTREND_TREND_SYSTEM_RESET ; stdcall ;
var     _trend_up           :   boolean ;
        _trend_down         :   boolean ;
        _trend_sideways     :   boolean ;
        _systemlockstatus   :   string  ;
        pMessageBoxAnswer   :   word    ;
begin


    {++ 	Identify New Trend     ++}
    {-----------------------------------------------------------------------------------}
    
    if gBarName_D1_FirstTick then begin

        SetCurrencyAndTimeframe( gCurrency , PERIOD_D1 );   // To set price picking on D1


        gDriftline_D1_val_1 := GetIndicatorValue( gDriftline_D1_Handle , 3, 0 );
        { The index for driftline value 1 recent bar has to be 3, not 1 ! }

        gDriftline_D1_val_2 := GetIndicatorValue( gDriftline_D1_Handle , 4 , 0 );
        { The index for driftline value 2 recent bar has to be 4, not 1 ! Ver_3_20180126 }
        
        gDriftline_D1_val_3 := GetIndicatorValue( gDriftline_D1_Handle , 5 , 0 );


        Print(  '[ENTRY_NEWTREND_TREND_SYSTEM_RESET]: First Tick D1 ' +
                'Time(1): '     + FormatDateTime( 'yyyy-mm-dd hh:nn' ,  Time(1) )       + ' / ' +
                'Open(1)-D1: '  + FloatToStrF( Open(1) , ffFixed , 6, 4 )               + ' / ' +
                'Close(1)-D1: ' + FloatToStrF( Close(1) , ffFixed , 6, 4 )              + ' / ' +
                'Driftline_D1: '+ FloatToStrF( gDriftline_D1_val_1 , ffFixed , 6, 4 )   
                );


        // Current Trend
        // -------------------------------------------

        _trend_up   :=  
                        (   // Weekdays bar body is above driftline of D1
                                (Open(1)    > gDriftline_D1_val_1)
                            and (Close(1)   > gDriftline_D1_val_1)
                            and (gD1_DayName_Curr <> 'Sun')
                            and (gD1_DayName_Curr <> 'Sat')
                        )   
                    or
                        (   // Friday bar body is above driftline D1
                                (Open(2)    > gDriftline_D1_val_2)
                            and (Close(2)   > gDriftline_D1_val_2)
                            and (gD1_DayName_Curr = 'Mon')
                                // Friday bar is BLUE in Ver_3_20180126
                        );

        _trend_down  :=  
                        (   // Weekdays bar body is below driftline of D1
                                (Open(1)    < gDriftline_D1_val_1)
                            and (Close(1)   < gDriftline_D1_val_1)                                
                            and (gD1_DayName_Curr <> 'Sun')
                            and (gD1_DayName_Curr <> 'Sat')
                        )
                    or
                        (   // Friday bar body is below driftline of D1
                                (Open(2)    < gDriftline_D1_val_2)
                            and (Close(2)   < gDriftline_D1_val_2)
                            and (gD1_DayName_Curr = 'Mon')
                        );

                        
        _trend_sideways := (not _trend_up) and (not _trend_down);



        if      _trend_up       then    gTrend_D1_Curr := UP         
        else if _trend_down     then    gTrend_D1_Curr := DOWN       
        else if _trend_sideways then    gTrend_D1_Curr := SIDEWAY ;
        

        
        if      (gTrend_D1_Curr in [UP , DOWN] ) 
            and (gTrend_D1_Prev <> gTrend_D1_Curr) then begin
            
                gTrend_D1_NewUp_NewDown         := true     ;
                gToggleCheck_FileVar_AtNewTrend := false    ;
                
        end
        else 
                gTrend_D1_NewUp_NewDown := false ;

        
        // Set the timeframe to next one
        SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );                
                
                
    end;        // if gBarName_D1_FirstTick then begin
    


    {++ 	Reset the System Locks and large profit Flag on New Trend     ++}
    {-----------------------------------------------------------------------------------}
    
    SetCurrencyAndTimeframe( gCurrency , PERIOD_H1 );
    
    if gTrend_D1_NewUp_NewDown and (GetNumberOfOpenPositions = 0) then begin
    
        // Cancel large profit flag on new trend
        gLargeProfitFlag    := false ;
    
        // Ask to unlock the system via file check
        // gSystemTradeLockStatus.TXT every hour
        
        if gBarName_H1_FirstTick 
            and (gToggleCheck_FileVar_AtNewTrend = false ) then begin
        
                if ( not VarFile_Exists( 'gSystemTradeLockStatus' ) ) then begin
                    Pause;
                    pMessageBoxAnswer := 
                        MessageBox(0, 
                            PChar('gSystemTradeLockStatus' + '.txt' + ' NOT exists'), 
                            PChar('Please ensure the file ' + 
                                    'gSystemTradeLockStatus' + '.txt'    + chr(10)+chr(13) +
                                    'is available on directory: '   + chr(10)+chr(13) +
                                    gVarFileDirectory
                                    ), MB_OK);
                    Pause;
                    gSystemTradeLockStatus := LOCKED ;
                    // No file, means the system is LOCKED
                end
                else begin
                    
                    _systemlockstatus := 
                        VarFile_Read_Then_Delete( 'gSystemTradeLockStatus' );
                        
                    { case _systemlockstatus of }
                        { 'LOCKED'    : gSystemTradeLockStatus := LOCKED      ; }
                        { 'UNLOCKED'  : gSystemTradeLockStatus := UNLOCKED    ; }
                    { end; }
                    
                    if  _systemlockstatus = 'LOCKED'        then 
                        gSystemTradeLockStatus := LOCKED      
                    else if _systemlockstatus = 'UNLOCKED'  then 
                        gSystemTradeLockStatus := UNLOCKED ;
                    
                    
                    gToggleCheck_FileVar_AtNewTrend := true ;
                    
                end;
        
        end;

    
    end;        // if gTrend_D1_NewUp_NewDown then begin
    
    
    
    {++ 	Return Timeframe to M5     ++}
    {-----------------------------------------------------------------------------------}

    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );
    

end; // procedure ENTRY_NEWTREND_TREND_SYSTEM_RESET





procedure ENTRY_MANAGEMENT_TRENDY_ALLSIGNALS ; stdcall ;
var     i   :   integer ;
begin


    {++ 	Get trendy signals depend on trading mode     ++}
    {++ 	EXCEPT FlipFlop signals     ++}
    {-----------------------------------------------------------------------------------}

    if ( gMarketMode = CANTTELL_RALLY_OR_JAGGY ) then begin

        gTrigger_M5_Rally_AllSignals_Buy := (
                            gTrigger_M5_Buy_Rally_Standard
                        or  gTrigger_M5_Buy_Rall_Extr_retrac
                        or  gTrigger_M5_Buy_Market_Jaggy
                    );

        gTrigger_M5_Rally_AllSignals_Sell := (
                            gTrigger_M5_Sell_Rally_Standard
                        or  gTrigger_M5_Sell_Rall_Extr_retrac
                        or  gTrigger_M5_Sell_Market_Jaggy
                    );
    end
    else if ( gMarketMode = RALLY ) then begin

        gTrigger_M5_Rally_AllSignals_Buy := (
                            gTrigger_M5_Buy_Rally_Standard
                        or  gTrigger_M5_Buy_Rall_Extr_retrac
                    );

        gTrigger_M5_Rally_AllSignals_Sell := (
                            gTrigger_M5_Sell_Rally_Standard
                        or  gTrigger_M5_Sell_Rall_Extr_retrac
                    );

    end
    else if ( gMarketMode = JAGGY ) then begin

        gTrigger_M5_Rally_AllSignals_Buy := (
                            gTrigger_M5_Buy_Market_Jaggy
                    );

        gTrigger_M5_Rally_AllSignals_Sell := (
                            gTrigger_M5_Sell_Market_Jaggy
                    );
    end;

    // All trendy signals now become one signal

    {++ 	Initialise all prices to force zero values if not used     ++}
    {-----------------------------------------------------------------------------------}
    { So that, when its value is 0.0, you know the system does not assign value ;  }
    { something must be missing }

    gEstimatedEntryPrice_Buy    := 0.0;
    gEstimatedEntryPrice_Sell   := 0.0;
    gStopLoss_Price_Buy         := 0.0;
    gStopLoss_Price_Sell        := 0.0;
    gDistance_Buy               := 0.0;
    gDistance_Buy_Pips          := 0.0;
    gDistance_Sell              := 0.0;
    gDistance_Sell_Pips         := 0.0;
    gDistance_Pips              := 0.0;
    
    gEntryPrice_Position_One    := 0.0;
    { gTakeProfitPrice_Buy        := 0.0; }
    { gTakeProfitPrice_Sell       := 0.0; }
    { Do not set to zero because the value will be used by next position }


    {++ 	Calculate Estimated Entry Price     ++}
    {-----------------------------------------------------------------------------------}

    if gTrigger_M5_Rally_AllSignals_Buy then
        gEstimatedEntryPrice_Buy := Open(0)  + gSpreadInPrice
    else if gTrigger_M5_Rally_AllSignals_Sell then
        gEstimatedEntryPrice_Sell := Open(0) - gSpreadInPrice;



    {++ 	Calculate Stop Loss     ++}
    {-----------------------------------------------------------------------------------}
    if gTrigger_M5_Rally_AllSignals_Buy then
        gStopLoss_Price_Buy     := Min( Open(0) , Low(1) )
                                    - 2.5 * gATR_M5_val_1 - gSpreadInPrice
    else if gTrigger_M5_Rally_AllSignals_Sell then
        gStopLoss_Price_Sell    := Max( Open(0) , High(1) )
                                    + 2.5 * gATR_M5_val_1 + gSpreadInPrice ;



    {++ 	Calculate Distance     ++}
    {-----------------------------------------------------------------------------------}
    if gTrigger_M5_Rally_AllSignals_Buy then begin
        gDistance_Buy       := gEstimatedEntryPrice_Buy - gStopLoss_Price_Buy;
        gDistance_Buy_Pips  := gDistance_Buy / (Point * gPointToPrice) ;
        gDistance_Pips      := gDistance_Buy_Pips ;
    end
    else if gTrigger_M5_Rally_AllSignals_Sell then begin
        gDistance_Sell      := gStopLoss_Price_Sell - gEstimatedEntryPrice_Sell ;
        gDistance_Sell_Pips := gDistance_Sell / (Point * gPointToPrice);
        gDistance_Pips      := gDistance_Sell_Pips ;
    end;

    {++ 	Calculate Position sizing     ++}
    {-----------------------------------------------------------------------------------}

    gRiskSizePercent := gRiskSize  / 100.0 ;

    // Calculate gLotSize_General for NORMAL CONTRACT (not MINI)
    if gTrigger_M5_Rally_AllSignals_Buy then begin
            gLotSize_General :=
                ( gRiskSizePercent * AccountEquity ) / gDistance_Buy / 100000.0 ;
        if AnsiPos('JPY', gCurrency) > 0 then
            gLotSize_General :=
                ( gRiskSizePercent * AccountEquity ) / gDistance_Buy / 1000.0 ;
    end
    else if gTrigger_M5_Rally_AllSignals_Sell then begin
            gLotSize_General :=
                ( gRiskSizePercent * AccountEquity ) / gDistance_Sell / 100000.0 ;
        if AnsiPos('JPY', gCurrency) > 0 then
            gLotSize_General :=
                ( gRiskSizePercent * AccountEquity ) / gDistance_Sell / 1000.0 ;
    end;

        // Example 1:
        // risk = $100 ; dist = 15 pips (GBPJPY)
        // lot size = $100 / (15 * 0.01) / 1000.00 = 0.67 normal contracts

        // Example 2:
        // risk = $100 ; dist = 15 pips (EURUSD)
        // $100 / (15 * 0.0001) / 100000.00 = 0.67 normal contracts


    if (gTrigger_M5_Rally_AllSignals_Buy or gTrigger_M5_Rally_AllSignals_Sell) then begin
        Print('[ENTRY_MANAGEMENT_TRENDY_ALLSIGNALS]: ' +
        'Lot size'          + FloatToStrF(gLotSize_General , ffNumber, 7,1 )  + ' / ' +
        'Distance in pips: '+ FloatToStrF(gDistance_Pips , ffNumber, 7,1 )    + ' / ' +
        'AccountEquity: '   + FloatToStrF(AccountEquity , ffCurrency , 12,2 ) + ' / ' +
        'Risk size: '       + FloatToStrF(gRiskSize , ffFixed, 5,2) + '% '
                );
    end;


    {++ 	Send Order Position sizing     ++}
    {-----------------------------------------------------------------------------------}

    gNumberOfOpenPositions := GetNumberOfOpenPositions ;
    // TechnicalFunctions.PAS
    // Convertible to MQ4
    
    if gNumberOfOpenPositions <= 6 then begin
    
    
        // Check Historical Trade with Large Profit
        // -------------------------------------------------------------------------
        
        { if (gLargeProfitFlag = false) then  }
            { for i:=0 to HistoryTotal - 1 do }
            { begin }
                { if OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) then }
                    { if (OrderProfitPips > 800.0 - 10.0) then begin }
                        { gLargeProfitFlag := true ; }
                        { break; }
                    { end; }
            { end; }

            

        // Position 1
        // -------------------------------------------------------------------------

        if gTrigger_M5_Rally_AllSignals_Buy 
            and (gLargeProfitFlag = false)
            and (gSystemTradeLockStatus = UNLOCKED)
            and (gNumberOfOpenPositions = 0) then begin
    
            gMagicNumberThisPosition := 6871000 + (gNumberOfOpenPositions+1);
    
            // Take profit since 800 pips of first position
            gTakeProfitPrice_Buy := Open(0) + 800.0 * (Point * gPointToPrice);
            gEntryPrice_Position_One    := Open(0) ;
            
            Print( '..... sending order ......' ) ;
            SendInstantOrder(
                    Symbol,
                    op_Buy,
                    gLotSize_General ,
                    gStopLoss_Price_Buy,
                    gTakeProfitPrice_Buy,
                    'PositionNumber_'+IntToStr(gNumberOfOpenPositions+1) ,
                    gMagicNumberThisPosition ,
                    gOrderHandle_General
                );
            Print('*** Orders Total POST: ' + IntToStr( OrdersTotal )   + ' / ' +
                  'OrderHandle (Ticket): '  + IntToStr( gOrderHandle_General )
                    ) ;
        end
        else if gTrigger_M5_Rally_AllSignals_Sell 
            and (gLargeProfitFlag = false)
            and (gSystemTradeLockStatus = UNLOCKED)
            and (gNumberOfOpenPositions = 0) then begin

            gMagicNumberThisPosition := 6871000 + (gNumberOfOpenPositions+1);
            
            // Take profit since 800 pips of first position
            gTakeProfitPrice_Sell := Open(0) - 800.0 * (Point * gPointToPrice);
            gEntryPrice_Position_One    := Open(0) ;
            
            Print( '..... sending order ......' ) ;
            SendInstantOrder(
                    Symbol,
                    op_Sell,
                    gLotSize_General ,
                    gStopLoss_Price_Sell,
                    gTakeProfitPrice_Sell,
                    'PositionNumber_'+IntToStr(gNumberOfOpenPositions+1) ,
                    gMagicNumberThisPosition ,
                    gOrderHandle_General
                );
            Print('*** Orders Total POST: ' + IntToStr( OrdersTotal )   + ' / ' +
                  'OrderHandle (Ticket): '  + IntToStr( gOrderHandle_General )
                    ) ;        
        end;
        
        
        // Position 2, 3, 4, 5, 6
        // -------------------------------------------------------------------------        
        if gTrigger_M5_Rally_AllSignals_Buy 
            and (gLargeProfitFlag = false)
            and (gSystemTradeLockStatus = UNLOCKED)
            and (gNumberOfOpenPositions in [1, 2, 3, 4, 5]) then begin

            
            // Check latest position if profitable
            if OrderSelect((OrdersTotal-1), SELECT_BY_POS, MODE_TRADES) then 
                if OrderProfitPips > 0.0 then begin
            
                    gMagicNumberThisPosition := 6871000 + (gNumberOfOpenPositions+1);
                                        
                    Print( '..... sending order ......' ) ;
                    SendInstantOrder(
                            Symbol,
                            op_Buy,
                            gLotSize_General ,
                            gStopLoss_Price_Buy,
                            gTakeProfitPrice_Buy,   // Take profit since 800 pips of first position
                            'PositionNumber_'+IntToStr(gNumberOfOpenPositions+1) ,
                            gMagicNumberThisPosition ,
                            gOrderHandle_General
                        );
                    Print('*** Orders Total POST: ' + IntToStr( OrdersTotal )   + ' / ' +
                          'OrderHandle (Ticket): '  + IntToStr( gOrderHandle_General )
                            ) ;
                end;
                    
                    
        end
        else if gTrigger_M5_Rally_AllSignals_Sell 
            and (gLargeProfitFlag = false)
            and (gSystemTradeLockStatus = UNLOCKED)
            and (gNumberOfOpenPositions in [1, 2, 3, 4, 5]) then begin

            // Check latest position if profitable
            if OrderSelect((OrdersTotal-1), SELECT_BY_POS, MODE_TRADES) then 
                if OrderProfitPips > 0.0 then begin
            
                    gMagicNumberThisPosition := 6871000 + (gNumberOfOpenPositions+1);
                                        
                    Print( '..... sending order ......' ) ;
                    SendInstantOrder(
                            Symbol,
                            op_Sell,
                            gLotSize_General ,
                            gStopLoss_Price_Sell,
                            gTakeProfitPrice_Sell,  // Take profit since 800 pips of first position
                            'PositionNumber_'+IntToStr(gNumberOfOpenPositions+1) ,
                            gMagicNumberThisPosition ,
                            gOrderHandle_General
                        );
                    Print('*** Orders Total POST: ' + IntToStr( OrdersTotal )   + ' / ' +
                          'OrderHandle (Ticket): '  + IntToStr( gOrderHandle_General )
                            ) ;        
                end;
        end;
        
        
        // Check Large Profit on Open Position
        // -----------------------------------------------------------------------------
        // The idea is to be able to cancel the flag for the next trend
                
        if OrderSelect( 0 , SELECT_BY_POS , MODE_TRADES ) 
            and ( gLargeProfitFlag = false )  then begin
                if ( OrderProfitPips >= (800.0-10.0) ) then begin
                    gLargeProfitFlag        := true ;
                    gSystemTradeLockStatus  := LOCKED ;
                end;
        end;
        
        
    end;


end; // End procedure ENTRY_MANAGEMENT_TRENDY_ALLSIGNALS


procedure OPEN_MULTIPLE_ORDERS_IN_6_DAYS_AND_CLOSE_THEM_AT_ONCE ; stdcall ;
// This is great demonstration for pyramiding into multi position and closing all trades at once.
// The method is translatable to MQL4 !
var
    pOrderHandle                : integer       ;
    pMagicNumberThisPosition    : integer       ;
    pMessageBoxAnswer           : Word          ;
    pPosIndex                   : integer       ;
begin


    // Open 6 Orders in 6 Days
    // ---------------------------------------------------------------------------------

    if gBarName_D1_FirstTick then begin

        Inc( gD1_Bar_Count );

        pMagicNumberThisPosition := 6871000 + gD1_Bar_Count ;

        // Send Order
        if gD1_Bar_Count <= 6 then begin
            Print( 'Day #: ' + IntToStr( gD1_Bar_Count ) );
            Print( '*** Orders Total PRE: ' + IntToStr( OrdersTotal ) ) ;
            Print( '..... sending order ......' ) ;
            SendInstantOrder(
                    Symbol,
                    op_Sell,
                    1.1 ,
                    0,
                    0,
                    'Dummy order on Day '+IntToStr(gD1_Bar_Count) ,
                    pMagicNumberThisPosition ,
                    pOrderHandle
                );
            Print('*** Orders Total POST: ' + IntToStr( OrdersTotal )   + ' / ' +
                  'OrderHandle (Ticket): '  + IntToStr( pOrderHandle )
                    ) ;
        end;
    end;


    // Close all 6 Orders
    // ---------------------------------------------------------------------------------

    if gBarName_D1_FirstTick and (gD1_Bar_Count = 7) then begin
        // the Begin keyword right at the IF's line allows red marker highlight the block belong to IF block

        Pause;
        pMessageBoxAnswer := MessageBox(0, PChar('Day 7 Opening'), PChar('The positions are about to close'), MB_OK);
        Pause;
        // Close all orders
        for pPosIndex := OrdersTotal-1 downto 0 do begin
            Print( 'OrdersTotal BEFORE Closing the Order: ' + IntToStr( OrdersTotal ) );
                OrderSelect( pPosIndex , SELECT_BY_POS , MODE_TRADES  );
                Print( '   *** Closing the Order ***' );
                CloseOrder( OrderTicket );
            Print( 'OrdersTotal AFTER Closing the Order: ' + IntToStr( OrdersTotal ) );
        end;
        Pause;
        pMessageBoxAnswer := MessageBox(0, PChar('Positions closure'), PChar('All Positions have been closed'), MB_OK);
        Pause;
    end;
end;



{///////////////////////////////////////////////////////////////////////////////////////////////////////}
{*******************************************************************************************************}
{**                                  CORE PROCEDURES IN FOREX TESTER                                  **}
{*******************************************************************************************************}
{///////////////////////////////////////////////////////////////////////////////////////////////////////}




{-----Init strategy-----------------------------------------}
procedure InitStrategy; stdcall;
begin

  StrategyShortName('Powertool6X');
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
  AddOptionValue('Market Mode' , 'Cant Tell Rally or Jaggy' );                  // 2
  AddOptionValue('Market Mode' , 'Flip Flop' );                                 // 3

  { RegOption     ('Large Profit', ot_Boolean , gLargeProfitFlag ); }
  { AddOptionValue('Large Profit' , 'false');       }
  { AddOptionValue('Large Profit' , 'true');        }

  
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


    // Set Point to Price
    // ---------------------------------------------------------------------------------

    if( (Digits = 5) or (Digits=3) or (Digits = 1) )then
        gPointToPrice := 10.0
    else
        gPointToPrice := 1.0 ;



    // Initialisation
    // ---------------------------------------------------------------------------------

    gD1_Bar_Count   := 0 ;

    gSpreadPips     := 3.0 ;
    gSpreadInPrice  := gSpreadPips * (Point * gPointToPrice);

    
    // Undo flag that lock the system
    // ---------------------------------------------------------------------------------

    gLargeProfitFlag                := false ;
    gSystemTradeLockStatus          := UNLOCKED ;
    gToggleCheck_FileVar_AtNewTrend := true ;


    {** Note:
        Point = minimum price value for the selected currency.
                ex/ digit 5,3,1 ---> 150.001 ; minimum value is 0.001 or 0.1 pips
                    digit 4,2   ---> 150.01  ; minimum value is 0.01 or 1 pips
    **}


    
    // gVarFileDirectory 
    // ---------------------------------------------------------------------------------

    gVarFileDirectory := 'C:\ForexTester3\Strategies\gVarFileDirectory\';
    { Replace with the directory for the  }
    
    
    // Order Handle Initialisation
    // ---------------------------------------------------------------------------------

    { gP1_OrderHandle := -1; }
    { gP2_OrderHandle := -1; }
    { gP3_OrderHandle := -1; }
    { gP4_OrderHandle := -1; }
    { gP5_OrderHandle := -1; }
    { gP6_OrderHandle := -1; }
    { gP7_OrderHandle := -1; }
    { gP8_OrderHandle := -1; }


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


    gM5_RL_10_Handle    :=  CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'LinearRegressionIndicator'
                    ,       '10;0;Close'
                );

    gM5_RL_30_Handle    :=  CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'LinearRegressionIndicator'
                    ,       '30;0;Close'
                );

    gM5_EMA_5_Handle    :=  CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'MovingAverage'
                    ,       '5;0;0;Exponential (EMA);Close'
                );

    // Reference for MovingAverage :
    // C:\Users\Hendy\OneDrive\Documents\@Docs\_HUB_FT\Strategies\@ Cores\Marker Alignment W1-D1\
    // TechnicalFunctions.pas - line 196

    gM5_EMA_20_Handle   :=  CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'MovingAverage'
                    ,       '20;0;0;Exponential (EMA);Close'
                );

    gATR_M5_Handle :=       CreateIndicator(
                            gCurrency
                    ,       PERIOD_M5
                    ,       'ATR'
                    ,       '5;Close'
                );









    // Initiate tracker variables for bar numbers
    // ---------------------------------------------------------------------------------

    // gSetup_H1_Buy_Curr          := false ;
    // gSetup_H1_Sell_Curr         := false ;
    // gSetup_H1_Buy_BarNum_In     := 0 ;
    // gSetup_H1_Sell_BarNum_In    := 0 ;


    // Print the version on Journal
    // ---------------------------------------------------------------------------------
    Print(        
        'Ver_6X_20180424 Tue'
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
    myMilli                     : Word          ;
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
    {**   OPENING MULTIPLE ORDERS AND CLOSE THEM AT ONCE  **}
    {***************************************************************************************************}

    // OPEN_MULTIPLE_ORDERS_IN_6_DAYS_AND_CLOSE_THEM_AT_ONCE ;
    // This is great demonstration for pyramiding into multi position and closing all trades at once.
    // The method is translatable to MQL4 !




    {***************************************************************************************************}
    {**   ENTRY MANAGEMENT  **}
    {***************************************************************************************************}

    ENTRY_NEWTREND_TREND_SYSTEM_RESET ;
    
    ENTRY_MANAGEMENT_RALLY_STANDARD;
    ENTRY_MANAGEMENT_RALLY_EXTRE_RETRAC;
    ENTRY_MANAGEMENT_JAGGY;
    ENTRY_MANAGEMENT_FLIPFLOP;


    // Roll up all trendy signals into one entry trigger for trendy market
    // Perform actual entry
    //
    ENTRY_MANAGEMENT_TRENDY_ALLSIGNALS ;







    {***************************************************************************************************}
    {**   TIMEFRAME MANAGEMENT **}
    {***************************************************************************************************}
    {Ref:
        C:\Users\Hendy\OneDrive\Documents\@Docs\Business Project - Multi Forex Capital\03.Codes - Main\
        SYS - Trend 1 - D1 Wave 3\Trend1_D1_Wave_3_ver4.pas}

    SetCurrencyAndTimeframe(gCurrency , PERIOD_D1);
    gBarName_D1_Prev    := gBarName_D1_Curr ;
    gTrend_D1_Prev      := gTrend_D1_Curr   ;

    
    SetCurrencyAndTimeframe(gCurrency , PERIOD_H1);
    gBarName_H1_Prev    := gBarName_H1_Curr ;


    { timeframe low ** at the last point }
    SetCurrencyAndTimeframe( gCurrency , PERIOD_M5 );
    gBarName_M5_Prev    := gBarName_M5_Curr ;

end;

exports
  InitStrategy,
  DoneStrategy,
  ResetStrategy,
  GetSingleTick;
end.
