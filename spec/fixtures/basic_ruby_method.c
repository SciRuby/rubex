#include <ruby.h>

VALUE __rubex_f_addition(VALUE __rubex_self, VALUE __rubex_arg_a, VALUE __rubex_arg_b);
VALUE __rubex_f_addition(VALUE __rubex_self, VALUE __rubex_arg_a, VALUE __rubex_arg_b)
{
  int32_t __rubex_v_a = NUM2INT(__rubex_arg_a);
  int32_t __rubex_v_b = NUM2INT(__rubex_arg_b);

  return INT2NUM(__rubex_v_a + __rubex_v_b);
}

Init_basic_ruby_method(void)
{
  // set ruby method
}