#medoo orm with zephir lang

make medoo to c extension for perfomance.


Requirements
------------
To compile zephir-parser:

* [re2c](http://re2c.org/)

To build the PHP extension:

* g++ >= 4.4/clang++ >= 3.x/vc++ 9
* gnu make 3.81 or later
* php development headers and tools
* zephir
---------------
You can install zephir using composer.
Run `composer require phalcon/zephir`, run `./install` and then run `zephir`
from your `bin-dir`. By default it is `./vendor/bin/zephir`.
You can read more about composer binaries
in it's [documentation](https://getcomposer.org/doc/articles/vendor-binaries.md).

For global installation via composer you can use `composer global require`.
Do not forget add `~/.composer/vendor/bin` into your `$PATH`.

Also you can just clone zephir repository and run `./install`.
For global installation add `-c` flag.

#Install
------------------
Compile the extension:

```bash
./bin/zephir compile
```

#Usage

* [Documentation](http://medoo.in/)


External Links
--------------
* [Documentation](http://zephir-lang.com/)
* [Official Blog](http://blog.zephir-lang.com/)
* [Forum](https://forum.zephir-lang.com/)
* [Twitter](https://twitter.com/zephirlang)


License
-------
Medoo-Zephir is open-sourced software licensed under the MIT License. See the LICENSE file for more information.

Thanks
------------

* [ Medoo orm ](http://medoo.in/)