#!/bin/bash
# Time: 2024-11-14 00:22:16
#
# 用法:
#   1. get-maintainer-email.sh 000\*
#   2. get-maintainer-email.sh '000*'
#   3. get-maintainer-email.sh "000*"
#   4. get-maintainer-email.sh "000*" fs/nfs fs/nfsd fs/nfs_common

program=$0

to_types=('maintainer' 'reviewer' 'supporter' 'commit_signer' 'blamed_fixes')
cc_types=('open list' 'moderated list')

except_emails=('chen.dylane@gmail.com')

to_emails=()
cc_emails=()
unknown_emails=()

function print_help ()
{
        echo "usage: ${program} get email info/commit message"
        echo
        echo "Examples: "
        echo "${program} -e xxx.path  get email info"
        echo "${program} -p 1  submit latest 1 commit with one patch"
        echo "${program} -p 1  v2 submit latest 1 commit with one patch in v2"
        echo "${program} -P 2  submit latest 2 commit with patchset"
	echo "${program} -P 3  v2 submit latest 3 commit with patchset in v2"
        echo
}

# 0: 已存在数组中，1: 不存在数组中
is_exist() {
        local -n array=$1
        local target_item=$2

        for item in "${array[@]}"; do
                if [[ "$item" == "${target_item}" ]]; then
                        return 0
                fi
        done
        return 1
}

# 0: 已存在某个数组中，1: 不存在任何数组中
is_email_exist() {
        local email=$1
        is_exist to_emails ${email}
        if [[ $? == 0 ]]; then
                return 0
        fi
        is_exist cc_emails ${email}
        if [[ $? == 0 ]]; then
                return 0
        fi
        is_exist unknown_emails ${email}
        if [[ $? == 0 ]]; then
                return 0
        fi
        return 1
}

# 0: 是例外的邮箱，1: 不是例外的邮箱
is_except_email() {
        local email=$1
        is_exist except_emails ${email}
        if [[ $? == 0 ]]; then
                return 0
        fi
        return 1
}

# 0:
#   - 成功添加到邮件数组中
#   - 已存在某个数组中
#   - 例外的邮箱
# 1: 未添加到数组中
add_email_array() {
        local -n types_array=$1
        local -n emails_array=$2
        local str=$3

        local emails_array_name=$2
        # echo ${types_array[@]}
        # echo ${str}

        local email=$(echo ${str} | awk '{print $1}') # 提取邮箱
        is_except_email ${email}
        if [[ $? == 0 ]]; then
                return 0
        fi

        for type_name in "${types_array[@]}"; do
                echo ${str} | grep -E "${type_name}" > /dev/null 2>&1
                if [[ $? == 0 ]]; then
                        is_email_exist ${email}
                        if [[ $? == 0 ]]; then
                                # echo "${email} already exist"
                                return 0
                        fi
                        # echo "${type_name}: ${email}"
                        emails_array+=(${email})
                        # echo "${emails_array_name}: ${emails_array[@]}"
                        return 0
                fi
        done
        return 1
}

# 传入的字符串格式: corbet@lwn.net (maintainer:DOCUMENTATION)
parse_line() {
        local str=$1
        local email=$(echo ${str} | awk '{print $1}') # 提取邮箱
        add_email_array to_types to_emails "${str}"
        if [[ $? == 0 ]]; then
                return
        fi
        add_email_array cc_types cc_emails "${str}"
        if [[ $? == 0 ]]; then
                return
        fi
        # echo "unknown: ${email}"
        unknown_emails+=(${email})
}

parse_cmd_output() {
        local output_str=$1
        while IFS= read -r line; do
                local line=$(echo ${line} | sed 's/.* <//') # ' <'之前的部分删除
                line=$(echo ${line} | sed 's/> / /g') # 删除'>'字符
                # echo "line: ${line}"
                parse_line "${line}"
        done <<< "${output_str}"
}

parse_pattern() {
        local pattern=$1
        echo "pattern: $pattern"
        for file in $pattern; do
                if [[ ${file} == '0000-cover-letter.patch' ]]; then
                        continue
                fi
                local cmd="./scripts/get_maintainer.pl ${file}"
                local output_str=$(${cmd})
                echo ${cmd}
                # echo "${output_str}"
                parse_cmd_output "${output_str}"
        done
}

print_email_result() {
        local emails_str="--to="
        for email in "${to_emails[@]}"; do
                emails_str+="${email},"
        done
        emails_str="${emails_str:0:${#emails_str}-1}" # 去掉最后的逗号

        emails_str+=" --cc="
        for email in "${cc_emails[@]}"; do
                emails_str+="${email},"
        done
        emails_str="${emails_str:0:${#emails_str}-1}" # 去掉最后的逗号

        echo
        echo "git send-email ${emails_str}"

        local unknown_str="unknown emails:"
        for email in "${unknown_emails[@]}"; do
                unknown_str+=" ${email}"
        done
        echo
        echo "${unknown_str}"
}

iter_pattern() {
        for arg in "$@"; do
                # echo "${arg}"
                parse_pattern "${arg}"
        done
}

test_str=$(cat <<EOF
this is name <1@test.com> (maintainer:MODULE ONE (A and B))
this is name <2@test.com> (supporter:MODULE ONE (A and B))
this is name <2@test.com> (open list:MODULE ONE (A and B))
this is name <3@test.com> (reviewer:MODULE ONE (A and B))
linux-cifs@vger.kernel.org (open list:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
samba-technical@lists.samba.org (moderated list:COMMON INTERNET FILE SYSTEM CLIENT (CIFS and SMB3))
linux-nfs@vger.kernel.org (open list:NFS, SUNRPC, AND LOCKD CLIENTS)
linux-kernel@vger.kernel.org (open list)
linux-kernel@vger.kernel.org (open list)
EOF
)

test() {
        local output_str=${test_str}
        # echo "${output_str}"
        parse_cmd_output "${output_str}"
}

function get_email_info() {
        iter_pattern "$@"
}

function main() {
        while [ $# -gt 0 ]; do
        case $1 in
                -e | --email)
                        get_email_info "$2"
                        print_email_result
                        exit 0
                        ;;
                -p | --patch)
                        # git format-patch --subject-prefix="PATCH next" -1 commitid
			if [ "$3" == "" ]; then
                        	git format-patch --subject-prefix="PATCH bpf-next" "-$2"
			else
                        	git format-patch --subject-prefix="PATCH bpf-next $3" "-$2"
			fi
                        exit 0
                        ;;
                -P | --pathset)
                        # git format-patch --subject-prefix="PATCH bpf-next" -3 commitid --cover-letter
			if [ "$3" == "" ]; then
                        	git format-patch --subject-prefix="PATCH bpf-next" "-$2" --cover-letter -o patchset_$3
			else
                        	git format-patch --subject-prefix="PATCH bpf-next $3" "-$2" --cover-letter -o patchset_$3
			fi
                        exit 0
                        ;;
                -h | --help)
                        print_help
                        exit 0
                        ;;
        esac
        done
}

main "$@"
