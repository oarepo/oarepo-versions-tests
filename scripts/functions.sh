
function api_call(){
  URL=${1:?Err: url missing}
  shift
  METHOD=${2:?Err: method missing}
  shift
  curl -s -X$METHOD -H "Accept: application/vnd.github.v3+json" -H "authorization: Bearer $TOK" -d '{"ref":"'$BR'"}' "$URL" $@
}
function api_get(){
  URL="$1"
  api_call "$URL" "GET" $@
}
function api_post(){
  URL="$1"
  api_call "$URL" "POST" $@
}
function api_trig(){
  URL="$1"
  WFLOW="$2"
  api_post "$URL/actions/workflows/$WFLOW/dispatches"
}

function get_latest_pypi_version(){
  REPO=$1
  MAJOR=${2:-}
  MINOR=${3:-}
  RE="^${MAJOR:-.+}\\\\.${MINOR:-}${MINOR:+\\\\.}"
  curl -s "https://pypi.org/pypi/$REPO/json" | jq -r '
  . as $in | [                                            # save main object
    .releases | keys[] |                                  # get keys of releses
    select(test("'$RE'")) |                               # select by regexp
    {version:.}+{files:$in.releases[.]} |                 # build objects with "version" inside
    select(.files[0].yanked or .files[1].yanked | not)    # filter out yanked releases
  ] |                                                     # make array
  max_by(.version|split(".")|map(tonumber)) |             # get max by numberized version string
  .version                                                # return latest matched version
  '
}
