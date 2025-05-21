clc
clear 

%% Einbinden von KEP_Data
KEP_Data_Vorlage

%% Hilfe
% https://de.mathworks.com/help/releases/R2024b/optim/ug/problem-based-workflow.html?searchHighlight=optimproblem&s_tid=doc_srchtitle
% https://de.mathworks.com/help/releases/R2024b/optim/ug/optimproblem.html#d126e144210
% https://de.mathworks.com/help/releases/R2024b/optim/ug/optimvar.html#namevaluepairarguments
% https://de.mathworks.com/help/releases/R2024b/optim/ug/example-linear-programming-via-problem.html

% %% AP1
% % Erstellen des Optimerungsproblem-Objekts
% kwData_Merit_Order = sortrows(kwData, 6);
% format short g;
% disp('Merit order (dalla più economica alla più costosa):');
% disp(kwData_Merit_Order);
% 
% nPP = size(kwData, 1);
% nT = T;
% 
% UB = kwData(:,5);
% UB = repmat(UB, 1, nT);
% cost = repmat(kwData(:,6), 1, nT);
% probAP1 = optimproblem("Description","Minimizzazione costi batterie","ObjectiveSense","min"); % Erstellen des Optimierungproblem-Objects --> Description und Sense füllen
% 
% % Erstellen der Variable(n)
% P_kt = optimvar( "P_kt", nPP, nT, "LowerBound", 0, "UpperBound", UB,"Type", "continuous");% wieviele Variablen?, "LowerBound", LB, ... % lower bounds, "UpperBound", UB, ... % upper bounds, "Type", ""); % Variablentyp: "continuous" oder "integer
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
% 
% %solAP1 = probAP1.solve("Solver", "linprog"); % linprog wenn LP, intelinprog wenn MILP
% 
% solAP1 = probAP1.solve("Solver", "linprog");
% 
% %% Risultati
% 
% total_cost = evaluate(probAP1.Objective, solAP1);
% disp("Costo totale:");
% disp(total_cost);
% 
% disp("Potenza erogata (kW) da ogni batteria per ogni ora:");
% disp(solAP1.P_kt);
% 
% figure;
% plot(1:nT, sum(solAP1.P_kt,1), 'b-', 'LineWidth', 2);
% hold on;
% plot(1:nT, Power_Demand, 'r--', 'LineWidth', 1.5);
% legend('Potenza totale erogata', 'Domanda');
% xlabel('Ora');
% ylabel('Potenza (kW)');
% title('Copertura della domanda oraria');
% grid on;




















% AP2a
clear
KEP_Data_Vorlage
%Erstellen des Optimerungsproblem-Objekts

nPP = size(kwData, 1);
nT= T;
UB_P = kwData(:,5);
UB_P = repmat(UB_P, 1, nT); 
c_var = repmat(kwData(:,6), 1, nT);
Pmin = repmat(kwData(:,4), 1, nT);
c_fix = repmat(kwData(:,7), 1, nT);
c_anf = repmat(kwData(:,8), 1, nT);
DT = repmat(kwData(:,9), 1, nT);
UT = repmat(kwData(:,10), 1, nT);
A = repmat(kwData(:,11), 1, nT);
rf_min = repmat(kwData(:,12), 1, nT);
rf_max = repmat(kwData(:,13), 1, nT);

BvO = kwData(:,3);

probAP2a = optimproblem("Description","minimize cost", "ObjectiveSense","min"); 
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
     probAP2a.Constraints.demand(l) = sum(P_kt(:,l)) == Power_Demand(l);
end
probAP2a.Constraints.leistungs_min = optimconstr(nPP, nT);
for i = 1:nPP
    for j = 1:nT
        probAP2a.Constraints.leistungs_min(i,j) = P_kt(i,j) >= Pmin(i,j) .* Betrieb_kt(i,j);
    end
end

%Vincolo potenza massima
probAP2a.Constraints.leistungs_max = optimconstr(nPP, nT);
for i = 1:nPP
    for j = 1:nT
        probAP2a.Constraints.leistungs_max(i,j) = P_kt(i,j) <= UB_P(i,j) .* Betrieb_kt(i,j);
    end
end

