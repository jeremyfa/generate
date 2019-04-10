# generate

An utility to generate haxe code, intended for code completion, from json-ish data.

## What does it do?

**generate** takes as input JSON data and generate Haxe code to gives access to the same values through typed haxe classes and enum abstracts, providing code completion and type safety.

### Why generating classes and enum abstracts, and not simply typedefs/structures?

Using typedefs/structures provides type safety but is based on dynamic access internally, which can be very problematic on many static targets (C++, for instance).

However, classes and enum abstracts are very good options to provide both type safety and efficient access that doesn't rely on dynamic resolution.

## How to use

### Practical example

```haxe
class Main {
    public static function main() {

        // The input data
        var input = {
            AAA: 1,
            BBB: 2,
            CCC: 3
        };

        // Init generator
        var gen = new generate.Generate();

        // Generate code from input
        gen.generateDataHaxeFiles('MyData', input, ['my','data']);

        // Print result
        for (key in gen.files.keys()) {
            trace('typepath: ' + key);
            trace('content: ' + gen.files.get(key));
        }

    }
}
```

### Explanation

Given this JSON data:

```json
{
    "AAA": 1,
    "BBB": 2,
    "CCC": 3
}
```

**generate** utility will provide this haxe code as a result:

```haxe
package my.data;

@:enum abstract MyData(Int) from Int to Int {

    var AAA = 1;

    var BBB = 2;

    var CCC = 3;

} //MyData
```

Note that because every value have the same type, and that this type is a primitive type (`Int`), an enum abstract was generated. This even allows to have type safety and unhandled `case` detection with `switch()` constructs

### More complex case

On more complex case, **generate** utility may provide multiple haxe files as a result.

Given this JSON data:

```json
{
    "CCC": {
        "EEE": 34,
        "DDD": 32
    },
    "AAA": true,
    "BBB": false
}
```

**generate** utility will provide multiple files:

```haxe
package my.data;

class MyData {

    public static var CCC = @:privateAccess new MyData_CCC();

    public inline static var AAA:Bool = true;

    public inline static var BBB:Bool = false;

} //MyData
```

```haxe
package my.data;

class MyData_CCC {

    @:noCompletion private function new() {}

    public inline var EEE:Int = 34;

    public inline var DDD:Int = 32;

} //MyData_CCC
```

## Possible improvements

**generate** utility should work fine for the above cases and the ones tested in `generate/Test.hx` (see json test files in `tests/` directory).

However, it could be improved to:

- Handle arrays in JSON data
- Have a bit more options?
- Write result files to a specified directory
