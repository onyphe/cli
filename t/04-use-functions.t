use Test;
BEGIN { plan(tests => 14) }

ok(sub { eval("use Metabrik::Client::Onyphe::Function"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Dedup"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Addcount"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Blacklist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Count"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Dedup"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Merge"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Output"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Search"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Where"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Whitelist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Exec"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Httpshot"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Whois"); $@ ? 0 : 1 }, 1, $@);
