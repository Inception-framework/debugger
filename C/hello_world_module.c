/* hello_world_module.c */
#include <linux/init.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/kernel.h>
#include <linux/jiffies.h>

static int hello_world_module_value = 1;
module_param(hello_world_module_value, int, 0644);
MODULE_PARM_DESC(hello_world_module_value, "Parameter of hello_world_module module.");

static int __init hello_world_module_init(void)
{
  pr_info("Hello sab4z!\nValue=%d\nJiffies=%lu\n", hello_world_module_value, jiffies);
  return 0;
}

static void __exit hello_world_module_exit(void)
{
  pr_info("Jiffies=%lu\nValue=%d\nBye sab4z!\n", jiffies, hello_world_module_value);
}

module_init(hello_world_module_init);
module_exit(hello_world_module_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("An example hello world module");
MODULE_AUTHOR("Marvin42");
