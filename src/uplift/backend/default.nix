{ releng_pkgs
}:

let

  inherit (releng_pkgs.lib) mkBackend fromRequirementsFile filterSource;
  inherit (releng_pkgs.pkgs) writeScript redis;
  inherit (releng_pkgs.pkgs.lib) fileContents;
  inherit (releng_pkgs.tools) pypi2nix;

  python = import ./requirements.nix { inherit (releng_pkgs) pkgs; };
  project_name = "uplift/backend";

  self = mkBackend rec {
    inherit python project_name;
    inProduction = true;
    version = fileContents ./VERSION;
    src = filterSource ./. { inherit(self) name; };
    buildInputs =
      (fromRequirementsFile ./../../../lib/cli_common/requirements-dev.txt python.packages) ++
      (fromRequirementsFile ./../../../lib/backend_common/requirements-dev.txt python.packages) ++
      (fromRequirementsFile ./requirements-dev.txt python.packages) ++
      [ redis ];
    propagatedBuildInputs =
      (fromRequirementsFile ./requirements.txt python.packages);
    passthru = {
      update = writeScript "update-${self.name}" ''
        pushd ${self.src_path}
        cache_dir=$PWD/../../../tmp/pypi2nix
        mkdir -p $cache_dir
        eval ${pypi2nix}/bin/pypi2nix -v \
          -C $cache_dir \
          -V 3.7 \
          -O ../../../nix/requirements_override.nix \
          -E postgresql \
          -e vcversioner \
          -e pytest-runner \
          -e setuptools-scm \
          -r requirements.txt \
          -r requirements-dev.txt
        popd
      '';
    };
  };

in self
