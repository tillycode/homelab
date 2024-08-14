{
  services.k3s = {
    role = "server";
    extraFlags = [
      "--node-label"
      "svccontroller.k3s.cattle.io/enablelb=true"
    ];
  };
}
