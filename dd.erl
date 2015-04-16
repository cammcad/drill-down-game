-module(dd).
-author("cfrederick").
-export([attendhut/1,rightface/1,leftface/1,halfrightface/1,halfleftface/1,aboutface/1,handsalute/1,
         paraderest/2,dressrightdress/2,readyfront/1,level/1,start/0,bythenumbers/3,start_by_the_numbers/2]).
-define(COMPASS,[{1,nw},{2,n},{3,ne},{4,e},{5,se},{6,s},{7,sw},{8,w}]).
-define(STARTINGINDEX,6).  %% Start Game Facing South or towards announcer (i.e. phone)

level(Level) ->
    greeting(Level).
greeting(Level) ->
    Greeting = io_lib:format("say \"~p level selected!\"",[Level]),
    os:cmd(Greeting),
    timer:sleep(1500),
    os:cmd("say \"when I call you to attention the drill down will begin!\""),
    timer:sleep(1500),
    os:cmd("say \"good-luck!\""),
    timer:sleep(2500),
    start().

dumpCurrentState(S) -> io:format("~p~n",[S]),
		       Say = io_lib:format("~p",[S]),
		       os:cmd("say " ++ Say).


visualizeDirection(S) ->
    spawn(fun() ->
		  {Compass,CurrentIndex} = S,
		  D = proplists:get_value(CurrentIndex,Compass),
		  io:format("~p~n",[D]) end).

computeNewIndex(Index) when Index > 8 -> Index - 8;
computeNewIndex(Index) when Index < 1 -> Index + 8; 
computeNewIndex(Index) -> Index. 
computeNewDirection(S,TransitionTo) ->
    {Compass,CurrentIndex} = S,
    case TransitionTo of
	rightface -> 
	    NewDirection = {Compass,computeNewIndex(CurrentIndex + 2)},
	    visualizeDirection(NewDirection),
	    NewDirection;
	leftface -> 
	    NewDirection = {Compass,computeNewIndex(CurrentIndex - 2)},
	    visualizeDirection(NewDirection),
	    NewDirection;
	halfrightface -> 
	    NewDirection = {Compass,computeNewIndex(CurrentIndex + 1)},
	    visualizeDirection(NewDirection),
	    NewDirection;
	halfleftface -> 
	    NewDirection = {Compass, computeNewIndex(CurrentIndex - 1)},
	    visualizeDirection(NewDirection),
	    NewDirection;
	aboutface -> 
	    NewDirection = {Compass, computeNewIndex(CurrentIndex + 4)},
	    visualizeDirection(NewDirection),
	    NewDirection;
	_ -> visualizeDirection(S),
	     S
    end.
	    


start() ->
    register(drilldown,spawn(fun() -> attendhut({?COMPASS,?STARTINGINDEX}) end)),
    timer:sleep(3000),
    SendCmd = fun(X) -> drilldown ! X, timer:sleep(3000) end,
    lists:foreach(fun(X) -> SendCmd(X) end,[leftface,leftface,rightface,rightface,halfrightface,aboutface,
					    aboutface,paraderest,handsalute,halfleftface,attendhut,aboutface,
					    rightface,halfrightface,halfleftface,rightface,rightface,aboutface,
					    dressrightdress,aboutface,leftfaceface,leftface,readyfront,
					    halfleftface,rightface,rightface,halfrightface,aboutface,leftface,
					    aboutface,aboutface,rightface,handsalute]).
%% State = {Command,Counts}, StartingIndex = 6 (i.e. south)
start_by_the_numbers(State,StartingIndex) ->
    dumpCurrentState("By the numbers..."),
    spawn(fun() -> bythenumbers(State,StartingIndex,[]) end).		  
		   

handleNextCommand(State) ->
    receive
        attendhut -> attendhut(computeNewDirection(State,attendhut));
	rightface -> rightface(computeNewDirection(State,rightface));
	leftface -> leftface(computeNewDirection(State,leftface));
	halfrightface -> halfrightface(computeNewDirection(State,halfrightface));
	halfleftface -> halfleftface(computeNewDirection(State,halfleftface));
	aboutface -> aboutface(computeNewDirection(State,aboutface));
	handsalute -> handsalute(computeNewDirection(State,handsalute));
	paraderest -> paraderest(computeNewDirection(State,paraderest),true);
	dressrightdress -> dressrightdress(computeNewDirection(State,dressrightdress),true);
	readyfront -> readyfront(computeNewDirection(State,readyfront));
	cancel -> exit(normal)

    end.

