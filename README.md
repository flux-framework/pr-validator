## PR commit message validator

Simple GitHub action to prevent accidental merge of PRs with
invalid commits. Currently, invalid commits include

 * Commits with `fixup` or `squash` in the subject
 * Merge commits

To add to a project, add the following to a GitHub workflow `.yml` file:

```yaml
on: pull_request
jobs:
  check-pr:
    name: validate commits
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        ref: ${{ github.event.pull_request.head.sha }}
        fetch-depth: 0
    - run: git fetch origin master
    - uses: flux-framework/pr-validator@master
```
