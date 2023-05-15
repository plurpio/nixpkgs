{ system,
  pkgs,

  # Projects the test configuration into a the desired value; usually
  # the test runner: `config: config.test`.
  callTest,

}:
# The return value of this function will be an attrset with arbitrary depth and
# the `anything` returned by callTest at its test leafs.
# The tests not supported by `system` will be replaced with `{}`, so that
# `passthru.tests` can contain links to those without breaking on architectures
# where said tests are unsupported.
# Example callTest that just extracts the derivation from the test:
#   callTest = t: t.test;

with pkgs.lib;

let
  discoverTests = val:
    if isAttrs val
    then
      if hasAttr "test" val then callTest val
      else mapAttrs (n: s: discoverTests s) val
    else if isFunction val
      then
        # Tests based on make-test-python.nix will return the second lambda
        # in that file, which are then forwarded to the test definition
        # following the `import make-test-python.nix` expression
        # (if it is a function).
        discoverTests (val { inherit system pkgs; })
      else val;
  handleTest = path: args:
    discoverTests (import path ({ inherit system pkgs; } // args));
  handleTestOn = systems: path: args:
    if elem system systems then handleTest path args
    else {};

  nixosLib = import ../lib {
    # Experimental features need testing too, but there's no point in warning
    # about it, so we enable the feature flag.
    featureFlags.minimalModules = {};
  };
  evalMinimalConfig = module: nixosLib.evalModules { modules = [ module ]; };

  inherit
    (rec {
      doRunTest = arg: ((import ../lib/testing-python.nix { inherit system pkgs; }).evalTest {
        imports = [ arg readOnlyPkgs ];
      }).config.result;
      findTests = tree:
        if tree?recurseForDerivations && tree.recurseForDerivations
        then
          mapAttrs
            (k: findTests)
            (builtins.removeAttrs tree ["recurseForDerivations"])
        else callTest tree;

      runTest = arg: let r = doRunTest arg; in findTests r;
      runTestOn = systems: arg:
        if elem system systems then runTest arg
        else {};
    })
    runTest
    runTestOn
    ;

  # Using a single instance of nixpkgs makes test evaluation faster.
  # To make sure we don't accidentally depend on a modified pkgs, we make the
  # related options read-only. We need to test the right configuration.
  #
  # If your service depends on a nixpkgs setting, first try to avoid that, but
  # otherwise, you can remove the readOnlyPkgs import and test your service as
  # usual.
  readOnlyPkgs =
    # TODO: We currently accept this for nixosTests, so that the `pkgs` argument
    #       is consistent with `pkgs` in `pkgs.nixosTests`. Can we reinitialize
    #       it with `allowAliases = false`?
    # warnIf pkgs.config.allowAliases "nixosTests: pkgs includes aliases."
    {
      _class = "nixosTest";
      node.pkgs = pkgs;
    };

in {

  # Testing the test driver
  nixos-test-driver = {
    extra-python-packages = handleTest ./nixos-test-driver/extra-python-packages.nix {};
    node-name = runTest ./nixos-test-driver/node-name.nix;
  };

  # NixOS vm tests and non-vm unit tests

  _3proxy = runTest ./3proxy.nix;
  aaaaxy = runTest ./aaaaxy.nix;
  acme = runTest ./acme.nix;
  adguardhome = runTest ./adguardhome.nix;
  aesmd = runTestOn ["x86_64-linux"] ./aesmd.nix;
  agate = runTest ./web-servers/agate.nix;
  agda = handleTest ./agda.nix {};
  airsonic = handleTest ./airsonic.nix {};
  akkoma = handleTestOn [ "x86_64-linux" "aarch64-linux" ] ./akkoma.nix {};
  akkoma-confined = handleTestOn [ "x86_64-linux" "aarch64-linux" ] ./akkoma.nix { confined = true; };
  alice-lg = handleTest ./alice-lg.nix {};
  allTerminfo = handleTest ./all-terminfo.nix {};
  alps = handleTest ./alps.nix {};
  amazon-init-shell = handleTest ./amazon-init-shell.nix {};
  apcupsd = handleTest ./apcupsd.nix {};
  apfs = handleTest ./apfs.nix {};
  apparmor = handleTest ./apparmor.nix {};
  atd = handleTest ./atd.nix {};
  atop = handleTest ./atop.nix {};
  atuin = handleTest ./atuin.nix {};
  auth-mysql = handleTest ./auth-mysql.nix {};
  authelia = handleTest ./authelia.nix {};
  avahi = handleTest ./avahi.nix {};
  avahi-with-resolved = handleTest ./avahi.nix { networkd = true; };
  babeld = handleTest ./babeld.nix {};
  bazarr = handleTest ./bazarr.nix {};
  bcachefs = handleTestOn ["x86_64-linux" "aarch64-linux"] ./bcachefs.nix {};
  beanstalkd = handleTest ./beanstalkd.nix {};
  bees = handleTest ./bees.nix {};
  binary-cache = handleTest ./binary-cache.nix {};
  bind = handleTest ./bind.nix {};
  bird = handleTest ./bird.nix {};
  birdwatcher = handleTest ./birdwatcher.nix {};
  bitcoind = handleTest ./bitcoind.nix {};
  bittorrent = handleTest ./bittorrent.nix {};
  blockbook-frontend = handleTest ./blockbook-frontend.nix {};
  blocky = handleTest ./blocky.nix {};
  boot = handleTestOn ["x86_64-linux" "aarch64-linux"] ./boot.nix {};
  bootspec = handleTestOn ["x86_64-linux"] ./bootspec.nix {};
  boot-stage1 = handleTest ./boot-stage1.nix {};
  borgbackup = handleTest ./borgbackup.nix {};
  botamusique = handleTest ./botamusique.nix {};
  bpf = handleTestOn ["x86_64-linux" "aarch64-linux"] ./bpf.nix {};
  breitbandmessung = handleTest ./breitbandmessung.nix {};
  brscan5 = handleTest ./brscan5.nix {};
  btrbk = handleTest ./btrbk.nix {};
  btrbk-doas = handleTest ./btrbk-doas.nix {};
  btrbk-no-timer = handleTest ./btrbk-no-timer.nix {};
  btrbk-section-order = handleTest ./btrbk-section-order.nix {};
  budgie = handleTest ./budgie.nix {};
  buildbot = handleTest ./buildbot.nix {};
  buildkite-agents = handleTest ./buildkite-agents.nix {};
  caddy = handleTest ./caddy.nix {};
  cadvisor = handleTestOn ["x86_64-linux"] ./cadvisor.nix {};
  cage = handleTest ./cage.nix {};
  cagebreak = handleTest ./cagebreak.nix {};
  calibre-web = handleTest ./calibre-web.nix {};
  cassandra_3_0 = handleTest ./cassandra.nix { testPackage = pkgs.cassandra_3_0; };
  cassandra_3_11 = handleTest ./cassandra.nix { testPackage = pkgs.cassandra_3_11; };
  cassandra_4 = handleTest ./cassandra.nix { testPackage = pkgs.cassandra_4; };
  ceph-multi-node = handleTestOn [ "aarch64-linux" "x86_64-linux" ] ./ceph-multi-node.nix {};
  ceph-single-node = handleTestOn [ "aarch64-linux" "x86_64-linux" ] ./ceph-single-node.nix {};
  ceph-single-node-bluestore = handleTestOn [ "aarch64-linux" "x86_64-linux" ] ./ceph-single-node-bluestore.nix {};
  certmgr = handleTest ./certmgr.nix {};
  cfssl = handleTestOn ["aarch64-linux" "x86_64-linux"] ./cfssl.nix {};
  cgit = handleTest ./cgit.nix {};
  charliecloud = handleTest ./charliecloud.nix {};
  chromium = (handleTestOn ["aarch64-linux" "x86_64-linux"] ./chromium.nix {}).stable or {};
  chrony-ptp = handleTestOn ["aarch64-linux" "x86_64-linux"] ./chrony-ptp.nix {};
  cinnamon = handleTest ./cinnamon.nix {};
  cjdns = handleTest ./cjdns.nix {};
  clickhouse = handleTest ./clickhouse.nix {};
  cloud-init = handleTest ./cloud-init.nix {};
  cloud-init-hostname = handleTest ./cloud-init-hostname.nix {};
  cloudlog = handleTest ./cloudlog.nix {};
  cntr = handleTestOn ["aarch64-linux" "x86_64-linux"] ./cntr.nix {};
  cockpit = handleTest ./cockpit.nix {};
  cockroachdb = handleTestOn ["x86_64-linux"] ./cockroachdb.nix {};
  coder = handleTest ./coder.nix {};
  collectd = handleTest ./collectd.nix {};
  connman = handleTest ./connman.nix {};
  consul = handleTest ./consul.nix {};
  consul-template = handleTest ./consul-template.nix {};
  containers-bridge = handleTest ./containers-bridge.nix {};
  containers-custom-pkgs.nix = handleTest ./containers-custom-pkgs.nix {};
  containers-ephemeral = handleTest ./containers-ephemeral.nix {};
  containers-extra_veth = handleTest ./containers-extra_veth.nix {};
  containers-hosts = handleTest ./containers-hosts.nix {};
  containers-imperative = handleTest ./containers-imperative.nix {};
  containers-ip = handleTest ./containers-ip.nix {};
  containers-macvlans = handleTest ./containers-macvlans.nix {};
  containers-names = handleTest ./containers-names.nix {};
  containers-nested = handleTest ./containers-nested.nix {};
  containers-physical_interfaces = handleTest ./containers-physical_interfaces.nix {};
  containers-portforward = handleTest ./containers-portforward.nix {};
  containers-reloadable = handleTest ./containers-reloadable.nix {};
  containers-restart_networking = handleTest ./containers-restart_networking.nix {};
  containers-tmpfs = handleTest ./containers-tmpfs.nix {};
  containers-unified-hierarchy = handleTest ./containers-unified-hierarchy.nix {};
  convos = handleTest ./convos.nix {};
  corerad = handleTest ./corerad.nix {};
  coturn = handleTest ./coturn.nix {};
  couchdb = handleTest ./couchdb.nix {};
  cri-o = handleTestOn ["aarch64-linux" "x86_64-linux"] ./cri-o.nix {};
  cups-pdf = handleTest ./cups-pdf.nix {};
  custom-ca = handleTest ./custom-ca.nix {};
  croc = handleTest ./croc.nix {};
  darling = handleTest ./darling.nix {};
  deepin = handleTest ./deepin.nix {};
  deluge = handleTest ./deluge.nix {};
  dendrite = handleTest ./matrix/dendrite.nix {};
  dex-oidc = handleTest ./dex-oidc.nix {};
  dhparams = handleTest ./dhparams.nix {};
  disable-installer-tools = handleTest ./disable-installer-tools.nix {};
  discourse = handleTest ./discourse.nix {};
  dnscrypt-proxy2 = handleTestOn ["x86_64-linux"] ./dnscrypt-proxy2.nix {};
  dnscrypt-wrapper = handleTestOn ["x86_64-linux"] ./dnscrypt-wrapper {};
  dnsdist = handleTest ./dnsdist.nix {};
  doas = handleTest ./doas.nix {};
  docker = handleTestOn ["aarch64-linux" "x86_64-linux"] ./docker.nix {};
  docker-rootless = handleTestOn ["aarch64-linux" "x86_64-linux"] ./docker-rootless.nix {};
  docker-registry = handleTest ./docker-registry.nix {};
  docker-tools = handleTestOn ["x86_64-linux"] ./docker-tools.nix {};
  docker-tools-cross = handleTestOn ["x86_64-linux" "aarch64-linux"] ./docker-tools-cross.nix {};
  docker-tools-overlay = handleTestOn ["x86_64-linux"] ./docker-tools-overlay.nix {};
  documize = handleTest ./documize.nix {};
  documentation = pkgs.callPackage ../modules/misc/documentation/test.nix { inherit nixosLib; };
  doh-proxy-rust = handleTest ./doh-proxy-rust.nix {};
  dokuwiki = handleTest ./dokuwiki.nix {};
  dolibarr = handleTest ./dolibarr.nix {};
  domination = handleTest ./domination.nix {};
  dovecot = handleTest ./dovecot.nix {};
  drbd = handleTest ./drbd.nix {};
  earlyoom = handleTestOn ["x86_64-linux"] ./earlyoom.nix {};
  early-mount-options = handleTest ./early-mount-options.nix {};
  ec2-config = (handleTestOn ["x86_64-linux"] ./ec2.nix {}).boot-ec2-config or {};
  ec2-nixops = (handleTestOn ["x86_64-linux"] ./ec2.nix {}).boot-ec2-nixops or {};
  ecryptfs = handleTest ./ecryptfs.nix {};
  fscrypt = handleTest ./fscrypt.nix {};
  ejabberd = handleTest ./xmpp/ejabberd.nix {};
  elk = handleTestOn ["x86_64-linux"] ./elk.nix {};
  emacs-daemon = handleTest ./emacs-daemon.nix {};
  endlessh = handleTest ./endlessh.nix {};
  endlessh-go = handleTest ./endlessh-go.nix {};
  engelsystem = handleTest ./engelsystem.nix {};
  enlightenment = handleTest ./enlightenment.nix {};
  env = handleTest ./env.nix {};
  envfs = handleTest ./envfs.nix {};
  envoy = handleTest ./envoy.nix {};
  ergo = handleTest ./ergo.nix {};
  ergochat = handleTest ./ergochat.nix {};
  esphome = handleTest ./esphome.nix {};
  etc = pkgs.callPackage ../modules/system/etc/test.nix { inherit evalMinimalConfig; };
  activation = pkgs.callPackage ../modules/system/activation/test.nix { };
  etcd = handleTestOn ["x86_64-linux"] ./etcd.nix {};
  etcd-cluster = handleTestOn ["x86_64-linux"] ./etcd-cluster.nix {};
  etebase-server = handleTest ./etebase-server.nix {};
  etesync-dav = handleTest ./etesync-dav.nix {};
  evcc = handleTest ./evcc.nix {};
  fancontrol = handleTest ./fancontrol.nix {};
  fcitx5 = handleTest ./fcitx5 {};
  fenics = handleTest ./fenics.nix {};
  ferm = handleTest ./ferm.nix {};
  firefox = handleTest ./firefox.nix { firefoxPackage = pkgs.firefox; };
  firefox-beta = handleTest ./firefox.nix { firefoxPackage = pkgs.firefox-beta; };
  firefox-devedition = handleTest ./firefox.nix { firefoxPackage = pkgs.firefox-devedition; };
  firefox-esr    = handleTest ./firefox.nix { firefoxPackage = pkgs.firefox-esr; }; # used in `tested` job
  firefox-esr-102 = handleTest ./firefox.nix { firefoxPackage = pkgs.firefox-esr-102; };
  firejail = handleTest ./firejail.nix {};
  firewall = handleTest ./firewall.nix { nftables = false; };
  firewall-nftables = handleTest ./firewall.nix { nftables = true; };
  fish = handleTest ./fish.nix {};
  flannel = handleTestOn ["x86_64-linux"] ./flannel.nix {};
  fluentd = handleTest ./fluentd.nix {};
  fluidd = handleTest ./fluidd.nix {};
  fontconfig-default-fonts = handleTest ./fontconfig-default-fonts.nix {};
  forgejo = handleTest ./gitea.nix { giteaPackage = pkgs.forgejo; };
  freenet = handleTest ./freenet.nix {};
  freeswitch = handleTest ./freeswitch.nix {};
  freshrss-sqlite = handleTest ./freshrss-sqlite.nix {};
  freshrss-pgsql = handleTest ./freshrss-pgsql.nix {};
  frr = handleTest ./frr.nix {};
  fsck = handleTest ./fsck.nix {};
  fsck-systemd-stage-1 = handleTest ./fsck.nix { systemdStage1 = true; };
  ft2-clone = handleTest ./ft2-clone.nix {};
  mimir = handleTest ./mimir.nix {};
  garage = handleTest ./garage {};
  gemstash = handleTest ./gemstash.nix {};
  gerrit = handleTest ./gerrit.nix {};
  geth = handleTest ./geth.nix {};
  ghostunnel = handleTest ./ghostunnel.nix {};
  gitdaemon = handleTest ./gitdaemon.nix {};
  gitea = handleTest ./gitea.nix { giteaPackage = pkgs.gitea; };
  github-runner = handleTest ./github-runner.nix {};
  gitlab = runTest ./gitlab.nix;
  gitolite = handleTest ./gitolite.nix {};
  gitolite-fcgiwrap = handleTest ./gitolite-fcgiwrap.nix {};
  glusterfs = handleTest ./glusterfs.nix {};
  gnome = handleTest ./gnome.nix {};
  gnome-flashback = handleTest ./gnome-flashback.nix {};
  gnome-xorg = handleTest ./gnome-xorg.nix {};
  gnupg = handleTest ./gnupg.nix {};
  go-neb = handleTest ./go-neb.nix {};
  gobgpd = handleTest ./gobgpd.nix {};
  gocd-agent = handleTest ./gocd-agent.nix {};
  gocd-server = handleTest ./gocd-server.nix {};
  gollum = handleTest ./gollum.nix {};
  gonic = handleTest ./gonic.nix {};
  google-oslogin = handleTest ./google-oslogin {};
  gotify-server = handleTest ./gotify-server.nix {};
  grafana = handleTest ./grafana {};
  grafana-agent = handleTest ./grafana-agent.nix {};
  graphite = handleTest ./graphite.nix {};
  graylog = handleTest ./graylog.nix {};
  grocy = handleTest ./grocy.nix {};
  grub = handleTest ./grub.nix {};
  gvisor = handleTest ./gvisor.nix {};
  hadoop = import ./hadoop { inherit handleTestOn; package=pkgs.hadoop; };
  hadoop_3_2 = import ./hadoop { inherit handleTestOn; package=pkgs.hadoop_3_2; };
  hadoop2 = import ./hadoop { inherit handleTestOn; package=pkgs.hadoop2; };
  haka = handleTest ./haka.nix {};
  haste-server = handleTest ./haste-server.nix {};
  haproxy = handleTest ./haproxy.nix {};
  hardened = handleTest ./hardened.nix {};
  harmonia = runTest ./harmonia.nix;
  headscale = handleTest ./headscale.nix {};
  healthchecks = handleTest ./web-apps/healthchecks.nix {};
  hbase2 = handleTest ./hbase.nix { package=pkgs.hbase2; };
  hbase_2_4 = handleTest ./hbase.nix { package=pkgs.hbase_2_4; };
  hbase3 = handleTest ./hbase.nix { package=pkgs.hbase3; };
  hedgedoc = handleTest ./hedgedoc.nix {};
  herbstluftwm = handleTest ./herbstluftwm.nix {};
  installed-tests = pkgs.recurseIntoAttrs (handleTest ./installed-tests {});
  invidious = handleTest ./invidious.nix {};
  oci-containers = handleTestOn ["aarch64-linux" "x86_64-linux"] ./oci-containers.nix {};
  odoo = handleTest ./odoo.nix {};
  # 9pnet_virtio used to mount /nix partition doesn't support
  # hibernation. This test happens to work on x86_64-linux but
  # not on other platforms.
  hibernate = handleTestOn ["x86_64-linux"] ./hibernate.nix {};
  hibernate-systemd-stage-1 = handleTestOn ["x86_64-linux"] ./hibernate.nix { systemdStage1 = true; };
  hitch = handleTest ./hitch {};
  hledger-web = handleTest ./hledger-web.nix {};
  hocker-fetchdocker = handleTest ./hocker-fetchdocker {};
  hockeypuck = handleTest ./hockeypuck.nix { };
  home-assistant = handleTest ./home-assistant.nix {};
  hostname = handleTest ./hostname.nix {};
  hound = handleTest ./hound.nix {};
  hub = handleTest ./git/hub.nix {};
  hydra = handleTest ./hydra {};
  i3wm = handleTest ./i3wm.nix {};
  icingaweb2 = handleTest ./icingaweb2.nix {};
  iftop = handleTest ./iftop.nix {};
  incron = handleTest ./incron.nix {};
  influxdb = handleTest ./influxdb.nix {};
  initrd-network-openvpn = handleTest ./initrd-network-openvpn {};
  initrd-network-ssh = handleTest ./initrd-network-ssh {};
  initrd-luks-empty-passphrase = handleTest ./initrd-luks-empty-passphrase.nix {};
  initrdNetwork = handleTest ./initrd-network.nix {};
  initrd-secrets = handleTest ./initrd-secrets.nix {};
  initrd-secrets-changing = handleTest ./initrd-secrets-changing.nix {};
  input-remapper = handleTest ./input-remapper.nix {};
  inspircd = handleTest ./inspircd.nix {};
  installer = handleTest ./installer.nix {};
  installer-systemd-stage-1 = handleTest ./installer-systemd-stage-1.nix {};
  invoiceplane = handleTest ./invoiceplane.nix {};
  iodine = handleTest ./iodine.nix {};
  ipv6 = handleTest ./ipv6.nix {};
  iscsi-multipath-root = handleTest ./iscsi-multipath-root.nix {};
  iscsi-root = handleTest ./iscsi-root.nix {};
  isso = handleTest ./isso.nix {};
  jackett = handleTest ./jackett.nix {};
  jellyfin = handleTest ./jellyfin.nix {};
  jenkins = handleTest ./jenkins.nix {};
  jenkins-cli = handleTest ./jenkins-cli.nix {};
  jibri = handleTest ./jibri.nix {};
  jirafeau = handleTest ./jirafeau.nix {};
  jitsi-meet = handleTest ./jitsi-meet.nix {};
  k3s = handleTest ./k3s {};
  kafka = handleTest ./kafka.nix {};
  kanidm = handleTest ./kanidm.nix {};
  karma = handleTest ./karma.nix {};
  kavita = handleTest ./kavita.nix {};
  kbd-setfont-decompress = handleTest ./kbd-setfont-decompress.nix {};
  kbd-update-search-paths-patch = handleTest ./kbd-update-search-paths-patch.nix {};
  kea = handleTest ./kea.nix {};
  keepalived = handleTest ./keepalived.nix {};
  keepassxc = handleTest ./keepassxc.nix {};
  kerberos = handleTest ./kerberos/default.nix {};
  kernel-generic = handleTest ./kernel-generic.nix {};
  kernel-latest-ath-user-regd = handleTest ./kernel-latest-ath-user-regd.nix {};
  keter = handleTest ./keter.nix {};
  kexec = handleTest ./kexec.nix {};
  keycloak = discoverTests (import ./keycloak.nix);
  keyd = handleTest ./keyd.nix {};
  keymap = handleTest ./keymap.nix {};
  knot = handleTest ./knot.nix {};
  komga = handleTest ./komga.nix {};
  krb5 = discoverTests (import ./krb5 {});
  ksm = handleTest ./ksm.nix {};
  kthxbye = handleTest ./kthxbye.nix {};
  kubernetes = handleTestOn ["x86_64-linux"] ./kubernetes {};
  kubo = runTest ./kubo.nix;
  ladybird = handleTest ./ladybird.nix {};
  languagetool = handleTest ./languagetool.nix {};
  latestKernel.login = handleTest ./login.nix { latestKernel = true; };
  leaps = handleTest ./leaps.nix {};
  lemmy = handleTest ./lemmy.nix {};
  libinput = handleTest ./libinput.nix {};
  libreddit = handleTest ./libreddit.nix {};
  libresprite = handleTest ./libresprite.nix {};
  libreswan = handleTest ./libreswan.nix {};
  librewolf = handleTest ./firefox.nix { firefoxPackage = pkgs.librewolf; };
  libuiohook = handleTest ./libuiohook.nix {};
  libvirtd = handleTest ./libvirtd.nix {};
  lidarr = handleTest ./lidarr.nix {};
  lightdm = handleTest ./lightdm.nix {};
  lighttpd = handleTest ./lighttpd.nix {};
  limesurvey = handleTest ./limesurvey.nix {};
  listmonk = handleTest ./listmonk.nix {};
  litestream = handleTest ./litestream.nix {};
  lldap = handleTest ./lldap.nix {};
  locate = handleTest ./locate.nix {};
  login = handleTest ./login.nix {};
  logrotate = handleTest ./logrotate.nix {};
  loki = handleTest ./loki.nix {};
  luks = handleTest ./luks.nix {};
  lvm2 = handleTest ./lvm2 {};
  lxd = handleTest ./lxd.nix {};
  lxd-nftables = handleTest ./lxd-nftables.nix {};
  lxd-image-server = handleTest ./lxd-image-server.nix {};
  #logstash = handleTest ./logstash.nix {};
  lorri = handleTest ./lorri/default.nix {};
  maddy = discoverTests (import ./maddy { inherit handleTest; });
  maestral = handleTest ./maestral.nix {};
  magic-wormhole-mailbox-server = handleTest ./magic-wormhole-mailbox-server.nix {};
  magnetico = handleTest ./magnetico.nix {};
  mailcatcher = handleTest ./mailcatcher.nix {};
  mailhog = handleTest ./mailhog.nix {};
  man = handleTest ./man.nix {};
  mariadb-galera = handleTest ./mysql/mariadb-galera.nix {};
  mastodon = discoverTests (import ./web-apps/mastodon { inherit handleTestOn; });
  pixelfed = discoverTests (import ./web-apps/pixelfed { inherit handleTestOn; });
  mate = handleTest ./mate.nix {};
  matomo = handleTest ./matomo.nix {};
  matrix-appservice-irc = handleTest ./matrix/appservice-irc.nix {};
  matrix-conduit = handleTest ./matrix/conduit.nix {};
  matrix-synapse = handleTest ./matrix/synapse.nix {};
  mattermost = handleTest ./mattermost.nix {};
  mediatomb = handleTest ./mediatomb.nix {};
  mediawiki = handleTest ./mediawiki.nix {};
  meilisearch = handleTest ./meilisearch.nix {};
  memcached = handleTest ./memcached.nix {};
  merecat = handleTest ./merecat.nix {};
  metabase = handleTest ./metabase.nix {};
  mindustry = handleTest ./mindustry.nix {};
  minecraft = handleTest ./minecraft.nix {};
  minecraft-server = handleTest ./minecraft-server.nix {};
  minidlna = handleTest ./minidlna.nix {};
  miniflux = handleTest ./miniflux.nix {};
  minio = handleTest ./minio.nix {};
  miriway = handleTest ./miriway.nix {};
  misc = handleTest ./misc.nix {};
  mjolnir = handleTest ./matrix/mjolnir.nix {};
  mod_perl = handleTest ./mod_perl.nix {};
  molly-brown = handleTest ./molly-brown.nix {};
  monica = handleTest ./web-apps/monica.nix {};
  mongodb = handleTest ./mongodb.nix {};
  moodle = handleTest ./moodle.nix {};
  moonraker = handleTest ./moonraker.nix {};
  morty = handleTest ./morty.nix {};
  mosquitto = handleTest ./mosquitto.nix {};
  moosefs = handleTest ./moosefs.nix {};
  mpd = handleTest ./mpd.nix {};
  mpv = handleTest ./mpv.nix {};
  mtp = handleTest ./mtp.nix {};
  multipass = handleTest ./multipass.nix {};
  mumble = handleTest ./mumble.nix {};
  # Fails on aarch64-linux at the PDF creation step - need to debug this on an
  # aarch64 machine..
  musescore = handleTestOn ["x86_64-linux"] ./musescore.nix {};
  munin = handleTest ./munin.nix {};
  mutableUsers = handleTest ./mutable-users.nix {};
  mxisd = handleTest ./mxisd.nix {};
  mysql = handleTest ./mysql/mysql.nix {};
  mysql-autobackup = handleTest ./mysql/mysql-autobackup.nix {};
  mysql-backup = handleTest ./mysql/mysql-backup.nix {};
  mysql-replication = handleTest ./mysql/mysql-replication.nix {};
  n8n = handleTest ./n8n.nix {};
  nagios = handleTest ./nagios.nix {};
  nar-serve = handleTest ./nar-serve.nix {};
  nat.firewall = handleTest ./nat.nix { withFirewall = true; };
  nat.standalone = handleTest ./nat.nix { withFirewall = false; };
  nat.nftables.firewall = handleTest ./nat.nix { withFirewall = true; nftables = true; };
  nat.nftables.standalone = handleTest ./nat.nix { withFirewall = false; nftables = true; };
  nats = handleTest ./nats.nix {};
  navidrome = handleTest ./navidrome.nix {};
  nbd = handleTest ./nbd.nix {};
  ncdns = handleTest ./ncdns.nix {};
  ndppd = handleTest ./ndppd.nix {};
  nebula = handleTest ./nebula.nix {};
  netbird = handleTest ./netbird.nix {};
  neo4j = handleTest ./neo4j.nix {};
  netdata = handleTest ./netdata.nix {};
  networking.networkd = handleTest ./networking.nix { networkd = true; };
  networking.scripted = handleTest ./networking.nix { networkd = false; };
  netbox = handleTest ./web-apps/netbox.nix { inherit (pkgs) netbox; };
  netbox_3_3 = handleTest ./web-apps/netbox.nix { netbox = pkgs.netbox_3_3; };
  # TODO: put in networking.nix after the test becomes more complete
  networkingProxy = handleTest ./networking-proxy.nix {};
  nextcloud = handleTest ./nextcloud {};
  nexus = handleTest ./nexus.nix {};
  # TODO: Test nfsv3 + Kerberos
  nfs3 = handleTest ./nfs { version = 3; };
  nfs4 = handleTest ./nfs { version = 4; };
  nghttpx = handleTest ./nghttpx.nix {};
  nginx = handleTest ./nginx.nix {};
  nginx-auth = handleTest ./nginx-auth.nix {};
  nginx-etag = handleTest ./nginx-etag.nix {};
  nginx-globalredirect = handleTest ./nginx-globalredirect.nix {};
  nginx-http3 = handleTest ./nginx-http3.nix {};
  nginx-modsecurity = handleTest ./nginx-modsecurity.nix {};
  nginx-njs = handleTest ./nginx-njs.nix {};
  nginx-pubhtml = handleTest ./nginx-pubhtml.nix {};
  nginx-sandbox = handleTestOn ["x86_64-linux"] ./nginx-sandbox.nix {};
  nginx-sso = handleTest ./nginx-sso.nix {};
  nginx-variants = handleTest ./nginx-variants.nix {};
  nifi = handleTestOn ["x86_64-linux"] ./web-apps/nifi.nix {};
  nitter = handleTest ./nitter.nix {};
  nix-ld = handleTest ./nix-ld.nix {};
  nix-serve = handleTest ./nix-serve.nix {};
  nix-serve-ssh = handleTest ./nix-serve-ssh.nix {};
  nixops = handleTest ./nixops/default.nix {};
  nixos-generate-config = handleTest ./nixos-generate-config.nix {};
  nixos-rebuild-specialisations = handleTest ./nixos-rebuild-specialisations.nix {};
  nixpkgs = pkgs.callPackage ../modules/misc/nixpkgs/test.nix { inherit evalMinimalConfig; };
  node-red = handleTest ./node-red.nix {};
  nomad = handleTest ./nomad.nix {};
  non-default-filesystems = handleTest ./non-default-filesystems.nix {};
  noto-fonts = handleTest ./noto-fonts.nix {};
  noto-fonts-cjk-qt-default-weight = handleTest ./noto-fonts-cjk-qt-default-weight.nix {};
  novacomd = handleTestOn ["x86_64-linux"] ./novacomd.nix {};
  nscd = handleTest ./nscd.nix {};
  nsd = handleTest ./nsd.nix {};
  ntfy-sh = handleTest ./ntfy-sh.nix {};
  nzbget = handleTest ./nzbget.nix {};
  nzbhydra2 = handleTest ./nzbhydra2.nix {};
  oh-my-zsh = handleTest ./oh-my-zsh.nix {};
  ombi = handleTest ./ombi.nix {};
  openarena = handleTest ./openarena.nix {};
  openldap = handleTest ./openldap.nix {};
  opensearch = discoverTests (import ./opensearch.nix);
  openresty-lua = handleTest ./openresty-lua.nix {};
  opensmtpd = handleTest ./opensmtpd.nix {};
  opensmtpd-rspamd = handleTest ./opensmtpd-rspamd.nix {};
  openssh = handleTest ./openssh.nix {};
  octoprint = handleTest ./octoprint.nix {};
  openstack-image-metadata = (handleTestOn ["x86_64-linux"] ./openstack-image.nix {}).metadata or {};
  openstack-image-userdata = (handleTestOn ["x86_64-linux"] ./openstack-image.nix {}).userdata or {};
  opentabletdriver = handleTest ./opentabletdriver.nix {};
  owncast = handleTest ./owncast.nix {};
  image-contents = handleTest ./image-contents.nix {};
  orangefs = handleTest ./orangefs.nix {};
  os-prober = handleTestOn ["x86_64-linux"] ./os-prober.nix {};
  osrm-backend = handleTest ./osrm-backend.nix {};
  overlayfs = handleTest ./overlayfs.nix {};
  pacemaker = handleTest ./pacemaker.nix {};
  packagekit = handleTest ./packagekit.nix {};
  pam-file-contents = handleTest ./pam/pam-file-contents.nix {};
  pam-oath-login = handleTest ./pam/pam-oath-login.nix {};
  pam-u2f = handleTest ./pam/pam-u2f.nix {};
  pam-ussh = handleTest ./pam/pam-ussh.nix {};
  pass-secret-service = handleTest ./pass-secret-service.nix {};
  patroni = handleTestOn ["x86_64-linux"] ./patroni.nix {};
  pantalaimon = handleTest ./matrix/pantalaimon.nix {};
  pantheon = handleTest ./pantheon.nix {};
  paperless = handleTest ./paperless.nix {};
  parsedmarc = handleTest ./parsedmarc {};
  pdns-recursor = handleTest ./pdns-recursor.nix {};
  peerflix = handleTest ./peerflix.nix {};
  peering-manager = handleTest ./web-apps/peering-manager.nix {};
  peertube = handleTestOn ["x86_64-linux"] ./web-apps/peertube.nix {};
  peroxide = handleTest ./peroxide.nix {};
  pgadmin4 = handleTest ./pgadmin4.nix {};
  pgjwt = handleTest ./pgjwt.nix {};
  pgmanage = handleTest ./pgmanage.nix {};
  phosh = handleTest ./phosh.nix {};
  photoprism = handleTest ./photoprism.nix {};
  php = handleTest ./php {};
  php80 = handleTest ./php { php = pkgs.php80; };
  php81 = handleTest ./php { php = pkgs.php81; };
  php82 = handleTest ./php { php = pkgs.php82; };
  phylactery = handleTest ./web-apps/phylactery.nix {};
  pict-rs = handleTest ./pict-rs.nix {};
  pinnwand = handleTest ./pinnwand.nix {};
  plasma-bigscreen = handleTest ./plasma-bigscreen.nix {};
  plasma5 = handleTest ./plasma5.nix {};
  plasma5-systemd-start = handleTest ./plasma5-systemd-start.nix {};
  plausible = handleTest ./plausible.nix {};
  please = handleTest ./please.nix {};
  pleroma = handleTestOn [ "x86_64-linux" "aarch64-linux" ] ./pleroma.nix {};
  plikd = handleTest ./plikd.nix {};
  plotinus = handleTest ./plotinus.nix {};
  podgrab = handleTest ./podgrab.nix {};
  podman = handleTestOn ["aarch64-linux" "x86_64-linux"] ./podman/default.nix {};
  podman-tls-ghostunnel = handleTestOn ["aarch64-linux" "x86_64-linux"] ./podman/tls-ghostunnel.nix {};
  polaris = handleTest ./polaris.nix {};
  pomerium = handleTestOn ["x86_64-linux"] ./pomerium.nix {};
  postfix = handleTest ./postfix.nix {};
  postfix-raise-smtpd-tls-security-level = handleTest ./postfix-raise-smtpd-tls-security-level.nix {};
  postfixadmin = handleTest ./postfixadmin.nix {};
  postgis = handleTest ./postgis.nix {};
  postgresql = handleTest ./postgresql.nix {};
  postgresql-jit = handleTest ./postgresql-jit.nix {};
  postgresql-wal-receiver = handleTest ./postgresql-wal-receiver.nix {};
  powerdns = handleTest ./powerdns.nix {};
  powerdns-admin = handleTest ./powerdns-admin.nix {};
  power-profiles-daemon = handleTest ./power-profiles-daemon.nix {};
  pppd = handleTest ./pppd.nix {};
  predictable-interface-names = handleTest ./predictable-interface-names.nix {};
  printing-socket = handleTest ./printing.nix { socket = true; };
  printing-service = handleTest ./printing.nix { socket = false; };
  privacyidea = handleTest ./privacyidea.nix {};
  privoxy = handleTest ./privoxy.nix {};
  prometheus = handleTest ./prometheus.nix {};
  prometheus-exporters = handleTest ./prometheus-exporters.nix {};
  prosody = handleTest ./xmpp/prosody.nix {};
  prosody-mysql = handleTest ./xmpp/prosody-mysql.nix {};
  proxy = handleTest ./proxy.nix {};
  prowlarr = handleTest ./prowlarr.nix {};
  pt2-clone = handleTest ./pt2-clone.nix {};
  pykms = handleTest ./pykms.nix {};
  public-inbox = handleTest ./public-inbox.nix {};
  pufferpanel = handleTest ./pufferpanel.nix {};
  pulseaudio = discoverTests (import ./pulseaudio.nix);
  qboot = handleTestOn ["x86_64-linux" "i686-linux"] ./qboot.nix {};
  qemu-vm-restrictnetwork = handleTest ./qemu-vm-restrictnetwork.nix {};
  quorum = handleTest ./quorum.nix {};
  quake3 = handleTest ./quake3.nix {};
  rabbitmq = handleTest ./rabbitmq.nix {};
  radarr = handleTest ./radarr.nix {};
  radicale = handleTest ./radicale.nix {};
  rasdaemon = handleTest ./rasdaemon.nix {};
  readarr = handleTest ./readarr.nix {};
  redis = handleTest ./redis.nix {};
  redmine = handleTest ./redmine.nix {};
  restartByActivationScript = handleTest ./restart-by-activation-script.nix {};
  restic = handleTest ./restic.nix {};
  retroarch = handleTest ./retroarch.nix {};
  robustirc-bridge = handleTest ./robustirc-bridge.nix {};
  roundcube = handleTest ./roundcube.nix {};
  rspamd = handleTest ./rspamd.nix {};
  rss2email = handleTest ./rss2email.nix {};
  rstudio-server = handleTest ./rstudio-server.nix {};
  rsyncd = handleTest ./rsyncd.nix {};
  rsyslogd = handleTest ./rsyslogd.nix {};
  rxe = handleTest ./rxe.nix {};
  sabnzbd = handleTest ./sabnzbd.nix {};
  samba = handleTest ./samba.nix {};
  samba-wsdd = handleTest ./samba-wsdd.nix {};
  sanoid = handleTest ./sanoid.nix {};
  schleuder = handleTest ./schleuder.nix {};
  sddm = handleTest ./sddm.nix {};
  seafile = handleTest ./seafile.nix {};
  searx = handleTest ./searx.nix {};
  service-runner = handleTest ./service-runner.nix {};
  sfxr-qt = handleTest ./sfxr-qt.nix {};
  sgtpuzzles = handleTest ./sgtpuzzles.nix {};
  shadow = handleTest ./shadow.nix {};
  shadowsocks = handleTest ./shadowsocks {};
  shattered-pixel-dungeon = handleTest ./shattered-pixel-dungeon.nix {};
  shiori = handleTest ./shiori.nix {};
  signal-desktop = handleTest ./signal-desktop.nix {};
  simple = handleTest ./simple.nix {};
  slurm = handleTest ./slurm.nix {};
  smokeping = handleTest ./smokeping.nix {};
  snapcast = handleTest ./snapcast.nix {};
  snapper = handleTest ./snapper.nix {};
  snipe-it = runTest ./web-apps/snipe-it.nix;
  soapui = handleTest ./soapui.nix {};
  sogo = handleTest ./sogo.nix {};
  solanum = handleTest ./solanum.nix {};
  sonarr = handleTest ./sonarr.nix {};
  sourcehut = handleTest ./sourcehut.nix {};
  spacecookie = handleTest ./spacecookie.nix {};
  spark = handleTestOn [ "x86_64-linux" "aarch64-linux" ] ./spark {};
  sqlite3-to-mysql = handleTest ./sqlite3-to-mysql.nix {};
  sslh = handleTest ./sslh.nix {};
  sssd = handleTestOn ["x86_64-linux"] ./sssd.nix {};
  sssd-ldap = handleTestOn ["x86_64-linux"] ./sssd-ldap.nix {};
  stargazer = runTest ./web-servers/stargazer.nix;
  starship = handleTest ./starship.nix {};
  step-ca = handleTestOn ["x86_64-linux"] ./step-ca.nix {};
  stratis = handleTest ./stratis {};
  strongswan-swanctl = handleTest ./strongswan-swanctl.nix {};
  stunnel = handleTest ./stunnel.nix {};
  sudo = handleTest ./sudo.nix {};
  swap-file-btrfs = handleTest ./swap-file-btrfs.nix {};
  swap-partition = handleTest ./swap-partition.nix {};
  swap-random-encryption = handleTest ./swap-random-encryption.nix {};
  sway = handleTest ./sway.nix {};
  switchTest = handleTest ./switch-test.nix {};
  sympa = handleTest ./sympa.nix {};
  syncthing = handleTest ./syncthing.nix {};
  syncthing-init = handleTest ./syncthing-init.nix {};
  syncthing-relay = handleTest ./syncthing-relay.nix {};
  systemd = handleTest ./systemd.nix {};
  systemd-analyze = handleTest ./systemd-analyze.nix {};
  systemd-binfmt = handleTestOn ["x86_64-linux"] ./systemd-binfmt.nix {};
  systemd-boot = handleTest ./systemd-boot.nix {};
  systemd-bpf = handleTest ./systemd-bpf.nix {};
  systemd-confinement = handleTest ./systemd-confinement.nix {};
  systemd-coredump = handleTest ./systemd-coredump.nix {};
  systemd-cryptenroll = handleTest ./systemd-cryptenroll.nix {};
  systemd-credentials-tpm2 = handleTest ./systemd-credentials-tpm2.nix {};
  systemd-escaping = handleTest ./systemd-escaping.nix {};
  systemd-initrd-btrfs-raid = handleTest ./systemd-initrd-btrfs-raid.nix {};
  systemd-initrd-luks-fido2 = handleTest ./systemd-initrd-luks-fido2.nix {};
  systemd-initrd-luks-keyfile = handleTest ./systemd-initrd-luks-keyfile.nix {};
  systemd-initrd-luks-empty-passphrase = handleTest ./initrd-luks-empty-passphrase.nix { systemdStage1 = true; };
  systemd-initrd-luks-password = handleTest ./systemd-initrd-luks-password.nix {};
  systemd-initrd-luks-tpm2 = handleTest ./systemd-initrd-luks-tpm2.nix {};
  systemd-initrd-modprobe = handleTest ./systemd-initrd-modprobe.nix {};
  systemd-initrd-shutdown = handleTest ./systemd-shutdown.nix { systemdStage1 = true; };
  systemd-initrd-simple = handleTest ./systemd-initrd-simple.nix {};
  systemd-initrd-swraid = handleTest ./systemd-initrd-swraid.nix {};
  systemd-initrd-vconsole = handleTest ./systemd-initrd-vconsole.nix {};
  systemd-initrd-networkd = handleTest ./systemd-initrd-networkd.nix {};
  systemd-initrd-networkd-ssh = handleTest ./systemd-initrd-networkd-ssh.nix {};
  systemd-initrd-networkd-openvpn = handleTest ./initrd-network-openvpn { systemdStage1 = true; };
  systemd-journal = handleTest ./systemd-journal.nix {};
  systemd-machinectl = handleTest ./systemd-machinectl.nix {};
  systemd-networkd = handleTest ./systemd-networkd.nix {};
  systemd-networkd-dhcpserver = handleTest ./systemd-networkd-dhcpserver.nix {};
  systemd-networkd-dhcpserver-static-leases = handleTest ./systemd-networkd-dhcpserver-static-leases.nix {};
  systemd-networkd-ipv6-prefix-delegation = handleTest ./systemd-networkd-ipv6-prefix-delegation.nix {};
  systemd-networkd-vrf = handleTest ./systemd-networkd-vrf.nix {};
  systemd-no-tainted = handleTest ./systemd-no-tainted.nix {};
  systemd-nspawn = handleTest ./systemd-nspawn.nix {};
  systemd-oomd = handleTest ./systemd-oomd.nix {};
  systemd-portabled = handleTest ./systemd-portabled.nix {};
  systemd-repart = handleTest ./systemd-repart.nix {};
  systemd-shutdown = handleTest ./systemd-shutdown.nix {};
  systemd-timesyncd = handleTest ./systemd-timesyncd.nix {};
  systemd-user-tmpfiles-rules = handleTest ./systemd-user-tmpfiles-rules.nix {};
  systemd-misc = handleTest ./systemd-misc.nix {};
  systemd-userdbd = handleTest ./systemd-userdbd.nix {};
  systemd-homed = handleTest ./systemd-homed.nix {};
  tandoor-recipes = handleTest ./tandoor-recipes.nix {};
  taskserver = handleTest ./taskserver.nix {};
  tayga = handleTest ./tayga.nix {};
  teeworlds = handleTest ./teeworlds.nix {};
  telegraf = handleTest ./telegraf.nix {};
  teleport = handleTest ./teleport.nix {};
  thelounge = handleTest ./thelounge.nix {};
  terminal-emulators = handleTest ./terminal-emulators.nix {};
  tiddlywiki = handleTest ./tiddlywiki.nix {};
  tigervnc = handleTest ./tigervnc.nix {};
  timescaledb = handleTest ./timescaledb.nix {};
  promscale = handleTest ./promscale.nix {};
  timezone = handleTest ./timezone.nix {};
  tinc = handleTest ./tinc {};
  tinydns = handleTest ./tinydns.nix {};
  tinywl = handleTest ./tinywl.nix {};
  tmate-ssh-server = handleTest ./tmate-ssh-server.nix { };
  tomcat = handleTest ./tomcat.nix {};
  tor = handleTest ./tor.nix {};
  traefik = handleTestOn ["aarch64-linux" "x86_64-linux"] ./traefik.nix {};
  trafficserver = handleTest ./trafficserver.nix {};
  transmission = handleTest ./transmission.nix {};
  # tracee requires bpf
  tracee = handleTestOn ["x86_64-linux"] ./tracee.nix {};
  trezord = handleTest ./trezord.nix {};
  trickster = handleTest ./trickster.nix {};
  trilium-server = handleTestOn ["x86_64-linux"] ./trilium-server.nix {};
  tsm-client-gui = handleTest ./tsm-client-gui.nix {};
  txredisapi = handleTest ./txredisapi.nix {};
  tuptime = handleTest ./tuptime.nix {};
  turbovnc-headless-server = handleTest ./turbovnc-headless-server.nix {};
  tuxguitar = handleTest ./tuxguitar.nix {};
  ucarp = handleTest ./ucarp.nix {};
  udisks2 = handleTest ./udisks2.nix {};
  ulogd = handleTest ./ulogd.nix {};
  unbound = handleTest ./unbound.nix {};
  unifi = handleTest ./unifi.nix {};
  unit-php = handleTest ./web-servers/unit-php.nix {};
  upnp = handleTest ./upnp.nix {};
  uptermd = handleTest ./uptermd.nix {};
  uptime-kuma = handleTest ./uptime-kuma.nix {};
  usbguard = handleTest ./usbguard.nix {};
  user-activation-scripts = handleTest ./user-activation-scripts.nix {};
  user-home-mode = handleTest ./user-home-mode.nix {};
  uwsgi = handleTest ./uwsgi.nix {};
  v2ray = handleTest ./v2ray.nix {};
  varnish60 = handleTest ./varnish.nix { package = pkgs.varnish60; };
  varnish72 = handleTest ./varnish.nix { package = pkgs.varnish72; };
  vault = handleTest ./vault.nix {};
  vault-agent = handleTest ./vault-agent.nix {};
  vault-dev = handleTest ./vault-dev.nix {};
  vault-postgresql = handleTest ./vault-postgresql.nix {};
  vaultwarden = handleTest ./vaultwarden.nix {};
  vector = handleTest ./vector.nix {};
  vengi-tools = handleTest ./vengi-tools.nix {};
  victoriametrics = handleTest ./victoriametrics.nix {};
  vikunja = handleTest ./vikunja.nix {};
  virtualbox = handleTestOn ["x86_64-linux"] ./virtualbox.nix {};
  vscodium = discoverTests (import ./vscodium.nix);
  vsftpd = handleTest ./vsftpd.nix {};
  warzone2100 = handleTest ./warzone2100.nix {};
  wasabibackend = handleTest ./wasabibackend.nix {};
  webhook = runTest ./webhook.nix;
  wiki-js = handleTest ./wiki-js.nix {};
  wine = handleTest ./wine.nix {};
  wireguard = handleTest ./wireguard {};
  without-nix = handleTest ./without-nix.nix {};
  wmderland = handleTest ./wmderland.nix {};
  wpa_supplicant = handleTest ./wpa_supplicant.nix {};
  wordpress = handleTest ./wordpress.nix {};
  wrappers = handleTest ./wrappers.nix {};
  writefreely = handleTest ./web-apps/writefreely.nix {};
  xandikos = handleTest ./xandikos.nix {};
  xautolock = handleTest ./xautolock.nix {};
  xfce = handleTest ./xfce.nix {};
  xmonad = handleTest ./xmonad.nix {};
  xmonad-xdg-autostart = handleTest ./xmonad-xdg-autostart.nix {};
  xpadneo = handleTest ./xpadneo.nix {};
  xrdp = handleTest ./xrdp.nix {};
  xss-lock = handleTest ./xss-lock.nix {};
  xterm = handleTest ./xterm.nix {};
  xxh = handleTest ./xxh.nix {};
  yabar = handleTest ./yabar.nix {};
  yggdrasil = handleTest ./yggdrasil.nix {};
  zammad = handleTest ./zammad.nix {};
  zeronet-conservancy = handleTest ./zeronet-conservancy.nix {};
  zfs = handleTest ./zfs.nix {};
  zigbee2mqtt = handleTest ./zigbee2mqtt.nix {};
  zoneminder = handleTest ./zoneminder.nix {};
  zookeeper = handleTest ./zookeeper.nix {};
  zram-generator = handleTest ./zram-generator.nix {};
  zrepl = handleTest ./zrepl.nix {};
  zsh-history = handleTest ./zsh-history.nix {};
}
