{ github-runner }:
github-runner.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches ++ [
    # for https://github.com/falcondev-oss/github-actions-cache-server
    ./prevent-overwriting-ACTIONS_RESULTS_URL.patch
    ./external-caching.patch
  ];
})
