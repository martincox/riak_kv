%% -------------------------------------------------------------------
%%
%% Copyright (c) 2016 Basho Technologies, Inc.  All Rights Reserved.
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


-module(riak_kv_requests).

%% API
-export([request_type/1,
         request_hash/1]).

-export([new_put_request/5,
         new_get_request/2,
         new_w1c_put_request/3,
         new_listkeys_request/2,
         is_coordinated_put/1,
         get_bucket_key/1,
         get_bucket/1,
         get_item_filter/1,
         get_object/1,
         get_encoded_obj/1,
         get_replica_type/1,
         set_object/2,
         get_request_id/1,
         get_start_time/1,
         get_options/1,
         remove_option/2
    ]).

-type bucket_key() :: {binary(),binary()}.
-type object() :: term().
-type request_id() :: non_neg_integer().
-type start_time() :: non_neg_integer().
-type request_options() :: [any()].
-type replica_type() :: primary | fallback.
-type encoded_obj() :: binary().
-type bucket() :: riak_core_bucket:bucket().

-record(riak_kv_put_req_v1,
        { bkey :: bucket_key(),
          object :: object(),
          req_id :: request_id(),
          start_time :: start_time(),
          options :: request_options()}).

-record(riak_kv_get_req_v1, {
          bkey :: bucket_key(),
          req_id :: request_id()}).

-record(riak_kv_w1c_put_req_v1, {
    bkey :: bucket_key(),
    encoded_obj :: encoded_obj(),
    type :: replica_type()
    % start_time :: non_neg_integer(), Jon to add?
}).

%% same as _v3, but triggers ack-based backpressure
-record(riak_kv_listkeys_req_v4, {
          bucket :: bucket(),
          item_filter :: function()}).

-opaque put_request() :: #riak_kv_put_req_v1{}.
-opaque get_request() :: #riak_kv_get_req_v1{}.
-opaque w1c_put_request() :: #riak_kv_w1c_put_req_v1{}.
-opaque listkeys_request() :: #riak_kv_listkeys_req_v4{}.
-type request() :: put_request()
                 | get_request()
                 | w1c_put_request()
                 | listkeys_request().

-type request_type() :: kv_put_request
                      | kv_get_request
                      | kv_w1c_put_request
                      | kv_listkeys_request
                      | unknown.

-export_type([put_request/0,
              get_request/0,
              w1c_put_request/0,
              listkeys_request/0,
              request/0,
              request_type/0]).

-spec request_type(request()) -> request_type().
request_type(#riak_kv_put_req_v1{}) -> kv_put_request;
request_type(#riak_kv_get_req_v1{}) -> kv_get_request;
request_type(#riak_kv_w1c_put_req_v1{}) -> kv_w1c_put_request;
request_type(#riak_kv_listkeys_req_v4{})-> kv_listkeys_request;
request_type(_) -> unknown.

request_hash(#riak_kv_put_req_v1{bkey=BKey}) ->
    riak_core_util:chash_key(BKey);
request_hash(_) ->
    undefined.


-spec new_put_request(bucket_key(),
                      object(),
                      request_id(),
                      start_time(),
                      request_options()) -> put_request().
new_put_request(BKey, Object, ReqId, StartTime, Options) ->
    #riak_kv_put_req_v1{bkey = BKey,
                        object = Object,
                        req_id = ReqId,
                        start_time = StartTime,
                        options = Options}.

-spec new_get_request(bucket_key(), request_id()) -> get_request().
new_get_request(BKey, ReqId) ->
    #riak_kv_get_req_v1{bkey = BKey, req_id = ReqId}.

-spec new_w1c_put_request(bucket_key(), encoded_obj(), replica_type()) -> w1c_put_request().
new_w1c_put_request(BKey, EncodedObj, ReplicaType) ->
    #riak_kv_w1c_put_req_v1{bkey = BKey, encoded_obj = EncodedObj, type = ReplicaType}.

-spec new_listkeys_request(bucket(), function()) -> listkeys_request().
new_listkeys_request(Bucket, ItemFilter) ->
    #riak_kv_listkeys_req_v4{bucket=Bucket, item_filter=ItemFilter}.

-spec is_coordinated_put(put_request()) -> boolean().
is_coordinated_put(#riak_kv_put_req_v1{options=Options}) ->
    proplists:get_value(coord, Options, false).

get_bucket_key(#riak_kv_put_req_v1{bkey = BKey}) ->
    BKey;
get_bucket_key(#riak_kv_w1c_put_req_v1{bkey = BKey}) ->
    BKey.

-spec get_bucket(request()) -> bucket().
get_bucket(#riak_kv_listkeys_req_v4{bucket = Bucket}) ->
    Bucket.

-spec get_item_filter(request()) -> function().
get_item_filter(#riak_kv_listkeys_req_v4{item_filter = ItemFilter}) ->
    ItemFilter.

-spec get_encoded_obj(request()) -> encoded_obj().
get_encoded_obj(#riak_kv_w1c_put_req_v1{encoded_obj = EncodedObj}) ->
    EncodedObj.

get_object(#riak_kv_put_req_v1{object = Object}) ->
    Object.

-spec get_replica_type(request()) -> replica_type().
get_replica_type(#riak_kv_w1c_put_req_v1{type = Type}) ->
    Type.

-spec get_request_id(request()) -> request_id().
get_request_id(#riak_kv_put_req_v1{req_id = ReqId}) ->
    ReqId;
get_request_id(#riak_kv_get_req_v1{req_id = ReqId}) ->
    ReqId.

get_start_time(#riak_kv_put_req_v1{start_time = StartTime}) ->
    StartTime.

get_options(#riak_kv_put_req_v1{options = Options}) ->
    Options.

set_object(#riak_kv_put_req_v1{}=Req, Object) ->
    Req#riak_kv_put_req_v1{object = Object}.

remove_option(#riak_kv_put_req_v1{options = Options}=Req, Option) ->
    NewOptions = proplists:delete(Option, Options),
    Req#riak_kv_put_req_v1{options = NewOptions}.
