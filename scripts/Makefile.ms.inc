axi-srcs = $(wildcard $(srcrootdir)/axi/*.vhd)
axi-vsrcs = $(wildcard $(srcrootdir)/axi/*.v)
axi-tags = $(patsubst $(srcrootdir)/axi/%.vhd,$(buildrootdir)/axi_lib/%.tag,$(axi-srcs)) $(patsubst $(srcrootdir)/axi/%.v,$(buildrootdir)/axi_lib/%.tag,$(axi-vsrcs))
$(axi-tags): $(buildrootdir)/axi_lib/exists
axi_lib: $(axi-tags)
axi_lib.axi_pkg: $(buildrootdir)/axi_lib/axi_pkg.tag
$(buildrootdir)/axi_lib/axi_pkg.tag: $(srcrootdir)/axi/axi_pkg.vhd

global-srcs = $(wildcard $(srcrootdir)/global/*.vhd)
global-vsrcs = $(wildcard $(srcrootdir)/global/*.v)
global-tags = $(patsubst $(srcrootdir)/global/%.vhd,$(buildrootdir)/global_lib/%.tag,$(global-srcs)) $(patsubst $(srcrootdir)/global/%.v,$(buildrootdir)/global_lib/%.tag,$(global-vsrcs))
$(global-tags): $(buildrootdir)/global_lib/exists
global_lib: $(global-tags)
global_lib.global: $(buildrootdir)/global_lib/global.tag
$(buildrootdir)/global_lib/global.tag: $(srcrootdir)/global/global.vhd
global_lib.numeric_std: $(buildrootdir)/global_lib/numeric_std.tag
$(buildrootdir)/global_lib/numeric_std.tag: $(srcrootdir)/global/numeric_std.vhd
global_lib.sim_utils_sim: $(buildrootdir)/global_lib/sim_utils_sim.tag
$(buildrootdir)/global_lib/sim_utils_sim.tag: $(srcrootdir)/global/sim_utils_sim.vhd
global_lib.sim_utils: $(buildrootdir)/global_lib/sim_utils.tag
$(buildrootdir)/global_lib/sim_utils.tag: $(srcrootdir)/global/sim_utils.vhd
global_lib.utils: $(buildrootdir)/global_lib/utils.tag
$(buildrootdir)/global_lib/utils.tag: $(srcrootdir)/global/utils.vhd
$(buildrootdir)/global_lib/global.tag: \
$(buildrootdir)/random_lib/rnd.tag \
$(buildrootdir)/global_lib/numeric_std.tag
$(buildrootdir)/global_lib/sim_utils.tag: \
$(buildrootdir)/random_lib/rnd.tag \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/global.tag \
$(buildrootdir)/global_lib/utils.tag
$(buildrootdir)/global_lib/sim_utils_sim.tag: \
$(buildrootdir)/random_lib/rnd.tag \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/global.tag \
$(buildrootdir)/global_lib/sim_utils.tag
$(buildrootdir)/global_lib/utils.tag: \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/global.tag

random-srcs = $(wildcard $(srcrootdir)/random/*.vhd)
random-vsrcs = $(wildcard $(srcrootdir)/random/*.v)
random-tags = $(patsubst $(srcrootdir)/random/%.vhd,$(buildrootdir)/random_lib/%.tag,$(random-srcs)) $(patsubst $(srcrootdir)/random/%.v,$(buildrootdir)/random_lib/%.tag,$(random-vsrcs))
$(random-tags): $(buildrootdir)/random_lib/exists
random_lib: $(random-tags)
random_lib.random_pkg: $(buildrootdir)/random_lib/random_pkg.tag
$(buildrootdir)/random_lib/random_pkg.tag: $(srcrootdir)/random/random_pkg.vhd
random_lib.rnd: $(buildrootdir)/random_lib/rnd.tag
$(buildrootdir)/random_lib/rnd.tag: $(srcrootdir)/random/rnd.vhd
$(buildrootdir)/random_lib/rnd.tag: \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/random_lib/random_pkg.tag

register-srcs = $(wildcard $(srcrootdir)/register/*.vhd)
register-vsrcs = $(wildcard $(srcrootdir)/register/*.v)
register-tags = $(patsubst $(srcrootdir)/register/%.vhd,$(buildrootdir)/register_lib/%.tag,$(register-srcs)) $(patsubst $(srcrootdir)/register/%.v,$(buildrootdir)/register_lib/%.tag,$(register-vsrcs))
$(register-tags): $(buildrootdir)/register_lib/exists
register_lib: $(register-tags)
register_lib.axi_register: $(buildrootdir)/register_lib/axi_register.tag
$(buildrootdir)/register_lib/axi_register.tag: $(srcrootdir)/register/axi_register.vhd
register_lib.axi_register_wrapper: $(buildrootdir)/register_lib/axi_register_wrapper.tag
$(buildrootdir)/register_lib/axi_register_wrapper.tag: $(srcrootdir)/register/axi_register_wrapper.vhd
$(buildrootdir)/register_lib/axi_register.tag: \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/utils.tag \
$(buildrootdir)/axi_lib/axi_pkg.tag
$(buildrootdir)/register_lib/axi_register_wrapper.tag: \
$(buildrootdir)/axi_lib/axi_pkg.tag \
$(buildrootdir)/register_lib/axi_register.tag

all-tags =  $(axi-tags) $(global-tags) $(random-tags) $(register-tags)
doc-srcs =  $(axi-srcs) $(global-srcs) $(random-srcs) $(register-srcs)
doc-vsrcs =  $(axi-vsrcs) $(global-vsrcs) $(random-vsrcs) $(register-vsrcs)
$(vhdocldir)/done: $(doc-srcs)
