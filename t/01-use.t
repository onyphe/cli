use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Api::Onyphe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Log"); $@ ? 0 : 1 }, 1, $@);
