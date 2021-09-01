unit TsuTYPE6238Ex;

interface
uses
  TsuTYPE6238, TsuCSVAppend, TsuTypes, TsuACOTypes
  ;

type
  TTscTYPE6238Ex  = class(TTscType6238)
    private
      FEQCSV  : TTscCSVAppend;
      FIVCSV  : TTscCSVAppend;
      procedure EQCSVHeaderSet(d_set:TTssTYPE6238CSVTypesEQ);
      procedure IVCSVHeaderSet(d_set:TTssTYPE6238CSVTypesIV);
      procedure EQCSVAddData;
      procedure IVCSVAddData;
    protected
      FEqCSVDataSet : TTssTYPE6238CSVTypesEQ;
      FIvCSVDataSet : TTssTYPE6238CSVTypesIV;
      procedure GetEQData;override;
      procedure GetIVData;override;
    public
      property EQCSV  : TTscCSVAppend read FEQCSV write FEQCSV;
      property IVCSV  : TTscCSVAppend read FIVCSV write FIVCSV;
      property EQCSVDataSet : TTssTYPE6238CSVTypesEQ read FEqCSVDataSet write EQCSVHeaderSet;
      property IVCSVDataSet : TTssTYPE6238CSVTypesIV read FIvCSVDataSet write IVCSVHeaderSet;
  end;

implementation

procedure TTscTYPE6238Ex.EQCSVHeaderSet(d_set:TTssTYPE6238CSVTypesEQ);
var
  typ : TTseTYPE6238CSVTypeEQ;
  cash  : string;
begin
  if Assigned(FEQCSV) then
    begin
      FEqCSVDataSet := d_set;
      FEQCSV.HeaderClear;
      for typ in FEqCSVDataSet do
        begin
          case FSettings.FreqChar of
            T6238_FC_A: cash  := 'A';
            T6238_FC_C: cash  := 'C';
            T6238_FC_Z: cash  := 'p';
          end;
          case typ of
            T6238_CT_EQ_DATE    : FEQCSV.HeaderAdd('Date');
            T6238_CT_EQ_RANGE   : FEQCSV.HeaderAdd('Range');
            T6238_CT_EQ_FREQCHAR: FEQCSV.HeaderAdd('FreqChar');
            T6238_CT_EQ_TIMECHAR: FEQCSV.HeaderAdd('TimeChar');
            T6238_CT_EQ_MEASTIME: FEQCSV.HeaderAdd('MeasTime');
            T6238_CT_EQ_Leq     : FEQCSV.HeaderAdd('L'+cash+'eq');
            T6238_CT_EQ_Le      : FEQCSV.HeaderAdd('L'+cash+'e');
            T6238_CT_EQ_Lpeak   : FEQCSV.HeaderAdd('L'+cash+'peak');
            T6238_CT_EQ_Lmin    : FEQCSV.HeaderAdd('Lmin');
            T6238_CT_EQ_Lmax    : FEQCSV.HeaderAdd('Lmax');
            T6238_CT_EQ_L05     : FEQCSV.HeaderAdd('LA05');
            T6238_CT_EQ_L10     : FEQCSV.HeaderAdd('LA10');
            T6238_CT_EQ_L50     : FEQCSV.HeaderAdd('LA50');
            T6238_CT_EQ_L90     : FEQCSV.HeaderAdd('LA90');
            T6238_CT_EQ_L95     : FEQCSV.HeaderAdd('LA95');
          end;
        end;
      FEQCSV.HeaderAddLine;
    end;
end;

procedure TTscTYPE6238Ex.IVCSVHeaderSet(d_set:TTssTYPE6238CSVTypesIV);
var
  typ : TTseTYPE6238CSVTypeIV;
