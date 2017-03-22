from __future__ import print_function

import re
import os
import sys


def guess_coala_branch_name(docker_branch_name):
    m = re.search('r(?:el)?(?:ease)?[^0-9]?([0-9]+\.[0-9]+(\.[0-9]+)*)',
                  docker_branch_name)
    if m:
        release_number = m.group(1)
        release_numbers = release_number.split('.')
        assert len(release_numbers) >= 2
        if len(release_numbers) == 2:
            float(release_number)
            return 'release/' + release_number
        else:
            [int(x) for x in release_numbers]
            return release_number

    return 'master'


def main():
    args = sys.argv[1:]
    assert args
    assert len(args) == 1
    docker_branch_name = args[0]
    if 'COALA_BRANCH' in os.environ and os.environ['COALA_BRANCH']:
        print(os.environ['COALA_BRANCH'])
    else:
        print(guess_coala_branch_name(docker_branch_name))


if __name__ == '__main__':
    main()
