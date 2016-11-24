#include <ruby.h>

VALUE __rubex_f_addition(int argc, VALUE *argv, VALUE __rubex_self);
VALUE __rubex_f_addition(int argc, VALUE *argv, VALUE __rubex_self)
{
  int32_t __rubex_v_a = NUM2INT(argv[0]);
  int32_t __rubex_v_b = NUM2INT(argv[1]);

  return INT2NUM(__rubex_v_a + __rubex_v_b);
}

void
Init_basic_ruby_method(void)
{
  rb_define_method(rb_cObject, "addition", __rubex_f_addition, -1);
}