%3. Definizione startup/shutdown
probAP2a.Constraints.startup_shutdown = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        if t == 1
           v_prev = double(BvO(j) > 0);  % stato precedente: acceso (1) o spento (0)
        else
            v_prev = Betrieb_kt(j,t-1);
        end
        probAP2a.Constraints.startup_shutdown(j,t) = Betrieb_kt(j,t) - v_prev == Son_kt(j,t) - Soff_kt(j,t);
    end
end


probAP2a.Constraints.downtime = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 2:nT
        if DT(j) > 0 && t > DT(j)
            % Se voglio accendere in t, devo essere stato spento per almeno DT(j) periodi
            probAP2a.Constraints.downtime(j,t) = sum(Betrieb_kt(j, t - DT(j):t - 1)) <= (1 - Son_kt(j,t)) * DT(j);
        end
    end
end

probAP2a.Constraints.uptime = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT - 1
        if UT(j) > 0 && t + UT(j) - 1 <= nT
            % Se accendo in t, devo rimanere acceso per almeno UT(j) periodi
            probAP2a.Constraints.uptime(j,t) = sum(1 - Betrieb_kt(j, t + 1 : t + UT(j) - 1)) <= (1 - Son_kt(j,t)) * UT(j);
        end
    end
end

probAP2a.Constraints.max_startups = optimconstr(nPP,1);
for j = 1:nPP
    probAP2a.Constraints.max_startups(j) = sum(Son_kt(j,:)) <= A(j,1);
end

probAP2a.Constraints.min_operating = optimconstr(nPP,1);
for j = 1:nPP
    probAP2a.Constraints.min_operating(j) = sum(Betrieb_kt(j,:)) >= rf_min(j,1);
end

probAP2a.Constraints.max_operating = optimconstr(nPP,1);
for j = 1:nPP
    probAP2a.Constraints.max_operating(j) = sum(Betrieb_kt(j,:)) <= rf_max(j,1);
end

%ap4


probAP2a.Constraints.ramping_up = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        if t==1
            Svor = SvO(j);
            Pvor = P_t(j);
        else
            Svor = Betrieb_kt(j, t-1);
            Pvor = P_kt(j, t-1);
        end

        probAP2a.Constraints.ramping_up(j,t) = -UB_P(j,t)<=-P_kt(j,t)+Pvor+(SU_SD(j)-UB_P(j,t))*Betrieb_kt(j,t)+(RU_RD(j)-SU_SD(j))*Svor;
    end
end

probAP2a.Constraints.ramping_down = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        if t==1
            Svor = SvO(j);
            Pvor = P_t(j);
        else
            Svor = Betrieb_kt(j, t-1);
            Pvor = P_kt(j, t-1);
        end

        probAP2a.Constraints.ramping_down(j,t) = 0<=UB_P(j,t)+P_kt(j,t)-Pvor+(SU_SD(j)-UB_P(j,t))*Svor+(RU_RD(j)-SU_SD(j))*Betrieb_kt(j,t);
    end
end

probAP2a.Constraints.shutting_down = optimconstr(nPP, nT-1);
for j = 1:nPP
    for t = 1:nT-1
        probAP2a.Constraints.shutting_down(j,t) = P_kt(j,t)<=SU_SD(j)*Betrieb_kt(j,t)+(UB_P(j,t)-SU_SD(j))*Betrieb_kt(j, t+1);
    end
end

%ap5


%
probAP2a.Constraints.isuc_1 = optimconstr(nPP, nT);
probAP2a.Constraints.isuc_alle = optimconstr(nPP, nT);

for j = 1:nPP
%     for t = 1:nT
%         if t == 1
            if SvO(j)==0 && abs(BvO(j)) >= CT(j)
                probAP2a.Constraints.isuc_1(j, t) = Isuc_kt(j, t) >= Son_kt(j, t);
            else
                probAP2a.Constraints.isuc_1(j, t) = Isuc_kt(j, t) == 0;
            end
            for t = 2:nT
            probAP2a.Constraints.isuc_alle(j, t-1) = Isuc_kt(j, t) >= Son_kt(j, t) - sum(Betrieb_kt(j, max(1, t- CT(j)):(t-1)));
            end
    %end
end

