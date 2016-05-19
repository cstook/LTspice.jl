# Internal Documentation

## Index

```@index
Pages = ["internal_api.md"]
```

## LTspice methods

```@docs
LTspice.run!
LTspice.parameters
```

## Circuit File Parsing

```@docs
LTspice.CircuitParsed
LTspice.Card
LTspice.parsecard!
LTspice.iscomment
```


## Log File Parsing

```@docs
LTspice.LogParsed
LTspice.NonSteppedLog
LTspice.SteppedLog
parse(::LTspice.SteppedLog)
LTspice.LogLine
LTspice.Header
LTspice.Footer
LTspice.Measurement
LTspice.StepParameters
LTspice.StepMeasurementName
LTspice.StepMeasurementValue
LTspice.parseline!
LTspice.processlines!
```

## Utilities

```@docs
LTspice.makecircuitfileincludeabsolutepath
LTspice.blanklog
LTspice.defaultltspiceexecutable
LTspice.MultiLevelIterator
LTspice.removetempdirectories
```