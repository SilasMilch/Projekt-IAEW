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
% KwData_Merit_Order = sortrows(kwData, 6);
% format short g;
% disp('Merit order von kw:');
% disp(kwData_Merit_Order);

nPP = size(kwData, 1);
nT = T;

UB = kwData(:, 5);
UB = repmat(UB, 1, nT); 
cost = repmat(kwData(:, 6), 1, nT);

% Erstellen des Optimierungsproblem-Objekts
probAP1 = optimproblem("Description", "Minimieren die kosten", "ObjectiveSense", "min");

% Erstellen der Variablen
P_kt = optimvar("P_kt", nPP, nT, "LowerBound", 0, "UpperBound", UB, "Type", "continuous");

% Erstellen der Zielfunktion
probAP1.Objective = sum(sum(P_kt .* cost));

% Erstellen der Nebenbedingungen
probAP1.Constraints.demand = optimconstr(nT, 1);
for l = 1:nT
    probAP1.Constraints.demand(l) = sum(P_kt(:, l)) == Power_Demand(l);
end

solAP1 = probAP1.solve("Solver", "linprog");

% Gesamt-kosten berechnen
ganzes_kosten = evaluate(probAP1.Objective, solAP1);
format long g;
disp("Totale in €:");
disp(ganzes_kosten);

disp("Leistungsabgabe (kW) von jeder Kraftwerkspark pro Stunde:");
disp(solAP1.P_kt);

%% AP2a

clear;
KEP_Data_Vorlage;  % Sicherstellen, dass die Daten geladen sind

% Parameter
nPP = size(kwData, 1);
nT = T;
UB_P = kwData(:, 5);
UB_P = repmat(UB_P, 1, nT); 
c_var = repmat(kwData(:, 6), 1, nT);
Pmin = repmat(kwData(:, 4), 1, nT);
c_fix = repmat(kwData(:, 7), 1, nT);
c_anf = repmat(kwData(:, 8), 1, nT);
DT = repmat(kwData(:, 9), 1, nT);
BvO = kwData(:, 3);

% Optimierungsproblem erstellen
probAP2a = optimproblem("Description", "minimize cost", "ObjectiveSense", "min"); 

% Variablen erstellen
P_kt = optimvar("P_kt", nPP, nT, "LowerBound", 0, "UpperBound", UB_P, "Type", "continuous"); 
Betrieb_kt = optimvar("Betrieb_kt", nPP, nT, "LowerBound", 0, "UpperBound", 1, "Type", "integer");
Son_kt = optimvar("Son_kt", nPP, nT, "LowerBound", 0, "UpperBound", 1, "Type", "integer");
Soff_kt = optimvar("Soff_kt", nPP, nT, "LowerBound", 0, "UpperBound", 1, "Type", "integer");

% Zielfunktion definieren
probAP2a.Objective = sum(sum(c_var .* P_kt + c_fix .* Betrieb_kt + c_anf .* Son_kt));

% Nachfragebedingungen
probAP2a.Constraints.demand = optimconstr(nT, 1);
for l = 1:nT
    probAP2a.Constraints.demand(l) = sum(P_kt(:, l)) == Power_Demand(l);
end

% Leistungs-Min-Bedingung
probAP2a.Constraints.leistungs_min = optimconstr(nPP, nT);
for i = 1:nPP
    for j = 1:nT
        probAP2a.Constraints.leistungs_min(i, j) = P_kt(i, j) >= Pmin(i, j) .* Betrieb_kt(i, j);
    end
end

% Leistungs-Max-Bedingung
probAP2a.Constraints.leistungs_max = optimconstr(nPP, nT);
for i = 1:nPP
    for j = 1:nT
        probAP2a.Constraints.leistungs_max(i, j) = P_kt(i, j) <= UB_P(i, j) .* Betrieb_kt(i, j);
    end
end

