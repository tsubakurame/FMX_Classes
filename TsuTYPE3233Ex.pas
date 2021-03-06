unit TsuTYPE3233Ex;

interface
uses
  System.TypInfo,
  TsuTYPE3233, TsuCSVAppend, TsuTypes, TsuACOTypes
  ;

type

  TTscTYPE3233Ex  = class(TTscTYPE3233)
    private
      FEQCSV    : Array[T3233_CH_X..T3233_CH_Z] of TTscCSVAppend;
      FIVCSV    : TTscCSVAppend;
      FIVCSVHeaderStCh  : TTseTYPE3233CSVTypeIV;
      FIVCSVHeaderEdCh  : TTseTYPE3233CSVTypeIV;
      procedure EQCSVHeaderSet(ch:TTseTYPE3233Ch; d_set:TTssTYPE3233CSVTypesEQ);
      procedure IVCSVHeaderSet(d_set:TTssTYPE3233CSVTypesIV);

      procedure EQCSVAddData;
      procedure IVCSVAddData;

      function GetEQCSVDataSet(ch:TTseTYPE3233Ch):TTssTYPE3233CSVTypesEQ;

      procedure SetEQCSV(ch:TTseTYPE3233Ch; csv:TTscCSVAppend);
      function GetEQCSV(ch:TTseTYPE3233Ch):TTscCSVAppend;
    protected
      FEqCSVDataSet : Array[T3233_CH_X..T3233_CH_Z] of TTssTYPE3233CSVTypesEQ;
      FIvCSVDataSet : TTssTYPE3233CSVTypesIV;
      procedure GetEQData;override;
      procedure GetIVData;override;
    public
      property EQCSVDataSet[ch:TTseTYPE3233Ch]  : TTssTYPE3233CSVTypesEQ read GetEQCSVDataSet write EQCSVHeaderSet;
      property IVCSVDataSet                     : TTssTYPE3233CSVTypesIV read FIvCSVDataSet   write IVCSVHeaderSet;
      property EQCSV[ch:TTseTYPE3233Ch] : TTscCSVAppend read GetEQCSV write SetEQCSV;
      property IVCSV                    : TTscCSVAppend read FIVCSV write FIVCSV;
  end;

implementation

procedure TTscTYPE3233Ex.EQCSVHeaderSet(ch:TTseTYPE3233Ch; d_set:TTssTYPE3233CSVTypesEQ);
var
  //I : TTseTYPE3233Ch;
  typ : TTseTYPE3233CSVTypeEQ;
  cash  : string;
begin
  if Assigned(FEQCSV[ch]) then
    begin
      FEqCSVDataSet[ch] := d_set;
      //for I := T3233_CH_X to T3233_CH_Z do
        //begin
          FEQCSV[ch].HeaderClear;
          for typ in FEqCSVDataSet[ch] do
            begin
              case FSettings.Filter[ch] of
                T3233_FT_Lv : cash  := 'Lv';
                T3233_FT_Lva: cash  := 'La';
              end;
              case typ of
                T3233_CT_EQ_Date     : FEQCSV[ch].HeaderAdd('Date');
                T3233_CT_EQ_RANGE    : FEQCSV[ch].HeaderAdd('Range');
                T3233_CT_EQ_FILTER   : FEQCSV[ch].HeaderAdd('Filter');
                T3233_CT_EQ_MEASTIME : FEQCSV[ch].HeaderAdd('MeasTime');
                T3233_CT_EQ_Leq      : FEQCSV[ch].HeaderAdd(cash+'eq');
                T3233_CT_EQ_LMIN     : FEQCSV[ch].HeaderAdd(cash+'Min');
                T3233_CT_EQ_LMAX     : FEQCSV[ch].HeaderAdd(cash+'Max');
                T3233_CT_EQ_L05      : FEQCSV[ch].HeaderAdd(cash+'05');
                T3233_CT_EQ_L10      : FEQCSV[ch].HeaderAdd(cash+'10');
                T3233_CT_EQ_L50      : FEQCSV[ch].HeaderAdd(cash+'50');
                T3233_CT_EQ_L90      : FEQCSV[ch].HeaderAdd(cash+'90');
                T3233_CT_EQ_L95      : FEQCSV[ch].HeaderAdd(cash+'95');
              end;
            end;
          FEQCSV[ch].HeaderAddLine;
        //end;
    end;
end;

procedure TTscTYPE3233Ex.IVCSVHeaderSet(d_set:TTssTYPE3233CSVTypesIV);
var
  typ : TTseTYPE3233CSVTypeIV;
