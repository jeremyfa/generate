package generate;

import haxe.Json;

using StringTools;

/** Generate data haxe code from data */
class Generate {

/// Options

    public var keep:Bool = true;

/// Public properties

    /** Generated file contents as values, type paths as keys */
    public var files = new Map<String,String>();

/// Lifecycle

    public function new() {

    }

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

    }

/// Internal

    function generateEnumAbstract(name:String, input:Dynamic, type:String, pack:Array<String>) {

        var content = new StringBuf();

        if (pack.length > 0) {
            content.add('package ');
            content.add(pack.join('.'));
            content.add(';\n');
        }
        else {
            content.add('package;\n');
        }

        content.add('\n');
        if (keep) {
            content.add('@:keep @:keepSub ');
        }
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
        var isString = false;
        var isBool = false;
        if (type == 'Int' || type == 'Float') {
            nullValue = '0';
        }
        else if (type == 'Bool') {
            nullValue = 'false';
            isBool = true;
        }
        else if (type == 'String') {
            isString = true;
        }

        // Add fields
        for (key in Reflect.fields(input)) {
            var value = Reflect.field(input, key);

            content.add('    ');
            if (key.startsWith('_')) {
                content.add('@:noCompletion ');
            }
            content.add('var ');
            content.add(key);
            content.add(' = ');
            if (value != null) {
                if (isString) {
                    content.add(Json.stringify(value));
                }
                else if (isBool) {
                    content.add(value ? 'true' : 'false');
                }
                else {
                    content.add(Std.string(value));
                }
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

    }

    function generateClass(name:String, input:Dynamic, pack:Array<String>, staticFields:Bool) {

        var content = new StringBuf();

        if (pack.length > 0) {
            content.add('package ');
            content.add(pack.join('.'));
            content.add(';\n');
        }
        else {
            content.add('package;\n');
        }

        content.add('\n');
        if (keep) {
            content.add('@:keep @:keepSub ');
        }
        content.add('class ');
        content.add(name);
        content.add(' {\n\n');

        if (!staticFields) content.add('    @:noCompletion private function new() {}\n\n');

        // Add fields
        for (key in Reflect.fields(input)) {
            var value = Reflect.field(input, key);

            var isSubType = false;
            var isInt = false;
            var isFloat = false;
            var isBool = false;
            var isString = false;

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

            key = sanitizeKeyForField(key);

            content.add('    ');
            if (key.startsWith('_')) {
                content.add('@:noCompletion ');
            }
            if (isSubType) {
                if (staticFields) {
                    content.add('public static final ');
                } else {
                    content.add('public final ');
                }
            } else {
                if (staticFields) {
                    content.add('public inline static final ');
                } else {
                    content.add('public final ');
                }
            }

            content.add(key);
            if (isInt) {
                content.add(':Int = ');
                content.add(Std.string(value));
            }
            else if (isFloat) {
                content.add(':Float = ');
                content.add(Std.string(value));
            }
            else if (isBool) {
                content.add(':Bool = ');
                content.add(value ? 'true' : 'false');
            }
            else if (isString) {
                content.add(':String = ');
                content.add(Json.stringify(value));
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

    }

    function sanitizeKeyForField(key:String):String {

        var code = key.charCodeAt(0);
        if (code >= '0'.code && code <= '9'.code) {
            key = '_' + key;
        }
        return key;

    }

}
