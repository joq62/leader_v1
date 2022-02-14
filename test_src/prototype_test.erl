%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(prototype_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("log.hrl").
%-include("configs.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
   %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
  %  io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start cluster_start()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cluster_start(),
    io:format("~p~n",[{"Stop cluster_starto()",?MODULE,?FUNCTION_NAME,?LINE}]),


%   io:format("~p~n",[{"Start killnode()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=killnode(),
    io:format("~p~n",[{"Stop killnode()",?MODULE,?FUNCTION_NAME,?LINE}]),


%   io:format("~p~n",[{"Start addnodes()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=addnodes(),
    io:format("~p~n",[{"Stop addnodes()",?MODULE,?FUNCTION_NAME,?LINE}]),




 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.

 %  io:format("application:which ~p~n",[{application:which_applications(),?FUNCTION_NAME,?MODULE,?LINE}]),

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
addnodes()->
    [Vm2,Vm3]=lists:delete(node(),nodes()),
    Leader=rpc:call(Vm3,leader,who_is_leader,[],5*1000),
    io:format("Leader   ~p~n",[{Leader,?MODULE,?FUNCTION_NAME,?LINE}]),
    
    %Add newer node
    {ok,Vm1}=test_nodes:start_slave("h200"),
    
    [rpc:call(Vm1,net_adm,ping,[N],5000)||N<-lists:delete(node(),nodes())],
    {ok,_}=rpc:call(Vm1,sd,start,[],5*1000),
    ok=rpc:call(Vm1,application,set_env,[[{leader,[{application,leader}]}]],5*1000),
    ok=rpc:call(Vm1,application,start,[leader],5*1000),
    timer:sleep(3000),

    [Vm1,Vm2,Vm3]=lists:sort(lists:delete(node(),nodes())), 

    Vm1=rpc:call(Vm1,leader,who_is_leader,[],5*1000),
    Vm1=rpc:call(Vm2,leader,who_is_leader,[],5*1000),
    Vm1=rpc:call(Vm3,leader,who_is_leader,[],5*1000),
    

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------



killnode()->
    [Vm1,Vm2,Vm3]=test_nodes:get_nodes(),
    Vm1=rpc:call(Vm2,leader,who_is_leader,[],5*1000),
    
 %   io:format("Leader   ~p~n",[{Leader,?MODULE,?FUNCTION_NAME,?LINE}]),
    %Kill leader
    rpc:call(Vm1,init,stop,[],1000),
    timer:sleep(3000),
    Vm2=rpc:call(Vm3,leader,who_is_leader,[],5*1000),
   % false=Leader=:=NewLeader,
   % io:format("NewLeader   ~p~n",[{NewLeader,?MODULE,?FUNCTION_NAME,?LINE}]),
    ok.    


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
cluster_start()->
    [Vm1,Vm2,Vm3]=test_nodes:get_nodes(),
    % Start first node
    {ok,_}=rpc:call(Vm1,sd,start,[],5*1000),
    ok=rpc:call(Vm1,application,set_env,[[{leader,[{application,leader}]}]],5*1000),
    ok=rpc:call(Vm1,application,start,[leader],5*1000),
    timer:sleep(3000),
    Vm1=rpc:call(Vm1,leader,who_is_leader,[],5*1000),
    io:format("Vm1 leader ~p~n",[{rpc:call(Vm1,leader,who_is_leader,[],5*1000),
				 ?MODULE,?FUNCTION_NAME,?LINE}]),
    % Start second node
    {ok,_}=rpc:call(Vm2,sd,start,[],5*1000),
    ok=rpc:call(Vm2,application,set_env,[[{leader,[{application,leader}]}]],5*1000),
    ok=rpc:call(Vm2,application,start,[leader],5*1000),
    timer:sleep(3000),

    Vm1=rpc:call(Vm1,leader,who_is_leader,[],5*1000),
    Vm1=rpc:call(Vm2,leader,who_is_leader,[],5*1000),
    
  % Start third node
    {ok,_}=rpc:call(Vm3,sd,start,[],5*1000),
    ok=rpc:call(Vm3,application,set_env,[[{leader,[{application,leader}]}]],5*1000),
    ok=rpc:call(Vm3,application,start,[leader],5*1000),
    timer:sleep(3000),

    Vm1=rpc:call(Vm1,leader,who_is_leader,[],5*1000),
    Vm1=rpc:call(Vm2,leader,who_is_leader,[],5*1000),
    Vm1=rpc:call(Vm3,leader,who_is_leader,[],5*1000),

    
    
    ok.
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
    % suppor debugging
    ok=application:start(sd),

    % Simulate host
    ok=test_nodes:start_nodes(),
 %   [Vm1|_]=test_nodes:get_nodes(),
    
          
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
   
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
