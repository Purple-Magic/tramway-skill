# Deployment Recipe

Use this recipe for `Implement deployment`, `update deployment`, or deployment setup requested during new Rails project creation.

Before secret handling, load `agents/recipes/save-rails-secrets-1password.md` and follow it for `config/master.key`, Rails credentials keys, staging/production secrets, provider tokens, and repository secrets.

Load `agents/rails.md` for deployment command and configuration conventions. Also load `agents/integrations.md` if deployment touches third-party providers, background delivery, or external service setup.

## Deployment Management Scripts (`bin/`)

Deploy/infra management commands (setup, deploy, logs, console, remove, remove_fully) are Ruby scripts under `bin/`, not `Makefile` targets. Each script is a thin proxy for the matching Kamal command: it preloads the environment Kamal needs for the target destination (`MAIN_HOST`/`DB_HOST`/`HOST`/`RAILS_ENV`), then hands off to `kamal` with the original arguments intact.

This skill does **not** use Terraform. Servers for `staging` and `production` are created and deleted by `bin/setup -d <environment>` and `bin/remove_fully -d <environment>`, which talk to whatever hosting the user chose, through that hosting's API or command-line utility (`doctl`, `hcloud`, `aws`, plain REST API, ...). All provider-specific code lives in one file, `lib/server_provider.rb`. Do not install, suggest, or generate Terraform for new work. If a project still has a `terraform/` directory, follow "Migrating Away From Terraform" below.

Required scripts:

- `bin/setup` — with no `-d`/`--destination` flag, keep Rails' own local-development bootstrap behavior (bundle install, `db:prepare`, clear logs/tmp, boot `bin/dev`) unchanged. With `-d staging` or `-d production`: look up the server in `.kamal/servers.yml`; if there is no IP recorded, ask whether to create a new server (or record an existing one) and, for a new one, require the typed environment name before creating anything; then wait for SSH, export the environment, and `exec kamal setup` with the original arguments.
- `bin/deploy` — resolve the recorded server/environment for the given `-d`/`--destination`, then `exec kamal deploy` with the original arguments. Never creates a server; aborts and points to `bin/setup -d <environment>` when none is recorded.
- `bin/logs` — resolve the same environment, then `exec kamal app logs` with the original arguments.
- `bin/console` — resolve the same environment, then `exec kamal app exec --interactive` with the original arguments plus the Rails console command.
- `bin/remove` — resolve the same environment, require the operator to type the full destination name to confirm, then `exec kamal remove` with the original arguments. It removes only the app (containers, networks) from the server; **the server itself stays and keeps costing money.** The script must carry a comment saying that `bin/remove_fully` exists for deleting the server too and must be used with great care.
- `bin/remove_fully` — resolve the same environment, require the operator to type the full destination name, then run `kamal remove` **and** delete the server at the hosting provider, in that order. `kamal remove` is never run by this script without the server deletion, and the server is never deleted without it. Refuses to run when no server (or no provider `server_id`) is recorded.

**Progress output for `bin/setup -d <environment>`.** Creating a server takes minutes, so the script must never go quiet. Use the `colorize` gem (add `gem "colorize"` to the `Gemfile` development group if absent, and run `bundle install`) via the `KamalCli.step`/`info`/`ok` helpers: print a blue `==>` line before each phase (creating the server, updating DNS, waiting for SSH, running `kamal setup`), a green `✔` line when it finishes, and a heartbeat line every ~10 seconds (`KamalCli.with_progress`) during any long blocking call such as the provider CLI waiting for the server, plus a retry line per SSH attempt. Errors use red. Never print tokens or secret values in these logs.

