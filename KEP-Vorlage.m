clc;
clear all;

%% Einbinden von KEP_Data
KEP_Data_Vorlage

%% Hilfe
% https://de.mathworks.com/help/releases/R2024b/optim/ug/problem-based-workflow.html?searchHighlight=optimproblem&s_tid=doc_srchtitle
% https://de.mathworks.com/help/releases/R2024b/optim/ug/optimproblem.html#d126e144210
% https://de.mathworks.com/help/releases/R2024b/optim/ug/optimvar.html#namevaluepairarguments
% https://de.mathworks.com/help/releases/R2024b/optim/ug/example-linear-programming-via-problem.html

%% AP1
% kwData_Merit_Order = sortrows(kwData, 6);
% format short g;
% disp('Merit order von kw:');
% disp(kwData_Merit_Order);
% 
% nPP = size(kwData, 1);
% nT= T;
% 
% UB = kwData(:,5);
% UB = repmat(UB, 1, nT); 
% cost = repmat(kwData(:,6), 1, nT);
% 
% % Erstellen des Optimerungsproblem-Objekts
% probAP1 = optimproblem("Description","Minimieren die kosten","ObjectiveSense","min"); % Erstellen des Optimierungproblem-Objects --> Description und Sense füllen
% 
% % Erstellen der Variable(n)
% P_kt = optimvar( "P_kt", nPP, nT, "LowerBound", 0, "UpperBound", UB, "Type","continuous");  % wieviele Variablen?, "LowerBound", LB, ... % lower bounds, "UpperBound", UB, ... % upper bounds, "Type", ""); % Variablentyp: "continuous" oder "integer
% 
% 
% 
% % Erstellen der Zielfunktion
% probAP1.Objective = sum(sum(P_kt .* cost));
% 
% % Erstellen der Nebenbedingung(en)
% probAP1.Constraints.demand = optimconstr(nT,1);
% for l = 1:nT
%     probAP1.Constraints.demand(l) = sum(P_kt(:,l)) == Power_Demand(l);
% end
% solAP1 = probAP1.solve("Solver", "linprog"); % linprog wenn LP, intelinprog wenn MILP
% 
% ganzes_kosten = evaluate(probAP1.Objective, solAP1);
% format long g;
% disp("Totale in €:");
% disp(ganzes_kosten);
% 
% disp("Leistungsabgabe (kW) von jeder Kraftwekspark pro stunde:");
% disp(solAP1.P_kt);
% 



%% AP2a
clear
KEP_Data_Vorlage
% Erstellen des Optimerungsproblem-Objekts

nPP = size(kwData, 1);
nT= T;
UB_P = kwData(:,5);
UB_P = repmat(UB_P, 1, nT); 
c_var = repmat(kwData(:,6), 1, nT);
Pmin = repmat(kwData(:,4), 1, nT);
c_fix = repmat(kwData(:,7), 1, nT);
c_anf = repmat(kwData(:,8), 1, nT);
DT = repmat(kwData(:,9), 1, nT);
BvO = repmat(kwData(:,3), 1, nT);

probAP2a = optimproblem("Description","", "ObjectiveSense",""); 
P_kt = optimvar("P_kt", nPP, nT, ...
                "LowerBound", 0, ...
                "UpperBound", UB_P, ...
                "Type", "continuous"); 
Betrieb_kt = optimvar("Betrieb_kt", nPP, nT, ...
                "LowerBound",0 , ...
                "UpperBound",1 , ...
                "Type", "integer");
Son_kt = optimvar("Son_kt", nPP, nT, ...
                "LowerBound",0 , ...
                "UpperBound",1 , ...
                "Type", "integer");
Soff_kt = optimvar("Soff_kt", nPP, nT, ...
                "LowerBound",0 , ...
                "UpperBound",1 , ...
                "Type", "integer");
probAP2a.Objective = sum(sum(c_var .* P_kt + c_fix .* Betrieb_kt + c_anf .* Son_kt));
probAP2a.Constraints.demand = optimconstr(nT,1);
for l = 1:nT
     probAP1.Constraints.demand(l) = sum(P_kt(:,l)) == Power_Demand(l);
end
probAP2a.Constraints.leistungsintervalle = optimconstr(nPP, nT);
for i = 1:nPP
    for j= 1:nT 
        probAP2a.Constraints.leistungsintervalle(i,J) = [
            P_kt(i,j) >= Pmin(i,j) * Betrieb_kt(i,j),
            P_kt(i,j) >= UB_P(i,j) * Betrieb_kt(i,j)
        ];
    end
end


solAP2a = probAP2a.solve("Solver","intlinprog");


    
%% Graphische Auswertung der berechneten Lösung

%Darstellung der im Betrieb befindlichen Kraftwerke zur Deckung des Lastgangs

%Darstellung der Grenzkosten im Verlauf des Optimierungszeitraums
    
    
