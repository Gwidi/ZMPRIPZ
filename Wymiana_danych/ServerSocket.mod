MODULE MainModule
    ! --- Punkty Stałe ---
    VAR robtarget PHome := [[-31.97,-72.53,-187.03],[0.975112,-0.0379626,0.0774618,-0.204241],[0,-1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    VAR robtarget PFirst := [[-36.56,-72.52,-86.14],[0.975104,-0.0379694,0.0774727,-0.204278],[0,-1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]; 
    VAR robtarget PSecond := [[-0.19,0.52,2.04],[0.975086,-0.0380104,0.0774439,-0.204363],[-1,-1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    
    ! --- Zmienne komunikacyjne ---
    VAR socketdev server_socket;
    VAR socketdev client_socket;
    VAR string received_str;
    VAR string send_ack := "ACK";
    CONST string robot_ip := "150.254.46.80";
    CONST num robot_port := 1025;
    
    ! --- Zmienne pomocnicze ---
    VAR robtarget P_var; ! Zmienna, którą będziemy aktualizować danymi z Pythona
    VAR num val_x; 
    VAR num val_y; 
    VAR num val_z;
    VAR num comma1;
    VAR num comma2;
    VAR num len;
    VAR bool ok;

    PROC Main()
        ! Start: Idź do PSecond i czekaj
        MoveJ PHome, v1000, z50, Tooldata_1 \WObj:=wobj3;
        MoveJ PFirst, v1000, z50, Tooldata_1 \WObj:=wobj3;
        MoveL PSecond, v500, fine, Tooldata_1 \WObj:=wobj3;
        
        TPWrite "Oczekiwanie na wspolrzedne...";

        SocketCreate server_socket;
        SocketBind server_socket, robot_ip, robot_port;
        SocketListen server_socket;
        SocketAccept server_socket, client_socket;
        TPWrite "Polaczono z Pythonem!";
        
        ! Inicjalizacja P_var - pobieramy rotację z PSecond lub ustawiamy [1,0,0,0]
        P_var := PSecond; 
        
        WHILE TRUE DO
            SocketReceive client_socket \Str:=received_str;
            
            IF received_str = "STOP" THEN
                GOTO ReturnHome;
            ENDIF
            
            ! --- Parsowanie (X,Y,Z) ---
            comma1 := StrFind(received_str, 1, ",");
            comma2 := StrFind(received_str, comma1 + 1, ",");
            len := StrLen(received_str);
            
            ok := StrToVal(StrPart(received_str, 1, comma1 - 1), val_x);
            ok := StrToVal(StrPart(received_str, comma1 + 1, comma2 - comma1 - 1), val_y);
            ok := StrToVal(StrPart(received_str, comma2 + 1, len - comma2), val_z);
            
            ! --- Aktualizacja celu ---
            ! Współrzędne z Pythona są teraz lokalne względem wobj3!
            P_var.trans.x := val_x;
            P_var.trans.y := val_y;
            P_var.trans.z := val_z;
            
            ! --- TWÓJ SEKWENCYJNY RUCH (Approach -> Action -> Retract) ---
            
            ! 1. Dojazd 20mm nad punkt (szybko, strefa z20)
            MoveL Offs(P_var,0,0,20), v100, z20, Tooldata_1 \WObj:=wobj3;
            
            ! 2. Zjazd do punktu (wolno, precyzyjnie 'fine')
            ! To jest moment, kiedy narzędzie dotyka punktu (np. P1, P2...)
            MoveL P_var, v20, fine, Tooldata_1 \WObj:=wobj3;
            
            ! (Opcjonalnie: Tutaj można dodać WaitTime 0.5; jeśli to np. zgrzewanie lub chwytanie)
            
            ! 3. Odjazd 20mm nad punkt (szybko, strefa z20)
            MoveL Offs(P_var,0,0,20), v100, z20, Tooldata_1 \WObj:=wobj3;
            
            ! --- Koniec sekwencji ---
            
            SocketSend client_socket \Str:=send_ack;
        ENDWHILE

    ReturnHome:
        SocketClose client_socket;
        SocketClose server_socket;
        
        MoveL PSecond, v500, z50, Tooldata_1 \WObj:=wobj3;
        MoveJ PHome, v1000, fine, Tooldata_1 \WObj:=wobj3;
        
    ERROR
        IF ERRNO = ERR_SOCK_TIMEOUT OR ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
            SocketClose server_socket;
            EXIT;
        ENDIF
    ENDPROC
ENDMODULE