**No silent hangs (rule for every script and helper).**
- Validate every typed value immediately: an IP prompt accepts only an IP address (`valid_ip?`), a hostname prompt only a domain (`valid_hostname?`). A wrong answer is rejected on the spot with a hint and a re-prompt (max 3 tries), never stored.
- Before any wait or network call, check the target resolves/is well-formed and abort at once on errors retrying cannot fix (unresolvable name, malformed address).
- Every wait loop has an explicit short timeout, prints elapsed/remaining time on each retry, and ends with an actionable error message (what to check, which file to fix).
- Every subprocess that can block (provider CLI, `kamal`) is wrapped in `KamalCli.with_progress` so a heartbeat shows it is alive.
- Before handing off to `kamal setup`, print the resolved `MAIN_HOST`/`HOST` for the operator to see. `kamal setup` is for first installation only; if the server already runs the app, point the operator to `bin/deploy -d <environment>` instead.
- `bin/setup` also validates entries already recorded in `.kamal/servers.yml` (a hand-edited or typo'd `main_host` aborts with a pointer to the file) before waiting for SSH.

Shared logic (recorded-server lookup, typed confirmations, SSH wait, environment export, required-command checks) belongs in `lib/kamal_cli.rb` and is `require_relative`d from each `bin/` script, not copy-pasted per script. Provider logic (create/delete server, optional DNS) belongs only in `lib/server_provider.rb`.

### Recorded server data (`.kamal/servers.yml`)

The scripts keep no IPs inside themselves. The server for each destination is recorded in `.kamal/servers.yml`, which must be gitignored (add `/.kamal/servers.yml` to `.gitignore`; do not ignore the rest of `.kamal/`, which holds `secrets` and hooks):

```yaml
staging:
  main_host: 203.0.113.10        # public IP; what Kamal connects to
  host: staging.example.com      # public hostname served by the app (HOST)
  server_id: "123456789"         # provider id; absent for a server recorded by hand
```

- A destination with no `main_host` entry means "no server yet". `bin/setup -d` asks what to do; every other script aborts.
- `server_id` exists only for servers created by `bin/setup`. A hand-recorded server has none, so `bin/remove_fully` cannot (and must not try to) delete it.
- The file is written right after the provider reports the server created, before SSH wait, DNS, or Kamal run, so a later failure never loses the `server_id` of a paid resource.

### Typed confirmation of server actions

Every action that creates or deletes a server must be confirmed by typing the **full environment name** exactly (`production`, not `prod`, not `y`), so a mis-click or a muscle-memory `y` cannot touch a server. Rules:

- The prompt comes first, before any provider call, `kamal` call, or file change.
- Exact string match only. No `--yes`/`-y`/environment-variable bypass in the scripts.
- The prompt states what will happen (create/delete, which host, that deletion is irreversible).
- When stdin is not a terminal (CI, pipes, agents), the script aborts instead of guessing.

### `lib/kamal_cli.rb`

```ruby
require "fileutils"
require "socket"
require "ipaddr"
require "yaml"
require "colorize"
require_relative "server_provider"

module KamalCli
  module_function

  # --- Progress output ------------------------------------------------------
  # Provisioning takes minutes. Every step prints what it is doing, so the operator never wonders
  # whether the script hung.

  def step(message) = puts("==> #{message}".blue.bold)
  def info(message) = puts("    #{message}")
  def ok(message) = puts("    ✔ #{message}".green)
  def warn_line(message) = puts("    ! #{message}".yellow)

  # Runs the block while a background thread prints "still working" every `every` seconds.
  def with_progress(message, every: 10)
    started = Time.now
    ticker = Thread.new do
      loop do
        sleep every
        info("#{message} (still working, #{(Time.now - started).to_i}s elapsed)".light_black)
      end
    end
    yield
  ensure
    ticker&.kill
  end

  SERVERS_FILE = File.expand_path("../.kamal/servers.yml", __dir__)

  def destination_from(args)
    args.each_cons(2) { |flag, value| return value if %w[-d --destination].include?(flag) }
    nil
  end

  def require_commands!(*names)
    names.each do |name|
      next if system("command -v #{name} > /dev/null 2>&1")

      abort "Missing required command: #{name}"
    end
  end

  # --- Recorded server data -------------------------------------------------

  def servers
    File.exist?(SERVERS_FILE) ? (YAML.safe_load_file(SERVERS_FILE) || {}) : {}
  end

  def server_for(destination)
    server = servers[destination]
    server if server && !server["main_host"].to_s.empty?
  end

  def save_server(destination, data)
    FileUtils.mkdir_p(File.dirname(SERVERS_FILE))
    File.write(SERVERS_FILE, servers.merge(destination => data).to_yaml)
  end

  def forget_server(destination)
    File.write(SERVERS_FILE, servers.reject { |name, _| name == destination }.to_yaml)
  end

  # --- Input validation (fail fast on typos instead of hanging later) -------

  HOSTNAME_PATTERN = /\A(?=.{1,253}\z)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/i

  def valid_ip?(value)
    IPAddr.new(value.to_s)
    value.to_s.match?(/\A[\d.:a-fA-F]+\z/) # reject names; IPAddr alone accepts some odd forms
  rescue IPAddr::Error
    false
  end

  def valid_hostname?(value)
    value.to_s.match?(HOSTNAME_PATTERN)
  end

  # Asks until the answer passes `valid`, or the operator submits an empty answer to cancel.
  def ask_valid(question, hint, &valid)
    3.times do
      answer = ask(question)
      return answer if answer.empty? || valid.call(answer)

      warn_line "'#{answer}' is not valid: #{hint}. Try again, or leave empty to cancel."
    end
    abort "Too many invalid answers. Nothing was changed.".red
  end

  # --- Prompts ---------------------------------------------------------------

  def require_terminal!
    abort "This step needs an interactive terminal. Nothing was changed." unless $stdin.tty?
  end

  def ask(question)
    require_terminal!
    print "#{question}: "
    $stdin.gets.to_s.strip
  end

  def yes?(question)
    ask("#{question} [y/N]").downcase.start_with?("y")
  end

  # Every action that creates or deletes a server goes through this. The operator must type the
  # full environment name; anything else (including an abbreviation or "y") aborts.
  def confirm_by_typing!(destination, action)
    require_terminal!
    puts "\n#{action}"
    print "Type the full environment name '#{destination}' to continue: "
    return if $stdin.gets.to_s.strip == destination

    abort "Confirmation did not match '#{destination}'. Aborting, nothing was changed."
  end

  # --- Server provisioning (only bin/setup -d calls this) -------------------

  def provision_server!(destination)
    puts "No server IP is recorded for '#{destination}' in #{SERVERS_FILE}."

    if yes?("Create a new server for '#{destination}' at the hosting provider?")
      confirm_by_typing!(destination, "This will CREATE a new, billable '#{destination}' server at the hosting provider.")
      host = ask_valid("Public hostname for '#{destination}' (for example #{destination}.example.com)", "expected a domain like app.example.com") { |v| valid_hostname?(v) }
      abort "A hostname is required. Nothing was created." if host.empty?

      step "Creating '#{destination}' server at the hosting provider (usually 1-3 minutes)"
      server = ServerProvider.create(destination).merge("host" => host)
      save_server(destination, server) # record the server_id immediately, before anything else can fail
      ok "Created server #{server['server_id']} at #{server['main_host']}"
      info "Recorded in #{SERVERS_FILE}"

      step "Updating DNS for #{host}"
      ServerProvider.upsert_dns(host, server["main_host"])
      ok "DNS step finished"
    else
      ip = ask_valid("IPv4/IPv6 address of an already existing '#{destination}' server (empty to cancel)", "expected an IP address like 203.0.113.10, not a name") { |v| valid_ip?(v) }
      abort "No server for '#{destination}'. Nothing was changed." if ip.empty?
      host = ask_valid("Public hostname for '#{destination}'", "expected a domain like app.example.com") { |v| valid_hostname?(v) }
      abort "A hostname is required. Nothing was recorded." if host.empty?

      server = { "main_host" => ip, "host" => host } # no server_id: bin/remove_fully cannot delete it
      save_server(destination, server)
    end

    server
  end

  # Never waits blindly: validates the target first, fails immediately on errors that retrying cannot
  # fix (bad name, bad address), and prints a countdown for the ones it does retry.
  def wait_for_ssh(host, port: 22, timeout: 180)
    step "Waiting for SSH on #{host}:#{port} (timeout #{timeout}s; a fresh server needs a minute or two to boot)"

    unless valid_ip?(host) || valid_hostname?(host)
      abort "'#{host}' is neither an IP address nor a hostname. Fix main_host in #{SERVERS_FILE} and retry.".red
    end
    begin
      Addrinfo.getaddrinfo(host, port, nil, :STREAM)
    rescue SocketError => e
      abort "Cannot resolve '#{host}' (#{e.message}). Fix main_host in #{SERVERS_FILE} and retry.".red
    end

    started = Time.now
    deadline = started + timeout
    attempt = 0
    begin
      attempt += 1
      Socket.tcp(host, port, connect_timeout: 5) { nil }
      ok "SSH is reachable after #{(Time.now - started).to_i}s"
      true
    rescue SystemCallError, Errno::ETIMEDOUT
      left = (deadline - Time.now).to_i
      abort "Timed out after #{timeout}s waiting for SSH on #{host}:#{port}. Check the IP, the firewall, and that the server is running.".red if left <= 0
      info "SSH not ready yet (attempt #{attempt}, #{(Time.now - started).to_i}s elapsed, #{left}s left), retrying in 5s...".light_black
      sleep 5
      retry
    end
  end

  # Resolves the recorded server for `destination`, exports MAIN_HOST/DB_HOST/HOST/RAILS_ENV for
  # Kamal and returns the server hash. Only `provision: true` (bin/setup) may create a server.
  def load_environment!(destination, provision: false)
    require_commands!("kamal")

    server = server_for(destination)
    server ||= provision_server!(destination) if provision
    abort "No server is recorded for '#{destination}'. Run `bin/setup -d #{destination}` first." unless server

    ENV["MAIN_HOST"] = server["main_host"]
    ENV["DB_HOST"] = server["main_host"]
    ENV["HOST"] = server["host"].to_s
    ENV["RAILS_ENV"] = destination

    server
  end
end
```

### `lib/server_provider.rb`

This file is the only place that knows about the hosting provider. Generate it for the provider the user chose. Keep this contract so the `bin/` scripts never change per provider:

- `create(destination)` → `{ "server_id" => "<provider id>", "main_host" => "<public IPv4>" }`; aborts on failure, and when a server was created but its IP could not be read, the abort message includes the provider id so the user can delete the orphan.
- `delete(server_id)` → deletes the server; aborts on failure. Passes the provider CLI's own "force/yes" flag, because the typed confirmation already happened in `KamalCli.confirm_by_typing!`.
- `upsert_dns(host, ip)` / `delete_dns(host)` → optional; no-ops when the user manages DNS by hand.

Reference implementation for DigitalOcean through `doctl` (adapt names/region/size/image/SSH key to the project; the SSH key fingerprint is not a secret):

```ruby
require "json"
require "open3"

module ServerProvider
  module_function

  APP_NAME = "my_app"
  REGION = "fra1"
  SIZE = "s-2vcpu-4gb"
  IMAGE = "ubuntu-24-04-x64"
  SSH_KEY_FINGERPRINT = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"

  def create(destination)
    KamalCli.require_commands!("doctl")

    name = "#{APP_NAME}-#{destination}"
    KamalCli.info "Requesting droplet '#{name}' (#{REGION}, #{SIZE}, #{IMAGE}) and waiting until it is active..."
    stdout = status = nil
    KamalCli.with_progress("Waiting for the provider to build the server") do
      stdout, status = Open3.capture2(
        "doctl", "compute", "droplet", "create", name,
        "--region", REGION, "--size", SIZE, "--image", IMAGE,
        "--ssh-keys", SSH_KEY_FINGERPRINT, "--wait", "--output", "json"
      )
    end
    abort "doctl could not create droplet '#{name}'.".red unless status.success?

    droplet = JSON.parse(stdout).first
    ip = droplet.dig("networks", "v4")&.find { |network| network["type"] == "public" }&.fetch("ip_address")
    abort "Droplet #{droplet['id']} was created but has no public IPv4. Check it in DigitalOcean and delete it if unused." if ip.nil?

    KamalCli.ok "Droplet #{droplet['id']} is active with public IP #{ip}"
    { "server_id" => droplet.fetch("id").to_s, "main_host" => ip }
  end

  def delete(server_id)
    KamalCli.require_commands!("doctl")

    system("doctl", "compute", "droplet", "delete", server_id, "--force") ||
      abort("doctl could not delete droplet #{server_id}. The server data is kept in #{KamalCli::SERVERS_FILE}; check the provider dashboard.")
  end

  def upsert_dns(_host, _ip); end

  def delete_dns(_host); end
end
```

For any other hosting:

- Prefer the provider's official command-line utility (for example `hcloud` for Hetzner, `linode-cli`, `vultr-cli`, `aws`/`gcloud`/`az`). Read its `--help` for the exact create/delete/JSON-output flags before writing the calls; do not guess flags.
- If there is no usable CLI, call the provider's REST API with `Net::HTTP`, reading the token from an environment variable via `ENV.fetch`.
- Run the provider CLI/API through argument arrays (`Open3.capture2("cli", "arg", ...)`, `system("cli", "arg", ...)`), never through an interpolated shell string.
- Authentication comes from the CLI's own login (for example `doctl auth init`) or from a local environment variable. The user sets it locally and replies `done`; never ask for the token in chat, never write it into the repository, and never print it.
- Cloud-init/user-data is not needed for Docker: `kamal setup` installs Docker on the fresh server over SSH. If the provider image needs a non-root deploy user, create it with the provider's user-data and keep `ssh.user` in `config/deploy.yml` consistent.

DNS (optional): when the user's DNS provider has an API, implement `upsert_dns`/`delete_dns` against it so `bin/setup` and `bin/remove_fully` keep the A record in sync. For Cloudflare, use the REST API with a scoped API token read from `CLOUDFLARE_API_TOKEN`: look up the zone (`GET /zones?name=<domain>`), find the record (`GET /zones/<id>/dns_records?type=A&name=<host>`), then create (`POST`), update (`PUT`), or delete (`DELETE`) it. Set `proxied: true` for the `Cloudflare SSL` variant and `proxied: false` for the `Kamal-based SSL` variant. DNS record changes are server actions too: they happen only inside the already typed-confirmed `bin/setup`/`bin/remove_fully` flows.

### The scripts

`bin/setup`:

```ruby
#!/usr/bin/env ruby
require "fileutils"
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV)

