# gren-args

A package for parsing arguments passed from the [gren/node](https://packages.gren-lang.org/package/gren-lang/node/version/2.0.0/module/Node) package.

### Getting started

To get started with this package, it's assumed you've already setup your program with the `gren/node` package.

Once you have your program running, you can get its arguments from the configuration object passed from the `Node.initalize` function. You can then parse those arguments using the `Args.parse` function in this package.

Here's a code example:

    Node.Program.await Node.initialize 
        (\configuration ->
            let
                -- Parse the passed arguments with this package
                { args, options } =
                    Args.parse configuration.args
            in
            -- Then start your program, doing whatever you'd like with the parsed arguments
            Node.Program.startProgram {}
        )

### Arguments vs. options

This package has a clear separation between arguments and options that are passed to a program.
 
#### Arguments

Arguments have the following properties:

- There is no data associated with arguments.
- The order of arguments may influence how the program runs.
- Certain arguments can be required for a program to run.
- All arguments must be passed to a program before any options are specified.

As an example, parsing the values returned from running `Args.parse` after running the following command: `program-name make` would have the following result:

    { args = [ "make" ]
    , options = Dict.fromArray []
    }

#### Options

Options have the following properties:

- An option can (but is not required to) have data associated with it. An option without data is often called a flag.
- The order of options does not matter to how a program runs
- Options are never required to run a program.
- All options must be passed after arguments have been specified.

As an example, running `program-name compile --input ./src/* -o ./dist.json` would have the following result:

    { args = [ "compile" ]
    , options = Dict.fromArray
        [ { key = "input", value = [ "./src/*" ] }
        , { key = "o", value = [ "./dist.json" ] }
        ]
    }

##### Parsing multiple values

This package will assume that any non-option value (not prefixed with a `--`) that comes after a option has been specified is a value associated with the latest option parsed.

For example, parsing `program-name test --files a b c` would result in the following:

    { args = [ "test" ]
    , options = Dict.fromArray
        [ { key = "files", value = [ "a", "b", "c" ] }
        ]
    }

If you want a specific option to only accept a single value (or no values), you can check for the length of the resulting `Array` associated with a option with a `case` statement.

##### Shortcut options

This package does not specify any difference between using a single `-` character or `--` when prefixing options. 

It's a convention that options prefixed with the `-` character are single-character shortcuts (like using `-o` in the above example instead of `--output`), but this package does not enforce this behavior. Keep this in mind when desgning your program - you may want to check for both the full option name (`--output`) and its shortcut (`-o`).

##### Parsing options with `=`

This packages handles options with a `=` in them. An option of `--name=John` will parse into `{ key = "name", value = [ "John" ] }`.

This also works when multiple values are passed. For example, a option of `--names=John Joan` will parse into ``{ key = "name", value = [ "John", "Joan" ] }``.

### Example

As an example, let's make a program that's capable of parsing arguments like the Gren compiler does. We'll handle the following cases:

1. When the `gren` command is run without any arguments or options, display a welcome message.
2. When `gren init` is run, we want to run a function that makes a new Gren program.
3. When any command is run with the `--help` option (without any values), we want to show some helpful messages associated with it.

This functionality can be built with a single `case` statement.

    parseArguments args =
        let
            { args, options } =
                -- Note that the first two arguments in the paassed args are dropped given that
                -- they are the node path and script path. You can also keep them and pattern
                -- match on them if you need that information for your program!
                Args.parse (Array.dropFirst 2 args)
        in
        case { args = args, help = Dict.get "help" options } of
            { args = [], help = Nothing } ->
                -- This is the result of `gren` being run without the help option
                displayWelcomeMessage
            
            { args = [ "init" ], help = Nothing } ->
                -- This is the result of `gren init` being run
                initGrenProgram

            { args = [ parsedArg ], help = Just [] } ->
                -- This is the result of passing any single argument to `gren` and including
                -- the `--help` options. For example, `gren init --help` or `gren make --help`
                -- would both trigger this branch. In this case, you might want to display
                -- a specific help message for the parsed argument!
                displayHelp parsedArg

            { args = _, help = Just _ } ->
                -- This is the result of associatng any data with the `--help` option. regardless
                -- of the arguments passed. For example, `gren --help now` would trigger this branch.
                -- We might want to remind the user that the `--help` option does not require any 
                -- values passed to it!
                displayHelpErrorMessage

            { args = parsedArgs, help = _ } ->
                -- Finally, a catch-all when the parsed arguments cannot be handled. You can
                -- display an error message to the user when this happens!
                displayUnknownArguments parsedArgs


As I hope you can see from the example, this package allows accept complex arguments and options for your program and, with a single case statement, map out how your program responds to those arguments.