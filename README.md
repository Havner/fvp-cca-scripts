# Prerequisites

To compile all of it some packages need to be available on the distro. Specific
details can be found here (toolchains will be downloaded by scripts, only
talking about distro provided tools):

https://trustedfirmware-a.readthedocs.io/en/latest/getting_started/prerequisites.html#package-installation-linux
https://tf-rmm.readthedocs.io/en/latest/getting_started/getting-started.html#package-installation-ubuntu-20-04-x64

Also cross compilation tools are needed for libfdt/kvmtool:
crossbuild-essential-arm64.

A quick summary for Ubuntu 20.04 (might not be complete). You need newer cmake
than the one Ubuntu provides. Hence snap.

    sudo apt-get install -y git build-essential python3 python3-pip make ninja-build device-tree-compiler
    sudo snap install cmake
    wget https://git.trustedfirmware.org/TF-RMM/tf-rmm.git/plain/docs/requirements.txt
    pip3 install --upgrade pip
    pip3 install -r requirements.txt
    sudo apt-get install crossbuild-essential-arm64 ccache bear

**IMPORTANT**

Add the snap directory to your PATH so the newer cmake will be available:

    export PATH="/snap/bin:$PATH"

# Space requirements

You need around 20GB. Maybe a little bit more.

- 14GB for init (it's possible to limit this significantly by doing shallow git)
- 3GB for the build itself
- 3GB for ccache

# Initialization

    $ ./scripts/fvp-cca.sh init

This step downloads all repos and sets them to proper branch and downloads
toolchains. If sucessful should be done just once.

Each rerun of this command will cleanup the whole directory and start from
scratch.

# Building

    $ ./scripts/fvp-cca.sh build

# Running

    $ ./scripts/fvp-cca.sh run

If you run this with an X Server you should see 3 windows. One FVP status window
and two xterms with terminal output. If you don't have X ignore the DISPLAY
messages and on separate terminals do:

    $ telnet localhost 5000
    $ telnet localhost 5003

The first one will show non secure world output, the second one will show RMM.

Also this version requires RSS to communicate with FVP/TF-A on port 5002
(UART2). Without it the TF-A will be locked on start waiting for reply to its
PSA call. You can use: https://github.com/Havner/minirss

# Running realm

Login as 'root'

Then:

    # cd /shared
    # ./realm.sh

Also give it time. It takes a while to load.

# Running kvm realm/rsi tests

Login as 'root'

Then:

    # cd /shared/kvm-tests
	# ./run-realm-tests

# Network

Network for FVP and Realm is configured automatically. To make use of it however
one needs to configure the host machine *before* running FVP. This is done with:

    $ ./scripts/fvp-cca.sh net_start

It will be done with sudo so expect the command to ask for a password. The
command 'net_stop' cleans that configuration.

That command configures a tap interface named cca0 and its address. It also
configures MASQUERADE for the FVP so the network from FVP (and from Realm) can
reach internet. The host's address is: 192.168.30.1. The FVP address is
192.168.30.2. FVP starts telnetd automatically so it's possible to telnet to
192.168.30.2 with root account without password to reach FVP machine.

On FVP machine, the lkvm that starts the Realm also configures tap0 device with
an address 192.168.33.1. The Realm will have address 192.168.33.2. MASQUERADE is
also configured so the Realm can access internet. DNS will not work though,
probably due to lack of glibc on the Realm (and as a consequence due to the lack
of DNS functions).

Realm also has a telnetd started so you can telnet to the Realm from FVP with
its address. No password required, it will drop directly to shell. FVP also has
a DNAT configured so you can telnet directly to the Realm from the host with
'telnet 192.168.30.2 2323'.

Summary of useful commands from the host:

    $ ./scripts/fvp-cca.sh net_start
	$ telnet 192.168.30.2
	$ telnet 192.168.30.2 2323

Summary of useful commands from the FVP:

    # ping -c 4 samsung.com
	# telnet 192.168.33.2

Summary of useful commands from the Realm:

    # ping -c 4 8.8.8.8

# Other options

Each step can be run on its own if there is a need:

    $ ./scripts/fvp-cca.sh --help
    Run with a target function name for what you intend to do.

    Possible targets are:
      init_clean
      init_tf_rmm
      init_tf_a
      init_linux_host
      init_linux_realm
      init_dtc
      init_kvmtool
	  init_kvm_unit_tests
      init_toolchains
      init_fvp
      init_out
      init           (does all the inits above including clean)
      build_tf_rmm
      build_tf_a
      build_linux_host
      build_linux_realm
      build_libfdt
      build_kvmtool
	  build_kvm_unit_tests
      build_root_host
      build_root_realm
      build          (does all the builds above in the correct order)
      run

      net_start      (requires root/sudo, allows to connect to FVP/realm)
      net_stop       (requires root/sudo, cleans up after net_start)

    Running without argument does:
      build
      run

    Initialization should be performed just once.