if destination.nil?
  # No -d/--destination given: local development bootstrap, unchanged from Rails' default bin/setup.
  FileUtils.chdir(File.expand_path("..", __dir__)) do
    puts "== Installing dependencies =="
    system("bundle check") || system("bundle", "install", exception: true)

    puts "\n== Preparing database =="
    system("bin/rails", "db:prepare", exception: true)
    system("bin/rails", "db:reset", exception: true) if ARGV.include?("--reset")

    puts "\n== Removing old logs and tempfiles =="
    system("bin/rails", "log:clear", "tmp:clear", exception: true)

    unless ARGV.include?("--skip-server")
      puts "\n== Starting development server =="
      STDOUT.flush
      exec "bin/dev"
    end
  end
  exit
end

# The only script allowed to create a server: asks first when no IP is recorded for this destination.
server = KamalCli.load_environment!(destination, provision: true)
KamalCli.step "Server for '#{destination}': MAIN_HOST=#{server['main_host']} HOST=#{server['host']}"

KamalCli.wait_for_ssh(server["main_host"])

KamalCli.step "Running `kamal setup` (installs Docker, boots accessories, first deploy; this can take several minutes)"
exec("kamal", "setup", *ARGV)
```

`bin/deploy`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/deploy -d <staging|production> [kamal deploy options]"
server = KamalCli.load_environment!(destination)
puts "Deploying '#{destination}' with MAIN_HOST=#{server['main_host']} and HOST=#{server['host']}"

exec("kamal", "deploy", *ARGV)
```

