
function api_call(){
  local url="${1:?api_call: url undefined}" ; shift
  local method="${1:-GET}" ; shift
  local inputs="${1:+\"inputs\":$1}" ; shift
  local data="${BR:+\"ref\":\"$BR\"}"
  local sep="${data:+,}"
  data="$data${inputs:+$sep$inputs}"
  data="{$data}"
  curl -s -X$method -H "Accept: application/vnd.github.v3+json" ${TOK:+ -H "authorization: Bearer $TOK"} -d "$data" "$url" $@
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
  local url="$1" ; shift
  local wflow="$1" ; shift
  api_post "$url/actions/workflows/$wflow/dispatches" $@
}

function api_get_trigrun(){
  local url=${1:?"api_call: url undefined"} ; shift
  local concl="${1:-}" ; shift
  local idx="${1:-0}" ; shift
  local cond='(.event=="push" or .event=="workflow_dispatch") and (.conclusion!="cancelled") and (.conclusion!=null) and (.referenced_workflows[0]!=null) and (.referenced_workflows[0].ref|test("^refs/(tags|heads/'$BR')"))'
  local fullurl="$url/actions/runs?branch=$BR&status=$concl"
  api_call "$fullurl" "GET" | jq -r "
    [
      .workflow_runs[]
      | select($cond)
    ]
    | sort_by(.run_started_at) | reverse [$idx]
    | [.run_started_at,.conclusion,.referenced_workflows[0].ref,.path,.url]
    |@tsv
  "
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

function mm_msg(){
  local msg="${1:-Incoming Webhook test $(date '+%y%m%d-%H%M%S')}"
  shift
  local channel="$1"
  shift
  local url="${MM_OAREPO_WH:?Error, MM_OAREPO_WH undefined}"
  local opts='-H "Content-Type: application/json"'
  local data="{\"text\":\"$msg\"${channel:+, \"channel\":\"$channel\"}}"
  curl -fs -X POST -H "Content-Type: application/json" -d "$data" "$url"
}
