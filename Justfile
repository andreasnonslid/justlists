# Define variables for paths
build_dir := "build"
executable := "justlists"

# Command to configure the build
configure:
    mkdir -p {{build_dir}}
    cmake -S . -B {{build_dir}}

# Command to build the program
build:
    just configure
    cmake --build {{build_dir}}

# Command to clean the build directory
clean:
    rm -rf {{build_dir}}

# Command to rebuild the program
rebuild:
    just clean
    just configure
    cmake --build {{build_dir}}

# Command to run the compiled program
run:
    just build
    ./{{build_dir}}/{{executable}}

# Command to update git submodules
update-submodules:
    git submodule update --init --recursive

# Shortcut to rebuild and run
rebuild-run:
    just clean
    just run
