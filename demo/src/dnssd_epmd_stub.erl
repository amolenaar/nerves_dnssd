-module(dnssd_epmd_stub).

-behaviour(gen_server).

%% epmd_module callbacks
-export([start_link/0,
         register_node/2,
         register_node/3,
         port_please/2,
         names/1]).

%% dnssd_dist callbacks
-export([local_port_please/0,
         port_please/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
	     terminate/2,
         code_change/3]).

%% The supervisor module erl_distribution tries to add us as a child
%% process.  We don't need a child process, so return 'ignore'.
start_link() ->
   gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

% stop() ->
%     gen_server:call(?MODULE, stop, infinity).

register_node(Name, Port) ->
    register_node(Name, Port, inet_tcp).

%% As of Erlang/OTP 19.1, register_node/3 is used instead of
%% register_node/2, passing along the address family, 'inet_tcp' or
%% 'inet6_tcp'.  This makes no difference for our purposes.
register_node(Name, Port, Family) when is_list(Name) ->
    register_node(iolist_to_binary(Name), Port, Family);
register_node(Name, Port, Family) when is_atom(Name) ->
    register_node(atom_to_binary(Name, utf8), Port, Family);
register_node(Name, Port, Family) when is_binary(Name) ->
    gen_server:call(?MODULE, {register_node, Name, Port, Family}).

port_please(_Name, _IP) ->
    {error, not_supported}.

names(Hostname) ->
    io:format("dnssd_epmd_stub: names ~p~n", [Hostname]),
    %% Since we don't have epmd, we don't really know what other nodes
    %% there are.
    {error, address}.

%% dnssd_dist callbacks

port_please(Name) when is_list(Name) ->
    port_please(iolist_to_binary(Name));
port_please(Name) when is_atom(Name) ->
    port_please(atom_to_binary(Name, utf8));
port_please(Name) when is_binary(Name) ->
    % TODO: resolve Name._epmd._tcp.local ,
    case gen_server:call(?MODULE, {port_please, Name}) of
        {ok, Hostname, Ip, Port} ->
            %% The distribution protocol version number has been 5 ever since
            %% Erlang/OTP R6.
            Version = 5,
            {port, Hostname, Ip, Port, Version};
        {error, Reason} ->
            {error, Reason}
    end.

local_port_please() ->
    gen_server:call(?MODULE, port).


%% gen_server callbacks

-record(state, {name, port, names, register_ref}).
-type state() :: #state{}.

-spec init(_) -> {'ok', state()}.

init(_) ->
    {ok, #state{name = nil, port=nil}}.


handle_call({register_node, Name, Port, inet_tcp}, _From, State) ->
    %% I can either keep record of the port, or periodically try to register (if the dnssd_server is up)

    % {ok, Ref} = dnssd:register(Name, "_epmd._tcp", Port),

    %% Now that I'm registered, I can also start browsing. If we discover a node, we can connect to it
    %% Need to return a "creation" number between 1 and 3.
    Creation = rand:uniform(3),
    {reply, {ok, Creation}, State#state{name = Name, port = Port}};

handle_call({port_please, Name}, _From, State) ->
    case dnssd:resolve_sync(Name, "_epmd._tcp", "local") of
        {ok, {Hostname, Port, TxtStrings}} ->
            io:format("EPMD: port_please ok ~p ~p ~p ~p~n", [Name, Hostname, Port, TxtStrings]),
            case dnssd:query_record_sync(Hostname, <<"A">>) of
                {ok, {Hostname, <<"A">>, <<"IN">>, <<A, B, C, D>>}} ->
                    io:format("EPMD: port_please query ok ~p ~p ~p ~p~n", [Name, binary_to_list(Hostname), {A, B, C, D}, Port]),
                    {reply, {ok, binary_to_list(Hostname), {A, B, C, D}, Port}, State};
                {error, Reason} ->
                    io:format("EPMD: port_please query error ~p ~p~n", [Hostname, Reason]),
                    {reply, {error, Reason}, State}
            end;
        {error, Reason} ->
            io:format("EPMD: port_please error ~p ~p~n", [Name, Reason]),
            {reply, {error, Reason}, State}
    end;

handle_call(port, _From, #state{port = Port} = State) ->
    {reply, {ok, Port}, State}.

handle_cast(_, State) ->
    {noreply, State}.

handle_info(_, State) ->
    {noreply, State}.

% terminate(_, #state{register_ref = Ref}) when Ref /= nil ->
%     dnssd:stop(Ref),
%     ok;
terminate(_, _) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
