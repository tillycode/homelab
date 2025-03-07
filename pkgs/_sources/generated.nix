# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  github-actions-cache-server = {
    pname = "github-actions-cache-server";
    version = "eaa039a4929650864bdddad1113e81b543ac3d44";
    src = fetchgit {
      url = "https://github.com/falcondev-oss/github-actions-cache-server.git";
      rev = "eaa039a4929650864bdddad1113e81b543ac3d44";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sparseCheckout = [ ];
      sha256 = "sha256-JBgcP/GloTdWT3DMM6cty3z8RXt8aArtwofPSO8RVgg=";
    };
    pnpmDepsHash = "sha256-og8VtU+zkC5nKgDSm21qW7GuAVqByUa0JGxc5/MUnPM=";
    date = "2025-03-07";
  };
  headscale-ui = {
    pname = "headscale-ui";
    version = "2025.01.20";
    src = fetchFromGitHub {
      owner = "gurucomputing";
      repo = "headscale-ui";
      rev = "2025.01.20";
      fetchSubmodules = false;
      sha256 = "sha256-I+kPzVxLwZ3Gw0oLro8j6p7D+n81mbPZ5t2wDcNP0lA=";
    };
  };
  sing-box = {
    pname = "sing-box";
    version = "v1.12.0-alpha.13";
    src = fetchFromGitHub {
      owner = "SagerNet";
      repo = "sing-box";
      rev = "v1.12.0-alpha.13";
      fetchSubmodules = false;
      sha256 = "sha256-bMG6Kn+s7v+hWLMoo5T1m9hnqdNJ/w4Iqcj+w8r4Rn8=";
    };
    vendorHash = "sha256-SLTrWUl73B/rqfEppM/O3LchEc/bHifAbvY+cM7d7dc=";
  };
  terraboard = {
    pname = "terraboard";
    version = "v2.4.0";
    src = fetchFromGitHub {
      owner = "camptocamp";
      repo = "terraboard";
      rev = "v2.4.0";
      fetchSubmodules = false;
      sha256 = "sha256-BkvGOE1ElETp4NLgMC9s8BtzNkskkvFt6/nVgmJNRww=";
    };
  };
}
