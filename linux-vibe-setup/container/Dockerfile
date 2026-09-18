# Podman-friendly dev container with the same per-user tooling as
# ../setup_user.py installs on a real basbox login (herdr, starship, delta,
# bat, fd, zoxide, ripgrep, fzf, claude, copilot, uv, node).
#
# Build context must be the linux-vibe-setup directory itself, so
# setup_user.py can find linux-tools.toml next to it:
#
#   cd linux-vibe-setup
#   podman build -f container/Dockerfile -t linux-vibe-devcontainer .
#   podman run -it --name devbox linux-vibe-devcontainer
#
# setup_system.py installs the complete shared package set in package-only mode.
# Host account configuration (subuid/subgid ranges and loginctl linger) is the
# only part skipped because this container does not run systemd.
FROM docker.io/library/ubuntu:24.04

ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3

COPY setup_system.py /tmp/linux-vibe-setup/setup_system.py
RUN python3 /tmp/linux-vibe-setup/setup_system.py --packages-only \
    && rm -rf /var/lib/apt/lists/*

RUN if getent passwd "${UID}" >/dev/null; then \
        userdel --remove "$(getent passwd "${UID}" | cut -d: -f1)"; \
    fi \
    && if getent group "${GID}" >/dev/null; then \
        groupmod --new-name "${USERNAME}" "$(getent group "${GID}" | cut -d: -f1)"; \
    else \
        groupadd --gid "${GID}" "${USERNAME}"; \
    fi \
    && useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash "${USERNAME}"

USER ${USERNAME}
WORKDIR /home/${USERNAME}

COPY --chown=${USERNAME}:${USERNAME} setup_user.py linux-tools.toml ./linux-vibe-setup/
RUN python3 ./linux-vibe-setup/setup_user.py

ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.local/share/node-v22/bin:${PATH}"

CMD ["/bin/bash"]
