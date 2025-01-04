let
  # issued by step-ca
  szp-io = ''
    -----BEGIN CERTIFICATE-----
    MIIBlzCCAT2gAwIBAgIQD4B4anrG10sDDxJBCNpsXzAKBggqhkjOPQQDAjAqMQ8w
    DQYDVQQKEwZzenAuaW8xFzAVBgNVBAMTDnN6cC5pbyBSb290IENBMB4XDTI1MDEw
    NDExMTAxMloXDTM1MDEwMjExMTAxMlowKjEPMA0GA1UEChMGc3pwLmlvMRcwFQYD
    VQQDEw5zenAuaW8gUm9vdCBDQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABGi7
    8cCxEtgFaQOTrJdRp5vszal/K8EBorPKcD5e2hoF3IeArIR9UT9FOUlFi5VMsO6H
    /ujrT8BHJiUVRSk+kA+jRTBDMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAG
    AQH/AgEBMB0GA1UdDgQWBBRD2EhdWNDhQtvcKmDwlCcqjKUP6DAKBggqhkjOPQQD
    AgNIADBFAiBmFwas1TZ12Ep5I4n3c+3IGa1f6S0a55HI8jF+TzYK1AIhAMUcpooa
    pIN4adad3ISkLGHMEBFybMQxI2321zDTcEEl
    -----END CERTIFICATE-----
  '';
in
{
  security.pki.certificates = [ szp-io ];
}