begin
  if Assigned(FIVCSV) then
    begin
      FIvCSVDataSet := d_set;
      FIVCSV.HeaderClear;
      FIVCSVHeaderStCh  := T3233_CT_IV_Date;
      for typ in FIvCSVDataSet do
        begin
          case typ of
            T3233_CT_IV_Date    : FIVCSV.HeaderAdd('Date');
            T3233_CT_IV_RANGE   : FIVCSV.HeaderAdd('Range');
            T3233_CT_IV_FILTER  : FIVCSV.HeaderAdd('Filter');
            T3233_CT_IV_X       :
              begin
                FIVCSV.HeaderAdd('X');
                FIVCSVHeaderEdCh  := typ;
                if FIVCSVHeaderStCh = T3233_CT_IV_Date then
                  FIVCSVHeaderStCh  := typ;
              end;
            T3233_CT_IV_Y       :
              begin
                FIVCSV.HeaderAdd('Y');
                FIVCSVHeaderEdCh  := typ;
                if FIVCSVHeaderStCh = T3233_CT_IV_Date then
                  FIVCSVHeaderStCh  := typ;
              end;
            T3233_CT_IV_Z       :
              begin
                FIVCSV.HeaderAdd('Z');
                FIVCSVHeaderEdCh  := typ;
                if FIVCSVHeaderStCh = T3233_CT_IV_Date then
                  FIVCSVHeaderStCh  := typ;
              end;
          end;
        end;
      FIVCSV.HeaderAddLine;
    end;
end;

procedure TTscTYPE3233Ex.EQCSVAddData;
var
  typ : TTseTYPE3233CSVTypeEQ;
begin
  if Assigned(FEQCSV[FReceivData.Ch]) then
    begin
      for typ in FEqCSVDataSet[FReceivData.Ch] do
        begin
          if not (T3233_CT_EQ_Date in FEqCSVDataSet[FReceivData.Ch]) then
            FEQCSV[FReceivData.Ch].AddTimeStamp  := False;
          case typ of
            T3233_CT_EQ_Date     : FEQCSV[FReceivData.Ch].AddTimeStamp := True;
            T3233_CT_EQ_RANGE    : FEQCSV[FReceivData.Ch].AddData(TsfGetTYPE3233RangeEnumName(FReceivData.Range));
            T3233_CT_EQ_FILTER   : FEQCSV[FReceivData.Ch].AddData(TsfGetTYPE3233FilterEnumName(FReceivData.Filter));
            T3233_CT_EQ_MEASTIME : FEQCSV[FReceivData.Ch].AddData(FReceivData.MeasTime.ToString);
            T3233_CT_EQ_Leq      : FEQCSV[FReceivData.Ch].AddData(FReceivData.Leq);
            T3233_CT_EQ_LMIN     : FEQCSV[FReceivData.Ch].AddData(FReceivData.Lmin);
            T3233_CT_EQ_LMAX     : FEQCSV[FReceivData.Ch].AddData(FReceivData.Lmax);
            T3233_CT_EQ_L05      : FEQCSV[FReceivData.Ch].AddData(FReceivData.L05);
            T3233_CT_EQ_L10      : FEQCSV[FReceivData.Ch].AddData(FReceivData.L10);
            T3233_CT_EQ_L50      : FEQCSV[FReceivData.Ch].AddData(FReceivData.L50);
            T3233_CT_EQ_L90      : FEQCSV[FReceivData.Ch].AddData(FReceivData.L90);
            T3233_CT_EQ_L95      : FEQCSV[FReceivData.Ch].AddData(FReceivData.L95);
          end;
        end;
      FEQCSV[FReceivData.Ch].AddLine;
    end;
end;

procedure TTscTYPE3233Ex.IVCSVAddData;
var
  d_set : TTssTYPE3233CSVTypesIV;
  typ   : TTseTYPE3233CSVTypeIV;
  hdtp  : TTseTYPE3233CSVTypeIV;
begin
  d_set := FIvCSVDataSet - [T3233_CT_IV_DATE, T3233_CT_IV_RANGE, T3233_CT_IV_FILTER];

  typ := TTseTYPE3233CSVTypeIV(Ord(FIVData.Ch) + 2);
  if typ in FIvCSVDataSet then
    begin
      if typ = FIVCSVHeaderStCh then
        begin
          for hdtp in FIvCSVDataSet do
            begin 
              case hdtp of
                T3233_CT_IV_Date  : FIVCSV.AddTimeStamp := True;
                T3233_CT_IV_RANGE : FIVCSV.AddData(TsfGetTYPE3233RangeEnumName(FSettings.Range[FIVData.Ch]));
                T3233_CT_IV_FILTER: FIVCSV.AddData(TsfGetTYPE3233FilterEnumName(FSettings.Filter[FIVData.Ch]));
              end;
            end;
        end;
      IVCSV.AddData(FIVData.Data.ValueS);
      if typ = FIVCSVHeaderEdCh then
        IVCSV.AddLine;
    end;
end;

procedure TTscTYPE3233Ex.GetEQData;
begin
  EQCSVAddData;
end;

procedure TTscTYPE3233Ex.GetIVData;
begin
  IVCSVAddData;
end;

function TTscTYPE3233Ex.GetEQCSVDataSet(ch:TTseTYPE3233Ch):TTssTYPE3233CSVTypesEQ;
begin
  Result  := FEqCSVDataSet[ch];
end;

procedure TTscTYPE3233Ex.SetEQCSV(ch:TTseTYPE3233Ch;csv:TTscCSVAppend);
begin
  FEQCSV[ch]  := csv;
end;

function TTscTYPE3233Ex.GetEQCSV(ch:TTseTYPE3233Ch):TTscCSVAppend;
begin
  Result  := FEQCSV[ch];
end;

end.
