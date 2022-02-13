use Test;
BEGIN { plan(tests => 24) }

ok(sub { eval("use Metabrik::Client::Onyphe::Function"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Addcount"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Allowlist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Blacklist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Blocklist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Count"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Dedup"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Exec"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Expand"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Export"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Fields"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Flat"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Httpshot"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Lookup"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Merge"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Output"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Piechart"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Search"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Splitsubnet"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Top"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Uniq"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Where"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Whitelist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Onyphe::Function::Whois"); $@ ? 0 : 1 }, 1, $@);
