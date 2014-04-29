#!/usr/bin/env bats

load _helper
load pkg

setup() {
    mkdir -p tmp/ellipsis_home
    export ELLIPSIS_HOME=tmp/ellipsis_home
}

teardown() {
    rm -rf $ELLIPSIS_HOME
}

@test "pkg.init_globals should setup PKG_PATH and PKG_NAME properly" {
    skip
}

@test "pkg.init should initialize globals for package and source hooks" {
    skip
}

@test "pkg.list_symlinks should list symlinks for package" {
    skip
}

@test "pkg.symlinks_mappings should list symlink mappings for package" {
    skip
}

@test "pkg.run should run command or hook from PKG_PATH" {
    skip
}

@test "pkg.run_hook should run_hook from PKG_PATH" {
    skip
}

@test "pkg.del should unset globals/hooks setup by package initialization" {
    skip
}

@test "pkg.del should unset globals/hooks setup by package initialization" {
    skip
}