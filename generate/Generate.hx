package generate;

@:enum abstract TestEnum(Float) from Float to Float {

    public var VAL_A = 0.2;

    public var VAL_B = 2;

} //TestEnum

/** Generate data haxe code from data */
class Generate {

/// Public properties

    /** Generated file contents as values, relative paths as keys */
    public var files = new Map<String,String>();

/// Lifecycle

    public function new() {

        var kind:TestEnum = VAL_A;

        switch (kind) {
            case VAL_A: trace('kind A: $kind');
            case VAL_B: trace('kind B: $kind');
        }

    } //new

/// Public API

    public function generateDataHaxeFiles(name:String, input:Dynamic, ?pack:Array<String>) {

        if (pack == null) pack = [];

        var hasSubTypes = false;
        var hasInts = false;
        var hasFloats = false;
        var hasBools = false;
        var hasStrings = false;

        // Gather info to determine which haxe construct is best
        for (key in Reflect.fields(input)) {
            var value = Reflect.field(input, key);
            if (value != null) {
                if (Std.is(value, Int)) {
                    hasInts = true;
                }
                else if (Std.is(value, Float)) {
                    hasFloats = true;
                }
                else if (Std.is(value, Bool)) {
                    hasBools = true;
                }
                else if (Std.is(value, String)) {
                    hasStrings = true;
                }
                else {
                    hasSubTypes = true;
                }
            }
        }

        // Check if we can generate an abstract enum
        // (enum abstracts are great for code safety, switch autocompletion...)
        if (!hasSubTypes) {
            if (hasInts && !hasFloats && !hasBools && !hasStrings) {
                generateEnumAbstract(name, input, 'Int', pack);
            }
            else if (hasFloats && !hasBools && !hasStrings) {
                generateEnumAbstract(name, input, 'Float', pack);
            }
            else if (hasBools && !hasInts && !hasFloats && !hasStrings) {
                generateEnumAbstract(name, input, 'Bool', pack);
            }
            else if (hasStrings && !hasInts && !hasFloats && !hasBools) {
                generateEnumAbstract(name, input, 'String', pack);
            }
            else {
                // Nope, then generate a class
                generateClass(name, input, pack);
            }
        }
        else {
            // Nope, then generate a class
            generateClass(name, input, pack);
        }

    } //generateDataHaxeFiles

/// Internal

    function generateEnumAbstract(name:String, input:Dynamic, type:String, pack:Array<String>) {

        // TODO

    } //generateEnumAbstract

    function generateClass(name:String, input:Dynamic, pack:Array<String>) {

        // TODO

    } //generateClass

} //Generate
