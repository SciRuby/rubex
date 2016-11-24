#include <ruby.h>

VALUE __rubex_f_addition(VALUE __rubex_self, VALUE __rubex_arg_a, VALUE __rubex_arg_b);
VALUE __rubex_f_addition(VALUE __rubex_self, VALUE __rubex_arg_a, VALUE __rubex_arg_b)
{
  int32_t __rubex_v_a = NUM2INT(__rubex_arg_a);
  int32_t __rubex_v_b = NUM2INT(__rubex_arg_b);

  return INT2NUM(__rubex_v_a + __rubex_v_b);
}

void
Init_basic_ruby_method(void)
{
  rb_define_method(rb_cObject, "addition", __rubex_f_addition, 2);
}