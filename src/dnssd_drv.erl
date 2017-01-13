%% -------------------------------------------------------------------
%%
%% Copyright (c) 2011 Andrew Tunnell-Jones. All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
%% @private
-module(dnssd_drv).

-behaviour(gen_server).

%% API
-export([start_link/1, stop/1]).
-export([results/1]).
-export([load/0, unload/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

%% Silence Avahi warning
-ifdef(AVAHI).
-on_load(set_avahi_compat_nowarn/0).
-endif.

-record(state, {notify,
		op,
		arg,
		port,
		results = [],
		rcount = dict:new()}).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-define(DRIVER_NAME, ?MODULE_STRING).

-define(DRV_CMD_ENUM        , 0).
-define(DRV_CMD_BROWSE      , 1).
-define(DRV_CMD_RESOLVE     , 2).
-define(DRV_CMD_REGISTER    , 3).
-define(DRV_CMD_QUERY_RECORD, 4).

-define(ERR_NOERROR                   , 0).
-define(ERR_UNKNOWN                   , -65537).
-define(ERR_NOSUCHNAME                , -65538).
-define(ERR_NOMEMORY                  , -65539).
-define(ERR_BADPARAM                  , -65540).
-define(ERR_BADREFERENCE              , -65541).
-define(ERR_BADSTATE                  , -65542).
-define(ERR_BADFLAGS                  , -65543).
-define(ERR_UNSUPPORTED               , -65544).
-define(ERR_NOTINITIALIZED            , -65545).
-define(ERR_ALREADYREGISTERED         , -65547).
-define(ERR_NAMECONFLICT              , -65548).
-define(ERR_INVALID                   , -65549).
-define(ERR_FIREWALL                  , -65550).
-define(ERR_INCOMPATIBLE              , -65551).
-define(ERR_BADINTERFACEINDEX         , -65552).
-define(ERR_REFUSED                   , -65553).
-define(ERR_NOSUCHRECORD              , -65554).
-define(ERR_NOAUTH                    , -65555).
-define(ERR_NOSUCHKEY                 , -65556).
-define(ERR_NATTRAVERSAL              , -65557).
-define(ERR_DOUBLENAT                 , -65558).
-define(ERR_BADTIME                   , -65559).
-define(ERR_BADSIG                    , -65560).
-define(ERR_BADKEY                    , -65561).
-define(ERR_TRANSIENT                 , -65562).
-define(ERR_SERVICENOTRUNNING         , -65563).
-define(ERR_NATPORTMAPPINGUNSUPPORTED , -65564).
-define(ERR_NATPORTMAPPINGDISABLED    , -65565).
-define(ERR_NOROUTER                  , -65566).
-define(ERR_POLLINGMODE               , -65567).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc Load port driver
%% @spec load() -> ok | {error, Error}
%% @end
%%--------------------------------------------------------------------
load() ->
    {ok, Drivers} = erl_ddll:loaded_drivers(),
    case lists:member(?DRIVER_NAME, Drivers) of
	true -> ok;
	false ->
	    case erl_ddll:load(priv_dir(), ?DRIVER_NAME) of
		ok -> ok;
		{error, Error} ->
		    error_logger:error_msg(
		      ?MODULE_STRING ": Error loading ~p: ~p~n",
		      [?DRIVER_NAME, erl_ddll:format_error(Error)]
		     ),
		    {error, Error}
	    end
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc Unload port driver
%% @spec unload() -> ok | {error, Error}
%% @end
%%--------------------------------------------------------------------
unload() ->
    case erl_ddll:unload_driver(?DRIVER_NAME) of
	ok -> ok;
	{error, Error} ->
	    error_logger:error_msg(
	      ?MODULE_STRING ": Error unloading ~p: ~p~n",
	      [?DRIVER_NAME, erl_ddll:format_error(Error)]
	     ),
	    {error, Error}
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc Starts the server
%% @spec start_link(Arg) -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(Arg) when is_tuple(Arg) ->
    gen_server:start_link(?MODULE, {self(), Arg}, []).

%%--------------------------------------------------------------------
%% @private
%% @doc Return current results
%% @spec results(Pid) -> {ok, Results}
%% @end
%%--------------------------------------------------------------------
results(Pid) when is_pid(Pid) ->
    gen_server:call(Pid, results).

%%--------------------------------------------------------------------
%% @private
%% @doc Stop the server
%% @spec stop(Pid) -> ok | {error, Error}
%% @end
%%--------------------------------------------------------------------
stop(Pid) when is_pid(Pid) ->
    gen_server:call(Pid, stop).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init({Pid, Arg}) when is_pid(Pid) andalso is_tuple(Arg) ->
    DrvPort = drv_open(),
    Init = case Arg of
	       {enumerate, Type}
		 when Type =:= browse orelse Type =:= reg ->
		   drv_enumerate(DrvPort, Type);
	       {browse, Type, Domain} ->
		   drv_browse(DrvPort, Type, Domain);
	       {resolve, Name, Type, Domain} ->
		   drv_resolve(DrvPort, Name, Type, Domain);
	       {register, Name, Type, Domain, Host, Port, Txt} ->
		   drv_register(DrvPort, Name, Type, Domain, Host, Port, Txt);
	       {query_record, Domain, RType} ->
		   drv_query_record(DrvPort, Domain, RType);
	       _ ->
		   {error, bad_op}
	   end,
    case Init of
	ok ->
	    State = #state{notify = Pid,
			   op = element(1, Arg),
			   arg = Arg,
			   port = DrvPort},
	    {ok, State};
	{error, Error} ->
	    ok = drv_close(DrvPort),
	    {stop, Error}
    end;
init(_) -> {stop, bad_op}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(results, _From, #state{results = Results} = State) ->
    Reply = {ok, Results},
    {reply, Reply, State};
handle_call(stop, _From, State) ->
    {stop, normal, ok, State};
handle_call(Request, _From, State) ->
    error_logger:info_msg(?MODULE_STRING " ~p ignoring call: ~p~n",
			  [ self(), Request]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(Msg, State) ->
    error_logger:info_msg(?MODULE_STRING " ~p ignoring cast: ~p~n",
			  [ self(), Msg]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info({Port, error, ErrNo}, #state{port = Port} = State) ->
    %% I think these errors are benign
    IgnoreList = [?ERR_NOERROR,
		  ?ERR_NOSUCHKEY,
		  ?ERR_NATTRAVERSAL,
		  ?ERR_DOUBLENAT,
		  ?ERR_BADKEY,
		  ?ERR_BADSIG,
		  ?ERR_BADTIME,
		  ?ERR_TRANSIENT,
		  ?ERR_NATPORTMAPPINGUNSUPPORTED,
		  ?ERR_NATPORTMAPPINGDISABLED,
		  ?ERR_NOROUTER,
		  ?ERR_POLLINGMODE],
    case lists:member(ErrNo, IgnoreList) of
	true -> {noreply, State};
	false -> {stop, {error, ErrNo, error_msg(ErrNo)}, State}
    end;
handle_info({Port, enumerate, {Flags, Domain}}, #state{port = Port} = State) ->
    NewState = case flags_add(Flags) of
		   true -> add_result(Domain, State);
		   false -> remove_result(Domain, State)
	       end,
    {noreply, NewState};
handle_info({Port, browse, {Flags, _IfIndex, Name, Type, Domain}},
	    #state{port = Port} = State) ->
    Result = {Name, Type, Domain},
    NewState = case flags_add(Flags) of
		   true -> add_result(Result, State);
		   false -> remove_result(Result, State)
	       end,
    {noreply, NewState};
handle_info({DrvPort, resolve, {_Flags, _IfIndex, _Fullname, Host, Port, Txt}},
	    #state{notify = Notify, port = DrvPort} = State) ->
    TxtStrings = decode_txt(Txt),
    Result = {Host, Port, TxtStrings},
    NewResults = [Result],
    case State#state.results of
	NewResults ->
	    {noreply, State};
	_ ->
	    NewState = State#state{results = NewResults},
	    Notify ! {?MODULE, self(), {resolve, Result}},
	    {noreply, NewState}
    end;
handle_info({Port, register, {Flags, Name, Type, Domain}},
	    #state{port = Port} = State) ->
    Result = {Name, Type, Domain},
    NewState = case flags_add(Flags) of
		   true -> add_result(Result, State);
		   false -> remove_result(Result, State)
	       end,
    {noreply, NewState};
handle_info({Port, query_record, {Flags, _IfIndex, Domain, RType, RClass, RData}},
	    #state{port = Port} = State) ->
    Result = {Domain, dns_service_type(RType), dns_service_class(RClass), RData},
    NewState = case flags_add(Flags) of
		   true -> add_result(Result, State);
		   false -> remove_result(Result, State)
	       end,
    {noreply, NewState};
handle_info(Info, State) ->
    error_logger:info_msg(?MODULE_STRING " ~p discarded message: ~p~n",
			  [ self(), Info]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, #state{port = Port} = _State) ->
    drv_close(Port),
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% Silence Avahi warning

-ifdef(AVAHI).
set_avahi_compat_nowarn() ->
    true = os:putenv("AVAHI_COMPAT_NOWARN", "1"),
    Rel = erlang:system_info(otp_release),
    case lists:prefix("R13", Rel) of
	true when Rel =/= "R13B04" -> true;
	_ -> ok
    end.
-endif.

%% Result tracking

add_result(Result, #state{notify = Notify,
			  op = Op,
			  results = Results,
			  rcount = Rcount} = State) ->
    Key = erlang:phash2(Result),
    NewRcount = dict:update_counter(Key, 1, Rcount),
    case lists:member(Result, Results) of
	false ->
	    Notify ! {?MODULE, self(), {Op, add, Result}},
	    State#state{results = [Result|Results],
			rcount = NewRcount};
	true ->
	    State#state{results = Results,
			rcount = NewRcount}
    end.

remove_result(Result, #state{notify = Notify,
			     op = Op,
			     results = Results,
			     rcount = Rcount} = State) ->
    Key = erlang:phash2(Result),
    NewRcount = dict:update_counter(Key, -1, Rcount),
    case dict:fetch(Key, NewRcount) of
	I when I =< 0 ->
	    Notify ! {?MODULE, self(), {Op, remove, Result}},
	    State#state{results = lists:delete(Result, Results),
			rcount = dict:erase(Key, NewRcount)};
	I when I > 0 ->
	    State#state{rcount = NewRcount}
    end.

%% Driver comms

drv_open() ->
    try erlang:open_port({spawn_driver, ?DRIVER_NAME}, [binary])
    catch error:badarg ->
	    case load() of
		ok -> erlang:open_port({spawn_driver, ?DRIVER_NAME}, [binary]);
		{error, _Reason} = Error -> Error
	    end
    end.

drv_close(Port) when is_port(Port) ->
    try erlang:port_close(Port), ok
    catch error:badarg -> ok end.

drv_enumerate(Port, Type)
  when is_port(Port), (Type =:= browse orelse Type =:= reg) ->
    erlang:port_call(Port, ?DRV_CMD_ENUM, Type).

drv_browse(Port, Type, Domain)
  when is_port(Port), is_binary(Type), is_binary(Domain) ->
    erlang:port_call(Port, ?DRV_CMD_BROWSE, {Type, Domain}).

drv_resolve(Port, Name, Type, Domain)
  when is_port(Port), is_binary(Name), is_binary(Type), is_binary(Domain) ->
    erlang:port_call(Port, ?DRV_CMD_RESOLVE, {Name, Type, Domain}).

drv_register(ErlPort, Name, Type, Domain, Host, Port, Txt)
  when is_port(ErlPort), is_binary(Name), is_binary(Type), is_binary(Domain),
       is_binary(Host), is_integer(Port), is_binary(Txt) ->
    Data = {Name, Type, Domain, Host, Port, Txt},
    erlang:port_call(ErlPort, ?DRV_CMD_REGISTER, Data).

drv_query_record(ErlPort, Domain, RType)
  when is_port(ErlPort), is_binary(Domain), is_binary(RType) ->
    Data = {Domain, RType},
    erlang:port_call(ErlPort, ?DRV_CMD_QUERY_RECORD, Data).

%% Misc

priv_dir() ->
    case code:priv_dir(dnssd) of
	List when is_list(List) -> List;
	{error, bad_name} ->
	    filename:join(filename:dirname(code:which(?MODULE)), "../priv")
    end.

flags_add(Int) when is_integer(Int) -> 0 =/= Int band 16#2.

decode_txt(Txt) when is_binary(Txt) ->
    [ decode_txt_pair(String) || <<Size, String:Size/binary>> <= Txt ].

decode_txt_pair(Txt) -> decode_txt_pair(<<>>, Txt).

decode_txt_pair(String, <<>>) -> String;
decode_txt_pair(Key, <<$=, Value/binary>>) -> {Key, Value};
decode_txt_pair(Key, <<S, Rest/binary>>) ->
    decode_txt_pair(<<Key/binary, S>>, Rest).

error_msg(?ERR_NOERROR) -> "no error";
error_msg(?ERR_UNKNOWN) -> "unknown";
error_msg(?ERR_NOSUCHNAME) -> "no such name";
error_msg(?ERR_NOMEMORY) -> "no memory";
error_msg(?ERR_BADPARAM) -> "bad param";
error_msg(?ERR_BADREFERENCE) -> "bad reference";
error_msg(?ERR_BADSTATE) -> "bad state";
error_msg(?ERR_BADFLAGS) -> "bad flags";
error_msg(?ERR_UNSUPPORTED) -> "unsupported";
error_msg(?ERR_NOTINITIALIZED) -> "not initialized";
error_msg(?ERR_ALREADYREGISTERED) -> "already registered";
error_msg(?ERR_NAMECONFLICT) -> "name conflict";
error_msg(?ERR_INVALID) -> "invalid";
error_msg(?ERR_FIREWALL) -> "firewall";
error_msg(?ERR_INCOMPATIBLE) -> "incompatible";
error_msg(?ERR_BADINTERFACEINDEX) -> "bad interface index";
error_msg(?ERR_REFUSED) -> "refused";
error_msg(?ERR_NOSUCHRECORD) -> "no such record";
error_msg(?ERR_NOAUTH) -> "no auth";
error_msg(?ERR_NOSUCHKEY) -> "no such key";
error_msg(?ERR_NATTRAVERSAL) -> "NAT traversal";
error_msg(?ERR_DOUBLENAT) -> "double-NAT";
error_msg(?ERR_BADTIME) -> "bad time";
error_msg(?ERR_BADSIG) -> "bad sig";
error_msg(?ERR_BADKEY) -> "bad key";
error_msg(?ERR_TRANSIENT) -> "transient";
error_msg(?ERR_SERVICENOTRUNNING) -> "service not running";
error_msg(?ERR_NATPORTMAPPINGUNSUPPORTED) -> "NAT port mapping unsupported";
error_msg(?ERR_NATPORTMAPPINGDISABLED) -> "NAT port mapping disabled";
error_msg(?ERR_NOROUTER) -> "no router";
error_msg(?ERR_POLLINGMODE) -> "polling mode";
error_msg(_) -> "undefined".

%% dns-sd.h:kDNSServiceType
dns_service_type(  1) -> <<"A">>;
dns_service_type(  2) -> <<"NS">>;
dns_service_type(  3) -> <<"MD">>;
dns_service_type(  4) -> <<"MF">>;
dns_service_type(  5) -> <<"CNAME">>;
dns_service_type(  6) -> <<"SOA">>;
dns_service_type(  7) -> <<"MB">>;
dns_service_type(  8) -> <<"MG">>;
dns_service_type(  9) -> <<"MR">>;
dns_service_type( 10) -> <<"NULL">>;
dns_service_type( 11) -> <<"WKS">>;
dns_service_type( 12) -> <<"PTR">>;
dns_service_type( 13) -> <<"HINFO">>;
dns_service_type( 14) -> <<"MINFO">>;
dns_service_type( 15) -> <<"MX">>;
dns_service_type( 16) -> <<"TXT">>;
dns_service_type( 17) -> <<"RP">>;
dns_service_type( 18) -> <<"AFSDB">>;
dns_service_type( 19) -> <<"X25">>;
dns_service_type( 20) -> <<"ISDN">>;
dns_service_type( 21) -> <<"RT">>;
dns_service_type( 22) -> <<"NSAP">>;
dns_service_type( 23) -> <<"NSAP_PTR">>;
dns_service_type( 24) -> <<"SIG">>;
dns_service_type( 25) -> <<"KEY">>;
dns_service_type( 26) -> <<"PX">>;
dns_service_type( 27) -> <<"GPOS">>;
dns_service_type( 28) -> <<"AAAA">>;
dns_service_type( 29) -> <<"LOC">>;
dns_service_type( 30) -> <<"NXT">>;
dns_service_type( 31) -> <<"EID">>;
dns_service_type( 32) -> <<"NIMLOC">>;
dns_service_type( 33) -> <<"SRV">>;
dns_service_type( 34) -> <<"ATMA">>;
dns_service_type( 35) -> <<"NAPTR">>;
dns_service_type( 36) -> <<"KX">>;
dns_service_type( 37) -> <<"CERT">>;
dns_service_type( 38) -> <<"A6">>;
dns_service_type( 39) -> <<"DNAME">>;
dns_service_type( 40) -> <<"SINK">>;
dns_service_type( 41) -> <<"OPT">>;
dns_service_type( 42) -> <<"APL">>;
dns_service_type( 43) -> <<"DS">>;
dns_service_type( 44) -> <<"SSHFP">>;
dns_service_type( 45) -> <<"IPSECKEY">>;
dns_service_type( 46) -> <<"RRSIG">>;
dns_service_type( 47) -> <<"NSEC">>;
dns_service_type( 48) -> <<"DNSKEY">>;
dns_service_type( 49) -> <<"DHCID">>;
dns_service_type( 50) -> <<"NSEC3">>;
dns_service_type( 51) -> <<"NSEC3PARAM">>;
dns_service_type( 55) -> <<"HIP">>;
dns_service_type( 99) -> <<"SPF">>;
dns_service_type(100) -> <<"UINFO">>;
dns_service_type(101) -> <<"UID">>;
dns_service_type(102) -> <<"GID">>;
dns_service_type(103) -> <<"UNSPEC">>;
dns_service_type(249) -> <<"TKEY">>;
dns_service_type(250) -> <<"TSIG">>;
dns_service_type(251) -> <<"IXFR">>;
dns_service_type(252) -> <<"AXFR">>;
dns_service_type(253) -> <<"MAILB">>;
dns_service_type(254) -> <<"MAILA">>;
dns_service_type(255) -> <<"ANY">>;
dns_service_type(  S) -> integer_to_binary(S).

%% dns-sd.h:kDNSServiceClass
dns_service_class(1) -> <<"IN">>;
dns_service_class(C) -> integer_to_binary(C).

%%%===================================================================
%%% Tests
%%%===================================================================

-ifdef(TEST).

%% Result tracking

add_result_new_test_() ->
    Result = a,
    Key = erlang:phash2(Result),
    InRcount = dict:new(),
    OutRcount = dict:update_counter(Key, 1, InRcount),
    State = #state{notify = self(), results = [], rcount = InRcount},
    ExpectedState = State#state{results = [a], rcount = OutRcount},
    ResultState = add_result(a, State),
    ExpectedMessage = {?MODULE, self(), {undefined, add, Result}},
    RecMessage = receive X -> X after 1000 -> timeout end,
    [?_assertEqual(ExpectedState, ResultState),
     ?_assertEqual(ExpectedMessage, RecMessage)].

add_result_existing_test_() ->
    Result = a,
    Key = erlang:phash2(Result),
    InRcount = dict:from_list([{Key, 1}]),
    OutRcount = dict:update_counter(Key, 1, InRcount),
    In = #state{results = [a], rcount = InRcount},
    Out = In#state{rcount = OutRcount},
    ?_assertEqual(Out, add_result(a, In)).

remove_result_last_test_() ->
    Result = a,
    Key = erlang:phash2(Result),
    Rcount = dict:from_list([{Key, 1}]),
    State = #state{notify = self(), results = [a], rcount = Rcount},
    ExpectedState = State#state{results = [], rcount = dict:new()},
    ResultState = remove_result(a, State),
    ExpectedMessage = {?MODULE, self(), {undefined, remove, Result}},
    RecMessage = receive X -> X after 1000 -> timeout end,
    [?_assertEqual(ExpectedState, ResultState),
     ?_assertEqual(ExpectedMessage, RecMessage)].

remove_result_more_test_() ->
    Result = a,
    Key = erlang:phash2(Result),
    InRcount = dict:from_list([{Key, 2}]),
    OutRcount = dict:update_counter(Key, -1, InRcount),
    In = #state{results = [a], rcount = InRcount},
    Out = In#state{rcount = OutRcount},
    ?_assertEqual(Out, remove_result(a, In)).

%% Driver comms

enum_test_() ->
    Args = [browse, reg],
    [?_test(
	begin
	    Port = drv_open(),
	    Result = (catch drv_enumerate(Port, Arg)),
	    drv_close(Port),
	    ?assertEqual(ok, Result)
	end
       ) || Arg <- Args ].

browse_test_() ->
    Domains = [<<>>, <<"local">>],
    [?_test(
	begin
	    DrvPort = drv_open(),
	    Result = (catch drv_browse(DrvPort, <<"_test._udp">>, Domain)),
	    drv_close(DrvPort),
	    ?assertEqual(ok, Result)
	end
       ) || Domain <- Domains ].

resolve_test_() ->
    ?_test(
       begin
	   DrvPort = drv_open(),
	   Result = (catch drv_resolve(DrvPort, <<"Name">>, <<"_test._udp">>,
				       <<"local">>)),
	   drv_close(DrvPort),
	   ?assertEqual(ok, Result)
       end
      ).

register_test_() ->
    Names = [<<"test">>, <<?MODULE_STRING>>],
    Type = <<"_test._udp">>,
    Domains = [<<>>, <<"local">>],
    Hosts = [<<>>, <<"example.com">>],
    Ports = [0, 1024],
    Txts = [<<>>, <<4, "test">>],
    [?_test(
	begin
	    DrvPort = drv_open(),
	    Result = (catch drv_register(
			       DrvPort, Name, Type, Domain, Host, Port, Txt)),
	    drv_close(DrvPort),
	    ?assertEqual(ok, Result)
	end
       ) || Name <- Names,
	    Domain <- Domains,
	    Host <- Hosts,
	    Port <- Ports,
	    Txt <- Txts ].

parallel_test_() ->
    ok = application:start(dnssd),
    Name = fun(N) -> list_to_binary(integer_to_list(N)) end,
    Type = fun(N) -> iolist_to_binary(["_test-", Name(N), "._udp"]) end,
    Dom = <<"local">>,
    Browse = fun(N) -> dnssd:browse(Type(N), Dom) end,
    Register = fun(N) -> dnssd:register(Name(N), Type(N), N, [], "", Dom) end,
    WaitForEvent = fun(Ref) ->
			   receive {dnssd, Ref, _} -> ok
			   after 10000 -> timeout end
		   end,
    Run = fun(N) ->
		  {ok, BrowseRef} = Browse(N),
		  {ok, RegRef} = Register(N),
		  ok = WaitForEvent(RegRef),
		  ok = WaitForEvent(BrowseRef),
		  ok = dnssd:stop(BrowseRef),
		  ok = dnssd:stop(RegRef),
		  true
	  end,
    {inparallel, [ ?_test(?assert(Run(N))) || N <- lists:seq(1,20) ]}.

-endif.
