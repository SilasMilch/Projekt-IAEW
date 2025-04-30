%% Definition des Optimierungszeitraumes
AnzDays = 1;        %Anzahl der Tage
T = 24 * AnzDays;   %Anzahl der Stunden des Optimierungszeitraumes

%% Definition der wiederverwendbaren Matrizen und Vektoren 
%Matrizen der Größe T x T 
EYE = eye(T);                        %Einheitsmatrix TxT
                       %Nullermatrix TxT

%Vektoren der Größe T x 1 bzw 1 x T
                        %Nuller-Zeilenvektor 1xT
                        %Nuller-Spaltenvektor Tx1
                        %Einser-Zeilenvektor 1xT
                        %Einser-Spaltenvektor Tx1

%% Bezeichnungen im weiteren Verlauf
%
%Eingangsdaten
%Nr     ->  Nummer des KWs
%SvO    ->  Status vor Optimierungszeitraum
%BvO    ->  Betriebsintervalle vor Optimierungszeitraum
%Pmin   ->  Minimal lieferbare Leistung
%Pmax   ->  Maximal lieferbare Leistung
%c_var  ->  GrenP_ktzkosten
%c_fix  ->  Fixkosten
%c_anf  ->  Anfahrtskosten
%DT     ->  Minimale Downtime
%UT     ->  Minimale Uptime
%A      ->  Maximale Anzahl von Startvorgängen
%rf_min ->  Minimale Anzahl von Betriebsintervallen
%rf_max ->  Maximale Anzahl von Betriebsintervallen
%RU_RD  ->  RampUp bzw. RampDown
%SU_SD  ->  StartUp bzw. ShutDown
%P_t<0  ->  Gelieferte Leistung vor Optimierungszeitraum
%c_suc  ->  Kaltstartkosten
%c_s    ->  Warmstartkosten (entsprechen den Anfahrtskosten)
%CT     ->  Cooltime
%SnO    ->  Status nach Optimierungszeitraum
%
%Variablen
%p      ->  Leistung
%v      ->  Zustand des KW (Online oder Offline)
%son    ->  Anfahrvariable
%soff   ->  Abschaltvariable
%p_endo ->  Maximal verfügbare Leistung
%isuc   ->  Indikatorvariable für Anfahrtkosten
%suc    ->  Indikatorvariable für Kaltstartkosten

%% Eingangsdaten
% header
KwDataHeader = struct("Nr", 1, "SvO", 2,  "BvO", 3, "Pmin", 4, "Pmax", 5, ...
    "c_var", 6, "c_fix", 7, "c_anf", 8, "DT", 9, "UT", 10, "A", 11, ...
    "rf_min", 12, "rf_max", 13, "RU_RD", 14, "SU_SD", 15, "P_t0", 16, ...
    "c_suc", 17, "c_s", 18, "CT", 19, "SnO", 20 );

%Kraftwerksdaten
    kwData=[
% 1     2   3   4       5       6       7       8       9   10  11  12      13      14      15      16      17      18      19      20        
% Nr    SvO BvO Pmin    Pmax    c_var   c_fix   c_anf   DT  UT  A   rf_min  rf_max  RU_RD   SU_SD   P_t<0   c_suc   c_s     CT      SnO 
  1     1   8   150     455     16.19   1000    4500    8   8   24  0       24      160     150     400     9000    4500    9       1
  2     1   8   150     455     17.26   970     5000    8   8   24  0       24      160     150     400     10000   5000    9       1
  3     0   -5  20      130     16.60   700     550     5   5   24  0       24      100     20      0       1100    550     6       1
  4     0   -5  20      130     16.50   680     560     5   5   24  0       24      100     20      0       1120    560     6       1
  5     0   -6  25      162     19.70   450     900     6   6   24  0       24      100     25      0       1800    900     7       1
  6     0   -3  20      80      22.26   370     170     3   3   24  0       24      60      20      0       340     170     4       1
  7     0   -3  25      85      27.74   480     260     3   3   24  0       24      60      25      0       520     260     4       1
  8     0   -1  10      55      25.94   660     30      1   1   24  0       24      40      10      0       60      30      2       1
  9     0   -1  10      55      27.27   665     30      1   1   24  0       24      40      10      0       60      30      2       1
  10    0   -1  10      55      27.79   670     30      1   1   24  0       24      40      10      0       60      30      2       1
];

%Kraftwerksdaten nach Kosten sortieren


%Initialisierung der für CPLEX erforderlichen Matrizen und Vektoren
                %Zielfunktion        
                %Nebenbedingungsmatrix
                %Upper-Bound
                %Lower-Bound
                %Lefthandside
                %Righthandside
                %Variablentypen der Zielfunktion
                %Matrix für Lastdeckungsbedingung

%Load Demand
Power_Demand=repmat([700 750 850 950 1000 1100 1150 1200 1300 1400 1450 1500 1400 1300 1200 1050 1000 1100 1200 1400 1300 1100 900 800]',AnzDays,1);