`bin/logs`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/logs -d <staging|production> [kamal app logs options]"
KamalCli.load_environment!(destination)

exec("kamal", "app", "logs", *ARGV)
```

`bin/console`:

```ruby
#!/usr/bin/env ruby
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/console -d <staging|production>"
KamalCli.load_environment!(destination)

exec("kamal", "app", "exec", "--interactive", *ARGV, "bin/rails console")
```

`bin/remove`:

```ruby
#!/usr/bin/env ruby
# Removes only the app (containers, networks) from the server with `kamal remove`.
# The server itself is NOT deleted and keeps running (and billing).
# To also delete the server at the hosting provider, there is `bin/remove_fully`.
# Use it carefully: it destroys the server and everything on it, and cannot be undone.
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/remove -d <staging|production> [kamal remove options]"
KamalCli.load_environment!(destination)

KamalCli.confirm_by_typing!(destination, "This will REMOVE the app from the '#{destination}' server (the server itself stays).")

exec("kamal", "remove", *ARGV)
```

`bin/remove_fully`:

```ruby
#!/usr/bin/env ruby
# Removes the app with `kamal remove` AND deletes the server at the hosting provider.
# Everything on the server (containers, volumes, databases) is lost for good. Use with great care.
# To remove only the app and keep the server, use `bin/remove`.
require_relative "../lib/kamal_cli"

destination = KamalCli.destination_from(ARGV) or abort "Usage: bin/remove_fully -d <staging|production>"
server = KamalCli.load_environment!(destination)

if server["server_id"].to_s.empty?
  abort "The '#{destination}' server (#{server['main_host']}) was recorded by hand, so there is no provider server id to delete. " \
        "Delete it in the hosting dashboard and use `bin/remove -d #{destination}` for the app."
end

KamalCli.confirm_by_typing!(
  destination,
  "This will run `kamal remove` and then DELETE the '#{destination}' server #{server['main_host']} " \
  "(provider id #{server['server_id']}) with everything on it. It cannot be undone."
)

