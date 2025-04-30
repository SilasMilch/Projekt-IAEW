    %Darstellung der im Betrieb befindlichen Kraftwerke zur Deckung des
    %Lastgangs
    scrsz = get(groot,'ScreenSize');                            %Bildschirmgröße in scrsz Speichern
    figure('Position',[scrsz(1) scrsz(2) scrsz(3) scrsz(4)])    %Neues Fenster im Vollbild öffnen
    subplot(2,1,1);         %Fenster in zwei Abschnitte unterteilen und in Abschnitt 1 plotten
    plot(Power_Demand);     %Leistungsnachfrage in einer Kurve plotten
    hold on;                
    Power_Grant = reshape(X, T*N, NoPP);           %Power_Grant mit entpsprechenden Werten aus dem Lösungsvektor X füllen
    Power_Grant = Power_Grant(1:T,1:NoPP);
    bar(Power_Grant,'stacked');     %Power_Grant in gestapeltem Balkendiagramm plotten
    xlabel('Uhrzeit / Stunden');    %X-Achsen Beschriftung
    ylabel('Leistung / MW');        %Y-Achsen Beschriftung
    axis([0 25 0 1600]);            %Achsenskallierung
    legend(KWlegend, 'Location','northeastoutside', 'Orientation','vertical')
    hold off;
    
    %Darstellung der Grenzkosten im Verlauf des Optimierungszeitraums
    kosten = C.*X;                  %Kostenvektor elementweise mit Lösungsvektor multiplizieren
    Kosten_t = reshape(kosten, T, N*NoPP);     %Vektor für Gesamtkosten in den einzelnen Zeitschritten T initialisieren
    Kosten_t = sum(Kosten_t,2)';
    subplot(2,1,2);                 %In Abschnitt 2 der bereits offenen Figure plotten
    plot(Kosten_t);                 %Kosten in einer Kurve plotten
    xlabel('Uhrzeit / Stunden');    %X-Achsen Beschriftung 
    ylabel('Kosten / €/MWh');       %Y-Achsen Beschriftung 
    axis([0 25 0 40000]);           %Achsenskallierung
    
    %Gesamtkosten der einzelnen KW übder die Dauern von T
    Kosten_KW = reshape(kosten, T*N, NoPP);
    Kosten_KW = sum(Kosten_KW);
    
    %Gesamtkosten über T
    Kosten_Gesamt = sum(kosten);