probAP2a.Constraints.Blb_Indikator = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        if isempty(max(1, t - CT(j)):(T-1))
            vSumExpr = 0;
        else
            vSumExpr = sum(Betrieb_kt(j, max(1, t - CT(j)):(T-1)));
        end

        probAP2a.Constraints.Blb_Indikator(j, t) = Blc_kt(j,t) <= vSumExpr + Isuc_kt(j,t);
    end
end



probAP2a.Constraints.cold_cost = optimconstr(nPP, nT);
for j = 1:nPP
    for t = 1:nT
        probAP2a.Constraints.cold_cost(j,t) = Son_kt(j,t)+Isuc_kt(j,t)<=1+Suc_kt(j,t);
    end
end

solAP2a = probAP2a.solve("Solver","intlinprog");



% Graphische Auswertung der berechneten Lösung

%Darstellung der im Betrieb befindlichen Kraftwerke zur Deckung des Lastgangs

%Darstellung der Grenzkosten im Verlauf des Optimierungszeitraums
%Bereinige negative Werte (numerische Artefakte)
solAP2a.P_kt(solAP2a.P_kt < 0) = 0;
%Ausgabe (kompakt wie in deiner Version)
total_cost = sum(sum(c_var .* solAP2a.P_kt + c_fix .* solAP2a.Betrieb_kt));
disp('=== OPTIMIERUNGSERGEBNIS ===');
fprintf('Gesamtkosten: %.2f €\n\n', total_cost);  % Assicurati che fval sia disponibile nel tuo script

disp('Leistungsabgabe (kW):');
disp(round(solAP2a.P_kt));  % Ganzzahlige Rundung für Lesbarkeit

disp('Betriebsstatus (1=ON, 0=OFF):');
disp(round(solAP2a.Betrieb_kt));

% Estrai le soluzioni ottimali
P_kt_sol = solAP2a.P_kt;
Betrieb_kt_sol = solAP2a.Betrieb_kt;
Son_kt_sol = solAP2a.Son_kt;

% Inizializza vettore per il costo totale per giorno
total_cost_per_day = zeros(nT, 1);

% Calcola e stampa il costo per ciascun giorno
for t = 1:nT
    cost_var = sum(c_var(:,t) .* P_kt_sol(:,t));
    cost_fix = sum(c_fix(:,t) .* Betrieb_kt_sol(:,t));
    cost_startup = sum(c_anf(:,t) .* Son_kt_sol(:,t));
    total_cost_per_day(t) = cost_var + cost_fix + cost_startup;
    
    fprintf('Giorno %d: Costo variabile = %.2f, Costo fisso = %.2f, Costo startup = %.2f, Costo totale = %.2f\n', ...
        t, cost_var, cost_fix, cost_startup, total_cost_per_day(t));
end

farben = lines(nPP);

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

%Betriebsstatus plotten
figure;
imagesc(round(solAP2a.Betrieb_kt));
colormap(gray);
xlabel('Zeitschritt');
ylabel('Kraftwerk');
title('Betriebsstatus (1 = AN, 0 = AUS)');
colorbar;
yticks(1:nPP);
xticks(1:nT);

%Darstellung der im Betrieb befindlichen Kraftwerke zur Deckung des Lastgangs (aus Betrieb_kt)
aktive_KW = sum(round(solAP2a.Betrieb_kt), 1);  % Zeilenweise Summe

figure;
bar(1:nT, aktive_KW);
xlabel('Zeitschritt');
ylabel('Anzahl aktiver Kraftwerke');
title('Anzahl im Betrieb befindlicher Kraftwerke je Zeitschritt');
grid on;

%Darstellung der Grenzkosten im Verlauf des Optimierungszeitraums
%Berechnung der Grenzkosten
marginal_costs = zeros(1, nT);
for t = 1:nT
    aktiv = round(solAP2a.Betrieb_kt(:,t)) == 1;
    if any(aktiv)
        marginal_costs(t) = max(kwData(aktiv,6));  % max variable Kosten der aktiven Kraftwerke
    else
        marginal_costs(t) = NaN;  % keine aktiven KW – optional behandeln
    end
end

figure;
plot(1:nT, marginal_costs, '-o');
xlabel('Zeitschritt');
ylabel('Grenzkosten (€/kWh)');
title('Grenzkostenverlauf (Merit-Order Preis)');
grid on;