attendhut(State) ->
    dumpCurrentState("Attend Hut!"),
    handleNextCommand(State).

rightface(State) ->
    dumpCurrentState("Right Face"),
    handleNextCommand(State).

leftface(State) ->
    dumpCurrentState("Left Face"),
    handleNextCommand(State).

halfrightface(State) ->
    dumpCurrentState("Half Right Face"),
    handleNextCommand(State).

halfleftface(State) ->
    dumpCurrentState("Half Left Face"),
    handleNextCommand(State).

aboutface(State) ->
    dumpCurrentState("About Face"),
    handleNextCommand(State).

handsalute(State) ->
    dumpCurrentState("Hand Salute"),
    handleNextCommand(State).

paraderest(State,ShouldDump) ->
    case ShouldDump of true -> dumpCurrentState("Parade Rest"); false -> dumpCurrentState("") end,
    receive
	attendhut -> attendhut(State);
	X -> %% as you were
	    dumpCurrentState(atom_to_list(X)),
	    timer:sleep(3000),
	    dumpCurrentState("As you were..."),
	    paraderest(State,false)
    end.

dressrightdress(State,ShouldDump) ->
    case ShouldDump of true -> dumpCurrentState("Dress Right Dress"); false -> dumpCurrentState("") end,
    receive
	readyfront -> readyfront(State);
	X  -> %% as you were
	     dumpCurrentState(atom_to_list(X)),
	     timer:sleep(3000),
	     dumpCurrentState("As you were..."),
	     dressrightdress(State,false)
    end.

readyfront(State) ->
    dumpCurrentState("Ready Front"),
    handleNextCommand(State).

%% State = [{Command,Counts}], CurrentIndex = integer -> direction, Acc = "Processed States"
bythenumbers(State,CurrentIndex,Acc) ->    
    receive
	1 -> case State == [] of
		 true ->
		     io:format("~p~n",[State]),
		     bythenumbers(State,CurrentIndex,Acc);
		 false ->
		     {Cmd,Counts} = hd(State),
		     HA = case Acc == [] of true -> []; false -> hd(Acc) end,
		     case HA == [] of 
			 true ->   
			           {_Compass,NewIndex} = computeNewDirection({?COMPASS,CurrentIndex},Cmd),
			           io:format("~p~n",[State]),
			           bythenumbers(State,NewIndex,[{Cmd,1}|Acc]); 
			 false -> 
			     {Command,Cnt} = HA,
			     case Cmd =:= Command andalso Counts =:= Cnt of
				 true -> 
				     {_Compass, NewIndex} = computeNewDirection({?COMPASS,CurrentIndex},Command),
				     NewState = tl(State),
				     io:format("~p~n",[NewState]),
				     bythenumbers(NewState,NewIndex,[{Cmd,1}|Acc]);
				 false ->
				     {_Compass,NewIndex} = computeNewDirection({?COMPASS,CurrentIndex},Command),
				     io:format("~p~n",[State]),
				     bythenumbers(State,NewIndex,[{Cmd,1}|Acc])
			     end
		     end
	     end;  
	2 -> case State == [] of
		 true ->
		     io:format("~p~n",[State]),
		     bythenumbers(State,CurrentIndex,Acc);
		 false ->
		     {Cmd,Counts} = hd(State),
		     {Command,Cnts} = hd(Acc),
		     case Cmd =:= Command andalso Counts =:= Cnts of
			 true ->
			         {_Compass,NewIndex} = computeNewDirection({?COMPASS,CurrentIndex},Cmd),
			         NewState = tl(State),
			         io:format("~p~n",[NewState]),
			         bythenumbers(NewState,NewIndex,[{Cmd,2}|Acc]);
			 false ->
			         {_Compass,NewIndex} = computeNewDirection({?COMPASS,CurrentIndex},Cmd),
			         io:format("~p~n",[State]),
			         bythenumbers(State,NewIndex,[{Cmd,2}|Acc])
		     end
	     end;
	cancel -> exit(normal);
	_ -> %% As you were
	     dumpCurrentState("As you were..."),
	     bythenumbers(State,CurrentIndex,Acc)
    end.
