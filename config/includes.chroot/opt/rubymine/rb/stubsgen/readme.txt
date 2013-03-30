This scripts are used to generate stubs for ruby built-in classes and modules

settings.rb - settings file, where you can define global varibales used in generation process
gen_stubs.rb - run it to generate stubs files for all built-in modules and classes

stubs_test.rb - file to test stubs content.

After stubs are generated, please move these methods from Module to Kernel: "include", "private", "public"