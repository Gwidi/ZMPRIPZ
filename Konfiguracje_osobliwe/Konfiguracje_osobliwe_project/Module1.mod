MODULE Module1
    CONST robtarget Target_10:=[[373.981007264,201.170409568,628.346294685],[0.698938892,0,0.715181393,-0.000000004],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_20:=[[373.981007247,-206.238421922,628.346289291],[0.698938892,0.000000039,0.715181393,0.000000005],[-1,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    !***********************************************************
    !
    ! Module:  Module1
    !
    ! Description:
    !   <Insert description here>
    !
    ! Author: Gwidon
    !
    ! Version: 1.0
    !
    !***********************************************************
    
    
    !***********************************************************
    !
    ! Procedure main
    !
    !   This is the entry point of your program
    !
    !***********************************************************
    PROC main()
        Path_10;
    ENDPROC
    PROC Path_10()
        MoveL Target_10,v100,fine,tool0\WObj:=wobj0;
        MoveL Target_20,v100,fine,tool0\WObj:=wobj0;
        MoveL Target_10,v100,fine,tool0\WObj:=wobj0;
    ENDPROC
ENDMODULE