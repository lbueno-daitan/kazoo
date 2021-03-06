%%%-------------------------------------------------------------------
%%% @copyright (C) 2012-2014, 2600Hz, INC
%%% @doc
%%%
%%% @end
%%% @contributors
%%%-------------------------------------------------------------------
-module(wh_amqp_sup).

-behaviour(supervisor).

-export([start_link/0
         ,stop_bootstrap/0
         ,pool_name/0
        ]).

-export([init/1]).

-include("amqp_util.hrl").

-define(DEFAULT_POOL_SIZE, 150).
-define(DEFAULT_POOL_OVERFLOW, 100).

-define(POOL_NAME, 'wh_amqp_pool').
-define(POOL_SIZE, wh_config:get_integer('amqp', 'pool_size', ?DEFAULT_POOL_SIZE)).
-define(POOL_OVERFLOW, wh_config:get_integer('amqp', 'pool_size', ?DEFAULT_POOL_OVERFLOW)).

-define(POOL_ARGS, [[{'worker_module', 'wh_amqp_worker'}
                     ,{'name', {'local', ?POOL_NAME}}
                     ,{'size', ?POOL_SIZE}
                     ,{'max_overflow', ?POOL_OVERFLOW}
                     ,{'neg_resp_threshold', 1}
                    ]]).

-define(SERVER, ?MODULE).
-define(CHILDREN, [?WORKER('wh_amqp_connections')
                   ,?SUPER('wh_amqp_connection_sup')
                   ,?WORKER('wh_amqp_assignments')
                   ,?WORKER('wh_amqp_history')
                   ,?WORKER('wh_amqp_bootstrap')
                   ,?WORKER_NAME_ARGS('poolboy', ?POOL_NAME, ?POOL_ARGS)
                  ]).

%% ===================================================================
%% API functions
%% ===================================================================

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Starts the supervisor
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> startlink_ret().
start_link() ->
    supervisor:start_link({'local', ?MODULE}, ?MODULE, []).

-spec stop_bootstrap() -> 'ok' |
                          {'error', 'running' | 'not_found' | 'simple_one_for_one'}.
stop_bootstrap() ->
    _ = supervisor:terminate_child(?SERVER, 'wh_amqp_bootstrap').

-spec pool_name() -> ?POOL_NAME.
pool_name() -> ?POOL_NAME.

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%% @end
%%--------------------------------------------------------------------
-spec init([]) -> sup_init_ret().
init([]) ->
    RestartStrategy = 'one_for_one',
    MaxRestarts = 5,
    MaxSecondsBetweenRestarts = 10,
    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
    {'ok', {SupFlags, ?CHILDREN}}.
