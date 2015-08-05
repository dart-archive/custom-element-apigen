# Custom Elements APIGen

This package contains a tool that lets you wrap custom elements written with
polymer.js and provide a Dart API for them.

The tool assumes that the JavaScript code was packaged using bower and follows
bower packages conventions.

To use it, you need to:
  * Install node/npm.
  * Globally install `bower` and `hydrolysis` npm packages.
  * configure bower to put the packages under `lib/src/` instead of the default
    `bower_components`. For exmaple, with a `.bowerrc` file as follows:

        {
          "directory": "lib/src"
        }

  * setup your `bower.json` file
  * install packages via `bower install`
  * (one time) create a configuration file for this tool
  * run the tool via `pub run custom_element_apigen:update configfile.yaml`

There is not much documentation written for this tool. You can find examples of
how this tool is used in the [polymer-elements][1] package.

[1]: https://github.com/dart-lang/polymer-elements/
