# Running the tests

## Dev installation

For the moment, you need `nyc`, so you must have `node` (and ideally `yarn`) installed.

```
$ git clone https://github.com/deep-cover/deep-cover.git
$ cd deep-cover
$ bundle
$ yarn install -g nyc  # or use npm
```

## rspec

To run the full test suite:
```
$ rspec
```

There's currently a bunch of output we'd like to get rid of, sorry.

You should get no failures.

## Char coverage specs

Much of the specs is in `spec/char_cover/*.rb`. Each file is a collection of tests, each separated with comments starting with `###` and `####`. Ruby code should be indented with 4 spaces. Each line can be followed by a spec comment, stating for each character if it is executed (space), not executed (x) or not executable (-). Lines that have any non-executed parts must have a spec comment otherwise they won't pass.

To run a particular file, say `spec/char_cover/literals.rb`, use `rspec -e literals`.

Note that `RuntimeError`s without any message (`raise`) are silently rescued for each test case. Other exceptions must be rescued in the spec.

To debug a particular case: `bin/cov literals` (will ask which sub spec to run), or `bin/cov literals 3` (to run the 3rd sub spec).

# Implementation notes

## Top level strategy

DeepCover is based on the awesome `parser` gem.

We use the parsed code to rewrite it such that we can deduce what has been executed or not. We insert trackers looking like `$_some_global[42][555] += 1` where 42 is a number unique to the file and 555 is the id of the tracker.

Our rewriting rules:
* only insert code, never change existing code
* keep the existing code on their original line
* are minimal. They don't call any method, rescue exceptions, etc.
* use the mimimal number of trackers (except for multiple assignments, we use one extra)

### Flow accounting

The goal is to instrument any Ruby code such that we can know, for each node, how many time it’s been executed (`Node#execution_count`). More precisely, for any node, we need to know how many times control flow has "entered" the node (`Node#flow_entry_count`), how many times it has exited the node normally (`Node#flow_completion_count`), and by deduction how many times control flow has been interrupted (say by a raise, throw, return, next, etc. `Node#flow_interrupt_count`).

We always deduce their execution from normal control flow. E.g. in `var = [1, 2, 3]`, to know if `3` was executed, we check if it's previous sibbling (`2`) was executed. To know that, we check if `1` was executed. `1` has no previous sibbling, so we check the parent `[]`. It itself checks the parent `var =`, which finally asks bring us to our parent (`Node::Root`). Only this parent introduces a small performance hit with a tracker ($_some_global[][] += 1`). So we get the execution count of the literals, the array creation and the variable assignment for free.

To summarize our strategy: a Node is not responsible to know how many times it was entered by control flow, that is the responsibility of the parent node. A Node's responsibility is to know how many times control flow exited it normally. For many nodes like literals, `flow_completion_count == flow_entry_count` so there's nothing special to be done. Others must do some accounting, in particular `Node::Send` must add a `$tracker[][]+=1` after the call to know if flow has been interrupted or not. Credit to @MaxLap for pointing us in that direction early on.

Default code for nodes in [flow_accounting.rb](https://github.com/deep-cover/deep-cover/blob/master/lib/deep_cover/node/mixin/flow_accounting.rb).

*To be continued...*
