#!/bin/sh -e

if [ "${DEBUG_OUTPUT}" = "true" ]; then
    set -x
fi

# Helpers
terraform_is_at_least() {
  [ "${1}" = "$(terraform -version | awk -v min="${1}" '/^Terraform v/{ sub(/^v/, "", $2); print min; print $2 }' | sort -V | head -n1)" ]
  return $?
}

# Evaluate if this script is being sourced or executed directly.
# See https://stackoverflow.com/a/28776166
sourced=0
if [ -n "$ZSH_VERSION" ]; then
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  # shellcheck disable=SC2296
  [ "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames.
     # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|-sh|dash|-dash) sourced=1;; esac
fi

JQ_PLAN='
  (
    [.resource_changes[]?.change.actions?] | flatten
  ) | {
    "create":(map(select(.=="create")) | length),
    "update":(map(select(.=="update")) | length),
    "delete":(map(select(.=="delete")) | length)
  }
'

# If TF_USERNAME is unset then default to GITLAB_USER_LOGIN
TF_USERNAME="${TF_USERNAME:-${GITLAB_USER_LOGIN}}"

# If TF_PASSWORD is unset then default to gitlab-ci-token/CI_JOB_TOKEN
if [ -z "${TF_PASSWORD}" ]; then
  TF_USERNAME="gitlab-ci-token"
  TF_PASSWORD="${CI_JOB_TOKEN}"
fi

# If TF_ADDRESS is unset but TF_STATE_NAME is provided, then default to GitLab backend in current project
if [ -n "${TF_STATE_NAME}" ]; then
  TF_ADDRESS="${TF_ADDRESS:-${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}}"
fi

# If TF_ROOT is set then use the -chdir option
if [ -n "${TF_ROOT}" ]; then
  abs_tf_root=$(cd "${CI_PROJECT_DIR}"; realpath "${TF_ROOT}")

  TF_CHDIR_OPT="-chdir=${abs_tf_root}"

  default_tf_plan_cache="${abs_tf_root}/plan.cache"
  default_tf_plan_json="${abs_tf_root}/plan.json"
fi


# If TF_PLAN_CACHE is not set then use either the plan.cache file within TF_ROOT if set, or plan.cache in CWD
if [ -z "${TF_PLAN_CACHE}" ]; then
  TF_PLAN_CACHE="${default_tf_plan_cache:-plan.cache}"
fi

# If TF_PLAN_JSON is not set then use either the plan.json file within TF_ROOT if set, or plan.json in CWD
if [ -z "${TF_PLAN_JSON}" ]; then
  TF_PLAN_JSON="${default_tf_plan_json:-plan.json}"
fi

# Set variables for the HTTP backend to default to TF_* values
export TF_HTTP_ADDRESS="${TF_HTTP_ADDRESS:-${TF_ADDRESS}}"
export TF_HTTP_LOCK_ADDRESS="${TF_HTTP_LOCK_ADDRESS:-${TF_ADDRESS}/lock}"
export TF_HTTP_LOCK_METHOD="${TF_HTTP_LOCK_METHOD:-POST}"
export TF_HTTP_UNLOCK_ADDRESS="${TF_HTTP_UNLOCK_ADDRESS:-${TF_ADDRESS}/lock}"
export TF_HTTP_UNLOCK_METHOD="${TF_HTTP_UNLOCK_METHOD:-DELETE}"
export TF_HTTP_USERNAME="${TF_HTTP_USERNAME:-${TF_USERNAME}}"
export TF_HTTP_PASSWORD="${TF_HTTP_PASSWORD:-${TF_PASSWORD}}"
export TF_HTTP_RETRY_WAIT_MIN="${TF_HTTP_RETRY_WAIT_MIN:-5}"

# Expose Gitlab specific variables to terraform since no -tf-var is available
# Usable in the .tf file as variable "CI_JOB_ID" { type = string } etc
export TF_VAR_CI_JOB_ID="${TF_VAR_CI_JOB_ID:-${CI_JOB_ID}}"
export TF_VAR_CI_COMMIT_SHA="${TF_VAR_CI_COMMIT_SHA:-${CI_COMMIT_SHA}}"
export TF_VAR_CI_JOB_STAGE="${TF_VAR_CI_JOB_STAGE:-${CI_JOB_STAGE}}"
export TF_VAR_CI_PROJECT_ID="${TF_VAR_CI_PROJECT_ID:-${CI_PROJECT_ID}}"
export TF_VAR_CI_PROJECT_NAME="${TF_VAR_CI_PROJECT_NAME:-${CI_PROJECT_NAME}}"
export TF_VAR_CI_PROJECT_NAMESPACE="${TF_VAR_CI_PROJECT_NAMESPACE:-${CI_PROJECT_NAMESPACE}}"
export TF_VAR_CI_PROJECT_PATH="${TF_VAR_CI_PROJECT_PATH:-${CI_PROJECT_PATH}}"
export TF_VAR_CI_PROJECT_URL="${TF_VAR_CI_PROJECT_URL:-${CI_PROJECT_URL}}"

# Use terraform automation mode (will remove some verbose unneeded messages)
export TF_IN_AUTOMATION=true

DEFAULT_TF_CONFIG_PATH="$HOME/.terraformrc"

# Set a Terraform CLI Configuration File
if [ -z "${TF_CLI_CONFIG_FILE}" ] && [ -f "${DEFAULT_TF_CONFIG_PATH}" ]; then
  export TF_CLI_CONFIG_FILE="${DEFAULT_TF_CONFIG_PATH}"
fi


terraform_authenticate_private_registry() {
  if terraform_is_at_least 1.2.0; then
    # From Terraform 1.2.0 and later, we can use TF_TOKEN_your_domain_name to authenticate to registry.
    # The credential environment variable has the following requirements:
    # - Domain names containing non-ASCII characters are converted to their punycode equivalent with an ACE prefix
    # - Periods are encoded as underscores
    # - Hyphens are encoded as double underscores
    # For more info, see https://www.terraform.io/cli/config/config-file#environment-variable-credentials
    if [ "${CI_SERVER_PROTOCOL}" = "https" ] && [ -n "${CI_SERVER_HOST}" ]; then
      tf_token_var_name=TF_TOKEN_$(idn2 "${CI_SERVER_HOST}" | sed 's/\./_/g' | sed 's/-/__/g')
      # If TF_TOKEN_ for the Gitlab domain is not set then use the CI_JOB_TOKEN
      if [ -z "$(eval "echo \${${tf_token_var_name}:-}")" ]; then
        export "${tf_token_var_name}"="${CI_JOB_TOKEN}"
      fi
    fi
  else
    # If we have a version older than 1.2.0, we use the credentials file.
    # This authentication method can be safely deleted when we'll remove support for Terraform 1.0 and 1.1
    export TF_CLI_CONFIG_FILE="${TF_CLI_CONFIG_FILE:-$DEFAULT_TF_CONFIG_PATH}"
    if [ ! -f "${TF_CLI_CONFIG_FILE}" ] && [ "${CI_SERVER_PROTOCOL}" = "https" ] && [ -n "${CI_SERVER_HOST}" ] && [ -n "${CI_SERVER_PORT}" ]; then
    cat << EOF > "${TF_CLI_CONFIG_FILE}"
credentials "${CI_SERVER_HOST}:${CI_SERVER_PORT}" {
token = "${CI_JOB_TOKEN}"
}
EOF
    fi
  fi
}

# If TF_IMPLICIT_INIT is not set, we set it to `true`.
# If set to `true` it will call `terraform init` prior
# to calling the wrapper `terraform` commands.
TF_IMPLICIT_INIT=${TF_IMPLICIT_INIT:-true}

terraform_init() {
  # If TF_INIT_NO_RECONFIGURE is not set to 'true',
  # a `-reconfigure` flag is added to the `terraform init` command.
  if [ "$TF_INIT_NO_RECONFIGURE" != 'true' ]; then
    tf_init_reconfigure_flag='-reconfigure'
  fi

  # We want to allow word splitting here for TF_INIT_FLAGS
  # shellcheck disable=SC2086
  terraform "${TF_CHDIR_OPT}" init "${@}" -input=false ${tf_init_reconfigure_flag} ${TF_INIT_FLAGS}
}

# If this script is executed and not sourced, a terraform command is ran.
# Otherwise, nothing happens and the sourced shell can use the defined variables
# and helper functions exposed by this script.
if [ $sourced -eq 0 ]; then
  # Authenticate to private registry
  terraform_authenticate_private_registry

  case "${1}" in
    "apply")
      $TF_IMPLICIT_INIT && terraform_init
      terraform "${TF_CHDIR_OPT}" "${@}" -input=false "${TF_PLAN_CACHE}"
    ;;
    "destroy")
      $TF_IMPLICIT_INIT && terraform_init
      terraform "${TF_CHDIR_OPT}" "${@}" -auto-approve
    ;;
    "fmt")
      terraform "${TF_CHDIR_OPT}" "${@}" -check -diff -recursive
    ;;
    "init")
      # shift argument list „one to the left“ to not call 'terraform init init'
      shift
      terraform_init "${@}"
    ;;
    "plan")
      $TF_IMPLICIT_INIT && terraform_init
      terraform "${TF_CHDIR_OPT}" "${@}" -input=false -out="${TF_PLAN_CACHE}"
    ;;
    "plan-json")
      terraform "${TF_CHDIR_OPT}" show -json "${TF_PLAN_CACHE}" | \
        jq -r "${JQ_PLAN}" \
        > "${TF_PLAN_JSON}"
    ;;
    "validate")
      $TF_IMPLICIT_INIT && terraform_init -backend=false
      terraform "${TF_CHDIR_OPT}" "${@}"
    ;;
    --)
      shift
      terraform "${TF_CHDIR_OPT}" "${@}"
    ;;
    *)
      terraform "${TF_CHDIR_OPT}" "${@}"
    ;;
  esac
else
  # This variable can be used if the script is sourced
  # shellcheck disable=SC2034
  TF_GITLAB_SOURCED=true
fi

