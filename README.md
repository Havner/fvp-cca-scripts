# Prerequisites

To compile all of it some packages need to be available on the distro. Specific
details can be found here (toolchains will be downloaded by scripts, only
talking about distro provided tools):

https://trustedfirmware-a.readthedocs.io/en/latest/getting_started/prerequisites.html#package-installation-linux
https://tf-rmm.readthedocs.io/en/latest/getting_started/getting-started.html#package-installation-ubuntu-20-04-x64

A quick summary for Ubuntu 20.04 (might not be complete). You need newer cmake
than the one Ubuntu provides. Hence snap.

    sudo apt-get install -y git build-essential python3 python3-pip make ninja-build device-tree-compiler
    sudo snap install cmake
    wget https://git.trustedfirmware.org/TF-RMM/tf-rmm.git/plain/docs/requirements.txt
    pip3 install --upgrade pip
    pip3 install -r requirements.txt

**IMPORTANT**

Add the snap directory to your PATH so the newer cmake will be available:

    export PATH="/snap/bin:$PATH"

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

# Other options

Each step can be run on its own if there is a need:

    $ ./scripts/fvp-cca.sh --help
    Run with a target function name for what you intend to do.

    Possible targets are:
      init_clean
      init_tf_rmm
      init_tf_a
      init_optee_build
      init_linux_cca
      init_toolchains
      init_fvp
      init_out
      init           (does all the inits above including clean)
      build_tf_rmm
      build_tf_a
      build_ns_linux
      build          (does all the builds above in the correct order)
      run

    Running without argument does:
      build
      run

    Initialization should be performed just once.