begin
  if Assigned(FIVCSV) then
    begin
      FIvCSVDataSet := d_set;
      FIVCSV.HeaderClear;
      for typ in FIvCSVDataSet do
        begin
          case typ of
            T6238_CT_IV_DATE    : FIVCSV.HeaderAdd('Date');
            T6238_CT_IV_RANGE   : FIVCSV.HeaderAdd('Range');
            T6238_CT_IV_FREQCHAR: FIVCSV.HeaderAdd('FreqChar');
            T6238_CT_IV_TIMECHAR: FIVCSV.HeaderAdd('TimeChar');
            T6238_CT_IV_IV      : FIVCSV.HeaderAdd('Data');
          end;
        end;
      FIVCSV.HeaderAddLine;
    end;
end;

procedure TTscTYPE6238Ex.GetEQData;
begin
  EQCSVAddData;
end;

procedure  TTscTYPE6238Ex.GetIVData;
begin
  IVCSVAddData;
end;

procedure TTscTYPE6238Ex.EQCSVAddData;
var
  typ : TTseTYPE6238CSVTypeEQ;
begin
  if Assigned(EQCSV) then
    begin
      if not (T6238_CT_EQ_DATE in FEqCSVDataSet) then
        FEQCSV.AddTimeStamp := False;
      for typ in FEqCSVDataSet do
        begin
          case typ of
            T6238_CT_EQ_DATE    : FEQCSV.AddTimeStamp := True;
            T6238_CT_EQ_RANGE   : FEQCSV.AddData(TsfGetTYPE6238RangeEnumName(FReceivData.Range));
            T6238_CT_EQ_FREQCHAR: FEQCSV.AddData(TsfGetTYPE6238FreqCharEnumName(FReceivData.FreqChar));
            T6238_CT_EQ_TIMECHAR: FEQCSV.AddData(TsfGetTYPE6238TimeCharEnumName(FReceivData.TimeChar));
            T6238_CT_EQ_MEASTIME: FEQCSV.AddData(FReceivData.MeasTime.ToString);
            T6238_CT_EQ_Leq     : FEQCSV.AddData(FReceivData.Leq);
            T6238_CT_EQ_Le      : FEQCSV.AddData(FReceivData.Le);
            T6238_CT_EQ_Lpeak   :
              begin
                case FReceivData.FreqChar of
                  T6238_FC_A  : FEQCSV.AddData('---.-');
                  T6238_FC_C,
                  T6238_FC_Z  : FEQCSV.AddData(FReceivData.Leq);
                end;
              end;
            T6238_CT_EQ_Lmin    : FEQCSV.AddData(FReceivData.Lmin);
            T6238_CT_EQ_Lmax    : FEQCSV.AddData(FReceivData.Lmax);
            T6238_CT_EQ_L05     : FEQCSV.AddData(FReceivData.LA05);
            T6238_CT_EQ_L10     : FEQCSV.AddData(FReceivData.LA10);
            T6238_CT_EQ_L50     : FEQCSV.AddData(FReceivData.LA50);
            T6238_CT_EQ_L90     : FEQCSV.AddData(FReceivData.LA90);
            T6238_CT_EQ_L95     : FEQCSV.AddData(FReceivData.LA95);
          end;
        end;
      FEQCSV.AddLine;
    end;
end;

procedure TTscTYPE6238EX.IVCSVAddData;
var
  typ : TTseTYPE6238CSVTypeIV;
begin
  if Assigned(FIVCSV) then
    begin
      if not (T6238_CT_IV_DATE in FIvCSVDataSet) then
        FIVCSV.AddTimeStamp := False;
      for typ in FIvCSVDataSet do
        begin
          case typ of
            T6238_CT_IV_DATE    : FIVCSV.AddTimeStamp := True;
            T6238_CT_IV_RANGE   : FIVCSV.AddData(TsfGetTYPE6238RangeEnumName(FSettings.Range));
            T6238_CT_IV_FREQCHAR: FIVCSV.AddData(TsfGetTYPE6238FreqCharEnumName(FSettings.FreqChar));
            T6238_CT_IV_TIMECHAR: FIVCSV.AddData(TsfGetTYPE6238TimeCharEnumName(FSettings.TimeChar));
            T6238_CT_IV_IV      : FIVCSV.AddData(FIVData.ValueS);
          end;
        end;
      FIVCSV.AddLine;
    end;
end;

end.
