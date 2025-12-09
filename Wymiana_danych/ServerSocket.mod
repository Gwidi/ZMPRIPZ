MODULE MainModule
    ! --- Deklaracja Narzędzia i Obiektu Pracy ---
    ! Pamiętaj: Te dane musisz zmierzyć/zdefiniować na swoim robocie!
    ! Tutaj są wartości przykładowe (TCP na środku kołnierza, WObj w bazie)
    PERS tooldata PointerTool := [TRUE, [[0,0,150],[1,0,0,0]], [1,[0,0,50],[1,0,0,0],0,0,0]];
    PERS wobjdata Workobject_socket := [FALSE, TRUE, "", [[500,0,300],[1,0,0,0]], [[0,0,0],[1,0,0,0]]];

    ! --- Punkty Stałe ---
    VAR robtarget PHome := [[0,0,0],[1,0,0,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    VAR robtarget PFirst := [[100,0,200],[1,0,0,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]; 
    VAR robtarget PSecond := [[300,0,300],[1,0,0,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    
    
    ! --- Zmienne komunikacyjne ---
    VAR socketdev server_socket;
    VAR socketdev client_socket;
    VAR string received_str;
    VAR string send_ack := "ACK";
    CONST string robot_ip := "127.0.0.1";
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
        MoveJ PHome, v1000, z50, PointerTool \WObj:=Workobject_socket;
        MoveJ PFirst, v1000, z50, PointerTool \WObj:=Workobject_socket;
        MoveL PSecond, v500, fine, PointerTool \WObj:=Workobject_socket;
        
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
            ! Współrzędne z Pythona są teraz lokalne względem Workobject_socket!
            P_var.trans.x := val_x;
            P_var.trans.y := val_y;
            P_var.trans.z := val_z;
            
            ! --- TWÓJ SEKWENCYJNY RUCH (Approach -> Action -> Retract) ---
            
            ! 1. Dojazd 20mm nad punkt (szybko, strefa z20)
            MoveL Offs(P_var,0,0,20), v100, z20, PointerTool \WObj:=Workobject_socket;
            
            ! 2. Zjazd do punktu (wolno, precyzyjnie 'fine')
            ! To jest moment, kiedy narzędzie dotyka punktu (np. P1, P2...)
            MoveL P_var, v20, fine, PointerTool \WObj:=Workobject_socket;
            
            ! (Opcjonalnie: Tutaj można dodać WaitTime 0.5; jeśli to np. zgrzewanie lub chwytanie)
            
            ! 3. Odjazd 20mm nad punkt (szybko, strefa z20)
            MoveL Offs(P_var,0,0,20), v100, z20, PointerTool \WObj:=Workobject_socket;
            
            ! --- Koniec sekwencji ---
            
            SocketSend client_socket \Str:=send_ack;
        ENDWHILE

    ReturnHome:
        SocketClose client_socket;
        SocketClose server_socket;
        
        MoveL PSecond, v500, z50, PointerTool \WObj:=Workobject_socket;
        MoveJ PHome, v1000, fine, PointerTool \WObj:=Workobject_socket;
        
    ERROR
        IF ERRNO = ERR_SOCK_TIMEOUT OR ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
            SocketClose server_socket;
            EXIT;
        ENDIF
    ENDPROC
ENDMODULE