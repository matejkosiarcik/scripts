#!/usr/bin/env bats

@test 'shell - bash' {
    run bash -c 'source home/shell/custom.bash'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]
    echo "${output}"

    run bash -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]
    echo "${output}"
}

@test 'shell - sh' {
    run sh -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]
    echo "${output}"
}
