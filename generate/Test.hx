package generate;

import sys.io.File;
import generate.Generate;
import haxe.Json;

class Test {

    public static function main():Void {

        for (i in 1...8) {
            test('data$i');
        }

    } //main

/// Tests

    static function test(name:String) {

        println('----------------------------------------------------');
        println('TEST $name\n');

        var generate = new Generate();
        var data = Json.parse(File.getContent('tests/$name.json'));
        generate.generateDataHaxeFiles(name.charAt(0).toUpperCase() + name.substr(1), data, [name]);
        
        println('JSON');
        println('\n' + Json.stringify(data, null, '    ') + '\n');

        for (key in generate.files.keys()) {
            println('HAXE $key');
            println(generate.files.get(key));
        }
    }

/// Helpers

    inline static function println(input:Dynamic) {
        #if sys
        Sys.println(input);
        #else
        trace(input);
        #end
    }

} //Test
