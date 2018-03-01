#!/usr/bin/env sh

########  Public functions #####################

#Usage: dns_rest_dns_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_rest_dns_add() {
  fulldomain=$1
  txtvalue=$2
  _info "Using REST DNS APi"
  
  REST_DNS_ENDPOINT="${REST_DNS_ENDPOINT:-$(_readaccountconf_mutable REST_DNS_ENDPOINT)}"
  REST_DNS_USER="${REST_DNS_USER:-$(_readaccountconf_mutable REST_DNS_USER)}"
  REST_DNS_PASS="${REST_DNS_PASS:-$(_readaccountconf_mutable REST_DNS_PASS)}"

  export _H2="Content-Type: application/json"
  method="POST"

  if [ -z "$REST_DNS_USER" ] || [ -z "$REST_DNS_PASS" ]; then
    REST_DNS_USER=""
    REST_DNS_PASS=""
    _err "You haven't specified a rest_dns api key and account yet."
    _err "Please create your key and try again."
    return 1
  fi
  _get_auth
  export _H1="Authorization: JWT ${_jwt_token}"

  if ! _get_root "$fulldomain"; then
      _err "Domain does not exist."
      return 1
  fi

  # save the dns server and key to the account.conf file.
  _saveaccountconf REST_DNS_ENDPOINT "${REST_DNS_ENDPOINT}"
  _saveaccountconf REST_DNS_USER "${REST_DNS_USER}"
  _saveaccountconf REST_DNS_PASS "${REST_DNS_PASS}"

  _endpoint="$REST_DNS_ENDPOINT/api/v1/$_domain/$fulldomain."
  _data="{\"request_type\":\"add\", \"ttl\": \"60\", \"type\": \"TXT\", \"target\": \"${txtvalue}\"}"
  _response="$(_post "$_data" "$_endpoint" "" "$method")"
  return 0
}

#Usage: dns_rest_dns_rm   _acme-challenge.www.domain.com  "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_rest_dns_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Using REST DNS APi"
  
  REST_DNS_ENDPOINT="${REST_DNS_ENDPOINT:-$(_readaccountconf_mutable REST_DNS_ENDPOINT)}"
  REST_DNS_USER="${REST_DNS_USER:-$(_readaccountconf_mutable REST_DNS_USER)}"
  REST_DNS_PASS="${REST_DNS_PASS:-$(_readaccountconf_mutable REST_DNS_PASS)}"

  export _H2="Content-Type: application/json"
  method="POST"

  if [ -z "$REST_DNS_USER" ] || [ -z "$REST_DNS_PASS" ]; then
    REST_DNS_USER=""
    REST_DNS_PASS=""
    _err "You haven't specified a rest_dns api key and account yet."
    _err "Please create your key and try again."
    return 1
  fi
  _get_auth
  export _H1="Authorization: JWT ${_jwt_token}"

  if ! _get_root "$fulldomain"; then
      _err "Domain does not exist."
      return 1
  fi

  _endpoint="$REST_DNS_ENDPOINT/api/v1/$_domain/$fulldomain."
  _data="{\"request_type\":\"del\", \"ttl\": \"60\", \"type\": \"TXT\", \"target\": \"${txtvalue}\"}"
  _response="$(_post "$_data" "$_endpoint" "" "$method")"
  return 0

}

####################  Private functions below ##################################
# _acme-challenge.www.domain.com
# returns
# _domain=domain.com
_get_root() {
  domain=$1
  i="$(echo "$fulldomain" | tr '.' ' ' | wc -w)"
  i=$(_math "$i" - 1)

  while true; do
    h=$(printf "%s" "$domain" | cut -d . -f "$i"-100)
    if [ -z "$h" ]; then
        return 1
    fi
    _domain="$h"
    return 0
  done
  _debug "$domain not found"
  return 1
}

_get_auth() {
  _data="{\"username\":\"$REST_DNS_USER\", \"password\":\"$REST_DNS_PASS\"}"
  _endpoint=$REST_DNS_ENDPOINT/auth
  _response="$(_post "$_data" "$_endpoint" "" "$method")"
  _jwt_token=$(echo $_response | jq -r .access_token)
}
