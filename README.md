# Repo that steps up a smoke test for multi-cluster ASM MCP on GKE clusters.
If you want to run the test across all variations you can run these commands to setup the projects and local configs.

```bash
export FOLDER_ID=
export BILLING_ID=
export PROJECT_PREFIX= 
make setup-test
```

For each test you want to run set the project and pick the make command that aligns with your test combination.
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


::WIP::
And a command to test Autopilot or Standard clusters connectivity
* GKE Autopilot connectivity test
```bash
make ap-cross-cluster-test
```
* GKE Autopilot and ASM MCP both on the REGULAR Channel
```bash
make std-cross-cluster-test
```
