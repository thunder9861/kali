include Java

import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.AnyParamDef unless defined? AnyParamDef
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefLeaf unless defined? ParamDefLeaf
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefRepeat unless defined? ParamDefRepeat
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefHash unless defined? ParamDefHash
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefArray unless defined? ParamDefArray
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefSeq unless defined? ParamDefSeq
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.EnumParam unless defined? EnumParam
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDef unless defined? ParamDef

require File.dirname(__FILE__) + '/hash_key_paramdef_delegate'

# Paramdefs DSL brief documentation
# 1. define_params CALL_FQN, paramdefs
#
#   paramdefs will be automatically wrapped in list, i.g. each call argument will be matched with paramdef at the same
#   index. HashParamdef - is exception, if hash is in parenthesis the basic rule work, otherwise all associations will
#   be collected and send to hash paramdef with index of first association in call arguments
#
# 2. or_pdef(param1, param2, ..param_n)
#   has semantic of:  param1 || param2 || .. || param_n
#   If OR paramdef contains HashParamdef or KleeneClosure paramdef - it can be applied for several call arguments
#
# 3. kleene(paramdef)
#  Kleene closure - interprets all call arguments for current and to the end of call with this paramdef.
#  E.g.
#    define_params FQN, one_of(:one), kleene(one_of(:other))) will accept
#    FQN :one
#    FQN :one, :other
#    FQN :one, :other, :other, .., :other
#
# 3. [] - list paramdef, expects to be applied of array of call arguments, e.g :key => [val2, val3, ..]
#
# 4. [paramdef, :*] ~ or_pdef(paramdef, [kleene(paramdef)])
#     Just a macros, e.g will accept to keys's values :key => val and :key => [val1, val2, val3]
#
# 5. [paramdef, :+]  ~ [kleene(paramdef)]
#     Just a macros
#
# 6. one_of(sting_or_symbol1, string_or_symbol2, ..)
#    Accepts one of alternatives. Each alternative is string or symbol value
#
# 7. maybe_one_of(sting_or_symbol1, string_or_symbol2, ..)
#    The same as one_of(..) but inspection will not warn about unexpected alternatives
#
# 8. {:key1 => paramdef1, :key2 => paramdef2, ..}
#     Hash of paramdefs. If it contains key :enable_optional_keys  - it will be automatically removed. If it's value
#    was true - inspection will not be warn about unexpected hash keys for corresponding call's argument
#
# 9. nil
#    This paramdef accept any value of argument. It is used as stub when we don't implement paramdef for some call's argument
#
class BaseParamDefsLoader
  def one_of(*params)
    EnumParam.create_one_of(params)
  end

  # one_of paramdef that doesn't differ strings and symbols
  def one_of_strings_or_symbols(*params)
    EnumParam.create_one_of_allowing_str_and_symb(params)
  end

  def maybe_one_of(*params)
    EnumParam.create_maybe_one_of(params)
  end

  def symbol_or_string_representation(str_or_symb)
    (str_or_symb.is_a?(Symbol) ? ":" : "") + str_or_symb.to_s
  end

  def define_params_copy(name, copy_from_name)
    @manager.registerParamDefCopy(copy_from_name, name)
  end

  def bool?(value)
    value == true || value == false
  end

  def convert_param_expr(p)
    if p.nil?
      ParamDefLeaf.new(nil_paramdef)
    elsif p.kind_of? Array
      ParamDefRepeat.new(convert_param_expr(p[0]), 0, -1, true)
    elsif p.kind_of? Hash
      optional = p.delete(:enable_optional_keys)
      optional_ref = bool?(optional) ? nil : convert_param_expr(optional)

      if optional
        hash = ParamDefHash.new(true, optional_ref)
      else
        hash = ParamDefHash.new(false, optional_ref)
      end
      p.each { |key, value|
        if key.kind_of?(ParamDef)
          hash.add_key(ParamDefs::HashKeyParamdefDelegate.new(key),
                       convert_param_expr(value))
        else
          hash.add_key(key, convert_param_expr(value))
        end
      }
      hash
    elsif p.kind_of? Symbol
      ParamDefLeaf.new(EnumParam.create_one_of([p]))
    elsif p.kind_of? org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefExpression
      p
    else
      ParamDefLeaf.new(p)
    end
  end

  def to_java_expressions(params)
    param_expressions = params.collect { |p| convert_param_expr(p) }
    param_expressions = param_expressions.to_java(:"org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefExpression")
  end

  def paramdef(module_or_class_name, method_name, *params)
    param_expressions = to_java_expressions(params)
    seq = ParamDefSeq.new(param_expressions)
    if method_name.kind_of? Array
      method_name.each do |c|
        @manager.registerParamDefExpression module_or_class_name + "::" + c, seq
      end
    else
      @manager.registerParamDefExpression module_or_class_name + "::" + method_name, seq
    end
  end

  def either(*params)
    org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.matcher.ParamDefOr.new(to_java_expressions(params))
  end

  def seq(*params)
    ParamDefSeq.new(to_java_expressions(params))
  end

  def one_str_literal_or_more_of(param)
    # Doesn't accept hash arguments in sequence
    ParamDefRepeat.new(convert_param_expr(param), 1, -1, true)
  end

  def one_complex_arg_or_more_of(param)
    # Doesn't accept hash arguments in sequence
    ParamDefRepeat.new(convert_param_expr(param), 1, -1, false)
  end

  def array_of(*params)
    param_expressions = to_java_expressions(params)
    seq = ParamDefSeq.new(param_expressions)
    ParamDefArray.new(seq)
  end

  def maybe(param)
    ParamDefRepeat.new(convert_param_expr(param), 0, 1, true)
  end

  def bool
    org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.BoolParam.new
  end

  def data_type
    org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.DataTypesParam.new
  end

  def nil_paramdef
    AnyParamDef.getInstance
  end
end