system("kamal", "remove", "-y", *ARGV) ||
  abort("`kamal remove` failed, so the server was NOT deleted. Fix the problem and run bin/remove_fully again.")

ServerProvider.delete_dns(server["host"])
ServerProvider.delete(server["server_id"])
KamalCli.forget_server(destination)

puts "Removed the app and deleted the '#{destination}' server #{server['main_host']}."
```

Rules:

1. `chmod +x bin/setup bin/deploy bin/logs bin/console bin/remove bin/remove_fully` and keep `#!/usr/bin/env ruby` as the shebang on each.
2. Pass the original `ARGV` straight through to `kamal` (including `-d <destination>`) so every native Kamal flag keeps working exactly as `kamal <subcommand> ...` would; do not reimplement or restrict Kamal's own CLI surface.
3. Do not duplicate the server lookup/env-var resolution logic per script; keep it in `lib/kamal_cli.rb`.
4. If the project keeps host values in a password manager such as 1Password and `.kamal/secrets` reads `MAIN_HOST` from it, write the new IP there from `KamalCli.provision_server!` (and clear it from `bin/remove_fully`) instead of duplicating that sync per script.
5. `exec` the final `kamal ...` call (not `system`) so exit codes and signals propagate normally; the only exception is `bin/remove_fully`, which must continue with the server deletion after `kamal remove`. Always invoke the plain `kamal` command (resolved from `PATH`, i.e. the globally installed Kamal gem), never the project's own `bin/kamal` Bundler binstub — `bin/kamal` requires the full project bundle (every gem in `Gemfile.lock`) to be installed on the local/operator machine, which defeats the purpose of these scripts: only the `kamal` gem itself should need to be installed locally to run deploy operations. If a project does not have `kamal` installed globally, tell the user to install it with `gem install kamal` instead of falling back to `bin/kamal`.
6. When implementing or updating deployment, replace any existing `Makefile` targets named `setup_<env>`, `deploy_<env>`, `logs_<env>`, `remove_<env>`, `create_new_<env>`, `destroy_<env>`, or similar with these six `bin/` scripts; do not keep both.
7. Update the target project `README` with `bin/setup -d <environment>`, `bin/deploy -d <environment>`, `bin/logs -d <environment>`, `bin/console -d <environment>`, `bin/remove -d <environment>`, and `bin/remove_fully -d <environment>` usage whenever these scripts are added or changed, and say clearly that `bin/remove` keeps the server while `bin/remove_fully` deletes it.
8. Never run `bin/remove` or `bin/remove_fully` unsupervised or as part of an automated flow, and never run `bin/setup -d <environment>` in a way that could create a server unless the user explicitly asked for that server. The user types the environment name themselves; an agent must not pipe or script the confirmation answer on their behalf.
9. Whenever `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, or `bin/remove_fully` are created or updated, update the target project's `AGENTS.md` (and `CLAUDE.md` if it does not simply delegate to `AGENTS.md`) so future Codex/Claude Code sessions in that project use these scripts instead of raw `kamal` commands for staging/production operations. Preserve existing `AGENTS.md`/`CLAUDE.md` content and add or refresh only the deployment-command guidance; do not replace the file wholesale. Use wording equivalent to:

   > For Kamal/deploy operations against `staging` or `production`, use `bin/setup -d <environment>`, `bin/deploy -d <environment>`, `bin/logs -d <environment>`, `bin/console -d <environment>`, `bin/remove -d <environment>`, and `bin/remove_fully -d <environment>` instead of running `kamal` directly. These scripts preload the environment (`MAIN_HOST`/`DB_HOST`/`HOST`/`RAILS_ENV`) that Kamal needs for that destination. Servers are created by `bin/setup` and deleted by `bin/remove_fully` through the hosting provider's API/CLI; both require the human to type the full environment name. Never run `bin/remove` or `bin/remove_fully` on your own, and never supply the confirmation for the user.
10. After any successful `bin/setup -d <environment>` or `bin/deploy -d <environment>` (Kamal itself reports success), run an HTTP smoke check against the deployed host's real URL — not just Kamal's own container health check — for example:

    ```bash
    curl -skL -o /dev/null -w '%{http_code}' https://<host>/
    ```

    A container passing its health check only proves the process is up; it does not prove a real page renders. Treat any response that isn't a terminal 2xx (following redirects) as a deploy failure and investigate with `bin/logs -d <environment>` before telling the user the deploy succeeded.
11. Add `/.kamal/servers.yml` to `.gitignore` whenever `lib/kamal_cli.rb` is added or updated. Never commit it, and never put provider tokens in it.
12. Validate the provisioning layer without touching a real provider: `ruby -c` on every script and library, `bin/remove_fully` without `-d` prints usage, a destination with no recorded server makes `bin/deploy`/`bin/logs`/`bin/console`/`bin/remove`/`bin/remove_fully` abort with the "Run `bin/setup -d <environment>` first" message, and with stdin not a terminal `bin/setup -d <environment>` aborts instead of creating a server. Do not create or delete a real server to validate unless the user explicitly asks.

### Migrating Away From Terraform

When `update deployment` (or any task) finds a `terraform/` directory, Terraform `Makefile` targets, `terraform/secrets.auto.tfvars`, or `terraform/*.sh` helpers in a project:

1. Do not install Terraform and do not run `terraform apply`/`destroy` for the user.
2. Carry the existing servers over so nothing is orphaned. If `terraform` is already installed locally, read the values once per workspace (`terraform -chdir=terraform workspace select <environment>`, then `terraform -chdir=terraform output -raw main_host_ip`, `subdomain_url`, `droplet_id`) and write them to `.kamal/servers.yml`. Otherwise ask the user for the IP, hostname and provider server id (from the provider dashboard).
3. Generate `lib/kamal_cli.rb`, `lib/server_provider.rb` and the six `bin/` scripts per this recipe.
4. Tell the user that the Terraform state was the only record of the resources Terraform manages (server, and DNS records if Cloudflare was managed by it). Ask for explicit confirmation before deleting `terraform/`, its state, and the Terraform `Makefile` targets; without that confirmation leave them in place and list them in the summary as unapplied.
5. Remove `terraform/secrets.auto.tfvars`-related `.gitignore` lines only together with the directory. Move any provider tokens it held into the CLI login or environment variables used by `lib/server_provider.rb`, without printing them.

## `.kamal/secrets` Local Secret Resolution

`.kamal/secrets` is evaluated by the local Kamal process on the host machine, not inside any project container. This is a common source of deploys that look successful (Kamal reports success, the container passes its health check) but 500 on the actual page, because the failure only surfaces in an accessory's container logs, not in Kamal's own web-role deploy output.

1. Any `$(...)` command inside `.kamal/secrets` that needs to run Rails/Ruby locally to resolve a secret (`rails runner`, `rails credentials:...`, etc.) must go through the project's configured local command runner — `dip rails runner ...` for `dip`-based projects — never bare `bin/rails`, `rails`, or `bundle exec rails`. Bare Rails commands only work when the project's gems are installed on the host Ruby, which `dip`-based projects intentionally do not do; the command fails with something like `Bundler::GemNotFound` on the host, and Kamal never sees that failure directly.
2. Redirect stderr on these substitutions (`2>/dev/null`). `dip`'s own container-startup/compose status lines print to stderr and would otherwise leak into the captured secret value.
3. A failed or empty local secret resolution does not raise a loud error at the point of failure: `$(...)` simply captures an empty string, and Kamal boots the affected accessory (for example Postgres) with that empty value (for example an empty `POSTGRES_PASSWORD`), which then crash-loops with an error like "Database is uninitialized and superuser password is not specified" in the accessory's own logs, not in Kamal's web-role deploy output. Treat an empty resolved secret as equivalent to a hard deployment failure, not a warning.
4. Before running `bin/setup`/`bin/deploy` against a real server, resolve every `$(...)` command from `.kamal/secrets` locally using the same local command runner and confirm each one returns a non-empty value, for example:

   ```bash
   dip rails runner "puts Rails.application.credentials.dig(:production, :database, :username)"
   ```

   An empty result here is the actual failure mode to catch — nothing else errors loudly, so this check must run every time `.kamal/secrets` is created or changed, before the next `bin/setup`/`bin/deploy`.

## Tooling Preflight (Installed Tools Check)

Before writing or changing any deployment file, check which tools the user already has for what the chosen setup needs, and offer to install what is missing right away, instead of discovering gaps when a script fails.

1. Decide the required tool list from the user's choices (hosting provider, secret storage, git platform, DNS):
   - always: `git`, `ruby` (matching the project's `.ruby-version`), `bundler`, `docker`, `ssh`/`ssh-keygen`, `curl`
   - Kamal: the global `kamal` binary (`gem install kamal`; not a `bin/kamal` binstub)
   - hosting provider CLI: e.g. `doctl` for DigitalOcean, `hcloud` for Hetzner, `aws` for AWS, or the provider's equivalent used by `lib/server_provider.rb`
   - secrets: `op` (1Password CLI) when 1Password is used; see `agents/recipes/save-rails-secrets-1password.md`
   - git platform CLI: `gh` for GitHub (repository secrets, CI), or the platform's equivalent
   - Cloudflare DNS tooling, only if the user chose it
   - local dev: `dip`, only for the local development environment
2. Detect, without changing anything: `command -v <tool>` and `<tool> --version` for each. For CLIs that need authentication, also check login state (`doctl account get`, `gh auth status`, `op whoami`) and an SSH key (`ls ~/.ssh/*.pub`).
3. Show the user one short table: tool, installed (with version) / missing / not authenticated.
4. For everything missing, propose installing it in the same message, using the user's platform package manager (detect it: `pacman`/`yay`, `apt`, `dnf`, `brew`, or `gem` for Ruby gems). Show the exact install command and wait for the user's approval before running it. Do not install anything silently, and never run `sudo` commands without approval.
5. For missing authentication, tell the user which login command to run themselves (in Claude Code, suggest the `! <command>` prefix so the output lands in the session). Never ask for tokens in chat and never print token values (see `SKILL.md` secrets rules).
6. If the user declines a tool, record what is skipped and adapt: do not generate scripts that depend on a tool the user will not install, or mark that area as skipped in the final summary.
7. Re-run the detection after installing and continue only when every required tool is present or explicitly skipped.

## Implement Deployment

Treat `Implement deployment` as a full deployment-systems task, not a narrow single-file change.

Required scope:

0. Run "Tooling Preflight (Installed Tools Check)" first: check the user's installed tools and offer to install the missing ones before editing anything.
1. Inspect existing deployment pieces before editing:
   - `config/deploy.yml`
   - `config/deploy.staging.yml`
   - `config/deploy.production.yml`
   - `.kamal/secrets`
   - `.kamal/servers.yml` (gitignored; recorded server data)
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `bin/remove_fully`, `lib/kamal_cli.rb`, `lib/server_provider.rb`
   - `AGENTS.md`, `CLAUDE.md` (deployment-command guidance)
   - any leftover `terraform/` directory or Terraform `Makefile` targets (handle per "Migrating Away From Terraform")
   - CI config such as `.github/workflows/` or the equivalent for the current git platform
2. Use the reference project as the primary source for Kamal and CI:
   - Kamal: `config/deploy.yml`, `config/deploy.staging.yml`, `config/deploy.production.yml`
   - GitHub CI/deploy workflows: `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`, `.github/workflows/deploy-production.yml`
   - Server provisioning is not taken from the reference project's Terraform; it is generated per this recipe (`lib/kamal_cli.rb`, `lib/server_provider.rb`, `bin/` scripts) for the hosting the user chose.
3. Ensure Kamal deployment exists for both `staging` and `production`.
4. Ensure `bin/setup -d <environment>` can create (after asking and a typed confirmation) and `bin/remove_fully -d <environment>` can delete the `staging` and `production` servers through the user's hosting provider.
5. Ensure `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, and `bin/remove_fully` cover the deploy-management flow for both environments, per "Deployment Management Scripts (`bin/`)" above.
6. Ensure CI is implemented. For non-GitHub platforms, preserve the same gate structure as the reference project using that platform's syntax.
7. Adapt imported config to the current project: app name, repository names, environments, hostnames, provider identifiers, and secret names.
8. If deployment uses Auth0, keep Auth0 secrets in Rails credentials when the reference-project approach does so.
9. If deployment files already exist, preserve applicable project-specific values and fill gaps instead of resetting the deployment stack.
10. If creating or updating `.kamal/secrets`, it must not contain shell `if` statements. Keep conditional lookup in scripts or external secret tooling. Any local secret-resolution command in it must follow "`.kamal/secrets` Local Secret Resolution" above (project's local command runner, stderr redirected).
11. If a `.gitignore` rule was added or changed that excludes a directory except a `.keep` file (`!/path/.keep`), create and commit that `.keep` file in the same change; do not leave it as an uncommitted no-op (see `agents/rails.md` "Deployment"). Also make sure `/.kamal/servers.yml` is gitignored.
12. Verify with the strongest available checks, such as:
    - `ruby -c` on `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `bin/remove_fully`, `lib/kamal_cli.rb`, and `lib/server_provider.rb`
    - the provisioning-layer checks from rule 12 of "Deployment Management Scripts (`bin/`)" (no server created or deleted)
    - syntax/consistency checks on Kamal config
    - resolve every `$(...)` secret-lookup command from `.kamal/secrets` locally (e.g. `dip rails runner "puts Rails.application.credentials.dig(...)"`) and confirm each returns a non-empty value, before running `bin/setup`/`bin/deploy` against a real server
    - `git ls-files <dir>/.keep` for every directory with a `.gitignore` `.keep`-exception pattern (e.g. `git ls-files app/assets/builds/.keep`), to confirm it is actually committed and will exist in Kamal's fresh build clone
    - CI workflow validation where practical
13. If `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, or `bin/remove_fully` were added or updated, update the target project `README` with concise deployment-management command usage, and update `AGENTS.md`/`CLAUDE.md` per rule 9 in "Deployment Management Scripts (`bin/`)" above.
14. After a real `bin/setup`/`bin/deploy` run against a server, run the HTTP smoke check from "Deployment Management Scripts (`bin/`)" rule 10 against the deployed host before reporting the deploy as done.
15. In the final summary, report what came directly from the reference project and what was adapted.

## Update Deployment

Treat `update deployment` as a deployment-sync task against the reference project.

Required scope:

0. Run "Tooling Preflight (Installed Tools Check)" first: check the user's installed tools and offer to install the missing ones before editing anything.
1. Inspect current deployment-related files:
   - `config/deploy.yml`
   - `config/deploy.staging.yml`
   - `config/deploy.production.yml`
   - `.kamal/secrets`
   - `.kamal/servers.yml`
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `bin/remove_fully`, `lib/kamal_cli.rb`, `lib/server_provider.rb`
   - `AGENTS.md`, `CLAUDE.md` (deployment-command guidance)
   - any leftover `terraform/` directory or Terraform `Makefile` targets
   - CI deploy workflows/config
2. Read matching deployment files from the reference project.
3. Apply all applicable deployment-related changes.
4. Explicitly include:
   - `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, `bin/remove_fully`, `lib/kamal_cli.rb`, and `lib/server_provider.rb` updates, per "Deployment Management Scripts (`bin/`)" above
   - migration away from Terraform when a `terraform/` setup exists, per "Migrating Away From Terraform" above
   - deployment configuration updates
   - `.kamal/secrets` updates, when applicable, with no shell `if` statements and following "`.kamal/secrets` Local Secret Resolution" above
   - If a project still has `Makefile` targets for `setup`/`deploy`/`logs`/`console`/`remove` or server create/destroy, replace them with the `bin/` scripts and remove the old targets
   - Any `.gitignore` `.keep`-exception directory (e.g. `app/assets/builds`) actually has its `.keep` file created and committed, not just declared in `.gitignore`
5. If a reference project deployment file is not directly applicable, preserve the reference behavior and adapt it to the current hosting/provider/platform.
6. Keep project-specific identifiers adapted correctly.
7. If `bin/setup`, `bin/deploy`, `bin/logs`, `bin/console`, `bin/remove`, or `bin/remove_fully` were added or updated, tell the user how to use the commands, update the target project `README`, and update `AGENTS.md`/`CLAUDE.md` per rule 9 in "Deployment Management Scripts (`bin/`)" above.
8. Before confirming the update is done, resolve every `$(...)` secret-lookup command from `.kamal/secrets` locally (non-empty check), run `git ls-files <dir>/.keep` for every `.gitignore` `.keep`-exception directory, and, after the next real `bin/setup`/`bin/deploy`, run the HTTP smoke check from "Deployment Management Scripts (`bin/`)" rule 10.
9. In the final summary, separate direct updates, adapted updates, and unapplied items with reasons.

## New-Project Deployment Add-On

If a new Rails project setup includes server/deploy setup, run this recipe after repository setup and before final bootstrap verification.

1. Ask whether the user already has a server.
2. If yes, ask for its IP and public hostname per environment and record them in `.kamal/servers.yml` (no `server_id`; such a server is never deleted by `bin/remove_fully`).
3. If not, ask which hosting provider they want. Recommend `DigitalOcean` because this skill ships a complete `doctl`-based reference `lib/server_provider.rb`.
4. Generate `lib/kamal_cli.rb`, `lib/server_provider.rb` (for the chosen provider, via its CLI or REST API), and the six `bin/` scripts per "Deployment Management Scripts (`bin/`)". Do not create any Terraform files.
5. Ask DNS provider. Recommend `Cloudflare` because this skill describes its API flow for `upsert_dns`/`delete_dns`.
6. If DNS is `Cloudflare` or another provider with an API, implement `upsert_dns`/`delete_dns` in `lib/server_provider.rb`. Otherwise keep them as no-ops and tell the user which DNS record to create by hand after `bin/setup` prints the new IP.
7. Ask the user to choose an SSL/TLS termination variant. There is no default; the user must pick one:
   - `Cloudflare SSL`: Cloudflare terminates TLS at its edge (proxy/orange-cloud on the DNS record). Requires an SSL/TLS encryption mode in Cloudflare (`Full` or `Full (strict)` recommended over `Flexible`) and, when using `Full (strict)`, either a Cloudflare Origin Certificate installed on the server or a publicly trusted cert. Only viable when DNS is `Cloudflare`.
   - `Kamal-based SSL`: `kamal-proxy` issues and renews certificates automatically via Let's Encrypt for the hosts in `config/deploy*.yml` (`proxy.ssl: true` / host-based ACME), with no Cloudflare proxying (DNS record must be un-proxied/"grey-cloud" so ACME HTTP-01 challenges reach the server).
   - If the user's choice does not match one of these two variants, ask them to describe their own SSL setup and adapt the deployment config to it.
8. Apply the chosen SSL variant consistently across `config/deploy.yml`, `config/deploy.staging.yml`, `config/deploy.production.yml`, and, for `Cloudflare SSL`, the `proxied` flag in `upsert_dns`.
9. Default database secret handling must follow the reference project:
   - Store deploy database values in Rails credentials by default.
   - Include `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` or equivalent values used by the current project.
10. Collect provider values only after the project and `lib/server_provider.rb` exist. They are constants in that file, not secrets: for DigitalOcean `app_name`, `region`, `size`, and the SSH key fingerprint (default to the system default SSH key; ask for a custom one only on explicit request; if the key is missing in DigitalOcean, add it under API -> Tokens/Keys -> SSH Keys and use its fingerprint); for Cloudflare the `domain`.
11. Provider credentials are never collected in chat and never stored in the repository. The user authenticates locally (for DigitalOcean `doctl auth init`, token from API -> Tokens/Keys -> Personal access tokens -> Generate New Token; for Cloudflare an API token with DNS edit rights exported as `CLOUDFLARE_API_TOKEN`) and replies `done`.
12. Add `/.kamal/servers.yml` to `.gitignore`.
13. Validate without creating a server:
    - `command -v kamal` (otherwise tell the user to run `gem install kamal`)
    - the provider CLI check, for example `doctl version` and `doctl account get` (read-only) for DigitalOcean
    - `ruby -c` on the scripts and libraries, and the rule 12 checks from "Deployment Management Scripts (`bin/`)"
14. Do not create the servers yourself. Tell the user to run `bin/setup -d staging` / `bin/setup -d production` in their own terminal; the script asks whether to create the server and requires the typed environment name. An agent must not answer those prompts for the user.
15. Explain key points to the user, including which SSL variant was configured and any manual step it still requires (e.g., setting Cloudflare's SSL/TLS mode in the dashboard), and that `bin/remove_fully` deletes the server while `bin/remove` does not.

## Repository Secrets

When requesting deploy/repository secrets, use `save-rails-secrets-1password.md` first, then guide repository setup:

1. Set secrets in repository secrets storage, never in chat.
2. GitHub: Settings -> Secrets and variables -> Actions -> New repository secret.
3. GitLab: Settings -> CI/CD -> Variables -> Add variable.
4. Walk through secrets one-by-one and wait for `done` after each:
   - `RAILS_MASTER_KEY`
   - `SSH_PRIVATE_KEY`
   - `SSH_USER`
   - `DISCORD_WEBHOOK_URL`, if Discord enabled
   - `KAMAL_REGISTRY_USERNAME` / `KAMAL_REGISTRY_PASSWORD`, only if the user chose an external registry
5. Use `config/master.key` or the relevant environment key as the source for `RAILS_MASTER_KEY`.
6. With localhost Kamal registry, do not request registry credentials.
