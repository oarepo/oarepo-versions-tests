
function api_call(){
  local url="$1"
  shift
  local method="$1"
  shift
  curl -s -X$method -H "Accept: application/vnd.github.v3+json" -H "authorization: Bearer $TOK" -d '{"ref":"'$BR'"}' "$url" $@
}
function api_get(){
  local url="$1"
  shift
  api_call "$url" "GET" $@
}
function api_post(){
  local url="$1"
  shift
  api_call "$url" "POST" $@
}
function api_trig(){
  local url="$1"
  local wflow="$2"
  api_post "$url/actions/workflows/$wflow/dispatches"
}

function get_latest_pypi_version(){
  local repo=$1
  local major=${2:-}
  local minor=${3:-}
  local re="^${major:-.+}\\\\.${minor:-}${minor:+\\\\.}"
  curl -s "https://pypi.org/pypi/$repo/json" | jq -r '
  . as $in | [                                            # save main object
    .releases | keys[] |                                  # get keys of releses
    select(test("'$re'")) |                               # select by regexp
    {version:.}+{files:$in.releases[.]} |                 # build objects with "version" inside
    select(.files[0].yanked or .files[1].yanked | not)    # filter out yanked releases
  ] |                                                     # make array
  max_by(.files[0].upload_time) |                         # get max by file upload time
  .version                                                # return latest matched version
  '
}
