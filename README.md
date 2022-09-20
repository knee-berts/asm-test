# Repo that steps up a smoke test for multi-cluster ASM MCP on GKE clusters.

```bash
export PROJECT_ID=
```

There are makefile commands for these combinations:
* GKE Standard and ASM MCP both on the RAPID Channel
```bash
make install-std-rapid
```
* GKE Standard and ASM MCP both on the REGULAR Channel
```bash
make install-std-regular
```
* GKE Autopilot and ASM MCP both on the RAPID Channel
```bash
make install-ap-rapid
```
* GKE Autopilot and ASM MCP both on the REGULAR Channel
```bash
make install-ap-regular
```

And a command to test Autopilot or Standard clusters connectivity
* GKE Autopilot connectivity test
```bash
make ap-cross-cluster-test
```
* GKE Autopilot and ASM MCP both on the REGULAR Channel
```bash
make std-cross-cluster-test
```
