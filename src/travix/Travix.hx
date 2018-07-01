package travix;

import haxe.DynamicAccess;
import haxe.Json;
import sys.FileSystem;
import haxe.ds.Option;
import sys.io.*;
import Sys.*;
import travix.commands.*;
import tink.cli.Rest;

using StringTools;
using haxe.io.Path;
using sys.FileSystem;
using sys.io.File;

#if macro
import haxe.macro.MacroStringTools;
import haxe.macro.Context;
#end

class Travix {
  public static inline var TESTS = 'tests.hxml';
  static inline var TRAVIX_COUNTER = '.travix_counter';
  static inline var HAXELIB_CONFIG = 'haxelib.json';
  
  // env
  public static var isTravis = getEnv('TRAVIS') == 'true';
  public static var isAppVeyor = getEnv('APPVEYOR') == 'True';
  public static var isCI = getEnv('CI') != null;
  
  // repeated calls, but ok...
  public static var isLinux = systemName() == 'Linux';
  public static var isMac = systemName() == 'Mac';
  public static var isWindows = systemName() == 'Windows';
  
  public static var counter = 0;
  
  public static function getInfos():Option<Infos> {
    return if(HAXELIB_CONFIG.exists()) Some(haxe.Json.parse(HAXELIB_CONFIG.getContent())) else None;
  }
    
  /**
   * @return fully qualified class name of the main class
   */
  public static function getMainClassFQName():String {
    
    function read(file:String) {
      for (line in file.getContent().split('\n').map(function (s:String) return s.split('#')[0].trim())) 
        if (line.startsWith('-main'))
          return Some(line.substr(5).trim());
        else
          if (line.endsWith('.hxml'))
            switch read(line) {
              case None:
              case v: return v;
            }
            
      return None;
    }
    
    var args = Sys.args();
    for(i in 0...args.length) {
      if(args[i] == '-main') return args[i + 1];
      else if(args[i].endsWith('.hxml')) switch read(args[i]) {
        case None: // do nothing
        case Some(v): return v;
      }
    }
    
    if(TESTS.exists()) switch read(TESTS) {
      case None: // do nothing
      case Some(v): return v;
    }
    
    return die('no -main class found');
  }
  
  /**
   * @return non-qualified class name of the main class (i.e. without package)
   */
  public static function getMainClassLocalName():String {
    return getMainClassFQName().split(".").pop();
  }

  public static function die(message:String, ?code = 500):Dynamic {
    println(message);
    exit(code);
    return null;
  }

  static function main() {
    incrementCounter();
    
    var args = Sys.args();
    
    if(Sys.getEnv('HAXELIB_RUN') == '1')
      Sys.setCwd(args.pop());

    // Remove the first argument (target), add "--" to get the others
    // into rest arguments.
    var first = args.shift();
    args.unshift("--");
    args.unshift(first);
      
    tink.Cli.process(args, new Travix()).handle(tink.Cli.exit);
  }

  static function incrementCounter()
    if(isTravis) {
      counter = TRAVIX_COUNTER.exists() ? Std.parseInt(TRAVIX_COUNTER.getContent()) : 0;
      TRAVIX_COUNTER.saveContent(Std.string(counter+1));
    }
    
  function new() {}
  
  @:defaultCommand
  public function help() {
    // println(tink.Cli.getDoc(this));
    
    println('Commands');
    println('  ');
    println('  init - initializes a project with a .travis.yml');
    println('  install - installs dependencies');
    println('  interp - run tests on interpreter');
    println('  neko - run tests on neko');
    println('  node - run tests on nodejs (with hxnodejs)');
    println('  js - run tests on js (with phantomjs)');
    println('  php - run tests on php 5.x');
    println('  php7 - run tests on php 7.x');
    println('  java - run tests on java');
    println('  flash - run tests on flash');
    println('  python - run tests on python');
    println('  cs - run tests on cs');
    println('  cpp - run tests on cpp');
    println('  lua - run tests on lua');
    println('  hl - run tests on hashlink');
  }
  
  @:command public var install = new InstallCommand();
  @:command public var run = new RunCommand();
  
  /**
   *  initializes a project with a .travis.yml
   */
  @:command 
  public function init()
    new InitCommand().doIt();
    
  @:command 
  public function auth(rest:Rest<String>)
    new AuthCommand().doIt(rest);
    
  @:command 
  public function release(rest:Rest<String>)
    new ReleaseCommand().doIt(rest);
  
  /**
   *  run tests on cs
   */
  @:command
  public function cs(rest:Rest<String>) {
    var command = new CsCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on node
   */
  @:command
  public function node(rest:Rest<String>) {
    var command = new NodeCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on cpp
   */
  @:command
  public function cpp(rest:Rest<String>) {
    var command = new CppCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on flash
   */
  @:command
  public function flash(rest:Rest<String>) {
    var command = new FlashCommand();
    command.install();
    command.buildAndRun(rest);
  }

  /**
   *  run tests on hashlink
   */
  @:command
  public function hl(rest:Rest<String>) {
    var command = new HashLinkCommand();
    command.install();
    command.buildAndRun(rest);
  }

  /**
   *  run tests on interp
   */
  @:command
  public function interp(rest:Rest<String>) {
    var command = new InterpCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on java
   */
  @:command
  public function java(rest:Rest<String>) {
    var command = new JavaCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on js
   */
  @:command
  public function js(rest:Rest<String>) {
    var command = new JsCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on lua
   */
  @:command
  public function lua(rest:Rest<String>) {
    var command = new LuaCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on neko
   */
  @:command
  public function neko(rest:Rest<String>) {
    var command = new NekoCommand();
    command.install();
    command.buildAndRun(rest);
  }
  
  /**
   *  run tests on php
   */
  @:command
  public function php(rest:Rest<String>) {
    var command = new PhpCommand(false);
    command.install();
    command.buildAndRun(rest);
    command.uninstall();
  }
  
  /**
   *  run tests on php7
   */
  @:command
  public function php7(rest:Rest<String>) {
    var command = new PhpCommand(true);
    command.install();
    command.buildAndRun(rest);
    command.uninstall();
  }
  
  /**
   *  run tests on python
   */
  @:command
  public function python(rest:Rest<String>) {
    var command = new PythonCommand();
    command.install();
    command.buildAndRun(rest);
  }
}

