package generate;

@:enum abstract TestEnum(Float) from Float to Float {

    public var VAL_A = 0.2;

    public var VAL_B = 2;

} //TestEnum

/** Generate data haxe code from data */
class Generate {

/// Public properties

    /** Generated file contents as values, type paths as keys */
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
                generateClass(name, input, pack, true);
            }
        }
        else {
            // Nope, then generate a class
            generateClass(name, input, pack, true);
        }

    } //generateDataHaxeFiles

/// Internal

    function generateEnumAbstract(name:String, input:Dynamic, type:String, pack:Array<String>) {

        var content = new StringBuf();

        content.add('\n');
        content.add('@:enum abstract ');
        content.add(name);
        content.add('(');
        content.add(type);
        content.add(') from ');
        content.add(type);
        content.add(' to ');
        content.add(type);
        content.add(' {\n\n');

        var nullValue = 'null';
        if (type == 'Int' || type == 'Float') {
            nullValue = '0';
        }
        else if (type == 'Bool') {
            nullValue = 'false';
        }

        // Add fields
        for (key in Reflect.fields(input)) {
            var value = Reflect.field(input, key);

            content.add('    var ');
            content.add(key);
            content.add(' = ');
            if (value != null) {
                content.add(Std.string(value));
            } else {
                content.add(nullValue);
            }
            content.add(';\n\n');
        }

        content.add('} //$name\n');
        content.add('\n');

        files.set(
            (pack.length > 0 ? pack.join('.') + '.' : '') + name,
            content.toString()
        );

    } //generateEnumAbstract

    function generateClass(name:String, input:Dynamic, pack:Array<String>, staticFields:Bool) {

        var content = new StringBuf();

        content.add('\n');
        content.add('class ');
        content.add(name);
        content.add(' {\n\n');

        content.add('    @:noCompletion private function new() {}\n\n');

        // Add fields
        for (key in Reflect.fields(input)) {
            var value = Reflect.field(input, key);

            var isSubType = false;
            var isInt = false;
            var isFloat = false;
            var isBool = false;
            var isString = false;
            var isNull = false;

            if (Std.is(value, Int)) {
                isInt = true;
            }
            else if (Std.is(value, Float)) {
                isFloat = true;
            }
            else if (Std.is(value, Bool)) {
                isBool = true;
            }
            else if (Std.is(value, String)) {
                isString = true;
            }
            else if (value != null) {
                isSubType = true;
            }

            if (isSubType) {
                if (staticFields) {
                    content.add('    public static var ');
                } else {
                    content.add('    public var ');
                }
            } else {
                if (staticFields) {
                    content.add('    public inline static var ');
                } else {
                    content.add('    public inline var ');
                }
            }

            content.add(key);
            if (isInt || isFloat) {
                content.add(' = ');
                content.add(Std.string(value));
            }
            else if (isBool) {
                content.add(' = ');
                content.add(value ? 'true' : 'false');
            }
            else if (isString) {
                content.add(' = ');
                content.add(value);
            }
            else if (isSubType) {
                var className = name + '_' + key;
                generateClass(className, value, pack, false);
                content.add(' = @:privateAccess new ');
                content.add(className);
                content.add('()');
            }
            else { //isNull
                content.add(':Dynamic = null');
            }
            content.add(';\n\n');
        }

        content.add('} //$name\n');
        content.add('\n');

        files.set(
            (pack.length > 0 ? pack.join('.') + '.' : '') + name,
            content.toString()
        );

    } //generateClass

} //Generate