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
clear all; 
clc;
KEP_Data_Vorlage;

% Problemdimensionen
nPP = size(kwData, 1);  % Anzahl Kraftwerke
nT = T;                 % Anzahl Zeitschritte

% Datenmatrizen
UB_P = repmat(kwData(:,5), 1, nT);   % Maximale Leistung (kW)
c_var = repmat(kwData(:,6), 1, nT);  % Variable Kosten (€/kWh)
Pmin = repmat(kwData(:,4), 1, nT);   % Minimale Leistung (kW)
c_fix = repmat(kwData(:,7), 1, nT);  % Fixkosten (€/h)

% Optimierungsproblem
probAP2a = optimproblem('Description', 'Kostenminimierung', 'ObjectiveSense', 'min');

% Variablen
P_kt = optimvar('P_kt', nPP, nT, 'LowerBound', 0, 'UpperBound', UB_P, 'Type', 'continuous');
Betrieb_kt = optimvar('Betrieb_kt', nPP, nT, 'LowerBound', 0, 'UpperBound', 1, 'Type', 'integer');

% Zielfunktion
probAP2a.Objective = sum(sum(c_var .* P_kt + c_fix .* Betrieb_kt));

% Nebenbedingungen
probAP2a.Constraints.demand = sum(P_kt, 1) == Power_Demand';
probAP2a.Constraints.minPower = P_kt >= Pmin .* Betrieb_kt;
probAP2a.Constraints.maxPower = P_kt <= UB_P .* Betrieb_kt;

% Lösung
[solAP2a, fval] = solve(probAP2a, 'Solver', 'intlinprog');

% Bereinige negative Werte (numerische Artefakte)
solAP2a.P_kt(solAP2a.P_kt < 0) = 0;

% Ausgabe (kompakt wie in deiner Version)
disp('=== OPTIMIERUNGSERGEBNIS ===');
fprintf('Gesamtkosten: %.2f €\n\n', fval);

disp('Leistungsabgabe (kW):');
disp(round(solAP2a.P_kt));  % Ganzzahlige Rundung für Lesbarkeit

disp('Betriebsstatus (1=ON, 0=OFF):');
disp(round(solAP2a.Betrieb_kt));  % Sicherstellung, dass nur 0 oder 1 angezeigt wird



%% Graphische Auswertung der berechneten Lösung
% Farben für Plot (optional)
farben = lines(nPP);

% Leistungsabgabe plotten
figure;
hold on;
for k = 1:nPP
    plot(1:nT, solAP2a.P_kt(k,:), '-o', 'Color', farben(k,:), 'DisplayName', sprintf('KW %d', k));
end
xlabel('Zeitschritt');
ylabel('Leistung (kW)');
title('Leistungsabgabe der Kraftwerke');
legend('Location','bestoutside');
grid on;
hold off;

% Betriebsstatus plotten
figure;
imagesc(round(solAP2a.Betrieb_kt));
colormap(gray);
xlabel('Zeitschritt');
ylabel('Kraftwerk');
title('Betriebsstatus (1 = AN, 0 = AUS)');
colorbar;
yticks(1:nPP);
xticks(1:nT);

%Darstellung der im Betrieb befindlichen Kraftwerke zur Deckung des Lastgangs

%Darstellung der Grenzkosten im Verlauf des Optimierungszeitraums
    
    