% Start/Stop-Bedingung
probAP2a.Constraints.startup_shutdown = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        if t == 1
            v_prev = double(BvO(j) > 0);  % Zustand von t=1 (Betrieb 1 oder 0)
        else
            v_prev = Betrieb_kt(j, t-1);
        end
        probAP2a.Constraints.startup_shutdown(j, t) = Betrieb_kt(j, t) - v_prev == Son_kt(j, t) - Soff_kt(j, t);
    end
end

% Keine doppelten Start-Stop-Vorgänge
probAP2a.Constraints.no_double_switch = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        probAP2a.Constraints.no_double_switch(j, t) = Son_kt(j, t) + Soff_kt(j, t) <= 1;
    end
end

% Downtime-Bedingung
probAP2a.Constraints.downtime = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        if t > 1  % sicherstellen, dass t-1 nicht 0 wird
            probAP2a.Constraints.downtime(j, t) = sum(1 - Betrieb_kt(j, max(1, t - DT(j) + 1):t-1)) + Son_kt(j, t) <= DT(j);
        end
    end
end

% Lösung des Optimierungsproblems
solAP2a = probAP2a.solve("Solver", "intlinprog");

% Wenn keine Lösung gefunden wird, eine Fehlermeldung ausgeben
if isempty(solAP2a.P_kt) || any(isnan(solAP2a.P_kt), 'all')
    error('Das Optimierungsproblem konnte keine gültige Lösung finden.');
end

% Graphische Auswertung der berechneten Lösung
% Bereinige negative Werte
solAP2a.P_kt(solAP2a.P_kt < 0) = 0;

% Gesamtkosten berechnen
total_cost = sum(sum(c_var .* solAP2a.P_kt + c_fix .* solAP2a.Betrieb_kt));
disp('=== OPTIMIERUNGSERGEBNIS ===');
fprintf('Gesamtkosten: %.2f €\n\n', total_cost);  

% Leistungsabgabe (kW)
disp('Leistungsabgabe (kW):');
disp(round(solAP2a.P_kt));

% Betriebsstatus (1=ON, 0=OFF)
disp('Betriebsstatus (1=ON, 0=OFF):');
disp(round(solAP2a.Betrieb_kt));

% Plot der Leistungsabgabe der Kraftwerke
farben = lines(nPP);
figure;
hold on;
for k = 1:nPP
    plot(1:nT, solAP2a.P_kt(k,:), '-o', 'Color', farben(k,:), 'DisplayName', sprintf('KW %d', k));
end
xlabel('Zeitschritt');
ylabel('Leistung (kW)');
title('Leistungsabgabe der Kraftwerke');
legend('Location', 'bestoutside');
grid on;
hold off;

% Plot des Betriebsstatus
figure;
imagesc(round(solAP2a.Betrieb_kt));
colormap(gray);
xlabel('Zeitschritt');
ylabel('Kraftwerk');
title('Betriebsstatus (1 = AN, 0 = AUS)');
colorbar;
yticks(1:nPP);
xticks(1:nT);

% Anzahl aktiver Kraftwerke je Zeitschritt
aktive_KW = sum(round(solAP2a.Betrieb_kt), 1);
figure;
bar(1:nT, aktive_KW);
xlabel('Zeitschritt');
ylabel('Anzahl aktiver Kraftwerke');
title('Anzahl im Betrieb befindlicher Kraftwerke je Zeitschritt');
grid on;

% Grenzkosten im Verlauf des Optimierungszeitraums
marginal_costs = zeros(1, nT);
for t = 1:nT
    aktiv = round(solAP2a.Betrieb_kt(:, t)) == 1;
    if any(aktiv)
        marginal_costs(t) = max(kwData(aktiv, 6));  % max variable Kosten der aktiven Kraftwerke
    else
        marginal_costs(t) = NaN;  % keine aktiven KW
    end
end

figure;
plot(1:nT, marginal_costs, '-o');
xlabel('Zeitschritt');
ylabel('Grenzkosten (€/kWh)');
title('Grenzkostenverlauf (Merit-Order Preis)');
grid on;
