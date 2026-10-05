# Omarchy+ Odysseus

Owned Omarchy bar plugin for the locally hosted Odysseus AI workspace.

Left click starts the Qwen3-14B model, waits for both model and workspace readiness, and opens http://localhost:7000. Right click stops the model and releases its GPU memory. The filled dot means the managed service is active; an ellipsis indicates startup or an action in progress. The plugin polls service state every five seconds without starting Docker or loading a model.

Closing the browser does not stop the model. Use right click to unload it. Enabling the plugin does not start the model. The runtime has no boot enablement or automatic restart. The workspace services may remain running without occupying model VRAM.

## Requirements and installation

Hugin: Omarchy/Quickshell, Docker Compose, NVIDIA Container Toolkit, polkit with a graphical authentication agent, Python 3, and the existing working Odysseus stack. Runtime names are deliberately fixed to `odysseus-llama` and `odysseus-odysseus-1` on `odysseus_default`.

1. Run `scripts/validate` in the checkout.
2. Run `scripts/install-runtime`. This installs two owned root files and stops/adopts the existing model container; it does not touch Odysseus data, credentials or downloaded models.
3. Install the GitHub plugin: `omarchy plugin add https://github.com/ol4vr/omarchy-plus-odysseus.git --enable --yes`.
4. Choose placement with `omarchy bar move io.github.ol4vr.odysseus --section right`.

Open/Stop uses `pkexec /usr/bin/systemctl` for this dedicated service and may prompt for authentication. No Docker-group membership, passwordless sudo rule or Docker socket access is granted to the plugin. The service runs Docker control as root; it never executes source files from a user-writable checkout as root. Only root-owned copies under `/etc/systemd/system` and `/usr/local/libexec` are executed.

## Recovery

`config.json` records the tested model revision, image digest, context size and endpoint. `runtime/model-compose.yml` records the equivalent model-container setup. Restore the Odysseus stack and NVIDIA runtime first. Download the named GGUF at the recorded revision locally, then set `ODYSSEUS_MODEL_CACHE` to its absolute Hugging Face hub directory. After stopping/removing any old container of the same name, `docker compose -f runtime/model-compose.yml create` creates the stopped model container. Re-run `scripts/install-runtime` and install the plugin. Add endpoint `http://odysseus-llama:8000/v1` inside Odysseus with model `qwen3-14b`.

This repository contains code and model identifiers only, never downloaded weights, account secrets, conversations or client files. Downloading requires internet. Local chat was tested with Hugin disconnected; this plugin does not enforce network isolation and is not the protected photography Studio environment.

## Verification on Hugin

Confirm left click reaches a ready model and opens the workspace; send a chat message and inspect `nvidia-smi`. Right click must leave `systemctl is-active omarchy-plus-odysseus.service` inactive and remove the llama-server GPU allocation. Repeat start/stop, check cancellation of authentication, and confirm a reboot does not load the model until Open. Repeat the disconnected chat test after setup.

## Removal

Stop the model first, then remove the plugin with `omarchy plugin remove io.github.ol4vr.odysseus`. To remove the runtime, stop its service, remove only `/etc/systemd/system/omarchy-plus-odysseus.service` and `/usr/local/libexec/omarchy-plus-odysseus-ready`, then run `sudo systemctl daemon-reload`. Model containers, downloads and workspace data are preserved.

## License

MIT. Upstream Odysseus and llama.cpp retain their own licenses; this repository distributes neither project nor their model weights.
