# These are unusual code patterns to compare the builtin line coverage with our own.
# There may be overlap with other sample files. Too bad

### Case with one-liner when
    case 1 # missed_empty_branch
    when "hi"
      "not here"
#>X
    when 1; "here"
    end

### Multi-line literals
    [
        1,
        2,
        3,
    ]

    {
        a: 3,
        b: [
            4,
        ]
    }
