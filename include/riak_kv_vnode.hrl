-include_lib("riak_core/include/riak_core_vnode.hrl").


-record(riak_kv_w1c_put_reply_v1, {
    reply :: ok | {error, term()},
    type :: primary | fallback
}).

-record(riak_kv_listkeys_req_v2, {
          bucket :: binary()|'_'|tuple(),
          req_id :: non_neg_integer(),
          caller :: pid()}).

-record(riak_kv_listkeys_req_v3, {
          bucket :: binary() | tuple(),
          item_filter :: function()}).

-record(riak_kv_listbuckets_req_v1, {
          item_filter :: function()}).

-record(riak_kv_index_req_v1, {
          bucket :: binary() | tuple(),
          item_filter :: riak_kv_coverage_filter:filter(),
          qry :: riak_index:query_def()}).

%% same as _v1, but triggers ack-based backpressure
-record(riak_kv_index_req_v2, {
          bucket :: binary() | tuple(),
          item_filter :: riak_kv_coverage_filter:filter(),
          qry :: riak_index:query_def()}).

-record(riak_kv_vnode_status_req_v1, {}).

-record(riak_kv_delete_req_v1, {
          bkey :: {binary(), binary()},
          req_id :: non_neg_integer()}).

-record(riak_kv_map_req_v1, {
          bkey :: {binary(), binary()},
          qterm :: term(),
          keydata :: term(),
          from :: term()}).

-record(riak_kv_vclock_req_v1, {
          bkeys = [] :: [{binary(), binary()}]
         }).

-define(KV_W1C_PUT_REPLY, #riak_kv_w1c_put_reply_v1).
-define(KV_LISTBUCKETS_REQ, #riak_kv_listbuckets_req_v1).
-define(KV_INDEX_REQ, #riak_kv_index_req_v2).
-define(KV_VNODE_STATUS_REQ, #riak_kv_vnode_status_req_v1).
-define(KV_DELETE_REQ, #riak_kv_delete_req_v1).
-define(KV_MAP_REQ, #riak_kv_map_req_v1).
-define(KV_VCLOCK_REQ, #riak_kv_vclock_req_v1).

%% @doc vnode_lock(PartitionIndex) is a kv per-vnode lock, used possibly,
%% by AAE tree rebuilds, fullsync, and handoff.
%% See @link riak_core_background_mgr:get_lock/1
-define(KV_VNODE_LOCK(Idx), {vnode_lock, Idx}).
